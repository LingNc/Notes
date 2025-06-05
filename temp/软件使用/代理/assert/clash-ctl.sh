#!/bin/bash

# 配置文件路径（始终使用用户目录）
CONFIG_DIR="$HOME/.config/clash"
CONFIG_FILE="$CONFIG_DIR/.clash-ctl.conf"

# 系统安装路径
SYSTEM_BIN_PATH="/usr/local/bin/clash-ctl"

# 脚本自身路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# 初始化配置目录和文件
init_config() {
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "CLASH_API=http://127.0.0.1:9090" > "$CONFIG_FILE"
        echo "初始化配置文件: $CONFIG_FILE"
    fi
    source "$CONFIG_FILE"
}

# 安装依赖
install_deps() {
    local pkg_manager=""
    local install_cmd=""

    if command -v apt-get &> /dev/null; then
        pkg_manager="apt-get"
        install_cmd="sudo apt-get install -y"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
        install_cmd="sudo yum install -y"
    elif command -v dnf &> /dev/null; then
        pkg_manager="dnf"
        install_cmd="sudo dnf install -y"
    elif command -v pacman &> /dev/null; then
        pkg_manager="pacman"
        install_cmd="sudo pacman -Sy --noconfirm"
    else
        echo "错误：无法识别的包管理器！请手动安装依赖：curl jq"
        exit 1
    fi

    echo "检测到包管理器: $pkg_manager"
    echo "正在安装依赖: curl jq"

    if ! $install_cmd curl jq; then
        echo "依赖安装失败！请手动运行: $install_cmd curl jq"
        exit 1
    fi
}

# 检查依赖
check_deps() {
    local missing=()

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "缺少依赖: ${missing[*]}"
        read -p "是否自动安装依赖？[Y/n] " confirm
        if [[ ! $confirm =~ ^[Nn] ]]; then
            install_deps
        else
            echo "请手动安装依赖后重试"
            exit 1
        fi
    fi
}

# 安装脚本
install_script() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "安装需要root权限，请使用sudo运行"
        exit 1
    fi

    check_deps

    if [ -f "$SYSTEM_BIN_PATH" ]; then
        echo "检测到已安装的版本，正在更新..."
        rm -f "$SYSTEM_BIN_PATH"
    fi

    ln -s "$SCRIPT_PATH" "$SYSTEM_BIN_PATH"
    chmod +x "$SCRIPT_PATH"

    echo "已安装到系统路径: $SYSTEM_BIN_PATH"
    echo "现在可以在任意位置使用 'clash-ctl' 命令"
}

# 卸载脚本（修复sudo下配置文件路径问题）
uninstall_script() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "卸载需要root权限，请使用sudo运行"
        exit 1
    fi

    # 移除系统链接
    if [ -f "$SYSTEM_BIN_PATH" ] || [ -L "$SYSTEM_BIN_PATH" ]; then
        rm -f "$SYSTEM_BIN_PATH"
        echo "已移除系统链接: $SYSTEM_BIN_PATH"
    else
        echo "未找到系统安装的clash-ctl"
    fi

    # 获取实际用户的家目录（即使使用sudo）
    local user_home=$(eval echo ~$(logname))
    local user_config_dir="$user_home/.config/clash"
    local user_config_file="$user_config_dir/.clash-ctl.conf"

    # 删除用户配置文件（不使用sudo权限）
    if [ -f "$user_config_file" ]; then
        read -p "是否要删除配置文件 $user_config_file？[y/N] " confirm
        if [[ $confirm =~ ^[Yy] ]]; then
            rm -f "$user_config_file"
            echo "已删除配置文件: $user_config_file"

            # 如果配置目录为空，也删除目录
            if [ -d "$user_config_dir" ] && [ -z "$(ls -A "$user_config_dir")" ]; then
                rmdir "$user_config_dir"
                echo "已删除空配置目录: $user_config_dir"
            fi
        else
            echo "保留配置文件: $user_config_file"
        fi
    else
        echo "未找到配置文件: $user_config_file"
    fi

    echo "卸载完成"
}

# 设置控制器地址
set_api() {
    local api_url=$1
    if [[ ! "$api_url" =~ ^http:// ]]; then
        api_url="http://$api_url"
    fi

    mkdir -p "$CONFIG_DIR"
    echo "CLASH_API=$api_url" > "$CONFIG_FILE"
    echo "控制器地址已设置为: $api_url"
    echo "配置文件保存在: $CONFIG_FILE"
}

# 显示所有代理组和当前选择
show_groups() {
    response=$(curl -sX GET "$CLASH_API/proxies")
    if [ $? -ne 0 ]; then
        echo "错误：无法连接Clash API！请检查地址和Clash是否运行。"
        exit 1
    fi

    echo "=== 当前代理组和选择 ==="
    echo "$response" | jq -r '.proxies | to_entries[] | select(.value.type == "Selector") | "\(.key) \t当前选择: \(.value.now)"' | column -t -s $'\t'
}

# 显示组内节点和当前选择
show_nodes() {
    local group=$1
    response=$(curl -sX GET "$CLASH_API/proxies/$group")
    if [ $? -ne 0 ]; then
        echo "错误：无法获取代理组信息！"
        exit 1
    fi

    current=$(echo "$response" | jq -r '.now')
    echo "=== 组 '$group' 的节点 ==="
    echo "当前选择: $current"
    echo "所有节点:"
    echo "$response" | jq -r '.all[]' | while read -r node; do
        if [ "$node" == "$current" ]; then
            echo "  ✓ $node"
        else
            echo "  $node"
        fi
    done
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

# 显示当前所有选择的节点
show_current() {
    response=$(curl -sX GET "$CLASH_API/proxies")
    if [ $? -ne 0 ]; then
        echo "错误：无法连接Clash API！"
        exit 1
    fi

    echo "=== 当前选择的节点 ==="
    echo "$response" | jq -r '.proxies | to_entries[] | select(.value.type == "Selector") | "\(.key)\t\(.value.now)"' | while IFS=$'\t' read -r group node; do
        echo "  $group: $node"
    done
}

# 显示帮助
show_help() {
    echo "Clash 代理控制器 (v1.6)"
    echo "配置文件: $CONFIG_FILE"
    echo "系统路径: $SYSTEM_BIN_PATH"
    echo ""
    echo "用法:"
    echo "  sudo clash-ctl install         安装脚本到系统路径"
    echo "  sudo clash-ctl uninstall       卸载脚本并删除配置文件"
    echo "  clash-ctl set <控制器地址>     设置控制器地址"
    echo "  clash-ctl groups              列出所有代理组和当前选择"
    echo "  clash-ctl nodes <组名>        列出组内节点和当前选择"
    echo "  clash-ctl current            显示所有代理组的当前选择"
    echo "  clash-ctl switch <组名> <节点> 切换代理节点"
    echo "  clash-ctl help                显示帮助信息"
}

# 主流程
case $1 in
    install)
        install_script
        ;;
    uninstall)
        uninstall_script
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
        check_deps
        show_groups
        ;;
    nodes)
        init_config
        check_deps
        if [ -z "$2" ]; then
            echo "错误：请提供代理组名称"
            exit 1
        fi
        show_nodes "$2"
        ;;
    current)
        init_config
        check_deps
        show_current
        ;;
    switch)
        init_config
        check_deps
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