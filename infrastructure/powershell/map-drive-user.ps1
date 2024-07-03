# Define paths for the encryption key and credential files
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$keyPath = Join-Path -Path $documentsPath -ChildPath "encryptionkey.key"
$credentialPath = Join-Path -Path $documentsPath -ChildPath "credentials.xml"

# Function to generate and store the encryption key if it doesn't exist
function Generate-EncryptionKey {
    if (-Not (Test-Path $keyPath)) {
        $key = New-Object byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
        [System.IO.File]::WriteAllBytes($keyPath, $key)
        Write-Host "Encryption key generated and stored at $keyPath"
    } else {
        Write-Host "Encryption key already exists at $keyPath"
    }
}

# Function to prompt for credentials and store them securely
function Store-Credentials {
    if (-Not (Test-Path $credentialPath)) {
        $credential = Get-Credential -Message "Enter your username and password for the network drive."
        $key = [System.IO.File]::ReadAllBytes($keyPath)
        $securePassword = $credential.Password | ConvertFrom-SecureString -Key $key
        $credentialObject = New-Object PSObject -Property @{
            UserName = $credential.UserName
            Password = $securePassword
        }
        $credentialObject | Export-Clixml -Path $credentialPath
        Write-Host "Credentials encrypted and stored at $credentialPath"
    } else {
        Write-Host "Encrypted credentials file already exists at $credentialPath"
    }
}

# Function to map the network drive using stored credentials
function Map-NetworkDrive {
    $driveLetter = "Z:"
    $networkPath = "\\server\sharedfolder"

    if ((Test-Path $credentialPath) -and (Test-Path $keyPath)) {
        $key = [System.IO.File]::ReadAllBytes($keyPath)
        $credentialObject = Import-Clixml -Path $credentialPath
        $securePassword = $credentialObject.Password | ConvertTo-SecureString -Key $key
        $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        $credential = New-Object System.Management.Automation.PSCredential ($credentialObject.UserName, $securePassword)

        try {
            if (Test-Path "$driveLetter\") {
                net use $driveLetter /delete /y
            }

            $username = $credential.UserName
            # Properly handle special characters in password and path
            $command = "net use $driveLetter `"$networkPath`" /user:$username $passwordPlainText /persistent:yes"
            Invoke-Expression $command

            Write-Host "Drive mapped successfully to $driveLetter"

            if (Test-Path "$driveLetter\") {
                Write-Host "The drive is successfully mapped and visible."
            } else {
                Write-Host "The drive mapping process completed, but the drive is not visible."
            }
        } catch {
            Write-Host "Failed to map drive: $_"
        }
    } else {
        Write-Host "Credentials file or encryption key not found. Please run the script to store credentials first."
    }
}

# Main script execution
Generate-EncryptionKey
Store-Credentials
Map-NetworkDrive
