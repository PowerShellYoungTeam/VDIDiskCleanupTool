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
function Test-Connection {
    param (
        [string]$FQDN
    )
    return Test-Connection -ComputerName $FQDN -Count 1 -Quiet
}

# Function that takes FQDN as input and returns the disk size and free space for C: drive
function Get-DiskSpace {
    param (
        [string]$FQDN
    )
    return Get-WmiObject -ComputerName $FQDN -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
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
function Test-Path {
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

# Create a Function that takes a folder path and deletes all the files in the folder
function Delete-Files {
    param (
        [string]$FolderPath
    )
    Get-ChildItem -Path $FolderPath | Remove-Item -Force -Verbose
}


# Main Script Section
# Parse parameters
param (
    [string]$Parameter1,
    [int]$Parameter2
)

# Call functions
Get-SampleFunction -Parameter1 $Parameter1 -Parameter2 $Parameter2