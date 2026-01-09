@echo off
rem 这个文件应该保存为ANSI编码或GB2312编码

:: 设置变量
set "ZT_HOME=C:\ProgramData\ZeroTier\One"
set "DEST_FILE=%ZT_HOME%\planet"
:: 生成精确到分钟的时间戳 (格式: 年-月-日-时-分)
set "TIMESTAMP=%date:~0,4%-%date:~5,2%-%date:~8,2%-%time:~0,2%-%time:~3,2%"
:: 替换时间戳中可能的空格
set "TIMESTAMP=%TIMESTAMP: =0%"
set "BACKUP_FILE=%ZT_HOME%\planet.bak-%TIMESTAMP%"
set "TEMP_FILE="

:: 检查是否有管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 需要管理员权限来执行此操作。
    echo 请右键点击此脚本，选择"以管理员身份运行"。
    pause
    exit /b 1
)

:: 菜单选择
echo 请选择 Planet 文件来源:
echo 1. 从网络下载
echo 2. 使用本地文件
set /p SOURCE_OPTION=请输入选项 [1/2]: 

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
    echo 错误: 无效的选项!
    pause
    exit /b 1
)

:: 检查临时文件是否存在
if not exist "%TEMP_FILE%" (
    echo 错误: 操作前置步骤失败，未生成临时文件
    pause
    exit /b 1
)

:: 停止ZeroTierOneService服务
echo 正在停止ZeroTierOneService服务...
sc query ZeroTierOneService | findstr "RUNNING" > nul
if %errorLevel% equ 0 (
    sc stop ZeroTierOneService > nul
    timeout /t 3 > nul
) else (
    echo ZeroTierOneService服务已经停止或未在运行
)

:: 确认服务已停止
sc query ZeroTierOneService | findstr "STOPPED" > nul
if %errorLevel% neq 0 (
    echo 警告: 无法确认服务是否已停止，将尝试继续执行
)
echo 停止服务处理已完成。

:: 备份planet文件
if exist "%DEST_FILE%" (
    echo 正在备份原 Planet 文件到 %BACKUP_FILE% ...
    copy "%DEST_FILE%" "%BACKUP_FILE%" >nul 2>&1
    if %errorLevel% neq 0 (
        echo 备份文件失败，但将继续执行。
    ) else (
        echo 原始文件已成功备份。
    )
)

:: 替换planet文件前，先确保目标目录存在
if not exist "%ZT_HOME%" (
    echo 创建目标目录 %ZT_HOME%
    mkdir "%ZT_HOME%" 2>nul
)

:: 替换planet文件
echo 正在替换planet文件...
copy /y "%TEMP_FILE%" "%DEST_FILE%" >nul
if %errorLevel% neq 0 (
    echo 替换文件失败。
    pause
    exit /b 1
)
echo 替换文件已完成。

:: 删除临时文件
del "%TEMP_FILE%" >nul 2>&1

:: 启动ZeroTierOneService服务
echo 正在启动ZeroTierOneService服务...
sc start ZeroTierOneService >nul
if %errorLevel% neq 0 (
    echo 启动服务失败，请手动启动ZeroTierOneService服务。
) else (
    echo 服务已成功启动。
)

:: 完成
echo.
echo 所有操作已完成!
echo - 新 Planet 文件: %DEST_FILE%
if exist "%BACKUP_FILE%" echo - 备份文件: %BACKUP_FILE%
pause
exit /b 0

:download_option
    :: 获取用户输入的URL
    set /p DOWNLOAD_URL=请输入 Planet 文件的下载 URL: 
    
    :: 检查URL是否为空
    if "%DOWNLOAD_URL%"=="" (
        echo 错误: 下载链接不能为空!
        exit /b 1
    )
    
    :: 修复URL验证 - 使用更简单的方法
    echo %DOWNLOAD_URL% | find "http" >nul
    if %errorLevel% neq 0 (
        echo 错误: URL 必须包含 http 或 https
        exit /b 1
    )
    
    :: 设置临时文件名
    set "TEMP_FILE=%TEMP%\zerotier-planet-%TIMESTAMP%"
    
    :: --- 修改开始: 使用 curl 或 certutil 替代 powershell ---
    
    :: 方法1: 尝试使用 curl (Win10/11 自带)
    where curl >nul 2>&1
    if %errorLevel% equ 0 (
        echo 正在使用系统自带 Curl 下载...
        curl -L -o "%TEMP_FILE%" "%DOWNLOAD_URL%"
        if %errorLevel% neq 0 (
            echo Curl 下载失败，尝试使用 Certutil...
            goto :try_certutil
        ) else (
            goto :verify_download
        )
    )

    :try_certutil
    :: 方法2: 尝试使用 certutil (兼容旧版 Windows)
    where certutil >nul 2>&1
    if %errorLevel% equ 0 (
        echo 正在使用 Certutil 下载...
        rem -urlcache -split -f 是强制下载并覆盖
        certutil -urlcache -split -f "%DOWNLOAD_URL%" "%TEMP_FILE%" >nul
        if %errorLevel% neq 0 (
            echo Certutil 下载失败。
            del "%TEMP_FILE%" 2>nul
            exit /b 1
        )
    ) else (
        echo 错误: 系统未找到 curl 或 certutil 工具，无法下载。
        exit /b 1
    )
    
    :verify_download
    :: --- 修改结束 ---
    
    :: 检查文件是否为空
    for %%F in ("%TEMP_FILE%") do if %%~zF==0 (
        echo 错误: 下载的文件为空!
        del "%TEMP_FILE%" 2>nul
        exit /b 1
    )
    
    echo 下载文件已完成。
    exit /b 0

:local_option
    :: 获取本地文件路径
    set /p LOCAL_FILE=请输入本地 Planet 文件的完整路径: 
    
    if "%LOCAL_FILE%"=="" (
        echo 错误: 文件路径不能为空!
        exit /b 1
    )
    
    if not exist "%LOCAL_FILE%" (
        echo 错误: 文件 %LOCAL_FILE% 不存在!
        exit /b 1
    )
    
    :: 检查文件是否为空
    for %%F in ("%LOCAL_FILE%") do if %%~zF==0 (
        echo 错误: 文件 %LOCAL_FILE% 为空!
        exit /b 1
    )
    
    :: 复制到临时文件
    set "TEMP_FILE=%TEMP%\zerotier-planet-%TIMESTAMP%"
    echo 正在复制本地文件到临时位置...
    copy /y "%LOCAL_FILE%" "%TEMP_FILE%" >nul
    if %errorLevel% neq 0 (
        echo 无法复制文件!
        exit /b 1
    )
    
    echo 准备本地文件已完成。
    exit /b 0