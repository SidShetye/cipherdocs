param (
    [string] $folder,
    [boolean] $cleanupOriginals
)

Import-Module -Name $PSScriptRoot\CipherDocs.psm1 -Force -DisableNameChecking

Function EncryptFiles([Object[]] $files, [boolean] $cleanupOriginals) {
    $i=0
    foreach ($file in $files) {
        $i++
        $encFilePath = $file.FullName + ".gpg"
        if (-not (Test-Path $encFilePath)) {
            Trace-Log "[$i of $($files.Count)] Encrypting $file ..."
            gpg --output $encFilePath --cipher-algo AES256 --encrypt --sign --recipient $global:recipient $file.FullName 
            if ($cleanupOriginals) {
                Trace-Log "Deleting unencrypted leftover [$file]"
                Remove-Item $file.FullName -Force
            }
        } else {
            Trace-Log "WARNING: Skipping already encrypted file: $file" -BackgroundColor Black -ForegroundColor Red
        }
    }
}

Function Get-CleanupDecision() {
    $userChoice = AlertUser $("Delete unencrypted original leftover files after encryption? " + `
                            "It is recommended you do remove for a cleaner workflow " + `
                            "but make sure you have a backup.") 4

    $skipMessage = "Skipping deletion of unencrypted, original files"
    if ($userChoice -like "yes") {
        $userFinalWarning = AlertUser $("Are you sure we should cleanup leftover unencrypted original files " + `
                                      "after encryption? Make sure you have a backup to keep around for the next few days") 4
        if ($userFinalWarning -like "yes") {
            # Remove originals (!!!)
            Trace-Log "Ok, will cleanup unencrypted, original files after encryption."
            return $true
        } else {
            Trace-Log $skipMessage
        }
    } else {
        Trace-Log $skipMessage
    }

    return $false
}

######################################################
# MAIN

$startTime = Get-Date
# true is recommended for cleanup, but it cleans via deletion. So ... conservative default of false
$cleanupOriginals = $false 

$helpMessage = @"
Encrypt all files within a folder (including subfolders).

It is suggested that you
1. Create a backup of the folder you're about to encrypt. Keep it handy for a few 
days and if everything looks ok, delete that backup.
2. Don't add any new files till the folder encryption completes - they can be skipped over
3. Select Yes to delete leftover original file after their encryption (you did backup, right?)

Now pick the folder to encrypt
"@
Trace-Log $helpMessage

# If not CLI mode, prompt via GUI ...
if ($folder -eq $null -or $folder -eq "") {
    $folder = GetFolderFromUser "Select the folder to encrypt"
    $cleanupOriginals = Get-CleanupDecision
}

# Prepare file list and do encryption + cleanup operation
# Exclude already encrypted files as well as Google Docs "pointer files" (there is no local content anyway, and deleting them deletes content in the cloud!)
$files = Get-ChildItem $folder -Recurse -File -Exclude "*.gpg", "*.gdoc", "*.gslides", "*.gsheet", "*.gdraw", "*.gtable", "*.gform"
EncryptFiles $files $cleanupOriginals
$endTime = Get-Date

Trace-Log "Finished encrypting all files within $folder." -BackgroundColor DarkGreen -ForegroundColor White
Trace-Log "Total time was $($endTime - $startTime) for $($files.Count) files"