@echo off
rem This file should be saved with ANSI or GB2312 encoding

:: Set variables
set "ZT_HOME=C:\ProgramData\ZeroTier\One"
set "DEST_FILE=%ZT_HOME%\planet"
:: Generate timestamp accurate to minutes (format: year-month-day-hour-minute)
set "TIMESTAMP=%date:~0,4%-%date:~5,2%-%date:~8,2%-%time:~0,2%-%time:~3,2%"
:: Replace possible spaces in timestamp
set "TIMESTAMP=%TIMESTAMP: =0%"
set "BACKUP_FILE=%ZT_HOME%\planet.bak-%TIMESTAMP%"
set "TEMP_FILE="

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Administrator privileges are required to execute this operation.
    echo Please right-click this script and select "Run as administrator".
    pause
    exit /b 1
)

:: Menu selection
echo Please select Planet file source:
echo 1. Download from network
echo 2. Use local file
set /p SOURCE_OPTION=Please enter option [1/2]: 

if "%SOURCE_OPTION%"=="1" (
    call :download_option
    if %errorLevel% neq 0 (
        pause
        exit /b 1
    )
) else if "%SOURCE_OPTION%"=="2" (
    call :local_option
    if %errorLevel% neq 0 (
        pause
        exit /b 1
    )
) else (
    echo Error: Invalid option!
    pause
    exit /b 1
)

:: Check if temporary file exists
if not exist "%TEMP_FILE%" (
    echo Error: Operation prerequisite step failed, temporary file not generated
    pause
    exit /b 1
)

:: Stop ZeroTierOneService service
echo Stopping ZeroTierOneService service...
sc query ZeroTierOneService | findstr "RUNNING" > nul
if %errorLevel% equ 0 (
    sc stop ZeroTierOneService > nul
    timeout /t 3 > nul
) else (
    echo ZeroTierOneService service already stopped or not running
)

:: Confirm service has stopped
sc query ZeroTierOneService | findstr "STOPPED" > nul
if %errorLevel% neq 0 (
    echo Warning: Unable to confirm if service has stopped, will attempt to continue execution
)
echo Service stop processing completed.

:: Backup planet file
if exist "%DEST_FILE%" (
    echo Backing up original Planet file to %BACKUP_FILE% ...
    copy "%DEST_FILE%" "%BACKUP_FILE%" >nul 2>&1
    if %errorLevel% neq 0 (
        echo Backup file failed, but will continue execution.
    ) else (
        echo Original file has been successfully backed up.
    )
)

:: Before replacing planet file, ensure target directory exists
if not exist "%ZT_HOME%" (
    echo Creating target directory %ZT_HOME%
    mkdir "%ZT_HOME%" 2>nul
)

:: Replace planet file
echo Replacing planet file...
copy /y "%TEMP_FILE%" "%DEST_FILE%" >nul
if %errorLevel% neq 0 (
    echo Replace file failed.
    pause
    exit /b 1
)
echo Replace file completed.

:: Delete temporary file
del "%TEMP_FILE%" >nul 2>&1

:: Start ZeroTierOneService service
echo Starting ZeroTierOneService service...
sc start ZeroTierOneService >nul
if %errorLevel% neq 0 (
    echo Start service failed, please manually start ZeroTierOneService service.
) else (
    echo Service has been successfully started.
)

:: Completion
echo.
echo All operations completed!
echo - New Planet File: %DEST_FILE%
if exist "%BACKUP_FILE%" echo - Backup File: %BACKUP_FILE%
pause
exit /b 0

:download_option
    :: Get user input URL
    set /p DOWNLOAD_URL=Please enter the download URL for the Planet file: 
    
    :: Check if URL is empty
    if "%DOWNLOAD_URL%"=="" (
        echo Error: Download link cannot be empty!
        exit /b 1
    )
    
    :: Fix URL validation - use simpler method
    echo %DOWNLOAD_URL% | find "http" >nul
    if %errorLevel% neq 0 (
        echo Error: URL must contain http or https
        exit /b 1
    )
    
    :: Set temporary file name
    set "TEMP_FILE=%TEMP%\zerotier-planet-%TIMESTAMP%"
    
    :: --- Prefer curl/certutil before falling back to Powershell ---
    :: Method 1: use bundled curl (available on Win10/11)
    where curl >nul 2>&1
    if %errorLevel% equ 0 (
        echo Downloading via system curl...
        curl -L -o "%TEMP_FILE%" "%DOWNLOAD_URL%"
        if %errorLevel% neq 0 (
            echo Curl download failed, attempting Certutil...
            goto :try_certutil
        ) else (
            goto :verify_download
        )
    )

    :try_certutil
    :: Method 2: use certutil (built into all Windows)
    where certutil >nul 2>&1
    if %errorLevel% equ 0 (
        echo Downloading via Certutil...
        rem -urlcache -split -f is recommended for larger downloads
        certutil -urlcache -split -f "%DOWNLOAD_URL%" "%TEMP_FILE%" >nul
        if %errorLevel% neq 0 (
            echo Certutil download failed.
            del "%TEMP_FILE%" 2>nul
            exit /b 1
        )
    ) else (
        echo Error: System lacks curl and certutil, unable to download the file.
        exit /b 1
    )

    :verify_download
    :: Confirm the downloaded file is not empty
    for %%F in ("%TEMP_FILE%") do if %%~zF==0 (
        echo Error: Downloaded file is empty!
        del "%TEMP_FILE%" 2>nul
        exit /b 1
    )

    echo Download file completed.
    exit /b 0

:local_option
    :: Get local file path
    set /p LOCAL_FILE=Please enter the full path of the local Planet file: 
    
    if "%LOCAL_FILE%"=="" (
        echo Error: File path cannot be empty!
        exit /b 1
    )
    
    if not exist "%LOCAL_FILE%" (
        echo Error: File %LOCAL_FILE% does not exist!
        exit /b 1
    )
    
    :: Check if file is empty
    for %%F in ("%LOCAL_FILE%") do if %%~zF==0 (
        echo Error: File %LOCAL_FILE% is empty!
        exit /b 1
    )
    
    :: Copy to temporary file
    set "TEMP_FILE=%TEMP%\zerotier-planet-%TIMESTAMP%"
    echo Copying local file to temporary location...
    copy /y "%LOCAL_FILE%" "%TEMP_FILE%" >nul
    if %errorLevel% neq 0 (
        echo Cannot copy file!
        exit /b 1
    )
    
    echo Prepare local file completed.
    exit /b 0