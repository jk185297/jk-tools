Get-ChildItem -Path c:\bootdrv -Recurse -Include iber*.exe,alohapaymentservice.exe,alohacp.dll,*alohatogo*.exe | Select-Object -ExpandProperty VersionInfo