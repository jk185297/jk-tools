Get-Service *takeout*|Stop-Service
Get-Service CtlSvr|Stop-Service
Get-Process iber*,rad*,*kit*,ocp*,*testcmc*|Stop-Process -Force
