param (
    [string] $folder,
    [boolean] $cleanupOriginals
)

# Edit this to be your own OpenPGP/GnuGP keypair name
$recipient = "sid@crypteron.com"

########################################################

Function Get-InputFolderViaGui {
    $shell = New-Object -ComObject "Shell.Application"
    $folder = $shell.BrowseForFolder(0, "Select folder for encryption", 0)
    if($folder) {
        return $folder.self.Path
    } else {
        FatalError "No folder selected"
    }
}

Function FatalError([string] $errMsg) {
    Write-Host $errMsg -ForegroundColor Black -BackgroundColor Red
    Write-Host "Press enter to terminate ..." -ForegroundColor Black -BackgroundColor Red
    Read-Host
    Exit 1
}

Function EncryptFiles([Object[]] $files, [boolean] $cleanupOriginals) {
    $i=1
    foreach ($file in $files) {
        $i++
        $encFilePath = $file.FullName + ".gpg"
        if (-not (Test-Path $encFilePath)) {
            Write-Host "[$i of $($files.Count)] Encrypting $file ..."
            gpg --cipher-algo AES256 --encrypt --sign --recipient $recipient $file.FullName
            if ($cleanupOriginals) {
                Write-Host "Deleting unencrypted leftover [$file]"
                Remove-Item $file.FullName -Force
            }
        } else {
            Write-Host "WARNING: Skipping already encrypted file: $file" -BackgroundColor Black -ForegroundColor Red
        }
    }
}

Function Get-CleanupDecisionViaGui() {
    Write-Host "After encrypting, cleanup leftover unencrypted files?" -BackgroundColor DarkGreen -ForegroundColor White

    $userAlert = New-Object -ComObject wscript.shell 
    # 0 OK : 1 OK and Cancel : 2 Abort, Retry, and Ignore : 3 Yes, No, and Cancel : 4 Yes and No : 5 Retry and Cancel  
    $alertType = 4

    # Retry = 4, Cancel = 2, Yes = 6, No = 7
    $userChoice = $userAlert.popup("After encryption, cleanup leftover unencrypted original files? Make sure you've got a backup", 0, "Delete confirmation", $alertType) 

    $skipMessage = "Skipping deletion of unencrypted, original files"
    if ($userChoice -eq 6) {
        $userFinalWarning = $userAlert.popup("Are you sure we should cleanup leftover unencrypted original files after encryption?", 0, "Final confirmation", $alertType) 
        if ($userFinalWarning -eq 6) {
            # Remove originals (!!!)
            Write-Host "Ok, will cleanup unencrypted, original files after it's been encrypted."
            return $true
        } else {
            Write-Host $skipMessage
        }
    } else {
        Write-Host $skipMessage
    }

    return $false
}

######################################################
# MAIN

$startTime = Get-Date
# true is recommended for cleanup, but it cleans via deletion. So ... conservative default of false
$cleanupOriginals = $false 

$helpMessage = @"
This will encrypt all files in a folder (including subfolders) that 
you be prompted for shortly. After encryption completes, you will 
then be asked if you want to delete those unencrypted, original files. 
It is suggested that you
1. Create a backup of the folder you're about to encrypt. Keep it handy for a few 
days until you're sure everything is ok (then delete the backup).
2. Don't add any new files till the folder encryption completes
3. Select Yes to delete the originals after encryption completes (You did backup, right?)

Now select the folder to encrypt
"@
Write-Host $helpMessage -BackgroundColor Black -ForegroundColor Green

# If not CLI mode, prompt via GUI ...
if ($folder -eq $null -or $folder -eq "") {
    $folder = Get-InputFolderViaGui
    $cleanupOriginals = Get-CleanupDecisionViaGui
}

# Prepare file list and do encryption + cleanup operation
# Exclude already encrypted files as well as Google Docs "pointer files" (there is no local content anyway, and deleting them deletes content in the cloud!)
$files = Get-ChildItem $folder -Recurse -File -Exclude "*.gpg", "*.gdoc", "*.gslides", "*.gsheet", "*.gdraw", "*.gtable", "*.gform"
EncryptFiles $files $cleanupOriginals
$endTime = Get-Date

Write-Host "Finished encrypting all files within $folder." -BackgroundColor DarkGreen -ForegroundColor White
Write-Host "Total time was $($endTime - $startTime) for $($files.Count) files"