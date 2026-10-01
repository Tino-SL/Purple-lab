# Join computer to Active Directory domain

$Domain = "lab.local"
$Password = ConvertTo-SecureString "vagrant" -AsPlainText -Force

$Credential = New-Object System.Management.Automation.PSCredential(
    "vagrant@lab.local",
    $Password
)

# Check if computer is already part of the domain
$ComputerSystem = Get-CimInstance Win32_ComputerSystem

if ($ComputerSystem.PartOfDomain -and $ComputerSystem.Domain -eq $Domain) {

    Write-Host "Computer is already a member of $Domain"

}
else {

    Write-Host "Joining computer to $Domain..."

    Add-Computer `
        -DomainName $Domain `
        -Credential $Credential `
        -ErrorAction Stop

}
