# Edit this to be your own OpenPGP/GnuGP keypair name
$global:recipient = "you@youremail.com"

#########################################################
## Put common stuff here
$Logfile = $PSScriptRoot + "\CipherDocs.log"


Function Confirm-DefaultEmailIsModified() {
    $userAlert = New-Object -ComObject wscript.shell 

	# so installer replacement doesn't replace THIS!
	$installDefaultEmail = "you" + "@youremail.com" 

    if ($global:recipient -eq $installDefaultEmail) {
        $errMsg = @"
Recipient is still the default $($global:recipient)! Please change to your own
email address by editing the script at $PSScriptRoot. Refer to the readme.md file for details.

Press enter to terminate
"@

        $dontCare = $userAlert.popup($errMsg, 0, "Error", 0)
        Write-Host $errMsg -BackgroundColor Red -ForegroundColor Black
        Read-Host
    }
}

Function Get-FileState ($filePath) {
    $clearFileState = @{
        "path" = $filePath; 
        "timestamp" = (Get-Item $filePath).LastWriteTimeUtc; 
        "hash" = (Get-FileHash $filePath).Hash 
    }
    return $clearFileState
}

Function FatalException([string] $message) {
    AlertUser $message 0
    throw [System.IO.IOException] $message
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

Function AlertUser(
    [string] $message, 
    # type of dialog. 0=OK, 1=OK Cancel, 2=Abort Retry Ignore, 3=Yes No Cancel, 4=Yes No, 5=Retry Cancel  
    [int] $type = 0) {

    Trace-Log $message

    $userAlert = New-Object -ComObject wscript.shell 
    $choiceInt = $userAlert.popup($message, 0, "", $type)
    $choice = ""

    switch ($choiceInt) 
    { 
        1 {$choice = "ok"}
        2 {$choice = "cancel"}
        3 {$choice = "abort"}
        4 {$choice = "retry"} 
        5 {$choice = "ignore"}
        6 {$choice = "yes"}
        7 {$choice = "no"}
        default { FatalException "Got unknown $choiceInt "}
    }

    return $choice
}

Function GetFolderFromUser($message) {
    $shell = New-Object -ComObject "Shell.Application"
    $folder = $shell.BrowseForFolder(0, $message, 0)
    if($folder) {
        return $folder.self.Path
    } else {
        FatalException "No folder selected"
    }
}

Function GetAnotherFilenameOnConflict([string] $filePath) {
    $outputFolder = Split-Path $filePath
    $filenameNoEncExt  = [System.IO.Path]::GetFileNameWithoutExtension($filePath) # c:\some\path\file.txt.gpg -> file.txt
    $filenameNoExt  = [System.IO.Path]::GetFileNameWithoutExtension($filenameNoEncExt)    # file.txt -> file
        
	$encExt = [System.IO.Path]::GetExtension($filePath) # ".pgp"
	$clearExt = [System.IO.Path]::GetExtension($filenameNoEncExt) # ".txt"

	# file -conflict-2016-12-**** .txt .pgp
    $outputEncFilename = $filenameNoExt + "-conflict-$(GetTimestampForFilename)" + $clearExt + $encExt
    $outputEncFilepath = Join-Path $outputFolder $outputEncFilename
	return $outputEncFilepath
}

Function GetUserInput($message) {

    Trace-Log $message

    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    $title = 'Input required'
    $text = [Microsoft.VisualBasic.Interaction]::InputBox($message, $title)
    return $text
}

Function ValidateStringAsEmail($email) {
    return ($email -as [System.Net.Mail.MailAddress]).Address -eq $email -and $email -ne $null
}

Function GetTimestampForFilename() {
	# get sortable, replace illegal chars
	return $(Get-Date).ToString("s").Replace(":","-")
}

Function ReplaceStringInFile( [string]$SearchString, [string]$ReplaceString, [string] $FilePath ) {
	# sanity check - check if the string even exists
	if (!(Select-String -Path $FilePath -Pattern $SearchString -SimpleMatch -Quiet -CaseSensitive))
	{
		[string] $error = "Could not find $SearchString inside $FilePath. "
		if (Select-String -Path $FilePath -Pattern $SearchString -SimpleMatch -Quiet)
		{
			$error = $error + "But it was found with a different case"
		}
        Trace-Error $error
	}
	
	(Get-Content $FilePath).replace($SearchString, $ReplaceString) | Set-Content $FilePath
}

# Write to console and file
Function Trace-Log ([string]$logstring, [string]$arg1, [string]$arg2, [string]$arg3, [string]$arg4, [string]$arg5, [string]$arg6, [string]$arg7, [string]$arg8, [string]$arg9, [string]$arg10, [string]$arg11, [string]$arg12, [string]$arg13) {
    # Calling functions may send in multiple strings, not just one single string, so we 
    # internally concat them all
    $outputString = $logstring + $arg1 + $arg2 + $arg3 + $arg4 + $arg5 + $arg6 + $arg7 + $arg8 + $arg9 + $arg10 + $arg11 + $arg12 + $arg13
    Add-Content $Logfile -value $outputString 
	Write-Host $outputString 
}

# Write to console and file
Function Trace-Error ([string]$logstring, [string]$arg1, [string]$arg2, [string]$arg3, [string]$arg4, [string]$arg5, [string]$arg6, [string]$arg7, [string]$arg8, [string]$arg9, [string]$arg10, [string]$arg11, [string]$arg12, [string]$arg13) {
    # Calling functions may send in multiple strings, not just one single string, so we 
    # internally concat them all
    $outputString = $logstring + $arg1 + $arg2 + $arg3 + $arg4 + $arg5 + $arg6 + $arg7 + $arg8 + $arg9 + $arg10 + $arg11 + $arg12 + $arg13
 	Add-Content $Logfile -value $("ERROR >> " + $outputString)
	Write-Error $outputString 
}
