$iberdir = @($env:IBERDIR, $env:LOCALDIR, 'C:\BOOTDRV\Aloha') | Select-Object -First 1
if (!(Test-Path $iberdir)) {
    throw "$iberdir does not exist"
}

$iberqs = "$iberdir\bin\iberqs.exe"
if (!(Test-Path $aloha1)) {
    throw "$aloha1 does not exist"
}

. $iberqs TERM 1