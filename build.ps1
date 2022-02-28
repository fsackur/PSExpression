[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
[CmdletBinding()]
param
(
    [string]$BinPath = (Join-Path $PSScriptRoot 'bin'),

    [string]$Destination = (Join-Path $PSScriptRoot 'Build'),

    [switch]$Clean,

    [switch]$InstallDependencies,

    [switch]$Build,

    [switch]$Import,

    [switch]$Test,

    [switch]$Package,

    [switch]$Publish,

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

$Package = $Package -or $Publish

$ProjectPath  = $PSScriptRoot | Join-Path -ChildPath PSExpression
$TestPath     = $PSScriptRoot | Join-Path -ChildPath Tests
$Dependencies = (
    @{
        Name = 'Pester'
        MinimumVersion = '5.3.1'
    },
    @{
        Name = 'PowerShellGet'
        MinimumVersion = '3.0.0'
    }
)


if ($Clean)
{
    if (Test-Path $BinPath)
    {
        Remove-Item $BinPath -Recurse -Force -ErrorAction Stop
    }

    if (Test-Path $Destination)
    {
        Remove-Item $Destination -Recurse -Force -ErrorAction Stop
    }
}
$ModuleBase = $Destination | Join-Path -ChildPath 'PSExpression'
New-Item $BinPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
New-Item $ModuleBase -ItemType Directory -Force -ErrorAction Stop | Out-Null


if ($InstallDependencies)
{
    $Dependencies | % {
        if (-not (Import-Module @_ -Global -PassThru -ErrorAction Ignore))
        {
            $Params =@{
                Force              = $true
                AllowClobber       = $true
                Repository         = 'PSGallery'
                SkipPublisherCheck = $true
                AllowPrerelease    = $_.Name -eq 'PowerShellGet'
            }
            "Installing $($_.Name)..."
            Install-Module @_ @Params -ErrorAction Stop
        }
    }
}


if ($Build)
{
    dotnet build $ProjectPath -o $BinPath /property:GenerateFullPaths=true
    if (-not $?)
    {
        throw "dotnet build failed with exit code $LASTEXITCODE"
    }

    $ManifestPath = $ProjectPath | Join-Path -ChildPath 'PSExpression.psd1'
    $ManifestPath | Copy-Item -Destination $ModuleBase
    $BinPath | Join-Path -ChildPath 'PSExpression.dll' | Copy-Item -Destination $ModuleBase
}


if ($Import -or $Test)
{
    $ModuleBase | Import-Module -Global -Force -ErrorAction Stop
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

if ($Package -or $Publish)
{
    $Dependencies | ? Name -eq 'PowerShellGet' | % {Import-Module @_ -Global -ErrorAction Stop}

    if ($Publish)
    {
        Publish-PSResource -Path $ModuleBase -Repository 'PSGallery' -DestinationPath $Destination
    }
    else
    {
        if (-not (Get-PSResourceRepository 'PSExpression' -ErrorAction Ignore))
        {
            Register-PSResourceRepository -Name 'PSExpression' -URL $Destination -Trusted
        }
        try
        {
            Publish-PSResource -Path $ModuleBase -Repository 'PSExpression'
        }
        finally
        {
            Unregister-PSResourceRepository -Name 'PSExpression'
        }
    }
}
