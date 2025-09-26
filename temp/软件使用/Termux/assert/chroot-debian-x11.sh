#!/data/data/com.termux/files/usr/bin/bash

# ================================================================= #
#                          Chroot 环境启动脚本                       #
# ================================================================= #

# 配置环境变量，在root情况下可以正常使用termux命令
export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:/system/bin:/system/xbin:/sbin:/sbin/bin:$PATH"

# --- 请在这里配置您的变量 ---

# 1. Chroot 根目录的完整路径
DEBIANPATH="$HOME/debian-rootfs"
# 2. 您想默认登录的普通用户名
USERNAME="user"
# 3. 终止程序的等待时间（秒）
GRACE_PERIOD=3
# 4. 强制终止前的确认等待时间（秒）
CONFIRM_TIMEOUT=15

# --------- 主程序逻辑 --------- #

echo ">>> 正在启动 Chroot Debian X11 环境..."
# 1. 必要性检查
if [ ! -d "$DEBIANPATH" ]; then
    echo "[错误] Debian 根目录不存在: $DEBIANPATH"
    exit 1
fi
# 获取 chroot 内部用户的 UID 和 GID
CHROOT_UID=$(su -c chroot "$DEBIANPATH" /usr/bin/id -u "$USERNAME")

echo ">>> 步骤 1/5: 必要性检查成功。"

# 2. 清理旧termux进程
echo ">>> 步骤 2/5: 清理旧的 Termux 进程..."
# 因为这个termux x11在进程中是app_process运行的，没办法直接指定termux-x11或者使用一些方法筛选和捕获这个pid也是可以的
su -c killall -9 termux-x11 pulseaudio

# 3. 启动Termux侧进程
echo ">>> 步骤 3/5: 启动 Termux 侧必要进程..."
echo "    - 启动 X11 服务..."
# 启动termux-x11
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
# Also you must set XKB_CONFIG_ROOT environment variable pointing to container's /usr/share/X11/xkb directory,
# otherwise you will have xkbcomp-related errors.
export XKB_CONFIG_ROOT=$DEBIANPATH/usr/share/X11/xkb
su -c setenforce 0
export TMPDIR=$DEBIANPATH/tmp
export XDG_RUNTIME_DIR=$DEBIANPATH/run/user/$CHROOT_UID
export CLASSPATH=$(/system/bin/pm path com.termux.x11 | cut -d: -f2)
su -c /system/bin/app_process / --nice-name=termux-x11 com.termux.x11.CmdEntryPoint :1 &

sleep 3 # 等待X服务器启动
echo "    - 启动 pulseaudio 音频服务..."
su -c pulseaudio --start --exit-idle-time=-1
su -c pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

chroot_func(){
    # 必要性检查
    if [ "$(id -u)" != "0" ]; then
        echo "[错误] 此函数必须以 root 权限运行。请使用 'su -c $0'。"
        exit 1
    fi

    # 4. 挂载必要的文件系统
    echo ">>> 步骤 4/5: 准备挂载模式..."
    mount -o remount,dev,suid /data
    echo "    [/data] 已重新挂载，并启用 suid。"

    echo "    - 挂载所有必要的 API 和目录..."
    # 挂载驱动器
    mount --bind /dev "${DEBIANPATH}/dev"
    # 挂载其他必要的文件系统
    mount -t devpts devpts "${DEBIANPATH}/dev/pts"
    mount -t proc proc "${DEBIANPATH}/proc"
    mount -t sysfs sysfs "${DEBIANPATH}/sys"
    # 创建一个共享内存空间指定大小，有很多程序要使用，如Electron APPS需要/dev/shm
    mkdir -p "${DEBIANPATH}/dev/shm"
    mount -t tmpfs -o size=1G tmpfs "${DEBIANPATH}/dev/shm"
    # 不需要挂载Termux的tmp目录
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

    # 5. 进入 Chroot 环境
    echo ">>> 步骤 5/5: 进入 Debian Chroot 环境 (使用 env -i 纯净模式)..."
    echo "    - 登录用户: ${USERNAME}"
    echo "    - 退出即可自动清理环境。"
    echo ""

    # 使用 env -i 以干净的环境变量进入 chroot
    # 设置终端类型为支持256色的xterm
    env -i \
        TERM="xterm-256color" \
        chroot "$DEBIANPATH" /bin/su - "${USERNAME}" --login -c "
            export TERM='xterm-256color'
            # --- 进入chroot后的命令 ---
            # 设置PATH环境变量，包含常用的系统路径
            export PATH='/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games'
            # 设置临时目录
            export TMPDIR='/tmp'
            # 设置显示变量
            export DISPLAY=':1'
            # 设置PulseAudio服务器地址
            export PULSE_SERVER='tcp:127.0.0.1:4713'
            export LD_LIBRARY_PATH='/usr/lib/aarch64-linux-gnu/'
            export VK_DRIVER_FILES='/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json'
            export OCL_ICD_VENDORS='/usr/local/etc/OpenCL/vendors/mesa.icd'
            # MESA_VK_WSI_PRESENT_MODE=mailbox
            # 设置MESA加载器驱动覆盖为kgsl
            export MESA_LOADER_DRIVER_OVERRIDE='kgsl'
            # vulkan驱动需要
            export TU_DEBUG='noconform'
            # 设置XDG运行时目录
            export XDG_RUNTIME_DIR=/run/user/$CHROOT_UID
            # 设置媒体管理
            export PIPEWIRE_RUNTIME_DIR=/run/user/$CHROOT_UID
            # 设置XDG会话类型为x11
            export XDG_SESSION_TYPE='x11'
            # 设置Qt平台插件为xcb
            export QT_QPA_PLATFORM='xcb'

            # 修改 kwinrc 配置文件以禁用特效
	        kwriteconfig5 --file kwinrc --group Compositing --key Enabled false

            # 用 dbus-launch 启动整个 Xsession。
            # KDE 会话启动后，会自动根据配置(autostart)拉起 fcitx5。
            # fcitx5 会自动连接到这个由 dbus-launch 创建的会话总线上。
            sudo service dbus start
            export \$(dbus-launch)

            wireplumber &
            /usr/bin/pipewire &
            /usr/bin/pipewire-pulse &

            startplasma-x11
            # /etc/X11/Xsession

            # 修改 kwinrc 配置文件以启用特效
	        # kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
        "

    # 6. 退出后清理挂载点

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
    # umount "${DEBIANPATH}/apex"
    # umount "${DEBIANPATH}/system"
    # umount "${DEBIANPATH}/tmp"
    umount "${DEBIANPATH}/dev/shm"
    umount "${DEBIANPATH}/dev/pts"
    umount "${DEBIANPATH}/sys"
    umount "${DEBIANPATH}/proc"
    umount "${DEBIANPATH}/dev"

    # 3. 检查卸载状态
    echo ">>> 步骤 3/4: 检查挂载点状态..."
    if mount | grep -q "$DEBIANPATH"; then
        echo ""
        echo "[警告] 仍有挂载点卸载失败！"
    else
        echo "    - 所有挂载点已成功清理。"
    fi
}

# 使用 su -c 以 root 权限运行 chroot_func 函数，并传递环境变量
su -c "exec /data/data/com.termux/files/usr/bin/bash" << EOF
export DEBIANPATH='$DEBIANPATH'
export USERNAME='$USERNAME'
export GRACE_PERIOD='$GRACE_PERIOD'
export CONFIRM_TIMEOUT='$CONFIRM_TIMEOUT'
export PATH='$PATH'
export CHROOT_UID='$CHROOT_UID'

$(declare -f chroot_func)

chroot_func
EOF

# 4. 终止Termux的服务进程
echo ">>> 步骤 4/4: 终止 Termux 侧服务进程..."
echo "    - 正在终止 Termux X11 服务..."
su -c killall -TERM termux-x11
echo "    - 正在终止 pulseaudio 服务..."
su -c killall -TERM pulseaudio