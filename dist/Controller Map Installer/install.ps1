# Modern Control Remapping (The Witcher 3) - controller map installer. The map is Modern Control Map's, carried over into
# this mod on 2026-10-14 (the owner: "transfer over any of the current keybinds that it has to the current
# UVC"); map.json is that mod's file unchanged.
# Puts the map's controller bindings into input.settings and leaves every keyboard binding as it is. A backup of each
# file it changes is written beside it first. Run with the game closed:
#   Install Controller Map.bat                          (the game's settings folder in Documents)
#   Install Controller Map.bat "<folder>"               (another settings folder, e.g. a Mod Organizer 2 profile with
#                                                        profile-specific game settings)
param(
    [string]$Folder,
    [switch]$Uninstall,
    # build tests on a copy only (tools); never needed by a player
    [switch]$SkipGameCheck
)
$ErrorActionPreference = 'Stop'

function Fail([string]$msg) { Write-Host ''; Write-Host "  $msg" -ForegroundColor Red; Write-Host ''; exit 1 }

if (-not $SkipGameCheck -and (Get-Process -Name 'witcher3' -ErrorAction SilentlyContinue)) { Fail 'The Witcher 3 is running - close it first.' }

if (-not $Folder) { $Folder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3' }
$inputFile = Join-Path $Folder 'input.settings'
if (-not (Test-Path -LiteralPath $inputFile)) {
    Fail "No input.settings in '$Folder'. Start the game once so it writes its settings, or pass the folder that holds them."
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$utf8 = New-Object System.Text.UTF8Encoding($false)

if ($Uninstall) {
    $backups = @(Get-ChildItem -LiteralPath $Folder -Filter '*.before-uvc-controller-map-*' | Sort-Object Name)
    if ($backups.Count -eq 0) { Fail 'No Modern Control Remapping controller map backup in this folder.' }
    $firstStamp = ($backups[0].Name -split 'before-uvc-controller-map-')[1]
    foreach ($b in $backups | Where-Object { $_.Name.EndsWith($firstStamp) }) {
        $target = Join-Path $Folder ($b.Name -replace '\.before-uvc-controller-map-.*$', '')
        Copy-Item -LiteralPath $b.FullName -Destination $target -Force
        Write-Host "  restored $target"
    }
    Write-Host '  The settings are back as they were before the first install.'
    exit 0
}

$map = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'map.json') -Raw -Encoding UTF8 | ConvertFrom-Json

# ---- input.settings: the controller lines of each action the map sets -------------------------------------------------
$text = [System.IO.File]::ReadAllText($inputFile, $utf8)
$nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = New-Object System.Collections.Generic.List[string]
$lines.AddRange([string[]]($text -split "`r?`n"))

$byContext = @{}
foreach ($r in $map.rules) {
    if (-not $byContext.ContainsKey($r.context)) { $byContext[$r.context] = @() }
    $byContext[$r.context] += $r
}

$changed = 0; $missing = @()
foreach ($ctx in $byContext.Keys) {
    $start = $lines.IndexOf("[$ctx]")
    if ($start -lt 0) { $missing += $ctx; continue }
    foreach ($r in $byContext[$ctx]) {
        $end = $start + 1
        while ($end -lt $lines.Count -and -not $lines[$end].StartsWith('[')) { $end++ }
        $act = [regex]::Escape($r.action)
        $padRx = "^(IK_Pad_\w+|IK_PS4_\w+)=\(Action=$act[,)]"
        $last = -1; $have = @{}
        for ($i = $end - 1; $i -gt $start; $i--) {
            if ($lines[$i] -match $padRx) { $lines.RemoveAt($i); $end--; continue }
            if ($lines[$i] -match "^\w+=\(Action=$act[,)]") {
                if ($last -lt 0) { $last = $i }
                if ($lines[$i].StartsWith('IK_None=')) { $have[$lines[$i]] = 1 + [int]$have[$lines[$i]] }
            }
        }
        $at = if ($last -ge 0) { $last + 1 } else { $end }
        while ($at -gt $start + 1 -and $lines[$at - 1] -eq '' -and $last -lt 0) { $at-- }
        $add = @($r.pad)
        # each empty pad slot the map leaves is an IK_None line with the action's own State/IdleTime, up to the number
        # the map has - so a second run adds none
        foreach ($n in @($r.none)) {
            for ($k = [int]$have[$n.line]; $k -lt [int]$n.count; $k++) { $add += $n.line }
        }
        foreach ($l in $add) { $lines.Insert($at, $l); $at++ }
        $changed++
    }
}

Copy-Item -LiteralPath $inputFile -Destination "$inputFile.before-uvc-controller-map-$stamp"
[System.IO.File]::WriteAllText($inputFile, ($lines -join $nl), $utf8)
Write-Host "  input.settings: $changed controller bindings set (keyboard untouched)"
if ($missing.Count) { Write-Host "  not in this file, left alone: $($missing -join ', ')" }

# ---- the two game options the map needs ------------------------------------------------------------------------------
foreach ($name in 'dx12user.settings', 'user.settings') {
    $f = Join-Path $Folder $name
    if (-not (Test-Path -LiteralPath $f)) { continue }
    $t = [System.IO.File]::ReadAllText($f, $utf8)
    $n2 = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
    $ls = New-Object System.Collections.Generic.List[string]
    $ls.AddRange([string[]]($t -split "`r?`n"))
    foreach ($s in $map.settings) {
        $sec = $ls.IndexOf("[$($s.section)]")
        if ($sec -lt 0) { $ls.Add("[$($s.section)]"); $ls.Add("$($s.key)=$($s.value)"); continue }
        $e = $sec + 1; $done = $false
        while ($e -lt $ls.Count -and -not $ls[$e].StartsWith('[')) {
            if ($ls[$e] -match "^$([regex]::Escape($s.key))=") { $ls[$e] = "$($s.key)=$($s.value)"; $done = $true }
            $e++
        }
        if (-not $done) { $ls.Insert($sec + 1, "$($s.key)=$($s.value)") }
    }
    Copy-Item -LiteralPath $f -Destination "$f.before-uvc-controller-map-$stamp"
    [System.IO.File]::WriteAllText($f, ($ls -join $n2), $utf8)
    Write-Host "  ${name}: Sprint by Pressing Left Stick off, Quick Sign Casting on Quick Casting"
}
Write-Host ''
Write-Host "  The Modern Control Remapping controller map is installed. Backups: *.before-uvc-controller-map-$stamp"
Write-Host '  Also set in the game: Options > Accessibility > Automatically Apply Blade Oils ON (required) and'
Write-Host '  Manual Sword Drawing/Sheathing OFF (recommended).'
