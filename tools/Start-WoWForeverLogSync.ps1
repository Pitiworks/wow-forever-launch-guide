param(
    [string]$Source,
    [string]$Destination = "\\192.168.178.88\Daten\WoWForeverLaunchProbe.lua",
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = "Stop"

if (-not $Source) {
    Write-Host "Paste the full path of WoWForeverLaunchProbe.lua once." -ForegroundColor Cyan
    $Source = Read-Host "Source"
}

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SavedVariables file not found: $Source"
}

$lastWrite = [DateTime]::MinValue
Write-Host "WFLG sync is running. Keep this window open while you play." -ForegroundColor Green
Write-Host "Source: $Source"
Write-Host "Destination: $Destination"

while ($true) {
    try {
        $item = Get-Item -LiteralPath $Source
        if ($item.LastWriteTimeUtc -gt $lastWrite) {
            $destinationDirectory = Split-Path -Parent $Destination
            if (-not (Test-Path -LiteralPath $destinationDirectory)) {
                throw "Shared destination is unavailable: $destinationDirectory"
            }
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
            $lastWrite = $item.LastWriteTimeUtc
            Write-Host ("{0} synced {1}" -f (Get-Date -Format "HH:mm:ss"), $item.Name) -ForegroundColor Green
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    Start-Sleep -Seconds $IntervalSeconds
}
