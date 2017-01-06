Import-Module -Name $PSScriptRoot\..\CipherDocs.psm1 -Force -DisableNameChecking


Function Test-GetUserInput() {
    $email = GetUserInput "What's your email address?"
    Write-Host $email
}

Function Test-ValidateStringAsEmail() {
    # Test 1
    $email = "name@server.com"
    $outcome = ValidateStringAsEmail $email
    if ($outcome -ne $true) {
        throw "Test failed $email $outcome"
    }

    # Test 2 
    $email = "nameserver"
    $outcome = ValidateStringAsEmail $email
    if ($outcome -ne $false) {
        throw "Test failed $email $outcome"
    }
}

Function Test-AlertUser() {
    Write-Host "Ok. Got " $(AlertUser "Click OK" 0)
    Write-Host "Cancel. Got " $(AlertUser "Click Cancel" 1)
    Write-Host "Abort. Got " $(AlertUser "Click Abort" 2)
    Write-Host "Yes. Got " $(AlertUser "Click Yes" 3)
    Write-Host "No. Got " $(AlertUser "Click No" 4)
    Write-Host "Retry. Got " $(AlertUser "Click Retry" 5)
}

# Main Test run here. Upgrade to an actual framework + functional coverage when more time
Test-GetUserInput
Test-ValidateStringAsEmail
Test-AlertUser
GetTimestampForFilename
GetAnotherFilenameOnConflict "c:\temp\financials.xlsx.gpg"
