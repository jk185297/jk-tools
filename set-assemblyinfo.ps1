param (
    [string]$version
)

function SetVersion ($file, $version)
{
    echo "Changing version in $file to $version"
    $fileObject = get-item $file
    #$fileObject.Set_IsReadOnly($False)
 
    $sr = new-object System.IO.StreamReader( $file, [System.Text.Encoding]::GetEncoding("utf-8") )
    $content = $sr.ReadToEnd()
    $sr.Close()
 
    $content = [Regex]::Replace($content, "(\d+)\.(\d+)\.(\d+)[\.(\d+)]*", $version);
 
    $sw = new-object System.IO.StreamWriter( $file, $false, [System.Text.Encoding]::GetEncoding("utf-8") )
    $sw.Write( $content )
    $sw.Close()
    #$fileObject.Set_IsReadOnly($True)
}

function setVersionInDir($dir, $version) {
    
    if ($version -eq "") {
        Write-Host "version not found"
        exit 1
    }
    
    # Set the Assembly version
    $info_files = Get-ChildItem $dir -Recurse -Include "AssemblyInfo.cs"
    foreach($file in $info_files)
    {
        Setversion $file $version
    }
}

$dir = "./"
setVersionInDir $dir $version
