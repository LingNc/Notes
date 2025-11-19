#!/bin/bash

# 1. 检测 sudo 权限
if [ "$(id -u)" -ne 0 ]; then
  echo "错误：此脚本必须以 root (sudo) 权限运行。"
  echo "请尝试使用: sudo ./setup_moon.sh"
  exit 1
fi

# 定义 ZeroTier 目录
ZT_HOME="/var/lib/zerotier-one"

# 检查 ZT 目录是否存在
if [ ! -d "$ZT_HOME" ]; then
    echo "错误：未找到 ZeroTier 目录 $ZT_HOME"
    echo "请确认 ZeroTier 已正确安装。"
    exit 1
fi

# 2. 提示用户输入
read -p "请输入您服务器的公共 IP 地址: " SERVER_IP
read -p "请输入 ZeroTier 的端口 (默认 9993): " ZT_PORT

# 如果端口为空，使用默认值
: ${ZT_PORT:="9993"}

echo "--- 正在为 $SERVER_IP:$ZT_PORT 配置 Moon ---"

# 3. 运行 initmoon
echo "1. 正在生成 moon.json 配置文件..."
cd "$ZT_HOME" || exit

zerotier-idtool initmoon identity.public > moon.json
if [ $? -ne 0 ]; then
    echo "错误：zerotier-idtool initmoon 执行失败。"
    exit 1
fi

# 4. 修改 moon.json
echo "2. 正在修改 moon.json, 添加 stableEndpoints..."
# 使用 sed 替换 stableEndpoints。
# 这条命令查找 "stableEndpoints": [] (允许[]中有空格) 并替换它。
sed -i "s/\"stableEndpoints\": \[\s*\]/\"stableEndpoints\": \[\"$SERVER_IP\/$ZT_PORT\"\]/" moon.json

# 检查替换是否成功
if ! grep -q "$SERVER_IP" moon.json; then
     echo "错误：sed 替换 stableEndpoints 失败。请检查 moon.json 格式。"
     exit 1
fi

# 5. 运行 genmoon
echo "3. 正在生成 moon 签名文件..."
zerotier-idtool genmoon moon.json
if [ $? -ne 0 ]; then
    echo "错误：zerotier-idtool genmoon 执行失败。"
    exit 1
fi

# 6. 创建 moons.d 并移动文件
MOONS_DIR="$ZT_HOME/moons.d"
echo "4. 正在创建 $MOONS_DIR 目录 (如果不存在)..."
mkdir -p "$MOONS_DIR"

# 查找生成的 .moon 文件 (文件名以 000000 开头)
MOON_FILE=$(find . -maxdepth 1 -name '000000*.moon')

if [ -z "$MOON_FILE" ]; then
    echo "错误：未找到生成的 .moon 文件。"
    exit 1
fi

echo "5. 正在将 $MOON_FILE 移动到 $MOONS_DIR ..."
mv "$MOON_FILE" "$MOONS_DIR/"

# 7. 重启服务
echo "6. 正在重启 zerotier-one 服务..."
if command -v systemctl > /dev/null; then
    systemctl restart zerotier-one
elif command -v service > /dev/null; then
    service zerotier-one restart
else
    echo "警告：无法自动重启服务。请手动运行 'sudo systemctl restart zerotier-one' 或 'sudo service zerotier-one restart'。"
fi

# 提取 Moon ID
MOON_ID=$(grep '"id"' moon.json | awk -F'"' '{print $4}')

echo "--- Moon 节点配置完成! ---"
echo "您的 Moon ID 是: $MOON_ID"
echo "其他设备现在可以使用 'zerotier-cli orbit $MOON_ID $MOON_ID' 加入 moon。"