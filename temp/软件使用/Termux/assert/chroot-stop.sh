#!/data/data/com.termux/files/usr/bin/bash

# ================================================================= #
#                          Chroot 环境停止脚本                       #
# ================================================================= #

# 配置环境变量，在root情况下可以正常使用termux命令
export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:/system/bin:/system/xbin:/sbin:/sbin/bin:$PATH"

# --- 请在这里配置您的变量 ---

# 1. Chroot 根目录的完整路径
DEBIANPATH="/data/data/com.termux/files/home/debian-prootfs"
# 2. 您想默认登录的普通用户名
USERNAME="lingnc"
# 3. 终止程序的等待时间（秒）
GRACE_PERIOD=3
# 4. 强制终止前的确认等待时间（秒）
CONFIRM_TIMEOUT=15

# --------- 主程序逻辑 --------- #

echo ">>> 正在停止 Chroot Debian 环境..."

chroot_stop_func(){
    echo ">>> 正在退出 Chroot 并清理环境..."

    # 确保 lsof 已安装
    if ! command -v lsof &> /dev/null; then
        echo ">>> lsof 命令未找到，正在尝试安装..."
        pkg install lsof -y
    fi

    # 1. 终止 chroot 内的残留进程
    echo ">>> 步骤 1/4: 终止 Chroot 内的残留进程..."

    # --- 阶段1：优雅终止 (SIGTERM) ---
    PIDS=$(lsof -t "${DEBIANPATH}")
    if [ -z "$PIDS" ]; then
        echo "    - 未发现 Chroot 内有正在运行的进程。"
    else
        echo "    - 正在发送 TERM 信号 (15)，请求以下进程优雅退出："
        echo "$(echo "${PIDS}" | tr '\n' ' ')"
        echo "${PIDS}" | xargs -r kill -TERM

        echo "    - 等待 ${GRACE_PERIOD} 秒，让进程自行清理..."
        sleep ${GRACE_PERIOD}

        # --- 阶段2：交互式强制终止 (SIGKILL) ---
        STUBBORN_PIDS=$(lsof -t ${DEBIANPATH})
        if [ -z "$STUBBORN_PIDS" ]; then
            echo "    - 所有进程已成功退出。"
        else
            echo ""
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 警告 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "    - 以下顽固进程未能在优雅退出期间终止："

            # 使用 ps 命令显示进程的 PID 和名称，更直观
            ps -o pid,comm -p $(echo ${STUBBORN_PIDS} | tr '\n' ' ')

            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo ""

            # -p: 显示提示文字
            # -n 1: 只读取一个字符
            # -t ${CONFIRM_TIMEOUT}: 设置超时时间
            read -p "是否要强制终止这些进程 (Y/n)? (${CONFIRM_TIMEOUT}秒后自动继续): " -n 1 -t ${CONFIRM_TIMEOUT} REPLY

            # 如果用户没有输入 (超时) 或输入了回车，默认值为 'y'
            REPLY=${REPLY:-y}

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "" # 在提示后换行，保持格式整洁
                echo "    - 正在发送 KILL 信号 (9) 强制终止..."
                echo "${STUBBORN_PIDS}" | xargs -r kill -9
                sleep 1 # 等待内核处理
            else
                echo ""
                echo "    - 已取消强制终止。后续卸载操作很可能会失败。"
            fi
        fi
    fi

    # 2. 卸载文件系统
    echo ">>> 步骤 2/4: 清理挂载点..."
    # 依次卸载所有挂载的文件系统
    umount "${DEBIANPATH}/tmp" 2>/dev/null || true
    umount "${DEBIANPATH}/dev/shm" 2>/dev/null || true
    umount "${DEBIANPATH}/dev/pts" 2>/dev/null || true
    umount "${DEBIANPATH}/sys" 2>/dev/null || true
    umount "${DEBIANPATH}/proc" 2>/dev/null || true
    umount "${DEBIANPATH}/dev" 2>/dev/null || true

    # 3. 检查卸载状态
    echo ">>> 步骤 3/4: 检查挂载点状态..."
    if mount | grep -q "$DEBIANPATH"; then
        echo ""
        echo "[警告] 仍有挂载点卸载失败！"
        mount | grep "$DEBIANPATH"
    else
        echo "    - 所有挂载点已成功清理。"
    fi
}

# 使用 su -c 以 root 权限运行清理函数
su -c "exec /data/data/com.termux/files/usr/bin/bash" << EOF
export DEBIANPATH='$DEBIANPATH'
export USERNAME='$USERNAME'
export GRACE_PERIOD='$GRACE_PERIOD'
export CONFIRM_TIMEOUT='$CONFIRM_TIMEOUT'
export PATH='$PATH'

$(declare -f chroot_stop_func)

chroot_stop_func
EOF

# 4. 终止Termux的服务进程
echo ">>> 步骤 4/4: 终止 Termux 侧服务进程..."
echo "    - 正在终止 Termux X11 服务..."
pkill -TERM app_process 2>/dev/null || true
echo "    - 正在终止 pulseaudio 服务..."
pkill -TERM pulseaudio 2>/dev/null || true

echo ">>> Chroot 环境停止完成。"
