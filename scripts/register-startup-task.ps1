# ─────────────────────────────────────────────────────────────────────────────
#  register-startup-task.ps1
#  Run ONCE (as normal user) to register the auto-start scheduled task.
#  The task starts the docker compose stack every time you log in.
#
#  Usage:  .\scripts\register-startup-task.ps1
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$taskName   = "UM-AuthorityAnalyzer-Startup"
$scriptPath = Join-Path $PSScriptRoot "start-on-boot.ps1"
$pwsh       = "powershell.exe"

# Remove any existing registration
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action  = New-ScheduledTaskAction -Execute $pwsh `
               -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $taskName `
    -Action   $action `
    -Trigger  $trigger `
    -Settings $settings `
    -RunLevel Limited `
    -Description "Auto-starts the UM Authority Check Analyzer docker compose stack on login" | Out-Null

Write-Host "✅ Scheduled task '$taskName' registered."
Write-Host "   The stack will start automatically at every login."
Write-Host "   To run now: Start-ScheduledTask -TaskName '$taskName'"
Write-Host "   To remove:  Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
