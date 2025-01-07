<#
.SYNOPSIS
    VDIDiskCleanuptool.ps1

.DESCRIPTION
    This script is used to clean up the VDI disk space by deleting the old files.

.PARAMETER Hostnames
    hostname or an array of hostnames to run the script on.

.PARAMETER Domain
    pass the domain for fqdn.

.PARAMETER PartialPaths
    array of partial paths to folders that need to be checked in the user folder.;,

.EXAMPLE
    Example of how to use the script.

.NOTES
    File Name      : VDIDiskCleanuptool.ps1
    Author         : 
    Prerequisite   : PowerShell V2.0

    chucked togther with Gitlab Copilot's help

#>

# Parameters Section (for testing so I don't need pass parameters)
$Hostnames = 'Hostname'
$Domain = 'uk.uk.corp'
$PartialPaths = 'Downloads', 'Documents', 'Desktop', 'Pictures', 'Music', 'Videos', 'AppData\Local\Temp', 'AppData\Local\CrashDumps'

# Functions Section

# function that asks the user to confirm if the want to proceed, it will double check if the user wants to proceed, if neither Y or N is entered , it will ask again, it should handle lowercase and uppercase
function Confirm-Action {
    $response = Read-Host "Do you want to proceed? (Y/N)"
    while ($response -notin 'Y', 'N') {
        $response = Read-Host "Please enter Y or N"
    }
    return $response -eq 'Y'
}


# function that takes hostname and domain as input and returns the fqdn
function Get-FQDN {
    param (
        [string]$Hostname,
        [string]$Domain
    )
    return "$Hostname.$Domain"
}

# Function that takes FQDN as input and checks if the host is reachable
function Test-VDIConnection {
    param (
        [string]$FQDN
    )
    return Test-Connection -ComputerName $FQDN -count 1 -quiet
}

# Function that takes FQDN as input and returns the disk size and free space for C: drive
function Get-DiskSpace {
    param (
        [string]$FQDN
    )
    $diskdeets = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $FQDN | ? {$_. DriveType -eq 3} | select DeviceID, {$_.Size /1GB}, {$_.FreeSpace /1GB}
    return $diskdeets
}

# Function that checks for the existence of Pagefile.sys, pagefile.sys and Hiberfil.sys in the root of C: drive and returns if it exists and what size it is
function Get-SystemFiles {
    param (
        [string]$FQDN
    )
    $results = @()
    $systemFiles = @('Pagefile.sys', 'pagefile.sys', 'Hiberfil.sys')
    foreach ($systemFile in $systemFiles) {
        $fullPath = "\\$FQDN\c$\$systemFile"
        $exists = Test-Path -Path $fullPath
        if ($exists) {
            $size = (Get-Item -Path $fullPath).Length
        } else {
            $size = 0
        }
        $results += [PSCustomObject]@{
            Name = $systemFile
            Exists = $exists
            Size = $size
        }
    }
    return $results
}

# Function that takes FQDN as input and returns the contents of C:\temp folder, including size and last modified date
function Get-TempFolderContents {
    param (
        [string]$FQDN
    )
    return Get-ChildItem -Path "\\$FQDN\c$\temp" | Select-Object Name, Length, LastWriteTime
}

# Function that takes FQDN as input and gets return all the non default user folders in c:\users
function Get-UserFolders {
    param (
        [string]$FQDN
    )
    return Get-ChildItem -Path "\\$FQDN\c$\Users" -Directory | Where-Object { $_.Name -notin 'Public', 'Default', 'All Users' }
}

# Function that takes a path to a users folder and an array of partial paths and join paths them then and test-paths them and return the results along with the full path tested
function Test-UserFolderPaths {
    param (
        [string]$UserFolderPath,
        [string[]]$PartialPaths
    )
    $results = @()
    foreach ($partialPath in $PartialPaths) {
        $fullPath = Join-Path -Path $UserFolderPath -ChildPath $partialPath
        $results += [PSCustomObject]@{
            Path = $fullPath
            Exists = Test-Path -Path $fullPath
        }
    }
    return $results
}

# Function that takes a folder path and return the contenst including name, size and last modified date
function Get-FolderContents {
    param (
        [string]$FolderPath
    )
    return Get-ChildItem -Path $FolderPath | Select-Object Name, Length, LastWriteTime
}

# Function that search's user's localappdata folder for .ost files and reports on the name, size and last modified date
function Get-OSTFiles {
    param (
        [string]$UserFolderPath
    )
    return Get-ChildItem -Path "$UserFolderPath\Local\Microsoft\Outlook" -Filter *.ost | Select-Object Name, Length, LastWriteTime
}

# Create a Function that takes a folder path and deletes all the files in the folder
function Remove-Files {
    param (
        [string]$FolderPath
    )
    Get-ChildItem -Path $FolderPath | Remove-Item -Force -Verbose
}


# Controller Functions Section

# Function that takes hostname, domain and partial paths as input and runs the cleanup process
function Run-Cleanup {
    param (
        [string]$Hostname,
        [string]$Domain,
        [string[]]$PartialPaths
    )
    $FQDN = Get-FQDN -Hostname $Hostname -Domain $Domain

    write-host $FQDN
    Test-VDIConnection -FQDN $FQDN
    if (Test-VDIConnection -FQDN $FQDN -verbose) {
        $diskSpace = Get-DiskSpace -FQDN $FQDN
        Write-Host "Computer: $Hostname"
        Write-Host "Disk Size: $($diskSpace.Size)"
        Write-Host "Free Space: $($diskSpace.FreeSpace)"
        $systemFiles = Get-SystemFiles -FQDN $FQDN
        Write-Host "System Files:"
        $systemFiles | Format-Table
        $tempFolderContents = Get-TempFolderContents -FQDN $FQDN
        Write-Host "Temp Folder Contents:"
        $tempFolderContents | Format-Table
        $userFolders = Get-UserFolders -FQDN $FQDN
        foreach ($userFolder in $userFolders) {
            Write-Host "User Folder: $($userFolder.Name)"
            $OSTFiles = Get-OSTFiles -UserFolderPath $userFolder.FullName
            Write-Host "OST Files:"
            $OSTFiles | Format-Table
            $results = Test-UserFolderPaths -UserFolderPath $userFolder.FullName -PartialPaths $PartialPaths
            foreach ($result in $results) {
                if ($result.Exists) {
                    Write-Host "Path: $($result.Path) exists"
                    $folderContents = Get-FolderContents -FolderPath $result.Path
                    Write-Host "Folder Contents:"
                    $folderContents | Format-Table
                    if (Confirm-Action) {
                        Remove-Files -FolderPath $result.Path
                    }
                } else {
                    Write-Host "Path: $($result.Path) does not exist"
                }
            }
        }
    } else {
        Write-Host "Host $Hostname is not reachable"
    }
}


#test area###

Run-Cleanup -Domain $Domain  -Hostname $Hostnames -PartialPaths $PartialPaths
