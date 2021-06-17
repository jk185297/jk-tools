$taxApps = @("1040", "1041", "1065", "1120", "5500", "7060", "7090", "F990", "DFLT","1065")
$taxApps   
Write-Output "`n`n"
$taxApps | Select-Object -Unique
