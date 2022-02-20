[CmdletBinding()]
param
(
    [string]$OutPath = (Join-Path $PSScriptRoot 'bin'),

    [switch]$Clean,

    [switch]$Import
)

$ProjectPath = Join-Path $PSScriptRoot PSExpression

if ($Clean -and (Test-Path $OutPath))
{
    Remove-Item $OutPath -Recurse -Force -ErrorAction Stop
}
New-Item $OutPath -ItemType Directory -Force -ErrorAction Stop | Out-Null

dotnet build $ProjectPath -o $OutPath /property:GenerateFullPaths=true
if (-not $?)
{
    return
}

$ProjectPath | Join-Path -ChildPath 'PSExpression.psd1' | Copy-Item -Destination $OutPath

if ($Import)
{
    $OutPath | Join-Path -ChildPath 'PSExpression.psd1' | Import-Module -Global -Force -ErrorAction Stop
}
