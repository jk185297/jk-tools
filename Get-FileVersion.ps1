param ( [string[]]$paths )
begin {
    # I want to do some stuff with relative paths.   
    # create a variable that I can use later
    $P = [string](get-location)

    # the workhorse of the script
    function GetVersionInfo
    {
        param ( [string]$path )
        # resolve the path, we're going to need a fully qualified path to hand
        # to the method, so go get it.  I may not have that depending on how
        # was called
        $rpath = resolve-path $path 2>$null
        # the thing we hand to the method is the path string, so we'll tuck that away
        $path = $rpath.path
        # check to be sure that we're in the filesystem
        if ( $rpath.provider.name -ne "FileSystem" ) 
        { 
            "$path is not in the filesystem"
            return $null
        }
        # now that I've determined that I'm in the filesystem, go get the fileversion
        $o = [system.diagnostics.fileversioninfo]::GetVersionInfo($path)
        # this little dance adds a new property to the versioninfo object
        # I add the relative path to the versioninfo so I can inspect that in the output object
        # the way that add-member works is to not emit the object, so I need to 
        # use the -passthrough parameter
        $o|add-member noteproperty RelativePath ($path.replace($P,".")) -pass
    }
    # whoops! something bad happened
    function ShowFileError
    {
        param ( [string]$path )
        if ( test-path $path -pathtype container )
        {
            "$path is a container"
        }
        else
        {
            "$path not found"
        }
    }
}

# data could have been piped - check $_ to see if this cmdlet had data
# piped to it
process {
    if ( $_ )
    {
        # make sure that I'm not trying to get a versioninfo of a directory
        if ( test-path $_ -pathtype leaf )
        {
            GetVersionInfo $_
        }
        else
        {
            ShowFileError $_
        }
    }
}

# we could have also gotten arguments on the command line
end {
    if ( $paths )
    {
        # by calling resolve path first, I can deal with wildcards on the command line
        foreach ( $path in resolve-path $paths )
        {
            # make sure it's a file, not a directory
            if ( test-path $path -pathtype leaf )
            {
                GetVersionInfo $path
            }
            else
            {
                ShowFileError $path
            }
        }
    }
}
