$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if((Test-Path -LiteralPath $key) -ne $true) {  New-Item $key -force -ea SilentlyContinue };
New-ItemProperty -LiteralPath $key -Name 'StoreAppsOnTaskbar' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'StartMenuAdminTools' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'ServerAdminUI' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'HideFileExt' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'DontPrettyPath' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'ShowInfoTip' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'HideIcons' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'MapNetDrvBtn' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'AutoCheckSelect' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'ShowStatusBar' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'DontUsePowerShellOnWinX' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'NavPaneExpandToCurrentFolder' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'NavPaneShowAllFolders' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath $key -Name 'Hidden' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;

Stop-Process -processname explorer -Force
