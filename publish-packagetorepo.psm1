function Publish-PackageToRepo {
    Param(
        [string[]]$File,
        [string]$Name = (Get-Item -Path $File).Name,
        [string]$Destination,
        [string]$Version = 'Incremental',
        [string]$Log = "$Destination\Logs",
        [string]$Archive = 'zip'
    )

    # Initialise Variables
    $Date = Get-Date -Format ddmmyy
    $Time = Get-Date -Format HH:mm:ss
    $LogFile = $Date + "_PackageToRepo.log"
    $IsNupkg = $False
    $ChocoTemplate = 'web_app'
    
    
    # Initialise logfile
    If (Test-Path $Log) {
        $Value = @(
            "Logfile Initialized at $Time",
            "File:        $File",
            "Name:        $Name",
            "Destination: $Destination",
            "Version:     $Version",
            "Archive:     $Archive"
        )
        New-Item -Path $Log -Name $LogFile -ItemType Logs -Value $Value
    }

    # Locate the executable for 7z.exe
    [string]$7zipRegistry = 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
    $7zipAppVObj = Get-AppVClientPackage -All | Where-Object {$_.Name -like "*7*zip*"} | Select-Object -First

    If ($7zipAppVObj -ne '' -or $null) {
        # APPV Package Exists. Use That.
        [string]$7zipGUID = $7zipAppVObj.PackageID
        
        If ($7zipAppVObj.IsPublishedToUser -eq $True) {
            [string]$7zipEXE = "C:\Users\" + $env:username + "\AppData\Local\Microsoft\AppV\Client\Integration\" + $7zipGUID + "\Root\VFS\ProgramFilesX64\7-Zip\7z.exe"
        } elseif ($7zipAppVObj.IsPublishedGlobally -eq $True) {
            [string]$7zipEXE = "C:\ProgramData\App-V\" + $7zipGUID + "\Root\VFS\ProgramFilesX64\7-Zip\7z.exe"
        } else {
            Throw "A 7-Zip APPV Package exists, however it is not currently published to a User or Globally."
        }
    } elseif (Test-Path $7zipRegistry) {
        # APPV Doesn't exist. Check for Physical install.
        [string]$7zipEXE = (Get-ItemProperty $7zipRegistry | Select-Object InstallLocation).InstallLocation + "7z.exe"
    } else {
        Throw "A 7-Zip Installation cannot be found."
    }

    # Gather $CurrentBuildVersion if exists
    If (Test-Path "$Destination\$Name.*.$Archive") {
        $CurrentBuild = @(Get-ChildItem -Path $Destination | Where-Object -Property Name -like "$Name*" | Sort-Object -Descending)[0]
        $CurrentBuildVersion = (Get-Item $CurrentBuild).Name.Substring($Name.Length, -$Archive.Length)
    } Else {
       $CurrentBuildVersion = '0.0.0.0' 
    }

    # Test path to $File and 7z.exe. If fail either, Throw.
    If ( !(Test-Path $File) -or !(Test-Path $7zipEXE) ) {
        ThrowError -ExceptionMessage "Unable to access path: $File"
    }
    
    # Set the Arguments for the Archival method
    $TempFile = Join-Path ([System.IO.Path]::GetTempPath()) ($Name + '.' + $Version + ".7z")
    $TempCache = New-Item (Join-Path ([System.IO.Path]::GetTempPath()) ($Name + '.' + $Version)) -type directory
    $OutPackage = [System.IO.DirectoryInfo](Join-Path (Join-Path $TempCache $Name) ($Name + '.' + $Version + '.' + $Archive))

    switch ($Archive) {
        {$_ -eq '7z'} {
            $Args = @(
                'a',
                '-t7z',
                '-r',
                $TempFile,
                ($File.ToString() + "\*")
            )
        }
        {$_ -eq 'nupkg'} {
            $Args = @(
                'a',
                '-t7z',
                '-r',
                $TempFile,
                ($File.ToString() + "\*")
            )
            [bool]$IsNupkg = $True
        }
        Default {
            $Args = @()
        }
    }

    # Use 7zip to make Archive
    & $7zipEXE $Args 

    # If output is to be a nupkg, use Chocolatey to take the .7z and create nupkg
    If ($IsNupkg) {
        $ChocoArgs = @(
            'new'
            $Name,
            '--a',
            '--version',
            $Version,
            '--template',
            $ChocoTemplate,
            '--outputdirectory',
            $TempCache,
            "zipfile=$TempFile",
            '--force'
        )
        
        # Create skeleton for the nupkg from template
        & 'choco' $ChocoArgs 

        $ChocoPackArgs = @(
            'pack',
            '--cache',
            $TempCache.FullName
        )

        # Pack the chocolay package
        Push-Location (Join-Path $TempCache $Name)
        $r = & 'choco' 'pack'
        Pop-Location

        # Remove the 7z archive used to build the nupkg
        Remove-Item $TempFile
    }

    # Move the Archive file up to the Destination
    Copy-Item (Get-Item $OutPackage) $Destination -Force

    # Remove the folder with the .nuspec file that got created at build time
    Remove-Item (Join-Path $TempCache $Name) -Recurse
    Remove-Item $TempCache -Recurse -Force


    # Close logfile.
    # Get-ChildItem on the new package, and output its properties to Log.
}
