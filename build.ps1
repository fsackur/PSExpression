[CmdletBinding()]
param
(
    [string]$OutPath = (Join-Path $PSScriptRoot 'bin'),

    [switch]$Clean,

    [switch]$InstallDependencies,

    [switch]$Build,

    [switch]$Import,

    [switch]$Test,

    [hashtable]$TestSettings = @{},

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

    $TestSettings.OutputFile = '.\TestResults.xml'
    $TestResult = Invoke-Pester -PassThru @TestSettings

    if ($UploadTestResultUri)
    {
        [Net.WebClient]::new().UploadFile(
            $UploadTestResultUri,
            ($TestSettings.OutputFile | Resolve-Path)
        )
    }

    if ($TestResult.FailedCount -gt 0)
    {
        throw "Failed test count: $($TestResult.FailedCount)"
    }
}
