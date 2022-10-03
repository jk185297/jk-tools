#Requires -RunAsAdministrator

function ensureChocolatey {
    if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
        Write-Output "installing chocolatey..."
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
    else {
        Write-Output "chocolatey is already installed"
    }

    $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
    choco feature enable -n=allowGlobalConfirmation *> $null
    choco feature enable -n=failOnAutoUninstaller *> $null
    choco feature enable -n=useRememberedArgumentsForUpgrades *> $null
}

function ensureVswhere {
    if ($null -eq (Get-Command "vswhere.exe" -ErrorAction SilentlyContinue)) { 
        ensureChocolatey
        choco install vswhere *> $null
    }
}

function invokeShellModule {
    ensureVswhere
    $vsInstallPath = vswhere -latest -property installationPath
    if (-not $vsInstallPath) {
        throw "Visual Studio not installed"
    }

    $devShellModule = Get-ChildItem -Path $vsInstallPath -Recurse -Include Microsoft.VisualStudio.DevShell.dll | Select-Object -ExpandProperty fullname
    if (-not $devShellModule) {
        throw "Unable to find VsDevShell module"
    }

    Import-Module $devShellModule -Force
    Enter-VsDevShell -VsInstallPath $vsInstallPath -SkipAutomaticLocation
}

invokeShellModule
