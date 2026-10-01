Write-Output "=== Schannel errors (last 20 min) ==="
Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Schannel';StartTime=(Get-Date).AddMinutes(-20)} -ErrorAction SilentlyContinue |
  Select-Object -First 5 | ForEach-Object { Write-Output ("[{0}] {1}: {2}" -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, ($_.Message -split "`n")[0]) }
Write-Output "=== ActiveDirectory-related LDAP-over-SSL events (Directory Service log) ==="
Get-WinEvent -FilterHashtable @{LogName='Directory Service';Id=1220;StartTime=(Get-Date).AddMinutes(-30)} -ErrorAction SilentlyContinue |
  Select-Object -First 3 | ForEach-Object { Write-Output ("[{0}] 1220: {1}" -f $_.TimeCreated.ToString('HH:mm:ss'), ($_.Message -split "`n")[0]) }
Write-Output "done"
