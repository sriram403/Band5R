# Samples every 2 s: time, CPU load %, Godot game count, lane b heartbeat physics frames. Stops when the stop file exists.
param([string]$Out, [string]$Stop, [string]$HbB)
Remove-Item $Stop -ErrorAction SilentlyContinue
"time`tcpu`tgodot`thb_b" | Out-File -Encoding utf8 $Out
while (-not (Test-Path $Stop)) {
  $c = (Get-CimInstance Win32_Processor).LoadPercentage
  $g = @(Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Where-Object { $_.Name -notmatch '_console' }).Count
  $h = ''
  try { $h = (Get-Content $HbB -Raw | ConvertFrom-Json).physics_frames } catch {}
  "$(Get-Date -Format HH:mm:ss.f)`t$c`t$g`t$h" | Out-File -Append -Encoding utf8 $Out
  Start-Sleep -Milliseconds 1500
}
