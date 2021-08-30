@echo off
SET DIR=%~dp0%
SET PATH=%PATH%;%systemroot%\System32\WindowsPowerShell\v1.0

where choco /q || call :installChoco
choco upgrade chocolatey
choco feature enable -n=allowGlobalConfirmation
choco feature enable -n=failOnAutoUninstaller
choco feature enable -n=useRememberedArgumentsForUpgrades
REM choco install sysinternals
choco install notepadplusplus --x86
REM choco install vscode
REM choco install conemu
REM choco install nuget.commandline
REM choco install sqlserver-cmdlineutils --version=14.0
REM choco install mssqlserver2014-sqllocaldb
REM choco install sql-server-management-studio
REM choco install powershell
REM powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Install-PackageProvider -Name NuGet -Force"
REM powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
REM Install psPAS in order to use get-vault-cred.ps1 script
REM Install-Module -Name psPAS




choco install beyondcompare
goto :eof


:installChoco
powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
refreshenv
exit /b
