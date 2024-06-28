# restores a full database backup to another database from source's latest full backup file in specified directory
 
# begin script configuration here
$TargetSqlServerInstance = "s-azsql.grc.local\grcsql"                                                                        # target server instance 
$TargetDb = "GRC_MMDemo"                                                                                            # target database 
$BackupDir = "\\s-azsql.grc.local\Backup"                                                                 # directory / share where backups are stored
$SourceLogicalDataFileName = "GRC_MM_dat"                                                                           # logical data file name of source db 
$SourceLogicalLogFileName =  "GRC_MM_log"                                                                       # logical log file name of source db
$TargetLogicalDataFileName = "GRCDB_dat"                                                                           # logical name you want to change logical data file on target db to
$TargetLogicalLogFileName =  "GRCDB_log"                                                                       # logical name you want to change logical log file on target db to
$TargetPhysicalDataFileName = "D:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\RefreshTest.mdf"     # full path\file of target db physical data file 
$TargetPhysicalLogFileName =  "C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\RefreshTest_log.mdf" # full path\file of target db physical log file 
$CompatLevel = 100                                                                                                   # compatibility level to set target database to (2019=150, 2017=140, 2016=130, 2014=120, 2012=110, 2008/2008R2=100, 2005=90, 2000=80, 7=70) 
# end script configuration here
 
# import sqlserver module
Import-Module sqlserver
 
# latest full backup file name is dynamically determined and appended to backup directory
$LatestFullBackupFile = Get-ChildItem -Path $BackupDir -Filter *.bak | Sort-Object LastAccessTime -Descending | Select-Object -First 1 
$FileToRestore = $BackupDir + '\' + $LatestFullBackupFile
 
# kill any connections in target database
$KillConnectionsSql=
"
USE master
GO
ALTER DATABASE $TargetDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE master
GO
ALTER DATABASE $TargetDb SET MULTI_USER
GO
USE master
GO
"
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query $KillConnectionsSql 
 
# import sqlserver module
Import-Module sqlserver
 
# restore
$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$SourceLogicalDataFileName", "$TargetPhysicalDataFileName")
$RelocateLog  = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$SourceLogicalLogFileName",  "$TargetPhysicalLogFileName")
Restore-SqlDatabase -ServerInstance $TargetSqlServerInstance -Database $TargetDb -BackupFile $FileToRestore -RelocateFile @($RelocateData,$RelocateLog) -ReplaceDatabase
# end restore
 
# set db owner to sa
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Database $TargetDb -Query "EXEC sp_changedbowner sa"
 
# set compatibility level
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "ALTER DATABASE $($TargetDb) SET COMPATIBILITY_LEVEL =$($CompatLevel)"  
 
# set recovery model to simple
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "ALTER DATABASE $($TargetDb) SET RECOVERY SIMPLE WITH NO_WAIT"  
 
# rename logical files
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "ALTER DATABASE $TargetDb MODIFY FILE (NAME='$SourceLogicalDataFileName', NEWNAME='$TargetLogicalDataFileName')"
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "ALTER DATABASE $TargetDb MODIFY FILE (NAME='$SourceLogicalLogFileName', NEWNAME='$TargetLogicalLogFileName')"
 
# dbcccheckdb
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "DBCC checkdb ($TargetDb) --WITH NO_INFOMSGS"
 
# display sp_helpdb
Invoke-Sqlcmd -ServerInstance $TargetSqlServerInstance -Query "EXEC sp_helpdb $($TargetDb)" 