cls
@pushd %~dp0
@echo off
echo This is from the batch script.
powershell -ExecutionPolicy Bypass -File "testScript.ps1" -param1 "Foo"
pause
popd