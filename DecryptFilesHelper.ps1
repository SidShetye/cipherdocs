param (
    [string] $folder,
    [boolean] $cleanupOriginals = $false
)

Import-Module -Name $PSScriptRoot\CipherDocs.psm1 -Force -DisableNameChecking

Function DecryptFiles([Object[]] $files, [boolean] $cleanupOriginals) {
    $i=0
    foreach ($file in $files) {
        $i++
        $decFilePath =  $file.FullName -replace '(.*).gpg$','$1'
        if (-not (Test-Path $decFilePath)) {
            Trace-Log "[$i of $($files.Count)] Decrypting $file ..."
            gpg --output $decFilePath -dv $file.FullName 
            if ($LastExitCode) {
                Trace-Log "ERROR: GPG errorcode $LastExitCode"
            }
            if ($cleanupOriginals) {
                Trace-Log "Deleting encrypted file [$file]"
                Remove-Item $file.FullName -Force
            }
        } else {
            Trace-Log "WARNING: Skipping already decrypted file: $file" -BackgroundColor Black -ForegroundColor Red
        }
    }
}

Function Get-CleanupDecision() {
    $userChoice = AlertUser $("Delete encrypted files after decryption? ") 4

    $skipMessage = "Skipping deletion of encrypted files"
    if ($userChoice -like "yes") {
        $userFinalWarning = AlertUser $("FINAL CONFIRMATION: Hit YES again to confirm cleanup of " + `
                                      "encrypted files after decryption.") 4
        if ($userFinalWarning -like "yes") {
            # Remove originals (!!!)
            Trace-Log "Ok, will cleanup encrypted files after decryption."
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

$helpMessage = @"
DECRYPT all files within a folder (including subfolders).

It is suggested that you
1. Create a backup of the folder you're about to encrypt. Keep it handy for a few 
days and if everything looks ok, delete that backup.
2. Don't add any new files till the folder encryption completes - they can be skipped over
3. Select Yes to delete encrypted files after decryption

Now pick the folder to decrypt
"@
Trace-Log $helpMessage

# If not CLI mode, prompt via GUI ...
if ($folder -eq $null -or $folder -eq "") {
    $folder = GetFolderFromUser "Select the folder to decrypt recursively"
    $cleanupOriginals = Get-CleanupDecision
}

# Prepare file list and do encryption + cleanup operation
# Pick encrypted files
$files = Get-ChildItem $folder -Recurse -File -Include "*.gpg"
DecryptFiles $files $cleanupOriginals
$endTime = Get-Date

Trace-Log "Finished encrypting all files within $folder." -BackgroundColor DarkGreen -ForegroundColor White
Trace-Log "Total time was $($endTime - $startTime) for $($files.Count) files"