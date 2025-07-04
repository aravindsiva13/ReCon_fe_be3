@echo off
title Complete Reconciliation Process
echo =====================================
echo   COMPLETE RECONCILIATION PROCESS
echo =====================================
echo.

cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo Step 1/3: Preparing Input Files...
echo =====================================
call "1_Prepare_Input_Files.bat"
if %errorlevel% neq 0 (
    echo ERROR: Step 1 failed - Prepare Input Files
    echo Error code: %errorlevel%
    exit /b 1
)
echo Step 1 completed successfully.
echo.

echo Step 2/3: Processing PayTM and PhonePe Data...
echo =====================================
call "2_PayTm_PhonePe_Recon.bat"
if %errorlevel% neq 0 (
    echo ERROR: Step 2 failed - PayTM PhonePe Reconciliation
    echo Error code: %errorlevel%
    exit /b 2
)
echo Step 2 completed successfully.
echo.

echo Step 3/3: Loading Database and Generating Report...
echo =====================================
call "3_LoadDB_ReconDailyExtract.bat"
if %errorlevel% neq 0 (
    echo ERROR: Step 3 failed - Load DB and Generate Report
    echo Error code: %errorlevel%
    exit /b 3
)
echo Step 3 completed successfully.
echo.

echo =====================================
echo   ALL SCRIPTS COMPLETED SUCCESSFULLY
echo =====================================
echo Check the Output_Files folder for results.
echo Generated file: recon_output.xlsx
echo.