@echo off

echo Installing CipherDocs
echo During installation you will be prompted for permissions and 
echo see a few console windows flash. This is normal.
echo.
echo To cancel setup right now, press Control-C else 
pause
echo.
start /wait %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -ExecutionPolicy RemoteSigned -File InstallHelper.ps1
echo.
echo.
echo Installation is done!
echo.
pause
