param(
    [string]$Source,
    [string]$Destination = "\\192.168.178.88\Daten\WoWForeverLaunchProbe.lua",
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = "Stop"

if (-not $Source) {
    Write-Host "Paste the full path of WoWForeverLaunchProbe.lua or WoWForeverLaunchGuide.lua once." -ForegroundColor Cyan
    $Source = Read-Host "Source"
}

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SavedVariables file not found: $Source"
}

$sourceDirectory = Split-Path -Parent $Source
$destinationDirectory = Split-Path -Parent $Destination
$files = @(
    @{ Source = $Source; Destination = $Destination }
)
if ((Split-Path -Leaf $Source) -eq "WoWForeverLaunchGuide.lua" -and
    (Split-Path -Leaf $Destination) -eq "WoWForeverLaunchProbe.lua") {
    $files[0].Destination = Join-Path $destinationDirectory "WoWForeverLaunchGuide.lua"
}
if ((Split-Path -Leaf $Source) -eq "WoWForeverLaunchProbe.lua") {
    $files += @{ Source = (Join-Path $sourceDirectory "WoWForeverLaunchGuide.lua"); Destination = (Join-Path $destinationDirectory "WoWForeverLaunchGuide.lua") }
}
$lastWrites = @{}
Write-Host "WFLG sync is running. Keep this window open while you play." -ForegroundColor Green
Write-Host "Source: $Source"
Write-Host "Destination: $Destination"

while ($true) {
    try {
        foreach ($file in $files) {
            if (-not (Test-Path -LiteralPath $file.Source -PathType Leaf)) { continue }
            $item = Get-Item -LiteralPath $file.Source
            if (-not $lastWrites.ContainsKey($file.Source) -or $item.LastWriteTimeUtc -gt $lastWrites[$file.Source]) {
                $targetDirectory = Split-Path -Parent $file.Destination
                if (-not (Test-Path -LiteralPath $targetDirectory)) {
                    throw "Shared destination is unavailable: $targetDirectory"
                }
                Copy-Item -LiteralPath $file.Source -Destination $file.Destination -Force
                $lastWrites[$file.Source] = $item.LastWriteTimeUtc
                Write-Host ("{0} synced {1}" -f (Get-Date -Format "HH:mm:ss"), $item.Name) -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    Start-Sleep -Seconds $IntervalSeconds
}
