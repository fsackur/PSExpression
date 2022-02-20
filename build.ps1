[CmdletBinding()]
param
(
    [string]$OutPath = (Join-Path $PSScriptRoot 'bin')
)

$ProjectPath = Join-Path $PSScriptRoot PSExpression

if (Test-Path $OutPath)
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
