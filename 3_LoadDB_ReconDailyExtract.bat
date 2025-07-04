@REM @echo off
@REM python "C:\Users\IT\Downloads\recon_updated (1)\Recon\Update_Recon_Outcome.py"
@REM python "C:\Users\IT\Downloads\recon_updated (1)\Recon\Generate_Recon_Output.py"



@echo off
REM Change to the directory where this batch file is located
cd /d "%~dp0"

REM Now you can use just the filenames instead of full paths:
python "Update_Recon_Outcome.py"
python "Generate_Recon_Output.py"
