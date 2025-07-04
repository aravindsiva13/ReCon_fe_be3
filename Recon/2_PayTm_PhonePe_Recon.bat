@REM @echo off
@REM start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon\Process_PayTm.ps1"
@REM start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon\Process_PhonePe.ps1"
@REM start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon\Process_iCloud_Payment.ps1"
@REM start powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\IT\Downloads\recon_updated (1)\Recon\Process_iCloud_Refund.ps1"



@echo off
REM Change to the directory where this batch file is located
cd /d "%~dp0"

REM Now you can use just the filenames instead of full paths:
start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_PayTm.ps1"
start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_PhonePe.ps1" 
start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_iCloud_Payment.ps1"
start /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Process_iCloud_Refund.ps1"