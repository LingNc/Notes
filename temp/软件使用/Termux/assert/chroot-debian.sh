#!/data/data/com.termux/files/usr/bin/bash

# ================================================================= #
#                   Debian Chroot 环境启动脚本 (精简版)              #
#                                                                   #
#       本脚本使用 'env -i' 来确保一个完全干净的环境变量。             #
# ================================================================= #

# --- 请在这里配置您的变量 ---

# 1. Chroot 根目录的完整路径
DEBIANPATH="/data/data/com.termux/files/home/debian-rootfs"

# 2. 您想默认登录的普通用户名
USERNAME="user"

# --------------------------- 脚本主体 ---------------------------- #

# 函数：执行挂载操作
mount_filesystems() {
    echo ">>> 步骤 1/4: 准备挂载模式..."
    mount -o rw,remount,dev,suid /data
    echo "    [/data] 已重新挂载为读写模式，并启用 suid。"

    echo ">>> 步骤 2/4: 挂载所有必要的 API 和目录..."
    # 挂载驱动器
    mount --bind /dev "${DEBIANPATH}/dev"
    # 挂载其他必要的文件系统
    mount -t devpts devpts "${DEBIANPATH}/dev/pts"
    mount -t proc proc "${DEBIANPATH}/proc"
    mount -t sysfs sysfs "${DEBIANPATH}/sys"
    # 创建一个共享内存空间指定大小，有很多程序要使用，如Electron APPS需要/dev/shm
    # 确保目录存在
    if [ ! -d "${DEBIANPATH}/dev/shm" ]; then
        mkdir -p "${DEBIANPATH}/dev/shm"
    fi
    mount -t tmpfs -o size=1G tmpfs "${DEBIANPATH}/dev/shm"
    echo "    API 文件系统已挂载。"
}

# 函数：执行卸载操作
umount_filesystems() {
    echo ">>> 步骤 4/4: 退出 Chroot，正在清理挂载点..."
    umount "${DEBIANPATH}/dev/shm" 2>/dev/null
    umount "${DEBIANPATH}/dev/pts" 2>/dev/null
    umount "${DEBIANPATH}/sys" 2>/dev/null
    umount "${DEBIANPATH}/proc" 2>/dev/null
    umount "${DEBIANPATH}/dev" 2>/dev/null
    # 检测清理是否干净
    mount | grep "$DEBIANPATH"
    if [ $? -eq 0 ]; then
        echo "    [警告] 仍有挂载点未成功卸载，请手动检查并卸载。"
    else
        echo "    清理完成。"
    fi
}

# --------- 主程序逻辑 --------- #

if [ ! -d "$DEBIANPATH" ]; then
    echo "[错误] Debian 根目录不存在: $DEBIANPATH"
    exit 1
fi

if [ "$(id -u)" != "0" ]; then
    echo "[错误] 此脚本需要 root 权限才能运行。请使用 'su -c ./start-debian.sh' 来执行。"
    exit 1
fi

# 挂载必要的文件系统
mount_filesystems

echo ">>> 步骤 3/4: 进入 Debian Chroot 环境 (使用 env -i 纯净模式)..."
echo "    - 登录用户: ${USERNAME}"
echo "    - 输入 'exit' 命令即可退出并自动清理环境。"
echo ""

env -i TERM="xterm-256color" chroot $DEBIANPATH /bin/su - "${USERNAME}" --login

# 退出后清理挂载点
umount_filesystems