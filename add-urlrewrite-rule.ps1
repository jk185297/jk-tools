$site = "iis:\sites\OrganizerWebService"
$filterRoot = "system.webServer/rewrite/rules/rule[@name='RemoveAPIPath_']"
Clear-WebConfiguration -pspath $site -filter $filterRoot
Add-WebConfigurationProperty -pspath $site -filter "system.webServer/rewrite/rules" -name "." -value @{name='RemoveAPIPath' + $_ ;patternSyntax='Regular Expressions';stopProcessing='False'}
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/match" -name "url" -value "(api)/.*"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/conditions" -name "logicalGrouping" -value "MatchAny"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/action" -name "type" -value "Rewrite"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/action" -name "url" -value "http://localhost:9100"

