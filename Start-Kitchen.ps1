param (
    [int]$kpsController = 81
)

$kitchenFolder = "c:\bootdrv\AlohaKitchen"
if (-not (Test-Path $kitchenFolder)) {
    throw "Aloha Kitchen folder not found."
}

# Change to AlohaKitchen folder
Push-Location $kitchenFolder
Get-Service AlohaKitchenService | Stop-Service -ErrorAction SilentlyContinue

# ---- AK startup ARGs ----
# /TOUCH == enables touchscreen even when not set at AK screen
# /BOHSERVER == AK controller acts as service instance
# /SHOWFRAME == windowed
# /SHOWFRAME 1280x960+584+40 == windowed with window size and left/top offset
# /DebugKitchenConfig (ignore)
# /DisableKitchenWindowsOnTop (forces system to not mess with z order)
# /SHOWALLPRINTERS print simulator for AK terminal
# /ForceOriginalPOSCOMInterface
# /DebugMessages  shows messages being sent

# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /controller 9999 /BOHServer /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers /wow /Geometry 1365x768+0+0
# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /iberdir C:\BOOTDRV\Aloha /KitchenFolder C:\BootDrv\AlohaKitchen /controller 9999 /BOHServer $env:COMPUTERNAME /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers /showkitchenenvironment
# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /iberdir C:\BOOTDRV\Aloha /KitchenFolder C:\BootDrv\AlohaKitchen /controller 9999 /useLocalAddress /BOHServer $env:COMPUTERNAME /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers /showkitchenenvironment
# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /iberdir C:\BOOTDRV\Aloha /KitchenFolder C:\BootDrv\AlohaKitchen /controller 9999 /useLocalAddress /BOHServer $env:COMPUTERNAME /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers /showkitchenenvironment /wow /Geometry 1365x768+0+0
# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /KitchenFolder C:\BootDrv\AlohaKitchen /controller 9999 /BOHServer /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers /wow /Geometry 1365x768+0+0

# C:\BOOTDRV\AlohaKitchen\Bin\AlohaKitchen.exe /KitchenFolder C:\BootDrv\AlohaKitchen /controller 81 /BOHServer /ServerCanBeMaster /NoFileSync /Touch /ShowFrame /ShowMainWindow /DisableKitchenWindowsOnTop /ShowAllControllers

$env:KITCHENFOLDER = $kitchenFolder
$env:ALOHAKITCHENCONTROLLER = $kpsController
$env:SHOWKITCHENENVIRONMENT = 'TRUE'
$env:ALOHAKITCHENSHOWFRAME = 'TRUE'

# $ipAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { -not $_.IPAddress.StartsWith('169.') -and -not $_.IPAddress.StartsWith('192.168.') -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -ExpandProperty IPAddress | Select-Object -First 1
# if ($ipAddress) {
#     $env:KITCHENMULTICASTINTERFACE = $ipAddress
# }

$cmd = "$kitchenFolder\bin\AlohaKitchen.exe"
$params = @()
# $params += "/KitchenFolder $kitchenFolder"
# $params += "/controller $kpsController"
$params += "/BOHServer"
$params += "/ServerCanBeMaster"
$params += "/NoFileSync"
$params += "/Touch"
$params += "/ShowMainWindow"
$params += "/DisableKitchenWindowsOnTop"
# $params += "/ShowAllControllers"
$params += "/ShowFrame"
$params += "870x690+1040+0"

Write-Output "$cmd $params"
& $cmd $params
Pop-Location