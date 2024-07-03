# Define the network drive letter and the network path
$driveLetter = "Z:"
$networkPath = "\\server\sharedfolder"

# Prompt the user for their username and password
$credential = Get-Credential -Message "Enter your username and password for the network drive."

# Attempt to map the network drive
try {
    # Remove the drive if it already exists
    if (Test-Path -Path "$driveLetter\") {
        Remove-PSDrive -Name $driveLetter.TrimEnd(':') -Force
    }

    # Create the mapped drive
    net use $driveLetter $networkPath /user:$($credential.UserName) $($credential.GetNetworkCredential().Password)

    Write-Host "Drive mapped successfully to $driveLetter"

    # Check if the drive was mapped successfully
    if (Test-Path -Path "$driveLetter\") {
        Write-Host "The drive is successfully mapped and visible."
    } else {
        Write-Host "The drive mapping process completed, but the drive is not visible."
    }
} catch {
    Write-Host "Failed to map drive: $_"
}
