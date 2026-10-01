# Simulate a fresh DC: remove LDAPS cert from My + Root so the playbook must
# rebuild it. Test-only helper.
$fqdn = "WIN-JMD7EC5NQO9.lab.local"
foreach ($storeName in 'My','Root') {
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName,"LocalMachine")
  $store.Open("ReadWrite")
  $store.Certificates |
    Where-Object { $_.Subject -eq "CN=$fqdn" -and
                   $_.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.1' } |
    ForEach-Object { $store.Remove($_); Write-Output "removed from $storeName : $($_.Thumbprint)" }
  $store.Close()
}
Restart-Service NTDS -Force
Start-Sleep -Seconds 8
Write-Output ("NTDS: {0}" -f (Get-Service NTDS).Status)
Write-Output "stripped"
