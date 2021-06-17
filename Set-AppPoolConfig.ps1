Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue
  
# Set the idle time to 0(off)
Set-ItemProperty ("IIS:\AppPools\OrganizerToWebSvc") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(0))
 
# disable the regular time of 1740 minutes
Set-ItemProperty ("IIS:\AppPools\OrganizerToWebSvc") -Name Recycling.periodicRestart.time -Value "00:00:00"
 
# Clear any scheduled restart times
Clear-ItemProperty ("IIS:\AppPools\OrganizerToWebSvc") -Name Recycling.periodicRestart.schedule
 
# Set scheduled restart times
Set-ItemProperty ("IIS:\AppPools\OrganizerToWebSvc") -Name Recycling.periodicRestart.schedule -value @{value="05:00:00"}



Set-ItemProperty ('IIS:\AppPools\OrganizerToWebSvc') -Name Recycling.periodicRestart.time -value ([TimeSpan]::FromMinutes(60))
Set-ItemProperty ('IIS:\AppPools\OrganizerToWebSvc') -Name Recycling.periodicRestart.time -value ([TimeSpan]::FromMinutes(1740))


choco features enable -n=allowGlobalConfirmation;choco features enable -n=failOnAutoUninstaller;choco features enable -n=useRememberedArgumentsForUpgrades
