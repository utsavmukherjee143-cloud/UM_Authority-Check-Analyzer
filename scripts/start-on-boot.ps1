# ─────────────────────────────────────────────────────────────────────────────
#  start-on-boot.ps1
#  Registered as a Windows Scheduled Task — runs at login, waits for Docker
#  Desktop engine to be ready, then starts the docker compose stack.
#
#  Register once with:   .\scripts\register-startup-task.ps1
#  Remove with:          Unregister-ScheduledTask -TaskName "UM-AuthorityAnalyzer" -Confirm:$false
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "SilentlyContinue"

$logFile  = "$env:TEMP\authority-analyzer-startup.log"
$docker   = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin\docker.exe"
$project  = "C:\Users\UtsavMukherjee\Documents\IBM Basis+Security Curriculam\SAP GEN AI\Agentic AI\ASSEP\UM_Authority-Check-Analyzer"

function Log($msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content $logFile $line
    Write-Host $line
}

Log "=== Authority Analyzer startup ==="

# 1. Wait for Docker engine (up to 3 minutes)
Log "Waiting for Docker engine..."
$ready = $false
for ($i = 0; $i -lt 36; $i++) {
    Start-Sleep -Seconds 5
    & $docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    if ($i % 6 -eq 0) { Log "  ...still waiting ($($i*5)s)" }
}

if (-not $ready) {
    Log "ERROR: Docker engine did not start in 3 minutes. Aborting."
    exit 1
}
Log "Docker engine ready."

# 2. Start the stack
Log "Starting docker compose stack..."
Push-Location $project
& $docker compose up -d 2>&1 | ForEach-Object { Log "  $_" }
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -eq 0) {
    Log "Stack started. Getting tunnel URL..."
    # Wait up to 60s for cloudflared URL
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        $logs = (& $docker logs cloudflared-tunnel 2>&1) -join "`n"
        $m = [regex]::Match($logs, 'https://[a-z0-9\-]+\.trycloudflare\.com')
        if ($m.Success) {
            Log "PUBLIC URL: $($m.Value)"
            # Write URL to a well-known file so get-url.ps1 can read it
            $m.Value | Set-Content "$project\current-tunnel-url.txt" -Encoding UTF8
            break
        }
    }
    Log "Startup complete."
} else {
    Log "ERROR: docker compose up failed (exit $exitCode)"
}
