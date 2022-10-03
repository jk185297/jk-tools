param (
    [switch]$Release
)
$atoBase = "C:\NCRDev\alohatakeout"
$config = 'Debug'
if ($Release.IsPresent) {
    $config = 'Release'
}

$targetLocation = "$atoBase\bin\$config"
if (-not (Test-Path $targetLocation)) {
    throw "Target location not found: '$targetLocation'"
}

$atoServiceHost = "$targetLocation\Radiant.Hospitality.AlohaToGo.ServiceHost.exe"
$atoFoh = "$targetLocation\Radiant.Hospitality.AlohaToGo.exe"
$testConsole = "$targetLocation\AlohaTakeOutInterface.TestConsole.exe"
$testCmcAgent = "$targetLocation\AlohaTakeOutInterface.TestCmcAgent.exe"
$env:term = 1


Start-Service CtlSvr
Get-Service *takeout*|Stop-Service *> $null
Get-Process iber*|Stop-Process -Force

& $atoServiceHost /debug
& $atoFoh
# & $testCmcAgent
# & $testConsole
# & $testConsole /usetestapi
Start-Sleep 25
. Start-Kitchen.ps1
