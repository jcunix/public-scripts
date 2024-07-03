# Configurable variables.  Script name is the map drive script provided.  This will look for the file in the my documents folder. 
# this will allow you to use onedrive to keep the file backed up.
$scriptName = "MapNetworkDrive.ps1"
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$scriptPath = [System.IO.Path]::Combine($documentsPath, $scriptName)

# Function to determine if the OS is Windows 10 or Windows 11
function Get-OSVersion {
    $osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    if ($osVersion -like "10.0.22000*" -or $osVersion -like "10.0.22621*") {
        return "Windows 11"
    } elseif ($osVersion -like "10.0.1*") {
        return "Windows 10"
    } else {
        return "Other"
    }
}

# Function to copy the script to the user's startup folder
function Copy-ScriptToStartup {
    param (
        [string]$scriptPath
    )

    $osVersion = Get-OSVersion
    if ($osVersion -eq "Windows 10" -or $osVersion -eq "Windows 11") {
        $startupFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
        $destinationPath = [System.IO.Path]::Combine($startupFolder, [System.IO.Path]::GetFileName($scriptPath))

        try {
            Copy-Item -Path $scriptPath -Destination $destinationPath -Force
            Write-Host "Script copied to startup folder successfully."
        } catch {
            Write-Host "Failed to copy script to startup folder: $_"
        }
    } else {
        Write-Host "This script is only designed for Windows 10 and Windows 11."
    }
}

# Main script execution
if (Test-Path $scriptPath) {
    Copy-ScriptToStartup -scriptPath $scriptPath
} else {
    Write-Host "The script $scriptName was not found in the Documents folder."
}
