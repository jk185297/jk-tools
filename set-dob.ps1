function UpdateAlohaIniFile {
    param (
        [string]$filePath,
        [string]$dateOfBusiness
    )
    
    (Get-Content $filePath) | ForEach-Object { $_ -replace "DOB=.*","DOB=$dateOfBusiness" } | Set-Content $filePath
}

$iberdir = @($env:IBERDIR, $env:LOCALDIR, 'C:\BOOTDRV\Aloha') | Select-Object -First 1
if (!(Test-Path $iberdir)) {
    throw "$iberdir does not exist"
}

$aloha1 = "$iberdir\data\aloha.ini"
if (!(Test-Path $aloha1)) {
    throw "$aloha1 does not exist"
}

$aloha2 = "$iberdir\newdata\aloha.ini"
if (!(Test-Path $aloha2)) {
    throw "$aloha2 does not exist"
}

$dob_today = (Get-Date).ToString("MM dd yyyy")

UpdateAlohaIniFile $aloha1 $dob_today
UpdateAlohaIniFile $aloha2 $dob_today
