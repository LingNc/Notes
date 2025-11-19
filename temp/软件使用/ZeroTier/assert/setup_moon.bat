@echo off
setlocal

:: 1. 检测管理员权限
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo 错误：此脚本必须以管理员权限运行。
    echo 请右键单击本 .bat 文件并选择 "以管理员身份运行"。
    pause
    exit /b
)

:: 定义 ZeroTier 目录 (Windows 默认路径)
set "ZT_HOME=C:\ProgramData\ZeroTier\One"
set "ZT_TOOL=%ZT_HOME%\zerotier-idtool.bat"

:: 检查 ZeroTier 目录是否存在
if not exist "%ZT_HOME%\identity.public" (
    echo 错误：在 %ZT_HOME% 中未找到 identity.public。
    echo 请确认 ZeroTier 已安装在此路径。
    pause
    exit /b
)

:: 2. 提示用户输入
set /p SERVER_IP="请输入您服务器的公共 IP 地址: "
set /p ZT_PORT="请输入 ZeroTier 的端口 (默认 9993): "

:: 如果端口为空，使用默认值
if "%ZT_PORT%"=="" set "ZT_PORT=9993"

echo --- 正在为 %SERVER_IP%:%ZT_PORT% 配置 Moon ---

cd /d "%ZT_HOME%"

:: 3. 运行 initmoon
echo 1. 正在生成 moon.json 配置文件...
"%ZT_TOOL%" initmoon identity.public > moon.json
if %errorLevel% NEQ 0 (
    echo 错误：zerotier-idtool initmoon 执行失败。
    pause
    exit /b
)

:: 4. 修改 moon.json (使用 PowerShell)
echo 2. 正在修改 moon.json, 添加 stableEndpoints...
powershell -NoProfile -Command "$jsonPath = '%ZT_HOME%\moon.json'; $config = Get-Content $jsonPath | ConvertFrom-Json; $config.stableEndpoints = @('%SERVER_IP%/%ZT_PORT%'); $config | ConvertTo-Json -Depth 100 | Set-Content $jsonPath"

:: 检查修改是否成功
findstr /C:"%SERVER_IP%" moon.json >nul
if %errorLevel% NEQ 0 (
    echo 错误：修改 moon.json 失败。请检查 PowerShell 是否可用。
    pause
    exit /b
)

:: 5. 运行 genmoon
echo 3. 正在生成 moon 签名文件...
"%ZT_TOOL%" genmoon moon.json
if %errorLevel% NEQ 0 (
    echo 错误：zerotier-idtool genmoon 执行失败。
    pause
    exit /b
)

:: 6. 创建 moons.d 并移动文件
set "MOONS_DIR=%ZT_HOME%\moons.d"
echo 4. 正在创建 %MOONS_DIR% 目录 (如果不存在)...
if not exist "%MOONS_DIR%" mkdir "%MOONS_DIR%"

echo 5. 正在移动 .moon 文件...
set "MOON_FILE_FOUND="
for %%f in (000000*.moon) do (
    echo 找到文件: %%f
    move "%%f" "%MOONS_DIR%\"
    set "MOON_FILE_FOUND=1"
)

if not defined MOON_FILE_FOUND (
    echo 错误：未找到生成的 .moon 文件。
    pause
    exit /b
)

:: 7. 重启服务
echo 6. 正在重启 ZeroTierOneService 服务...
net stop ZeroTierOneService
net start ZeroTierOneService

:: 提取 Moon ID
echo --- Moon 节点配置完成! ---
powershell -NoProfile -Command "$config = Get-Content '%ZT_HOME%\moon.json' | ConvertFrom-Json; $moonId = $config.id; Write-Host "您的 Moon ID 是: $moonId"; Write-Host "其他设备现在可以使用 'zerotier-cli orbit $moonId $moonId' 加入 moon.""

pause
endlocal