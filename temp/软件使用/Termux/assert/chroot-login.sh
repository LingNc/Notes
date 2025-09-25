#!/data/data/com.termux/files/usr/bin/bash

# ================================================================= #
#                   Debian Chroot 环境启动脚本 (精简版)              #
#                                                                   #
#       本脚本使用 'env -i' 来确保一个完全干净的环境变量。             #
# ================================================================= #

export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:/system/bin:/system/xbin:/sbin:/sbin/bin:$PATH"

# --- 请在这里配置您的变量 ---

# 1. Chroot 根目录的完整路径
DEBIANPATH="/data/data/com.termux/files/home/debian-rootfs"

# 2. 您想默认登录的普通用户名
USERNAME="user"

# --------------------------- 脚本主体 ---------------------------- #

# 函数：执行挂载操作
mount_filesystems() {
    echo ">>> 步骤 1/4: 准备挂载模式..."
    mount -o remount,dev,suid /data
    echo "    [/data] 已重新挂载，并启用 suid。"

    echo ">>> 步骤 2/4: 挂载所有必要的 API 和目录..."
    # 挂载驱动器
    mount --bind /dev "${DEBIANPATH}/dev"
    # 挂载其他必要的文件系统
    mount -t devpts devpts "${DEBIANPATH}/dev/pts"
    #mount -t proc proc "${DEBIANPATH}/proc"
    mount -t proc  proc "${DEBIANPATH}/proc"
    mount -t sysfs sysfs "${DEBIANPATH}/sys"
    # 创建一个共享内存空间指定大小，有很多程序要使用，如Electron APPS需要/dev/shm
    # 确保目录存在
    mkdir -p "${DEBIANPATH}/dev/shm"
    mount -t tmpfs -o size=1G tmpfs "${DEBIANPATH}/dev/shm"
    # 不必挂载Termux的tmp目录
    mkdir -p "${DEBIANPATH}/tmp"
    # mount --bind /data/data/com.termux/files/usr/tmp "${DEBIANPATH}/tmp"
    # 确保tmp目录权限正确
    chmod 1777 "${DEBIANPATH}/tmp"
    # 只读挂载 /system 使用一些原生的安卓指令
    # mkdir -p "${DEBIANPATH}/system"
    # mount -o bind,ro /system "${DEBIANPATH}/system"
    # mkdir -p "${DEBIANPATH}/apex"
    # mount -o bind,ro /apex "${DEBIANPATH}/apex"
    echo "    API 文件系统已挂载。"
}

# 函数：执行卸载操作
umount_filesystems() {
    echo ">>> 步骤 4/4: 退出 Chroot，正在清理挂载点..."
    # 依次卸载所有挂载的文件系统
    # umount "${DEBIANPATH}/apex"
    # umount "${DEBIANPATH}/system"
    # umount "${DEBIANPATH}/tmp"
    umount "${DEBIANPATH}/dev/shm"
    umount "${DEBIANPATH}/dev/pts"
    umount "${DEBIANPATH}/sys"
    umount "${DEBIANPATH}/proc"
    umount "${DEBIANPATH}/dev"
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

# 1. 清空当前参数列表
set --

# 2. 像搭积木一样，一步步添加 unshare 和 chroot 的参数
#set -- "$@" --mount
#set -- "$@" -R "$DEBIANPATH"
#set -- "$@" -m --propagation=private

# 3. 添加 env -i 和所有需要的环境变量
# 使用 env -i 以干净的环境变量进入 chroot
set -- "$@" env -i
# 设置终端类型为支持256色的xterm
set -- "$@" TERM="xterm-256color"
# 设置PATH环境变量，包含常用的系统路径
#set -- "$@" PATH=$PATH
# 设置临时目录
#set -- "$@" TMPDIR="/tmp"

set -- "$@" chroot "$DEBIANPATH" /bin/su - "${USERNAME}" --login

# echo "${@}"
# 5. 最终执行构建好的完整命令
 "${@}"

# 退出后清理挂载点
umount_filesystems
