#!/bin/bash

# 配置文件路径
CONFIG_DIR="$HOME/.config/clash"
CONFIG_FILE="$CONFIG_DIR/.clash-ctl.conf"

# 脚本自身路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# 初始化配置目录和文件
init_config() {
    # 创建配置目录（如果不存在）
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "创建配置目录: $CONFIG_DIR"
    fi

    # 初始化配置文件（如果不存在）
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "CLASH_API=http://127.0.0.1:9090" > "$CONFIG_FILE"
        echo "初始化配置文件: $CONFIG_FILE"
    fi

    # 加载配置
    source "$CONFIG_FILE"
}

# 安装脚本到系统路径
install_script() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "安装需要root权限，请使用sudo运行"
        exit 1
    fi

    local target_path="/usr/local/bin/clash-ctl"

    if [ -f "$target_path" ]; then
        echo "检测到已安装的版本，正在更新..."
        rm -f "$target_path"
    fi

    ln -s "$SCRIPT_PATH" "$target_path"
    chmod +x "$SCRIPT_PATH"

    echo "已安装到系统路径: $target_path"
    echo "现在可以在任意位置使用 'clash-ctl' 命令"
}

# 设置控制器地址
set_api() {
    local api_url=$1
    if [[ ! "$api_url" =~ ^http:// ]]; then
        api_url="http://$api_url"
    fi

    # 确保配置目录存在
    mkdir -p "$CONFIG_DIR"

    echo "CLASH_API=$api_url" > "$CONFIG_FILE"
    echo "控制器地址已设置为: $api_url"
    echo "配置文件保存在: $CONFIG_FILE"
}

# 显示所有代理组
show_groups() {
    response=$(curl -sX GET "$CLASH_API/proxies")
    if [ $? -ne 0 ]; then
        echo "错误：无法连接Clash API！请检查地址和Clash是否运行。"
        exit 1
    fi

    echo "可用代理组:"
    echo "$response" | jq -r '.proxies | to_entries[] | select(.value.type == "Selector") | .key'
}

# 显示组内节点
show_nodes() {
    local group=$1
    response=$(curl -sX GET "$CLASH_API/proxies/$group")
    if [ $? -ne 0 ]; then
        echo "错误：无法获取代理组信息！"
        exit 1
    fi

    echo "组 '$group' 的节点:"
    echo "$response" | jq -r '.all[]'
}

# 切换代理节点
switch_node() {
    local group=$1
    local node=$2

    curl -sX PUT "$CLASH_API/proxies/$group" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$node\"}" >/dev/null

    if [ $? -eq 0 ]; then
        echo "已切换组 '$group' 到节点 '$node'"
    else
        echo "切换失败！"
    fi
}

# 检查依赖
check_deps() {
    if ! command -v curl &> /dev/null; then
        echo "错误：请先安装 curl"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo "错误：请先安装 jq (JSON解析工具)"
        exit 1
    fi
}

# 显示帮助
show_help() {
    echo "Clash 代理控制器 (v1.2)"
    echo "配置文件: $CONFIG_FILE"
    echo ""
    echo "用法:"
    echo "  sudo clash-ctl install         安装脚本到系统路径"
    echo "  clash-ctl set <控制器地址>     设置控制器地址"
    echo "  clash-ctl groups              列出所有代理组"
    echo "  clash-ctl nodes <组名>        列出组内节点"
    echo "  clash-ctl switch <组名> <节点> 切换代理节点"
    echo "  clash-ctl help                显示帮助信息"
}

# 主流程
check_deps

case $1 in
    install)
        install_script
        ;;
    set)
        init_config
        if [ -z "$2" ]; then
            echo "错误：请提供控制器地址"
            exit 1
        fi
        set_api "$2"
        ;;
    groups)
        init_config
        show_groups
        ;;
    nodes)
        init_config
        if [ -z "$2" ]; then
            echo "错误：请提供代理组名称"
            exit 1
        fi
        show_nodes "$2"
        ;;
    switch)
        init_config
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "错误：请提供代理组和节点名称"
            exit 1
        fi
        switch_node "$2" "$3"
        ;;
    help|*)
        show_help
        ;;
esac