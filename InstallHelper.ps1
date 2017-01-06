# This is the installer. Usually run by the .bat file for simplicity but if you want
# you can run this inside an elevated powershell command window yourself

Import-Module -Name $PSScriptRoot\CipherDocs.psm1 -Force -DisableNameChecking

# Check if admin ?
If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# Allow scripts like ours (unsigned local) to be run
Set-ExecutionPolicy RemoteSigned

# Switch back to where this file (and others) actually lives
Set-Location $PSScriptRoot

Write-Host "Installation started ... `n"

# Create destination folder
if (-Not (Test-Path $env:USERPROFILE\Documents\WindowsPowerShell\Scripts)) {
    mkdir -Force $env:USERPROFILE\Documents\WindowsPowerShell\Scripts
}

# Copy workflow script and common lib there
$installFolder = $env:USERPROFILE + "\Documents\WindowsPowerShell\Scripts"
Write-Host "Copying CipherDocs to $installFolder ..."
Copy-Item .\CipherDocs.ps1 $installFolder -Force
Copy-Item .\CipherDocs.psm1 $installFolder -Force
Copy-Item .\EncryptFiles* $installFolder -Force
Copy-Item .\readme* $installFolder -Force
Copy-Item .\license* $installFolder -Force

# Replace template email with user's email
Write-Host "Configuring PGP identity to use ..."
$emailIsGood = $false
do {
    $email = GetUserInput "Please enter your GnuPG/PGP ID or email address"
    if (-not (ValidateStringAsEmail $email)) {
        $ok = AlertUser $($email + " is not a valid email address. Please try again.")
    } else {
        $emailIsGood = $true
    }
} while (-Not $emailIsGood)
# modify self. If more settings, store separately in .json or .ini
ReplaceStringInFile "you@youremail.com" $email $installFolder\CipherDocs.psm1

Write-Host "Setup associations with Windows Explorer ..."
Start-Process cmd -ArgumentList "/C Assoc .gpg=gpgfile"
Start-Process cmd -ArgumentList '/C Ftype gpgfile="%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy RemoteSigned -File %USERPROFILE%\Documents\WindowsPowerShell\Scripts\CipherDocs.ps1 "%1" "%*"'

# Open
Write-Host "Installation done. `n"

Write-Host "Next, we'll bring up " -NoNewline
Write-Host "EncryptFiles.bat" -NoNewline -BackgroundColor DarkGreen -ForegroundColor White
Write-Host ". Run it to begin encrypting your files."

Write-Host "Press enter to proceed ..."
Read-Host
Start-Process Explorer $installFolder