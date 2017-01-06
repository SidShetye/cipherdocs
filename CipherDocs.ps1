param (
    [string] $filePath
)

Import-Module -Name $PSScriptRoot\CipherDocs.psm1 -Force -DisableNameChecking

Function GetTempFilePath([string] $origFilePath) {
    $tempDir = $env:Temp
    $attempt = 0
    $fileName = Split-Path $origFilePath -Leaf
    $fileNameOrig = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

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

Confirm-DefaultEmailIsModified

# Write to console instead of text log file so we don't track user's ongoing 
# activity. 
Write-Host "Processing $filePath ..."
$tempClearFilePath = GetTempFilePath $filePath

## Capture our starting encrypted file state
$encFileStartState = Get-FileState $filePath

## Decrypt 
Write-Host "Decrypting to local temp folder [$tempClearFilePath] ... "
do {
    gpg --output $tempClearFilePath --decrypt $filePath
    $decryptionErrorCode = $LASTEXITCODE 

    if ($decryptionErrorCode -ne 0) {        
        $userChoice = AlertUser "Error during decryption. Should we retry or cancel?" 5

        if ($userChoice -eq "cancel") {
            FatalException "GnuPG decryption error. Aborting."
        }
    }

} while ($decryptionErrorCode -ne 0)

# Measure and store current state of clear file
$clearFileState = Get-FileState $tempClearFilePath

Write-Host "Opening the document ... "
#TODO: This is quite flaky in Powershell ... if editor is already 
#      open prior to this, it returns immmediately!
#      better to monitor file periodically until handles == 0
Start-Process $tempClearFilePath -Wait 

# Editor closed, examine plaintext file
if (FileHasChanged $clearFileState) {
    if (FileHasChanged $encFileStartState) {
		$outputEncFilepath = GetAnotherFilenameOnConflict $filePath
        $msg = "$([System.IO.Path]::GetFileName($filePath)) was modified while you were editting it. " +
               "Your copy was saved and will be encrypted to $outputEncFilepath instead. " +
               "You need to manually merge file edits."
        AlertUser $msg 0
    } else {
        $outputEncFilepath = $filePath
    }

    Write-Host "Reencrypting the modified document ... "

    # TODO: Find all current recipients and then add each.
    # Find all current recipients: gpg --list-only --no-default-keyring --secret-keyring "" filename.ext.gpg
    # and then regex for "gpg: encrypted with 4096-bit RSA key, ID ABC12345, created 2016-03-18"
    # plucking out the 'ABC12345' IDs
    # To add multiple recipients: gpg --recipient first --recipient second --recipient third
    gpg --batch --yes --cipher-algo AES256 --encrypt --output $outputEncFilepath --sign --recipient $global:recipient $tempClearFilePath
}

Write-Host "Done ..."
