#!/bin/bash

# 替换 ZeroTier Planet 文件的自动化脚本 (macOS 版本)
#
# 官方文档参考: https://docs.zerotier.com/config/
# macOS 工作目录: /Library/Application Support/ZeroTier/One
#
# 使用方法: sudo bash planet_update_mac.sh

# 1. 检测是否以 root 身份运行
if [ "$(id -u)" != "0" ]; then
    echo "错误：必须使用 root 权限运行此脚本！"
    echo "请尝试使用 'sudo $0'"
    exit 1
fi

# 2. 检查并安装下载工具 (优先使用 curl)
check_tools() {
    if command -v curl &> /dev/null; then
        DOWNLOAD_CMD="curl -s -o"
    elif command -v wget &> /dev/null; then
        DOWNLOAD_CMD="wget -q -O"
    else
        echo "未找到 curl 或 wget。"
        echo "macOS 通常自带 curl。如需安装 wget，请运行: brew install wget"
        echo "或者先安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
}

# 3. 获取用户选择：下载或使用本地文件
get_source() {
    echo "请选择 Planet 文件来源："
    echo "1. 从网络下载"
    echo "2. 使用本地文件"
    read -p "请输入选项 [1/2]: " SOURCE_OPTION

    case $SOURCE_OPTION in
        1)
            SOURCE_TYPE="download"
            get_url
            ;;
        2)
            SOURCE_TYPE="local"
            get_local_file
            ;;
        *)
            echo "错误：无效的选项！"
            exit 1
            ;;
    esac
}

# 3a. 获取用户输入的下载链接
get_url() {
    read -p "请输入 Planet 文件的下载 URL: " DOWNLOAD_URL
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "错误：下载链接不能为空！"
        exit 1
    fi

    # 简单验证 URL 格式
    if [[ ! $DOWNLOAD_URL =~ ^https?:// ]]; then
        echo "错误：URL 必须以 http:// 或 https:// 开头"
        exit 1
    fi
}

# 3b. 获取本地文件路径
get_local_file() {
    read -p "请输入本地 Planet 文件的完整路径: " LOCAL_FILE

    if [ -z "$LOCAL_FILE" ]; then
        echo "错误：文件路径不能为空！"
        exit 1
    fi

    # 处理 macOS 路径中的空格
    LOCAL_FILE="${LOCAL_FILE/#\~/$HOME}"

    if [ ! -f "$LOCAL_FILE" ]; then
        echo "错误：文件 $LOCAL_FILE 不存在！"
        exit 1
    fi

    if [ ! -s "$LOCAL_FILE" ]; then
        echo "错误：文件 $LOCAL_FILE 为空！"
        exit 1
    fi
}

# 4. 生成带日期戳的文件名 (精确到分钟)
generate_filename() {
    # 格式: 年-月-日-时-分 (macOS date 命令兼容)
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M)
    FILENAME="/tmp/zerotier-planet-${TIMESTAMP}"
}

# 5. 下载文件或复制本地文件
prepare_file() {
    generate_filename

    if [ "$SOURCE_TYPE" = "download" ]; then
        echo "正在下载 Planet 文件到 ${FILENAME} ..."
        $DOWNLOAD_CMD "$FILENAME" "$DOWNLOAD_URL"

        if [ ! -f "$FILENAME" ]; then
            echo "错误：文件下载失败！请检查 URL 和网络连接。"
            exit 1
        fi

        # 检查文件是否非空
        if [ ! -s "$FILENAME" ]; then
            echo "错误：下载的文件为空！"
            exit 1
        fi
    else
        echo "正在复制本地文件到 ${FILENAME} ..."
        cp "$LOCAL_FILE" "$FILENAME"

        if [ $? -ne 0 ]; then
            echo "错误：无法复制文件！"
            exit 1
        fi
    fi
}

# 6. 停止 ZeroTier 服务 (macOS 使用 launchctl)
stop_zerotier() {
    echo "正在停止 ZeroTier 服务..."

    # macOS 使用 launchctl 管理服务
    # ZeroTier 在 macOS 上的服务 plist 文件
    ZT_PLIST="/Library/LaunchDaemons/com.zerotier.one.plist"

    if [ -f "$ZT_PLIST" ]; then
        launchctl unload "$ZT_PLIST" 2>/dev/null
    else
        echo "警告：未找到 ZeroTier 服务配置文件，尝试直接终止进程..."
    fi

    # 等待服务完全停止
    sleep 2

    # 检查进程是否仍在运行
    if pgrep -x "zerotier-one" > /dev/null; then
        echo "警告：无法停止 ZeroTier 服务，正在强制终止进程..."
        pkill -9 zerotier-one
        sleep 1
    fi
}

# 7. 备份并替换 Planet 文件
replace_file() {
    # macOS 上 ZeroTier 的配置目录
    ZT_HOME="/Library/Application Support/ZeroTier/One"
    BACKUP_FILE="${ZT_HOME}/planet.bak-${TIMESTAMP}"

    # 检查ZeroTier目录是否存在
    if [ ! -d "$ZT_HOME" ]; then
        echo "错误：ZeroTier 目录 $ZT_HOME 不存在！"
        echo "请确认已安装 ZeroTier: https://www.zerotier.com/download/"
        exit 1
    fi

    # 检查原始planet文件是否存在
    if [ ! -f "${ZT_HOME}/planet" ]; then
        echo "警告：原始 Planet 文件不存在，将直接创建新文件..."
    else
        echo "正在备份原 Planet 文件到 $BACKUP_FILE ..."
        cp "${ZT_HOME}/planet" "$BACKUP_FILE"
    fi

    echo "正在替换 Planet 文件..."
    mv -f "$FILENAME" "${ZT_HOME}/planet"

    # macOS 上 ZeroTier 通常以 root 运行，设置适当的权限
    chmod 644 "${ZT_HOME}/planet"
    chown root:admin "${ZT_HOME}/planet" 2>/dev/null || chown root:wheel "${ZT_HOME}/planet" 2>/dev/null || true
}

# 8. 重启服务 (macOS 使用 launchctl)
restart_service() {
    echo "正在启动 ZeroTier 服务..."

    ZT_PLIST="/Library/LaunchDaemons/com.zerotier.one.plist"

    # 使用 launchctl 加载服务
    if [ -f "$ZT_PLIST" ]; then
        launchctl load "$ZT_PLIST" 2>/dev/null
    else
        echo "错误：未找到 ZeroTier 服务配置文件 $ZT_PLIST"
        echo "请确认 ZeroTier 已正确安装"
        exit 1
    fi

    # 等待服务启动
    sleep 2

    # 检查服务状态
    if pgrep -x "zerotier-one" > /dev/null; then
        echo "✅ 操作成功完成！"
        echo "   - 新 Planet 文件: ${ZT_HOME}/planet"
        echo "   - 备份文件: $BACKUP_FILE"
        echo ""
        echo "提示: 你可以使用以下命令检查 ZeroTier 状态:"
        echo "   zerotier-cli status"
        echo "   zerotier-cli listpeers"
        echo ""
        echo "参考文档: https://docs.zerotier.com/config/"
    else
        echo "警告：启动 ZeroTier 服务失败，请手动检查！"
        echo "尝试手动启动: sudo launchctl load $ZT_PLIST"
        exit 1
    fi
}

# 主执行流程
main() {
    echo "========================================"
    echo "ZeroTier Planet 更新工具 (macOS 版本)"
    echo "========================================"
    echo ""

    check_tools
    get_source
    prepare_file
    stop_zerotier
    replace_file
    restart_service
}

main
