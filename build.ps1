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

    [string]$NewVersion,

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

$Package = $Package -or $Publish
$Import = $Import -or $Test

$ProjectPath = $PSScriptRoot | Join-Path -ChildPath PSExpression
$TestPath    = $PSScriptRoot | Join-Path -ChildPath Tests

$ModuleVersionPattern = "(?<=^ModuleVersion\s*=\s*(['`"]))(\d+\.)+\d+"

$ManifestPath = $ProjectPath | Join-Path -ChildPath 'PSExpression.psd1'
[version]$ModuleVersion = Get-Content $ManifestPath |
    Select-String $ModuleVersionPattern |
    Select-Object -ExpandProperty Matches |
    Select-Object -ExpandProperty Value -First 1

if (-not $ModuleVersion)
{
    throw "Failed to parse module version from '$ManifestPath'."
}

if ($NewVersion)
{
    [version]$NewVersion = $NewVersion -replace '^\D*' -replace '\D*$'    # v1.2.3-alpha => 1.2.3
    if ($NewVersion -ne $ModuleVersion)
    {
        if ($NewVersion -lt $ModuleVersion)
        {
            throw "New version '$NewVersion' is lower than current version '$ModuleVersion'."
        }

        $ManifestContent = Get-Content $ManifestPath
        $ManifestContent = $ManifestContent -replace $ModuleVersionPattern, $NewVersion
        $ManifestContent | Out-File $ManifestPath -Encoding utf8
        $ModuleVersion = $NewVersion

        $CsprojPath = $ProjectPath | Join-Path -ChildPath PSExpression.csproj
        $CsprojContent = Get-Content $CsprojPath
        'Version', 'AssemblyVersion', 'FileVersion', 'PackageVersion' | % {
            $CsprojContent = $CsprojContent -replace "(?<=<$_>).*(?=</$_>)", $NewVersion
        }
        $CsprojContent | Out-File $CsprojPath -Encoding utf8
    }
}


$UnversionedModuleBase = $Destination | Join-Path -ChildPath PSExpression
$ModuleBase = $UnversionedModuleBase | Join-Path -ChildPath $ModuleVersion
$ModulePsd1Path = $ModuleBase | Join-Path -ChildPath 'PSExpression.psd1'


if ($Clean)
{
    Write-Verbose "Cleaing $BinPath and $Destination..."
    if (Test-Path $BinPath)
    {
        Remove-Item $BinPath -Recurse -Force
    }

    if (Test-Path $Destination)
    {
        Remove-Item $Destination -Recurse -Force
    }
}
New-Item $ModuleBase -ItemType Directory -Force | Out-Null


if ($InstallDependencies)
{
    $Dependencies | % {
        if (-not (Get-Module $_.Name -ListAvailable -ErrorAction Ignore | ? Version -ge $_.MinimumVersion))
        {
            $Params = @{
                Force              = $true
                AllowClobber       = $true
                Repository         = 'PSGallery'
                SkipPublisherCheck = $true
                AllowPrerelease    = $_.Name -eq 'PowerShellGet'
            }
            Write-Verbose "Installing $($_.Name)..."
            Install-Module @Params @_
        }
    }
}


if ($Build)
{
    New-Item $BinPath -ItemType Directory -Force | Out-Null

    Write-Verbose "Building to $BinPath..."
    dotnet build $ProjectPath -o $BinPath /property:GenerateFullPaths=true
    if (-not $?)
    {
        throw "dotnet build failed with exit code $LASTEXITCODE"
    }
    $DllPath = $BinPath | Join-Path -ChildPath 'PSExpression.dll'

    $ManifestPath |
        Copy-Item -Destination $ModuleBase
    $ManifestPath |
        Copy-Item -Destination $UnversionedModuleBase
    $DllPath |
        Copy-Item -Destination $ModuleBase
    $DllPath |
        Copy-Item -Destination $UnversionedModuleBase
}


if ($Import)
{
    "Importing $ModulePsd1Path..."
    $ModulePsd1Path | Import-Module -Global -Force
}


if ($Test)
{
    $Dependencies | ? Name -eq 'Pester' | % {Import-Module @_ -Global}

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
    $Dependencies | ? Name -eq 'PowerShellGet' | % {Import-Module @_ -Global}

    if ($Publish)
    {
        Write-Verbose "Publishing to PSGallery..."
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
            Write-Verbose "Packaging to $Destination..."
            Publish-PSResource -Path $UnversionedModuleBase -Repository 'PSExpression'
        }
        finally
        {
            Unregister-PSResourceRepository -Name 'PSExpression'
        }
    }
}
