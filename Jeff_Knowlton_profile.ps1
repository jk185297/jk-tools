# Import-Module "$env:home\source\repos\jk-tools\utils.psm1" -Force

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile" -Force
}

function IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function prompt {
    $origLastExitCode = $LASTEXITCODE
    $adminPrefix = ""
    if (IsAdmin) {
        $adminPrefix = "Administrator: "
    } 
    $leaf = (Split-Path -Leaf $pwd).Split('.')|Select-Object -Last 1
    $Host.UI.RawUI.WindowTitle = "$($adminPrefix)$leaf"
    $branch = Get-GitBranch
    if ($null -ne $branch) {
        $Host.UI.RawUI.WindowTitle = "$($adminPrefix)$leaf [$branch]"
    }

    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation -NoNewline
    Write-VcsStatus
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1))`n`$ "
}

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
$Global:GitPromptSettings.EnableWindowTitle = $false
# $Global:GitPromptSettings.AfterText += "`n"

# If rm.exe is in the path, remove default powershell rm alias
if ($null -ne (Get-Command "rm.exe" -ErrorAction SilentlyContinue)) { 
    Remove-Item alias:rm -ErrorAction SilentlyContinue
}else {
    if (Test-Path $env:ProgramFiles\git\usr\bin\rm.exe) {
        $env:Path += ";$($env:ProgramFiles)\git\usr\bin"
        Remove-Item alias:rm -ErrorAction SilentlyContinue
    }
}

# Replace cd alias with pushd instead of chdir
# Remove-Item alias:cd -ErrorAction SilentlyContinue
# New-Alias cd Push-Location

# New-Alias ll Get-ChildItem
