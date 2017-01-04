# This is the installer. Usually run by the .bat file for simplicity but if you want
# you can run this inside an elevated powershell command window yourself

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

# Create destination folder
if (-Not (Test-Path $env:USERPROFILE\Documents\WindowsPowerShell\Scripts)) {
    mkdir -Force $env:USERPROFILE\Documents\WindowsPowerShell\Scripts
}

# Copy main script there
Copy-Item .\CipherDocs.ps1 $env:USERPROFILE\Documents\WindowsPowerShell\Scripts\CipherDocs.ps1 -Force

# Setup associations with Windows Explorer
Start-Process cmd -ArgumentList "/C Assoc .gpg=gpgfile"
Start-Process cmd -ArgumentList '/C Ftype gpgfile="%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -windowstyle hidden -ExecutionPolicy RemoteSigned -File %USERPROFILE%\Documents\WindowsPowerShell\Scripts\CipherDocs.ps1 "%1" "%*"'
