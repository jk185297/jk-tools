$atoBase = "C:\NCRDev\alohatakeout"
$config = 'Debug'
$targetLocation = "$atoBase\bin\$config"
if (-not (Test-Path $targetLocation)) {
    throw "Target location not found: '$targetLocation'"
}

$ocpTestingTool = "$atoBase\Utilities\OcpTestingTool\bin\$config\OcpTestingTool.exe"

function Start-OcpTestingTool {
    $vagrantAlohaPath = 'C:\vagrant\projects\atg-alohavmb\vagrant\AlohaW10Dev\aloha'
    if (Test-Path $vagrantAlohaPath) {
        Push-Location $vagrantAlohaPath
        & $ocpTestingTool
        Pop-Location
    }
}

Start-OcpTestingTool
