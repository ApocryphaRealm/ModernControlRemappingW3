# Package Modern Control Remapping (The Witcher 3) for testing:
#   1. tools\gen_menu.py --check  (the dist files are what the generator builds, every action and label checked)
#   2. copy dist\ to <stage>\Witcher 3 - Modern Control Remapping\Modern Control Remapping <VERSION>\
#   3. stamp the version into the package README (rule 6: the version at the top of the README)
# The version comes from VERSION, which only version-gate.ps1 writes. The stage folder comes from the project's resolver
# (distro-names.ps1 Resolve-PackageRoot), never a hand-joined path.
param(
    [string]$ProjectRoot = 'D:\Claude output',
    [string]$Stage = '7. current test builds',
    # an optional note in the folder name, e.g. 'one weapon row' -> "Modern Control Remapping 1.0.0 (one weapon row)", for
    # a rebuild under a number that is not posted yet (the version itself stays the gate's)
    [string]$Label = ''
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$' -or $version -eq '0.0.0') { throw "VERSION is '$version' - issue a number with version-gate.ps1 -Action bump first" }

& python -I (Join-Path $PSScriptRoot 'gen_menu.py') --check
if ($LASTEXITCODE -ne 0) { throw 'gen_menu.py --check failed - the package is not built' }

. (Join-Path $ProjectRoot '.MD\scripts\distro-names.ps1')
$root = Resolve-PackageRoot -Root (Join-Path $ProjectRoot $Stage) -ModName 'Modern Control Remapping' -Game 'Witcher 3' -ProjectRoot $ProjectRoot
$name = "Modern Control Remapping $version"
if ($Label) { $name += " ($Label)" }
$pkg = Join-Path $root $name
if (Test-Path -LiteralPath $pkg) { throw "$pkg already exists - a version is packaged once" }
New-Item -ItemType Directory -Force -Path $pkg | Out-Null
Copy-Item -Path (Join-Path $repo 'dist\*') -Destination $pkg -Recurse
Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination $pkg

$readme = Join-Path $pkg 'README.txt'
$text = [System.IO.File]::ReadAllText($readme)
$text = [regex]::Replace($text, '(?m)^Version \d+\.\d+\.\d+', "Version $version", 1)
[System.IO.File]::WriteAllText($readme, $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Output "packaged $pkg"
