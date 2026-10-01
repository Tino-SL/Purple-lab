# Install Active Directory Domain Services

Install-WindowsFeature `
    -Name AD-Domain-Services `
    -IncludeManagementTools

# AD configuration
$DomainName = "lab.local"
$DomainNetBIOSName = "LAB"
$DSRMPassword = ConvertTo-SecureString `
    "Password123!" `
    -AsPlainText `
    -Force

# Skip forest creation if this server is already a domain controller
if ((Get-CimInstance Win32_ComputerSystem).PartOfDomain) {
    Write-Host "Already part of a domain. Skipping Install-ADDSForest."
}
else {
    # Create the new Active Directory forest
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $DomainNetBIOSName `
        -InstallDns `
        -SafeModeAdministratorPassword $DSRMPassword `
        -NoRebootOnCompletion `
        -Force
}
