$atoBase = "C:\NCRDev\alohatakeout"
$targetLocation = "$atoBase\bin\Data"

if (-not (Test-Path $atoBase)) {
    throw "Base folder not found: '$atoBase'"
}

New-Item -Path $targetLocation -ItemType Junction -Value "$env:ATOPATH\data" -Force
