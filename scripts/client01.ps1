# Configure client01 network

# Find the lab NIC: the adapter that is NOT the Vagrant NAT adapter
# (the NAT one owns the default gateway).
$NatIf = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric | Select-Object -First 1).InterfaceIndex

$Interface = Get-NetAdapter -Physical |
    Where-Object { $_.Status -eq "Up" -and $_.ifIndex -ne $NatIf } |
    Select-Object -First 1

if (-not $Interface) { $Interface = Get-NetAdapter -Name "Ethernet1" }

Write-Host "Lab NIC: $($Interface.Name) (ifIndex $($Interface.ifIndex))"

# Remove existing IPv4 configuration on the lab NIC
Get-NetIPAddress `
    -InterfaceIndex $Interface.ifIndex `
    -AddressFamily IPv4 `
    -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false

# Set static IP
New-NetIPAddress `
    -InterfaceIndex $Interface.ifIndex `
    -IPAddress "192.168.100.30" `
    -PrefixLength 24

# Configure client01 DNS address (the DC)
Set-DnsClientServerAddress `
    -InterfaceIndex $Interface.ifIndex `
    -ServerAddresses "192.168.100.10"

# Prefer the lab NIC for DNS resolution: lower metric wins
Set-NetIPInterface -InterfaceIndex $Interface.ifIndex -InterfaceMetric 10

# Deprioritize the Vagrant NAT adapter and stop it registering in DNS
if ($NatIf -and $NatIf -ne $Interface.ifIndex) {
    Set-NetIPInterface -InterfaceIndex $NatIf -InterfaceMetric 100
    Set-DnsClient -InterfaceIndex $NatIf -RegisterThisConnectionsAddress $false
}
