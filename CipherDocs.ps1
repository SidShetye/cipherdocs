param (
    [string] $filePath
)

# Edit this to be your own OpenPGP/GnuGP keypair name
$recipient = "sid@crypteron.com"

########################################################

Function FatalException([string] $message) {
    $userAlert = New-Object -ComObject wscript.shell 
    $userAlert.popup($message, 0, "Error", 0)
    throw [System.IO.IOException] $message
}

Function GetTempFilePath([string] $origFilePath) {
    $tempDir = $env:Temp
    $attempt = 0
    $fileName = Split-Path $origFilePath -Leaf
    # $fileNameOrig = $fileName.Substring(0, $fileName.LastIndexOf('.'))
    $fileNameOrig = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

    # $fileNameOrig 
    $tempClearFilePath = Join-Path $tempDir $fileNameOrig 
    while (Test-Path $tempClearFilePath) {
        # try to remove it first
        try {
            Remove-Item $tempClearFilePath -Force
        } catch {
            # else just use another name, appending a number at the end
            $attempt += 1
            if ($attempt -gt 10) {
                FatalException "Too many temp files exist, manually remove some ($tempClearFilePath)"
            }

            $filenamebase = [System.IO.Path]::GetFileNameWithoutExtension($fileNameOrig)
            $filenameExt = [System.IO.Path]::GetExtension($fileNameOrig)
            $tempClearFile = $filenamebase + "-$attempt" + $filenameExt
            $tempClearFilePath = Join-Path $tempDir $tempClearFile
        }
    }

    return $tempClearFilePath
}

Function FileHasChanged($fileState) {
    $filePath = $fileState."path"
    $timestamp = (Get-Item $fileState."path").LastWriteTimeUtc; 
    
    
    if ($timestamp -eq ($fileState."timestamp")) {
        Write-Host "timestamps identical"
        return $false
    }

    $hash = (Get-FileHash $fileState."path").Hash 
    if ($hash -eq ($fileState."hash")) {
        Write-Host "hashes are identical"
        return $false
    }

    return $true
}

Write-Host "Processing $filePath ..."
$tempClearFilePath = GetTempFilePath $filePath

## Decryption
Write-Host "Decrypting to local temp folder [$tempClearFilePath] ... "
do {
    gpg --output $tempClearFilePath --decrypt $filePath
    $decryptionErrorCode = $LASTEXITCODE 
    # Write-Host "decryptionErrorCode is $decryptionErrorCode"

    if ($decryptionErrorCode -ne 0) {
        $userAlert = New-Object -ComObject wscript.shell 
        # AlertType - Buttons/Description   
        #0 Show OK button. 
        #1 Show OK and Cancel buttons. 
        #2 Show Abort, Retry, and Ignore buttons. 
        #3 Show Yes, No, and Cancel buttons. 
        #4 Show Yes and No buttons. 
        #5 Show Retry and Cancel buttons. 
        $alertType = 5

        # Retry = 4
        # Cancel = 2
        $userChoice = $userAlert.popup("Error during decryption. Should we retry or cancel?", 0, "Decryption Error", $alertType) 
    }

    if ($userChoice -eq 2) {
        throw "GnuPG decryption error. Aborting."
    }

} while ($decryptionErrorCode -ne 0)

# Measure and store current state
$clearFileState = @{
    "path" = $tempClearFilePath; 
    "timestamp" = (Get-Item $tempClearFilePath).LastWriteTimeUtc; 
    "hash" = (Get-FileHash $tempClearFilePath).Hash 
}

Write-Host "Opening the document ... "
# Invoke-Item $tempClearFilePath 
Start-Process -Wait $tempClearFilePath

if (FileHasChanged $clearFileState) {
    Write-Host "Reencrypting the modified document ... "

    # TODO: Find all current recipients and then add each.
    # Find all current recipients: gpg --list-only --no-default-keyring --secret-keyring "" filename.ext.gpg
    # and then regex for "gpg: encrypted with 4096-bit RSA key, ID ABC12345, created 2016-03-18"
    # plucking out the 'ABC12345' IDs
    # To add multiple recipients: gpg --recipient first --recipient second --recipient third
    gpg --batch --yes --cipher-algo AES256 --encrypt --output $filePath --sign --recipient $recipient $tempClearFilePath
}

Write-Host "Done ..."
