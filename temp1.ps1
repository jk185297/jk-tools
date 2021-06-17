# dir variable:
# $MyInvocation
# $MyInvocation.MyCommand.Name | Get-Member *
# $MyInvocation.ScriptName
([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName