@echo off

echo Welcome! Now installing CipherDocs
echo.
echo 1. Hit yes when prompted for admin permissions 
echo 2. Expect a few console windows flashes
echo.
pause
echo.
%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -ExecutionPolicy RemoteSigned -File InstallHelper.ps1
