$iberdir = @($env:IBERDIR, $env:LOCALDIR, 'C:\BOOTDRV\Aloha') | Select-Object -First 1
if (!(Test-Path $iberdir)) {
    throw "$iberdir does not exist"
}

$iberqs = "$iberdir\bin\iberqs.exe"
if (!(Test-Path $iberqs)) {
    throw "$iberqs does not exist"
}

. $iberqs TERM 1