Title: [Root] 手機Termux建立chroot Ubuntu環境，免Linux Deploy

URL Source: https://ivonblog.com/posts/termux-chroot-ubuntu/

Published Time: 2023-11-04T13:00:00+08:00

Markdown Content:
[🇺🇸 English version](https://ivonblog.com/en-us/posts/termux-chroot-ubuntu/)

緣由：Linux Deploy雖然介面直觀，但已經有點老舊，尤其是下載的發行版rootfs，還有預設下載指令稿寫的不好容易斷線，一些細部設定也不是讓人很滿意。因此拋棄Linux Deploy，直接使用Termux手動建立chroot環境吧。

跟免root權限的[proot Ubuntu](https://ivonblog.com/posts/termux-proot-distro-ubuntu/)比起來，chroot原生效能的執行速度還是比較快的。

本文以Ubuntu 22.04 LTS為範例，建立一個帶有桌面環境的chroot，並用Termux X11顯示桌面。文末再提供一鍵啟動指令稿。

測試手機：Sony Xperia 10 V，Android 13

![Image 1](https://ivonblog.com/posts/termux-chroot-ubuntu/images/Screenshot_20231112-19472.webp)

Ubuntu + KDE Plasma on Android

1. 硬體需求[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#1-%E7%A1%AC%E9%AB%94%E9%9C%80%E6%B1%82)
---------------------------------------------------------------------------------------------------

要跑桌面環境的話

處理器建議Qualcomm Snapdragon 845以上等級

RAM >= 6GB

儲存空間最少10GB

2. 安裝Busybox、Termux、Termux X11[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#2-%E5%AE%89%E8%A3%9Dbusyboxtermuxtermux-x11)
-------------------------------------------------------------------------------------------------------------------------------

1.   用Magisk刷入[Busybox](https://github.com/Magisk-Modules-Alt-Repo/BuiltIn-BusyBox/releases)模塊。

2.   安裝[Termux](https://ivonblog.com/posts/how-to-use-termux/)

3.   安裝[Termux X11](https://ivonblog.com/posts/termux-x11/)

4.   安裝[virglrenderer](https://ivonblog.com/posts/termux-virglrenderer/)啟用硬體加速

Linux Deploy預設把檔案系統存放成單一映像檔再掛載，但這裡我們直接把Ubuntu的rootfs解壓縮到Android檔案系統。

1.   開啟Termux，開啟後安裝tsu和pulseaudio

```
pkg update

pkg install tsu pulseaudio
```

1.   切換到su，進入Android shell

```
su
```

1.   選擇`/data/local/tmp`這個目錄比較不會有權限問題。首先新增存放檔案系統的目錄：

```
mkdir /data/local/tmp/chrootubuntu

cd /data/local/tmp/chrootubuntu
```

1.   下載最新Ubuntu base檔案系統，現在版本是24.04。您可以到[Ubuntu官網](https://cdimage.ubuntu.com/ubuntu-base/releases/)查看每日建置的最新版本。

```
busybox wget https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.2-base-arm64.tar.gz
```

1.   解壓縮，再新增一個當作內部儲存空間掛載點的sdcard目錄，並新增`/dev/shm`裝置目錄。

```
tar xpvf ubuntu-base-*-base-arm64.tar.gz --numeric-owner

mkdir ./sdcard

mkdir ./dev/shm

cd ../
```

1.   新增啟動chroot的指令稿：`vi startu.sh`，填入以下內容

```
#!/bin/sh

# Ubuntu檔案系統所在路徑
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# 解決setuid問題
busybox mount -o remount,dev,suid /data

busybox mount --bind /dev $UBUNTUPATH/dev
busybox mount --bind /sys $UBUNTUPATH/sys
busybox mount --bind /proc $UBUNTUPATH/proc
busybox mount -t devpts devpts $UBUNTUPATH/dev/pts

# Electron APPS需要/dev/shm
busybox mount -t tmpfs -o size=256M tmpfs $UBUNTUPATH/dev/shm

# 掛載內部儲存空間
busybox mount --bind /sdcard $UBUNTUPATH/sdcard

# chroot至Ubuntu
busybox chroot $UBUNTUPATH /bin/su - root

# 退出shell後取消掛載，因為後面要裝圖形環境所以這裡是註解狀態。若沒有要裝圖形環境再將以下指令取消註解。
#busybox umount $UBUNTUPATH/dev/shm
#busybox umount $UBUNTUPATH/dev/pts
#busybox umount $UBUNTUPATH/dev
#busybox umount $UBUNTUPATH/proc
#busybox umount $UBUNTUPATH/sys
#busybox umount $UBUNTUPATH/sdcard
```

1.   賦予指令稿執行權限

```
chmod +x startu.sh
```

1.   進入chroot，這樣就可以開始安裝後續服務了。在終端機輸入`exit`之後會自動取消掛載相關目錄。如果退出後chroot行程沒有中止，那麼就強制停止Termux。

```
sh startu.sh
```

1.   在下載套件前，先修正DNS和新增本機名稱：

```
# 使用Google的DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "127.0.0.1 localhost" > /etc/hosts
```

1.   然後解決`Download is performed unsandboxed as root`警告，並讓root能存取Android的網路：

```
groupadd -g 3003 aid_inet

groupadd -g 3004 aid_net_raw

groupadd -g 1003 aid_graphics

usermod -g 3003 -G 3003,3004 -a _apt

usermod -G 3003 -a root
```

1.   再來更新APT儲存庫：

```
apt update

apt upgrade
```

1.   安裝常用工具：

```
apt install vim net-tools sudo git
```

4. 新增一般使用者、中文化、設定輸入法[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#4-%E6%96%B0%E5%A2%9E%E4%B8%80%E8%88%AC%E4%BD%BF%E7%94%A8%E8%80%85%E4%B8%AD%E6%96%87%E5%8C%96%E8%A8%AD%E5%AE%9A%E8%BC%B8%E5%85%A5%E6%B3%95)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

1.   設定時區為台灣台北

```
ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
```

1.   修改root密碼

```
passwd root
```

1.   新增一般使用者並設定密碼

```
groupadd storage
groupadd wheel
useradd -m -g users -G wheel,audio,video,storage,aid_inet -s /bin/bash user
passwd user
```

1.   編輯：`vim /etc/sudoers`，在`root ALL=(ALL) ALL`的下一行加入以下內容:

```
user    ALL=(ALL:ALL) ALL
```

1.   切換到一般使用者

```
su user
```

1.   安裝`locales`套件並產生正體中文：

```
sudo apt install locales
sudo locale-gen zh_TW.UTF-8
```

1.   安裝Fcitx5輸入法

```
sudo apt install fcitx5*
```

1.   用vim編輯`/etc/environment`，加入以下內容。

```
LANG=zh_TW.UTF-8
LC_CTYPE="zh_TW.UTF-8"
LC_NUMERIC="zh_TW.UTF-8"
LC_TIME="zh_TW.UTF-8"
LC_COLLATE="zh_TW.UTF-8"
LC_MONETARY="zh_TW.UTF-8"
LC_MESSAGES="zh_TW.UTF-8"
LC_PAPER="zh_TW.UTF-8"
LC_NAME="zh_TW.UTF-8"
LC_ADDRESS="zh_TW.UTF-8"
LC_TELEPHONE="zh_TW.UTF-8"
LC_MEASUREMENT="zh_TW.UTF-8"
LC_IDENTIFICATION="zh_TW.UTF-8"
LC_ALL=
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
```

1.   Fcitx5輸入法可以用`fcitx5 &`指令啟動，或是點選應用程式列表的Fcitx5圖示。

5. 安裝桌面環境[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#5-%E5%AE%89%E8%A3%9D%E6%A1%8C%E9%9D%A2%E7%92%B0%E5%A2%83)
-----------------------------------------------------------------------------------------------------------------------

二擇一。XFCE4輕量簡樸，KDE重型華麗。

GNOME目前無法啟動。

### XFCE4[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#xfce4)

1.   安裝XFCE4（Xubuntu的配置）。出現`keyboard layout`的問題的時候輸入1，並選取使用`lighdm`

```
sudo apt install xubuntu-desktop
```

1.   設定預設終端機模擬器，輸入`xfce4-terminal`的編號

```
sudo update-alternatives --config x-terminal-emulator
```

用dbus啟動的指令是為`startxfce4`。下面會談到。

### KDE[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#kde)

1.   安裝KDE（Kubuntu的配置）

```
sudo apt install kubuntu-desktop
```

1.   設定預設終端機模擬器，輸入`konsole`的編號

```
sudo update-alternatives --config x-terminal-emulator
```

用dbus啟動KDE的指令是為`startplasma-x11`。下面會談到。

6. 其他調整[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#6-%E5%85%B6%E4%BB%96%E8%AA%BF%E6%95%B4)
---------------------------------------------------------------------------------------------------

### 設定SSH伺服器[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#%E8%A8%AD%E5%AE%9Assh%E4%BC%BA%E6%9C%8D%E5%99%A8)

1.   如果您有從遠端存取的需求就安裝openSSH。

```
sudo apt install openssh-client openssh-server
```

1.   手動啟動SSH server daemon:

```
mkdir /run/sshd
/usr/sbin/sshd -D &
```

1.   手機的IP位址可以用以下指令查看：

```
ifconfig
```

### 停用Snap[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#%E5%81%9C%E7%94%A8snap)

現在Ubuntu不論安裝Firefox還是Chrmoium都會重新導向用Snap安裝，偏偏chroot環境Snap又跑不起來，所以只好將它封鎖了。

1.   解除安裝Snap：

```
sudo apt-get autopurge snapd
```

1.   執行此指令防止以後自動安裝Snap，請一次全複製然後執行：

```
cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.
# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
```

1.   移除Snap之後會有很多套件無法安裝，於是就只能額外取得deb檔來安裝。以Firefox來說，可以改從Mozilla官方軟體庫安裝：

```
sudo apt install software-properties-common
sudo add-apt-repository ppa:mozillateam/ppa
sudo apt-get update
sudo apt-get install firefox-esr
```

7. 設定一鍵啟動指令稿[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#7-%E8%A8%AD%E5%AE%9A%E4%B8%80%E9%8D%B5%E5%95%9F%E5%8B%95%E6%8C%87%E4%BB%A4%E7%A8%BF)
-----------------------------------------------------------------------------------------------------------------------------------------------------

Termux本身有用PulseAudio → OpenGL ES發出音效的功能，接著用Termux X11充當X伺服器，用於顯示Ubuntu桌面。

在此我們利用Termux Widget，新增從手機桌面啟動chroot Ubuntu的捷徑。

1.   退出chroot環境

```
exit
```

1.   安裝[Termux Widget](https://f-droid.org/zh_Hant/packages/com.termux.widget/)

2.   開啟手機系統設定，授予Termux「顯示在其他應用程式上方」的權限。

3.   強制停止Termux。再重新啟動Termux。

4.   編輯啟動Ubuntu的指令稿

```
su -c "vi /data/local/tmp/startu.sh"
```

1.   將`busybox chroot $UBUNTUPATH /bin/su - root`這行改成登入`user`。`startxfce4`這個指令會自動啟動XFCE4桌面環境

```
busybox chroot $UBUNTUPATH /bin/su - user -c "export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startxfce4"
```

1.   新增捷徑檔案

```
touch .shortcuts/startchroot_ubuntu.sh
chmod +x .shortcuts/startchroot_ubuntu.sh
vim .shortcuts/startchroot_ubuntu.sh
```

1.   填入以下內容：

```
#!/bin/sh

# 中止所有舊行程
killall -9 termux-x11 Xwayland pulseaudio virgl_test_server_android termux-wake-lock

## 啟動Termux X11
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity

sudo busybox mount --bind $PREFIX/tmp /data/local/tmp/chrootubuntu/tmp

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :0 -ac &

sleep 3

# 啟動Termux的Pulse Audio
pulseaudio --start --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

# 啟動virgl server
virgl_test_server_android &

# 執行chroot Ubuntu的指令稿
su -c "sh /data/local/tmp/startu.sh"
```

1.   回到手機桌面，長按新增小工具，選取Termux Widget拖到桌面。剛剛寫的指令稿應該就會顯示在列表上了，按下Termux就會自動啟動，並進入桌面環境。

2.   要中止桌面還的話就是按Exit退出，或者強制停止Termux與Termux X11 APP。

8. 如何安全刪除chroot目錄的資料[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#8-%E5%A6%82%E4%BD%95%E5%AE%89%E5%85%A8%E5%88%AA%E9%99%A4chroot%E7%9B%AE%E9%8C%84%E7%9A%84%E8%B3%87%E6%96%99)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

刪除chroot環境的資料要格外小心，首先要退出chroot，確認一切都已經取消掛載（沒有`resource is busy`訊息），否則您可能會把sdcard資料也刪了。

最簡單的方式是直接重開機，這樣一切都會取消掛載。

然後刪除chroot目錄：

```
su -c "rm -r /data/local/tmp/chrootubuntu"
```

參考資料[#](https://ivonblog.com/posts/termux-chroot-ubuntu/#%E5%8F%83%E8%80%83%E8%B3%87%E6%96%99)
----------------------------------------------------------------------------------------------

chroot啟動指令稿參考自[mjuned47/Termux-Ubuntu](https://github.com/mjuned47/Termux-Ubuntu)

系統設定部份參考：

*   [在Android 上创建GNU/Linux 容器- 约伊兹的萌狼乡手札](https://blog.yoitsu.moe/linux/build_linux_container_on_android.html)
*   [在Termux chroot Ubuntu 22.04环境中使用vscode和zotero - 升升小屋](https://liuss.top/2022/10/19/termux-chroot-vscode/)
*   [cheadrian/Running Linux GUI apps on Android using Ubuntu in chroot, Magisk and Termux](https://github.com/cheadrian/termux-chroot-proot-wine-box86_64/blob/main/Setup_Chroot_Magisk.md)

移除Snap參考[How to remove Snap completely without losing Firefox? - AskUbuntu](https://askubuntu.com/questions/1369159/how-to-remove-snap-completely-without-losing-firefox)
