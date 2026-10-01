<#
    honey-watch.ps1  -  live lab activity console (run ON the DC)

    A real-time tail of the two sensors in this lab:
      * Security log      - authentication + directory access (honeypot hits)
      * Sysmon/Operational- process creation, network connections (from sysmon.yml)

    It highlights anything touching a honey account (svc_sqladmin, backup_svc,
    administrator_old) in RED so a Kerberoast / spray / recon from Kali is
    obvious as it happens. This is the low-footprint "follow the lab live"
    view - no SIEM, no extra VM, just the DC console.

    USAGE (on dc01, elevated PowerShell):
        C:\vagrant\scripts\honey-watch.ps1
        C:\vagrant\scripts\honey-watch.ps1 -Honey svc_sqladmin,backup_svc,administrator_old
        C:\vagrant\scripts\honey-watch.ps1 -PollSeconds 2 -IncludeSysmon:$false
#>
[CmdletBinding()]
param(
    [string[]]$Honey = @('svc_sqladmin','backup_svc','administrator_old'),
    [int]$PollSeconds = 3,
    [bool]$IncludeSysmon = $true
)

$ErrorActionPreference = 'SilentlyContinue'

# Security events we care about, with a human label.
$secMap = @{
    4624='logon OK'; 4625='logon FAILED'; 4634='logoff';
    4768='Kerberos TGT req'; 4769='Kerberos svc ticket'; 4771='Kerb preauth FAILED';
    4662='directory object READ'; 4720='user CREATED'; 4740='account LOCKED OUT'
}
$secIds = $secMap.Keys

function Test-Honey([string]$text) {
    foreach ($h in $Honey) { if ($text -match [regex]::Escape($h)) { return $h } }
    return $null
}

function Write-Line($time,$src,$id,$label,$detail,$honeyHit) {
    $stamp = $time.ToString('HH:mm:ss')
    if ($honeyHit) {
        Write-Host ("[{0}] {1,-7} {2,-4} " -f $stamp,$src,$id) -NoNewline -ForegroundColor DarkGray
        Write-Host ("HONEYPOT<{0}> " -f $honeyHit) -NoNewline -ForegroundColor Red
        Write-Host ("{0}  {1}" -f $label,$detail) -ForegroundColor Yellow
    } else {
        Write-Host ("[{0}] {1,-7} {2,-4} {3}  {4}" -f $stamp,$src,$id,$label,$detail) -ForegroundColor DarkGray
    }
}

Write-Host "=== honey-watch: live lab console ===" -ForegroundColor Cyan
Write-Host ("Honey accounts : {0}" -f ($Honey -join ', ')) -ForegroundColor Cyan
Write-Host ("Sources        : Security{0}" -f $(if($IncludeSysmon){' + Sysmon'}else{''})) -ForegroundColor Cyan
Write-Host  "Ctrl-C to stop. Red lines = a honey account was touched.`n" -ForegroundColor Cyan

# Start watching from 'now' so we only show fresh activity.
$last = Get-Date

while ($true) {
    $now = Get-Date

    # --- Security log ---
    $sec = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=$secIds; StartTime=$last } |
           Sort-Object TimeCreated
    foreach ($e in $sec) {
        $hit   = Test-Honey $e.Message
        $label = $secMap[[int]$e.Id]
        # pull the account name line for context
        $acct  = ($e.Message -split "`n" | Select-String -Pattern 'Account Name:' |
                  Select-Object -First 2 | ForEach-Object { ($_ -split ':')[-1].Trim() }) -join '/'
        Write-Line $e.TimeCreated 'SEC' $e.Id $label $acct $hit
    }

    # --- Sysmon Operational ---
    if ($IncludeSysmon) {
        $sm = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Sysmon/Operational'; StartTime=$last } |
              Sort-Object TimeCreated
        foreach ($e in $sm) {
            $hit    = Test-Honey $e.Message
            $label  = switch ([int]$e.Id) {
                        1 {'process'} ; 3 {'net conn'} ; 7 {'image load'} ;
                        11{'file create'} ; 22{'DNS query'} ; default {"sysmon id $($e.Id)"} }
            $detail = ($e.Message -split "`n" | Select-String -Pattern 'Image:|CommandLine:|DestinationIp:' |
                       Select-Object -First 1 | ForEach-Object { $_.ToString().Trim() })
            Write-Line $e.TimeCreated 'SYSMON' $e.Id $label $detail $hit
        }
    }

    $last = $now
    Start-Sleep -Seconds $PollSeconds
}
