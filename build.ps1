[CmdletBinding()]
param
(
    [string]$OutPath = (Join-Path $PSScriptRoot 'bin'),

    [switch]$Clean,

    [switch]$InstallDependencies,

    [switch]$Build,

    [switch]$Import,

    [switch]$Test,

    [hashtable]$TestConfig = @{
        Output = @{
            Verbosity = 'Detailed'
        }
        Should = @{
            ErrorAction = 'Continue'
        }
    },

    [uri]$UploadTestResultUri
)

$ProjectPath  = $PSScriptRoot | Join-Path -ChildPath PSExpression
$TestPath     = $PSScriptRoot | Join-Path -ChildPath Tests
$Dependencies = (
    @{
        Name = 'Pester'
        MinimumVersion = '5.3.1'
    }
)


if ($Clean -and (Test-Path $OutPath))
{
    Remove-Item $OutPath -Recurse -Force -ErrorAction Stop
}
New-Item $OutPath -ItemType Directory -Force -ErrorAction Stop | Out-Null


if ($InstallDependencies)
{
    $Dependencies | % {
        if (-not (Import-Module @_ -Global -PassThru -ErrorAction Ignore))
        {
            "Installing $($_.Name)..."
            Install-Module -Force -AllowClobber -Repository PSGallery @_ -ErrorAction Stop -SkipPublisherCheck
        }
    }
}


if ($Build)
{
    dotnet build $ProjectPath -o $OutPath /property:GenerateFullPaths=true
    if (-not $?)
    {
        throw "dotnet build failed with exit code $LASTEXITCODE"
    }
    $ProjectPath | Join-Path -ChildPath 'PSExpression.psd1' | Copy-Item -Destination $OutPath
}


if ($Import -or $Test)
{
    $OutPath | Join-Path -ChildPath 'PSExpression.psd1' | Import-Module -Global -Force -ErrorAction Stop
}


if ($Test)
{
    $Dependencies | ? Name -eq 'Pester' | % {Import-Module @_ -Global -ErrorAction Stop}

    [object]$TestConfig = New-PesterConfiguration $TestConfig
    $TestConfig.Run.Path = $TestPath

    $TestResultPath = $TestConfig.TestResult.OutputPath.Value
    if ($TestResultPath)
    {
        $TestConfig.TestResult.Enabled = $true
        $TestResultPath = [IO.Path]::GetFullPath($TestResultPath, $PSScriptRoot)
        $TestConfig.TestResult.OutputPath = $TestResultPath
        Remove-Item -Recurse -Force $TestResultPath -ErrorAction Ignore
    }

    Invoke-Pester -Configuration @TestConfig

    if ($UploadTestResultUri -and $TestResultPath)
    {
        "Uploading $($TestResultPath | Resolve-Path) to $UploadTestResultUri..."
        [Net.WebClient]::new().UploadFile(
            $UploadTestResultUri,
            $TestResultPath
        )
    }
}
