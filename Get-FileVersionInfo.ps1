# Get-FileVersionInfo.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Outputs file version information for files.

.DESCRIPTION
Outputs file version information for files. The output distinguishes between a file's "display" version (i.e., the version displayed as output for users, such as in the Windows Explorer properties dialog for the file) and the actual file version stored in the file. The output also contains the file version as an unsigned 64-bit integer you can use for comparison purposes.

.PARAMETER Path
Specifies a path to one or more files. Wildcards are permitted.

.PARAMETER LiteralPath
Specifies a path to one or more files. Unlike Path, the value of LiteralPath is used exactly as it is typed. No characters are interpreted as wildcards.

.PARAMETER ProductVersion
Includes properties for the product version in addition to the file version.

.INPUTS
System.String or System.IO.FileInfo

.OUTPUTS
PSObjects containing the following properties:
  Property                Type     Description
  FullName                String   Full path and filename of file
  FileVersionDisplay      String   File version displayed to user
  FileVersion             String   Actual file version, 'a.b.c.d' format
  FileVersionUInt64       UInt64   FileVersion property as number*
  ProductVersionDisplay   String   Product version displayed to user
  ProductVersion          String   Actual product version, 'a.b.c.d' format
  ProductVersionUInt64    UInt64   ProductVersion property as number*
Properties will be null if the file has no version information.
* You can compare versions using these properties.

.LINK
http://msdn.microsoft.com/en-us/library/system.diagnostics.fileversioninfo.aspx

.EXAMPLE
PS C:\> Get-FileVersionInfo "C:\Program Files\Sample Application\SampleApp.exe"
Outputs file version information for the specified file.

.EXAMPLE
PS C:\> Get-FileVersionInfo "C:\Program Files\Sample Application\*.dll"
Outputs file version information for the specified DLL files.

.EXAMPLE
PS C:\> Get-ChildItem "C:\Program Files\*" -Include *.exe,*.dll -Recurse | Get-FileVersionInfo
Outputs file version information for all EXE and DLL files in the 'C:\Program Files' path and its subdirectories.
#>

[CmdletBinding(DefaultParameterSetName="Path")]
param(
  [parameter(Position=0,Mandatory=$FALSE,ParameterSetName="Path",ValueFromPipeline=$TRUE)]
    $Path="*",
  [parameter(Position=0,Mandatory=$TRUE,ParameterSetName="LiteralPath")]
    [String[]] $LiteralPath
)

begin {
  $ParamSetName = $PSCmdlet.ParameterSetName
  if ( $ParamSetName -eq "Path" ) {
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("Path")) -and (-not $Path)
  }
  elseif ( $ParamSetName -eq "LiteralPath" ) {
    $PipelineInput = $FALSE
  }

  # Bitwise left shift (shifts $number left $bits bits).
  function Lsh {
    param(
      [UInt32] $number,
      [Byte] $bits
    )
    $number * [Math]::Pow(2, $bits)
  }

  # Outputs version number string 'a.b.c.d' as a single unsigned 64-bit integer (UInt64).
  function ConvertTo-UInt64 {
    param(
      [String] $version
    )
    $parts = $version.Split(".")
    (Lsh ((Lsh $parts[0] 16) -bor $parts[1]) 32) -bor ((Lsh $parts[2] 16) -bor $parts[3])
  }

  # Outputs version number string 'a.b.c.d' from component parts.
  function ConvertTo-VersionString {
    param(
      [UInt32] $major,
      [UInt32] $minor,
      [UInt32] $release,
      [UInt32] $build
    )
    "{0}.{1}.{2}.{3}" -f $major,$minor,$release,$build
  }

  # Outputs file version information for the specified file.
  function Get-VersionInfo {
    param(
      [System.IO.FileInfo] $file
    )
    # Create custom output object containing desired properties.
    $outputObject = new-object PSObject -property @{
      "FullName" = $file.FullName
      "FileVersionDisplay" = $NULL
      "FileVersion" = $NULL
      "FileVersionUInt64" = $NULL
      "ProductVersionDisplay" = $NULL
      "ProductVersion" = $NULL
      "ProductVersionUInt64" = $NULL
    } | select-object FullName,FileVersionDisplay,FileVersion,FileVersionUInt64,
      ProductVersionDisplay,ProductVersion,ProductVersionUInt64
    $verInfo = $file.VersionInfo
    # Update output object's properties if file has version info.
    if ( $verInfo.FileMajorPart -or $verInfo.FileMinorPart -or $verInfo.FileBuildPart -or $verInfo.FilePrivatePart ) {
      $outputObject.FileVersionDisplay = $verInfo.FileVersion
      $outputObject.FileVersion = ConvertTo-VersionString `
        $verInfo.FileMajorPart $verInfo.FileMinorPart `
        $verInfo.FileBuildPart $verInfo.FilePrivatePart
      $outputObject.FileVersionUInt64 = ConvertTo-UInt64 `
        $outputObject.FileVersion
      $outputObject.ProductVersionDisplay = $verInfo.ProductVersion
      $outputObject.ProductVersion = ConvertTo-VersionString `
        $verInfo.ProductMajorPart $verInfo.ProductMinorPart `
        $verInfo.ProductBuildPart $verInfo.ProductPrivatePart
      $outputObject.ProductVersionUInt64 = ConvertTo-UInt64 `
        $outputObject.ProductVersion
    }
    $outputObject
  }
}

process {
  if ( $PipelineInput ) {
    if ( -not $_.PSIsContainer ) {
      if ( Test-Path $_ ) {
        Get-VersionInfo $_
      }
      else {
        write-error "Cannot find path '$_' because it does not exist." `
          -category ObjectNotFound
      }
    }
  }
  else {
    if ( $ParamSetName -eq "Path" ) {
      if ( Test-Path $Path ) {
        get-childitem $Path -force | where-object { -not
          $_.PSIsContainer } | foreach-object {
          Get-VersionInfo $_
        }
      }
      else {
        write-error "Cannot find path '$Path' because it does not exist." `
          -category ObjectNotFound
      }
    }
    elseif ( $ParamSetName -eq "LiteralPath" ) {
      if ( Test-Path -literalpath $LiteralPath ) {
        get-childitem -literalpath $LiteralPath -force | where-object {
          -not $_.PSIsContainer } | foreach-object {
          Get-VersionInfo $_
        }
      }
      else {
        write-error "Cannot find path '$LiteralPath' because it does not exist." `
          -category ObjectNotFound
      }
    }
  }
}
