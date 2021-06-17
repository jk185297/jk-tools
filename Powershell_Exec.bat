: The following 2 examples should be saved with the same name of the powershell script to be executed but with a .bat or .cmd extension

: Without admin
@ECHO OFF
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dpn0.ps1'"
PAUSE

: With admin
@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
PAUSE

: Add this to end of powershell script to allow user to see output
REM # If running in the console, wait for input before closing.
REM if ($Host.Name -eq "ConsoleHost")
REM {
REM     Write-Host "Press any key to continue..."
REM     $Host.UI.RawUI.FlushInputBuffer()   # Make sure buffered input doesn't "press a key" and skip the ReadKey().
REM     $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
REM }