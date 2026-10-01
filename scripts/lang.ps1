Write-Host "Configuring timezone..."
Set-TimeZone -Id "Romance Standard Time"

Write-Host "Configuring Danish keyboard..."
$LanguageList = New-WinUserLanguageList -Language "da-DK"
Set-WinUserLanguageList $LanguageList -Force

Write-Host "Baseline configuration completed."
