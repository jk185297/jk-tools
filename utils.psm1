# utility functions

function IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

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
    choco feature enable -n=allowGlobalevelonfirmation *> $null
    choco feature enable -n=failOnAutoUninstaller *> $null
    choco feature enable -n=useRememberedArgumentsForUpgrades *> $null
}

function ensureGit {
    if ($null -eq (Get-Command "git.exe" -ErrorAction SilentlyContinue)) { 
        ensureChocolatey
        choco install poshgit *> $null
    }
}

function ensureVswhere {
    if ($null -eq (Get-Command "vswhere.exe" -ErrorAction SilentlyContinue)) { 
        ensureChocolatey
        choco install vswhere *> $null
    }
}

function vsDevShell {
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

function ToAdmin {
    if ($Host.Version.Major -gt 1) { $Host.Runspace.ThreadOptions = "ReuseThread" }
    if (-not (IsAdmin)) {
        $currentDirFullPath = Get-Location

        # Handle this differently if powershell core
        if ($Host.Version.Major -ge 7) {
            $newProcess = new-object System.Diagnostics.ProcessStartInfo "pwsh";
            $newProcess.Arguments = "-NoExit -WorkingDirectory $currentDirFullPath"
        }
        else {
            $newProcess = new-object System.Diagnostics.ProcessStartInfo "powershell";
            $newProcess.Arguments = "-NoExit -Command `"cd $currentDirFullPath`""
        }

        $newProcess.Verb = "runas";
        [System.Diagnostics.Process]::Start($newProcess);

        exit
    }
    else {
        Write-Host "Already running in elevated mode"
    }
    
}

function Get-ProjectUrl {
    param (
        [string]$projectPath
    )

    $projectUrl = Select-Xml -Path $projectPath -Namespace @{msb = "http://schemas.microsoft.com/developer/msbuild/2003" } -XPath "//msb:IISUrl" |
    Select-Object -Property @{Name = "IISUrl"; Expression = { $_.Node.InnerXml } } |
    Select-Object -ExpandProperty IISUrl
    return $projectUrl
}

function Get-DotNetVersion {
    param (
        [string]$filePath
    )
    if (-not $filePath) {
        throw "Full path of DLL is required."
    }

    $pathToDll = Resolve-Path $filePath
    if (-not (Test-Path $pathToDll)) {
        throw "Unable to find '$pathToDll'"
    }

    [byte[]]$dllByteArray = [System.IO.File]::ReadAllBytes($pathToDll)
    $result = [Reflection.Assembly]::ReflectionOnlyLoad($dllByteArray).CustomAttributes | Where-Object { $_.AttributeType.Name -eq "TargetFrameworkAttribute" } | Select-Object -ExpandProperty ConstructorArguments | Select-Object -ExpandProperty value
    return $result
}

function IsCorrectFramework {
    return (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 394802
}

function Get-TargetFrameworkVersions () {
    Get-ChildItem -Filter *.*proj -Recurse | ForEach-Object {
        $csprojPath = $_.FullName
        $targetFramework = Select-Xml -Path $csprojPath -Namespace @{msb = "http://schemas.microsoft.com/developer/msbuild/2003" } -XPath "//msb:TargetFrameworkVersion" |
        Select-Object -Property @{Name = "TargetFrameworkVersion"; Expression = { $_.Node.InnerXml } } |
        Select-Object -ExpandProperty TargetFrameworkVersion
        $targetFrameworkForNuget = $targetFramework.Replace(".", "").Replace("v", "net")

        Write-Output "$csprojPath ($targetFramework) [$targetFrameworkForNuget]"
    }
    # Select-Xml -Namespace @{msb = "http://schemas.microsoft.com/developer/msbuild/2003" } -XPath "//msb:TargetFrameworkVersion" |
    # Select-Object -Property @{Name = "TargetFrameworkVersion"; Expression = { $_.Node.InnerXml } } |
    # Select-Object -ExpandProperty TargetFrameworkVersion
    # Select-Object -ExpandProperty TargetFrameworkVersion |
    # Group-Object

}

function Get-LatestVersion {
    param (
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path | Where-Object { $_.Extension -in ".dll", ".exe" } | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
        $results = [PSCustomObject]@{
            Name        = $_.Name
            FileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_.FullName).FileVersion.Replace("RS/64 ", "")
        }
        Write-Output $results | Format-Table
    }
}

function Find-File () {
    param (
        [string]$Search = ""
    )
    
    if ($Search) {
        $start = Get-Date
        $results = @()
        Get-ChildItem -Recurse $($Search) | 
        ForEach-Object { 
            $result = [PSCustomObject]@{
                FullName      = $_.FullName
                LastWriteTime = $_.LastWriteTime
                Length        = $_.Length
                FileVersion   = $_.VersionInfo.FileVersion
            }
            $results += $result
        }
        Write-Output $results | Format-Table
        $end = Get-Date
        $elapsed = $($end - $start).ToString("hh\:mm\:ss\.ff")
        Write-Output "Elapsed = $elapsed"
    }
}
New-Alias ff Find-File

function Get-TFCloakStatus () {
    tf dir /folders | Where-Object { $_.Contains("$") -and -not $_.Contains(":") } | ForEach-Object { $_.substring(1, $_.length - 1) } | ForEach-Object { tf workfold $_ } | Where-Object { $_.Contains("$") }
}

function Get-IpAddress {
    # Get-NetIPAddress -AddressFamily IPv4 | Select-Object -Property InterfaceAlias, IPAddress
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { -not $_.IPAddress.StartsWith('169.') -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -Property InterfaceAlias, IPAddress
    # Get-NetIPAddress -AddressFamily IPv4 | Where-Object { -not $_.IPAddress.StartsWith('169.') -and -not $_.IPAddress.StartsWith('192.168.') -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -Property InterfaceAlias, IPAddress
    # Get-NetIPAddress -AddressFamily IPv4 | Where-Object { -not $_.IPAddress.StartsWith('169.') -and -not $_.IPAddress.StartsWith('192.168.') -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -ExpandProperty IPAddress
    # Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress.StartsWith('10.') } | Select-Object -Property InterfaceAlias, IPAddress
    # [System.Net.Dns]::GetHostAddresses($env:computername) | ? { $_.AddressFamily -eq "InterNetwork" -and $_.IPAddressToString.StartsWith("10.") } | % { $_.IPAddressToString }
    # ([System.Net.Dns]::GetHostAddresses($env:computername)).IPAddressToString | ?{!$_.Contains(":") -and !$_.StartsWith("192")}
    # ((ipconfig) -match "IPv4").split(":")[1].trim();
}
New-Alias ip Get-IpAddress

# function Update-NugetLocal () {
#     param (
#         [string]$Search = ""
#     )

#     $searchTerm = "*.nupkg"

#     if ($Search -ne "") {
#         $searchTerm = "*$Search*.nupkg"
#     }

#     Get-ChildItem -Recurse $($searchTerm) | Sort-Object Name | ForEach-Object { nuget add $_.FullName -source \\cr-velocityfs-0.tlr.thomson.com\Velocity\NuGet }
# }
# New-Alias unl Update-NugetLocal

function Get-ModulePathList {
    return $env:PSModulePath.replace(';;', ';').split(';') | Select-Object -Unique;
}

function pathAsList {
    return $env:path.replace(';;', ';').split(';') | Select-Object -Unique
}

function removeDuplicatesFromPath {
    $path = (([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)).replace(';;', ';').split(';') | Select-Object -Unique) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $path, [System.EnvironmentVariableTarget]::User)
    $path = (([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)).replace(';;', ';').split(';') | Select-Object -Unique) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $path, [System.EnvironmentVariableTarget]::Machine)
    refreshEnv *> $null
}

function ensureMsbuildInPath {
    ensureVswhere
    # $msbuildPath = vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1 | Split-Path
    $msbuildPath = vswhere -latest -find **\bin\msbuild.exe | Select-Object -Unique -First 1 | Split-Path
    $devenvPath = vswhere -latest -find **\devenv.exe | Select-Object -Unique -First 1 | Split-Path
    $path = (([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)).replace(';;', ';').split(';') | Select-Object -Unique) -join ';'
    $newPath = "$msbuildPath;$devenvPath;$path"
    [System.Environment]::SetEnvironmentVariable('PATH', $newPath, [System.EnvironmentVariableTarget]::Machine)
    removeDuplicatesFromPath
}

function bfg {
    ensureChocolatey
    java -jar "C:\ProgramData\chocolatey\lib\bfg-repo-cleaner\tools\bfg-1.13.0.jar" $args
}


function mcd ([string]$Path) {
    if (-not $Path) {
        return;
    }
    mkdir $Path -ErrorAction SilentlyContinue
    if (Test-Path $Path) {
        Set-Location $Path
    }
}

function promoteLogOrphans {
    Get-ChildItem -Recurse -File | Where-Object { $_.directory.name -eq $_.basename } | ForEach-Object { Move-Item $($_.FullName) $(split-path $_.directory); Remove-Item $_.directory }
}

function expandDiag {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DiagFile
    )

    if (-not (Test-Path $DiagFile)) {
        throw "Diag file $DiagFile doesn't exist"
    }

    $diagFileInfo = Get-ChildItem -Path $DiagFile
    Expand-Archive $diagFileInfo.FullName

    #Expand-Archive should have created a folder named after the filename without extension
    if (-not (Test-Path $diagFileInfo.BaseName)) {
        throw "Initial expansion failed"
    }

    Write-Output "Initial expansion successful"
    $expanded_count = 0

    $level = 0
    do {
        $level = $level + 1
        Write-Output "Recurse expansion level = $level"
    
        $expanded_count = 0

        foreach ($diag_item in (Get-ChildItem $diagFileInfo.BaseName -Recurse -Include *.zip)) {
            $expanded_count = $expanded_count + 1
        
            try {
                Expand-Archive -Path $diag_item.FullName -DestinationPath (Join-Path $diag_item.Directory.FullName $diag_item.BaseName)  
            }
            catch { }
        
            try {
                Remove-Item $diag_item.FullName -ErrorAction SilentlyContinue
            }
            catch { }
        
        }
    } while ($expanded_count -gt 0)
}

function vmdir {
    param (
        [string]$DriveLetter
    )
    if ($DriveLetter -and $DriveLetter.Length -eq 1) {
        Remove-Item "~\VirtualBox VMs" -ErrorAction SilentlyContinue
        $vmPath = "$DriveLetter" + ':\VM'
        New-Item -Path "~\VirtualBox VMs" -ItemType Junction -Value $vmPath
    }
    $virtualBoxLink = Get-ChildItem -Path "~" -Filter "VirtualBox VMs*" | Select-Object Name, Target
    $existingDrives = Get-WmiObject win32_logicaldisk name, volumename, filesystem -Filter drivetype=3 | Select-Object FileSystem, Name, VolumeName

    Write-Output $virtualBoxLink
    Write-Output $existingDrives | Format-Table -Property Name, VolumeName
    
    # @echo off
    # IF %1.==. wmic logicaldisk get name,volumename,description,filesystem & dir /al "%userprofile%\VirtualBox VMs*" & exit /b 0
    # rd "%userprofile%\VirtualBox VMs" 
    # mklink /j "%userprofile%\VirtualBox VMs" %1:\VM

}

function Update-NugetPackages {
    Write-Output "Refreshing nuget packages..."
    # use rm.exe if possible
    if ($null -eq (Get-Command "rm.exe" -ErrorAction SilentlyContinue)) { 
        Remove-Item .\packages -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        rm.exe -rf packages
    }
    # nuget locals all -clear
    # nuget restore -nocache
    $sln = Get-SolutionFile
    nuget restore $sln
}
New-Alias rn Update-NugetPackages

function Get-SolutionFile {
    $sln = $(Get-ChildItem *.sln | Select-Object -First 1 | ForEach-Object { $_.FullName })
    if (-not $sln -and (Test-Path './src')) {
        Push-Location './src'
        $sln = Get-SolutionFile
        Pop-Location
    }
    return $sln
}

# function Start-VS2017 {
#     $devenv = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\devenv.exe"
#     $sln = Get-SolutionFile
#     # $sln = $(dir *.sln | select -First 1 | % {$_.FullName})
#     & $devenv $sln
# }
# New-Alias vs17 Start-VS2017

function Start-VS2019 {
    ensureVswhere
    $devenv = vswhere -version 16.0 -property productPath
    if (-not $devenv) {
        $devenv = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe"
    }
    $sln = Get-SolutionFile
    & $devenv $sln
}
New-Alias vs19 Start-VS2019
New-Alias vs Start-VS2019

function Clean {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Get-ChildItem -Recurse -Include 'bin', 'obj', 'publish' |
    ForEach-Object {
        if ((Get-ChildItem $_.Parent.FullName | Where-Object { $_.Name -Like "*.sln" -or $_.Name -Like "*.*proj" }).Length -gt 0) {
            if ($PSCmdlet.ShouldProcess($_, "Delete folder")) {
                Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host deleted $_
            }
        }
    }
}

function Build {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [switch]$Release, 
        [switch]$Rebuild, 
        [switch]$Clean, 
        [switch]$RefreshNugetPackages,
        [switch]$MixedPlatforms,
        [switch]$Tail
    )

    $sln = Get-SolutionFile
    if (-not (Test-Path $sln)) {
        throw "No solutions found to build"
    }

    # ensureMsbuildInPath
    if ($null -eq (Get-Command "msbuild.exe" -ErrorAction SilentlyContinue)) { 
        vsDevShell
    }
    
    if ($Clean.IsPresent) {
        Clean
    }

    # Defaults
    $config = "Debug"
    # $platform = "x64"
    $platform = $null
    if ($MixedPlatforms.IsPresent) {
        $platform = "Mixed Platforms"
    }

    if ($Release.IsPresent) {
        $config = "Release"
    }

    # Search the .sln file for x64 platform, if not found use default
    # if ($platform -eq "x64") {
    #     if (Get-Content -Raw $sln | ForEach-Object { $_ -notlike '*x64*' }) {
    #         $platform = $null
    #     }
    # }

    if ($RefreshNugetPackages.IsPresent) {
        Update-NugetPackages
    }
    else {
        nuget restore $sln
    }

    $cmd = "msbuild.exe"
    $params = @()
    $params += "$sln"
    if ($Rebuild) {
        $params += "-t:rebuild"
    }
    else {
        $params += "-t:build"
    }
    $params += "-p:StopOnFirstFailure=true"
    $params += "-p:configuration=$config"
    if ($platform) {
        $params += "-p:platform=`"$platform`""
    }
    if ($Tail) {
        $params += "-fl"
    }

    if ($PSCmdlet.ShouldProcess($sln, "$cmd $params")) {
        if ($Tail) {
            Start-Process -FilePath "C:\NCRDev\jk-tools\baretailpro.exe" -ArgumentList ".\msbuild.log"
        }
        & $cmd $params
        if ($LastExitCode -ne 0) {
            throw "Build Failed: $cmd $params"
        }
        Write-Output "Build Succeeded: $cmd $params"
    
        if ($Release -and (Test-Path .\release-build.ps1)) {
            . .\release-build.ps1
        }
    }
}
function gitBash {
    & 'C:\Program Files\Git\git-bash.exe'
}
New-Alias gb gitBash

# function whereis {
#     $cmd = "where.exe"
#     & $cmd $args
# }
# New-Alias whence whereis


function Find-NotePadPlusPlus {
    param ([switch]$InstallIfMissing)

    ensureGit

    $nppExe = $null
    $npp_x86 = "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
    $npp_x64 = "$env:ProgramFiles\Notepad++\notepad++.exe"
    
    if (Test-Path $npp_x86) {
        $nppExe = $npp_x86
    }
    
    if (Test-Path $npp_x64) {
        $nppExe = $npp_x64
    }

    if ($null -eq $nppExe -and $InstallIfMissing) {
        choco install notepadplusplus *> $null
        $nppExe = $npp_x64
    }

    return $nppExe
}

function Start-NotepadPlusPlus {
    if (Test-Path "C:\Program Files (x86)\Notepad++\notepad++.exe") {
        Start-Process "C:\Program Files (x86)\Notepad++\notepad++.exe" $args
        return
    }

    if (Test-Path "C:\Program Files\Notepad++\notepad++.exe") {
        Start-Process "C:\Program Files\Notepad++\notepad++.exe" $args
        return
    }
}
New-Alias npp Start-NotepadPlusPlus

function Set-WindowTitle {
    $host.ui.RawUI.WindowTitle = $args[0]
}
New-Alias title Set-WindowTitle

function Get-GitEditor {
    ensureGit
    $gitEditor = git config --get core.editor
    Write-Output "git core.editor = '$gitEditor'"
}

function Set-GitEditor {
    param ([switch]$vim)

    $RestoreDefault = $vim.IsPresent
    ensureGit

    $nppExe = Find-NotePadPlusPlus
    if (-not $nppExe) {
        $RestoreDefault = $true
    }

    if ($RestoreDefault) {
        git config core.editor vim
    }
    else {
        git config core.editor "'$nppExe' -multiInst -notabbar -nosession -noPlugin"
    }
    Get-GitEditor
}


function Get-IISExpress {
    Get-Process -Name iisexpress | Format-Table id, mainwindowtitle -AutoSize
}

# function Get-SolutionPlatform {
#     $slns = Get-ChildItem *.sln -Recurse
#     # $results = @()
#     foreach ($sln in $slns) {
#         $slnContent = Get-Content -Raw $sln
#         $has64bit = $slnContent -match 'x64'
#         $result = @{"Has64bit" = $has64bit; "Filename" = $sln.FullName}
#         Write-Output $result
#         # $results += $result
#         # Write-Output "$has64bit `t $($sln.FullName)"
#     }

#     # $results
# }

function UnzipAll {
    if ($null -eq (Get-Command "7z" -ErrorAction SilentlyContinue)) { 
        return
    }

    Get-ChildItem -Recurse -Include *.zip | ForEach-Object {
        $params = @("x", "`"$($_.FullName)`"", "-o`"$($_.FullName.TrimEnd('.zip'))`"", "-y");
        $ex = Start-Process 7z -ArgumentList $params -NoNewWindow -Wait -PassThru
        if ($ex.ExitCode -eq 0) {
            write-host "Extraction successful, deleting $($_.FullName)"
            Remove-Item -Path $_.FullName -Force
        }
    }
}

function Start-Sleep($seconds) {
    $doneDT = (Get-Date).AddSeconds($seconds)
    while ($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        [System.Threading.Thread]::Sleep(500)
    }
    Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining 0 -Completed
}

function setterm() {
    param ([int]$term = 1)
    $env:term = $term
}

function nullterm {
    $env:term = $null
}

function Get-NextAltDir {
    $parentDirName = Split-Path -Path (Get-Location).Path
    $currentDirName = Split-Path -Path (Get-Location).Path -Leaf
    $parentDirNameLastChar = $parentDirName.Substring($parentDirName.Length - 1)
    $altDirRoot = $parentDirName
    [int]$altDirIndex = 1
    [int]$returnedInt = 0
    [bool]$result = [int]::TryParse($parentDirNameLastChar, [ref]$returnedInt)
    if ($result) {
        $altDirIndex = $returnedInt
        $altDirRoot = $parentDirName -replace ".$"
    }
    # Check to see if higher altdir exists
    $propostedHigherAltDir = "$altDirRoot$($altDirIndex + 1)"
    $nextAltDir = ""
    $higherAltDirExists = Test-Path $propostedHigherAltDir
    if ($higherAltDirExists) {
        $nextAltDir = Join-Path $propostedHigherAltDir $currentDirName
    }
    else {
        $nextAltDir = Join-Path $altDirRoot $currentDirName
    }

    # Check to see if current folder exists in higher altdir
    if (-not (Test-Path $nextAltDir)) {
        $nextAltDir = Join-Path $altDirRoot $currentDirName
    }

    return $nextAltDir
}

function AltDir {
    Set-Location $(Get-NextAltDir)
}

function AltBC {
    $bc = "C:\Program Files\Beyond Compare 4\BCompare.exe"
    if (-not (Test-Path $bc)) {
        return
    }

    $altDir = Get-NextAltDir

    . $bc $altDir $(Get-Location) /filters="-.git\;-.vs\;-packages\;-bin\;-obj\;-.bin\;-Publish\;-build\;-.github\;-.githooks\"
}