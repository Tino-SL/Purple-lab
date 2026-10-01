$ErrorActionPreference = 'Continue'
$fqdn = "WIN-JMD7EC5NQO9.lab.local"
$cert = Get-ChildItem Cert:\LocalMachine\My |
  Where-Object { $_.Subject -eq "CN=$fqdn" -and
                 $_.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.1' -and
                 $_.NotAfter -gt (Get-Date) } |
  Sort-Object NotAfter -Descending | Select-Object -First 1
Write-Output ("Cert: {0}" -f $cert.Thumbprint)

# 1. Trust the self-signed cert so Schannel accepts it as a default credential.
$root = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$root.Open("ReadWrite")
if (-not ($root.Certificates | Where-Object Thumbprint -eq $cert.Thumbprint)) {
  $root.Add($cert); Write-Output "Added cert to LocalMachine\Root (trusted)"
} else { Write-Output "Cert already in Root" }
$root.Close()

# 2. Restart NTDS so the LDAPS listener re-reads the cert stores.
Write-Output "Restarting NTDS (AD DS)..."
Restart-Service NTDS -Force
Start-Sleep -Seconds 8
Write-Output ("NTDS status: {0}" -f (Get-Service NTDS).Status)

Write-Output "=== new Schannel 36886 in last 1 min? ==="
$e = Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Schannel';Id=36886;StartTime=(Get-Date).AddMinutes(-1)} -ErrorAction SilentlyContinue
Write-Output ("count: {0}" -f @($e).Count)
Write-Output "done"
