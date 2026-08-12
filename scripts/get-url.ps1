# ─────────────────────────────────────────────────────────────────────────────
#  get-url.ps1
#  Shows the current public tunnel URL at any time.
#  Usage:  .\scripts\get-url.ps1
# ─────────────────────────────────────────────────────────────────────────────

$docker  = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin\docker.exe"
$urlFile = Join-Path $PSScriptRoot "..\current-tunnel-url.txt"

# Try cached file first
if (Test-Path $urlFile) {
    $cached = (Get-Content $urlFile -Raw).Trim()
    if ($cached) {
        Write-Host "Public URL (cached): $cached" -ForegroundColor Cyan
    }
}

# Always read live from container logs
$logs = (& $docker logs cloudflared-tunnel 2>&1) -join "`n"
$m = [regex]::Match($logs, 'https://[a-z0-9\-]+\.trycloudflare\.com')
if ($m.Success) {
    $url = $m.Value
    Write-Host "Public URL (live)  : $url" -ForegroundColor Green
    $url | Set-Content $urlFile -Encoding UTF8
    Write-Host ""
    Write-Host "Open in browser: $url"
    Start-Process $url
} else {
    Write-Host "Tunnel URL not found — is the cloudflared container running?" -ForegroundColor Yellow
    Write-Host "Run: docker compose logs cloudflared"
}
