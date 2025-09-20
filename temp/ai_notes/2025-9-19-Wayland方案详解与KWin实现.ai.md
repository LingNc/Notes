## 🤖 Assistant | GitHub Copilot

总结你贴的评论区信息，UP 的“Wayland 方案”核心是：用 KWin-Wayland 在 x11 后端上运行（Wayland-on-X），仍然借助 Termux:X11 做最终显示，这样既能启用 KWin 的 Wayland 合成与特效，又适配 Android 宿主无法直接用 DRM/KMS 的现实。并且要用 Freedreno，而不是 Zink，在 Wayland client 里也能吃到 GPU。

他的方法要点（从评论与常识拼出来的可复现步骤）
前提：
- Termux:X11 已能正常跑 X11（你现状就是）。
- 容器里装齐 KDE Wayland 相关包：kwin-wayland、plasma-workspace-wayland、plasma-wayland-session、xwayland、wayland-protocols 等。
- Freedreno(KGSL) Mesa 已安装好，且在 X11 下能硬件加速。

1) 宿主侧（Termux）先起 X 服务器
- termux-x11 :2 -ac
- 打开 Termux:X11 前台，不让系统杀进程。

2) 容器内环境变量（关键）
- export DISPLAY=:2
- export XDG_RUNTIME_DIR=/run/user/$(id -u); 确保存在并 700 权限
- export XDG_SESSION_TYPE=wayland
- export QT_QPA_PLATFORM=wayland
- Freedreno:
 - export MESA_LOADER_DRIVER_OVERRIDE=kgsl
 - export TU_DEBUG=noconform
- 可选：fcitx5 的输入法变量照你之前配置。

3) 启动 KWin-Wayland（x11 后端）
- 简单起步法：
 - dbus-launch --exit-with-session startplasma-wayland
- 如果 startplasma-wayland 脚本在你的发行版不稳或没把后端选成 x11，可显式起 kwin_wayland：
 - dbus-launch --exit-with-session kwin_wayland --xwayland --x11-display :2 --width=1920 --height=1080
 - 另一个终端内起 Plasma 会话（有的脚本会自动起）：startplasma-wayland
- 提示里提到：
 - “应用显示在 kwin_wayland 上”：要让应用作为 Wayland client 连接到该会话，QT/GTK 的平台变量要设为 wayland（你已经设了 QT_QPA_PLATFORM=wayland；GTK 应用可加 GTK_BACKEND=wayland 或留默认由 XWayland 兜底）。
 - kwin_wayland 窗口大小可用 --width/--height 指定；在 Termux:X11 里这个是一个 X 窗口，可手动全屏或用 Termux:X11 的全屏选项。

4) 确保不是用 Zink
- 评论里出现了“libEGL warning: wayland-egl: could not open zink …”这类报错，说明走到了 Zink。UP 的答复是“用 freedreno。那个在 wayland client 也能吃到”。
- 实操即：不要设置 MESA_LOADER_DRIVER_OVERRIDE=zink；改为 kgsl，并确保 Mesa 包包含 freedreno/turnip 的 KGSL 后端。
- 自检：
 - WAYLAND 会话里运行 glxinfo -B 或 eglinfo/eglinfo -a、glmark2-es2-wayland，renderer 不应是 llvmpipe，也不该提示 zink 缺失。
 - Vulkan 用 vkcube/wezmark 并看 ICD 是否 turnip。

5) KDE 合成器与特效
- KWin 就是 KDE 的合成器。你之前为稳定关了 X11 下的 Compositing；在 Wayland 下，KWin 本身就是 compositor，特效自然跟着启用。
- 若不稳：
 - 在“显示与渲染”里切换 KWin 的渲染后端为 OpenGL ES 试试。
 - 个别特效（模糊/背景透明等）先关一部分排错。

6) 常见问题与对策
- kwin_wayland 窗口不显示/不能全屏：
 - 确保 DISPLAY=:2 存在，Termux:X11 前台运行；
 - 启动时加 --width/--height，并在 Termux:X11 里切全屏。
- 应用不走 Wayland：
 - QT 应用需要 QT_QPA_PLATFORM=wayland；
 - GTK 应用常常自动落到 XWayland；可试 GTK_BACKEND=wayland，如果卡顿就先用 XWayland。
- 性能对比：
 - Wayland-on-X 不一定比纯 X11 快，但 KWin 的 Wayland 合成路径和特效会更完善；相较“Zink(OpenGL→Vulkan) + Turnip + X11”链路，直接用 Freedreno 的 OpenGL/ES 通常更稳更快。

一条可直接试的启动范例（容器内）
- 先确保 dbus:
 - sudo service dbus start
- 然后：
 - export DISPLAY=:2
 - export XDG_RUNTIME_DIR=/run/user/$(id -u); mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
 - export XDG_SESSION_TYPE=wayland
 - export QT_QPA_PLATFORM=wayland
 - export MESA_LOADER_DRIVER_OVERRIDE=kgsl
 - export TU_DEBUG=noconform
 - dbus-launch --exit-with-session kwin_wayland --xwayland --x11-display :2 --width=1600 --height=900
 - 另开终端：startplasma-wayland
- 如果你的发行版 startplasma-wayland 会自动拉起 kwin_wayland，那就一条命令：
 - dbus-launch --exit-with-session startplasma-wayland

最后说明
- 你与他“同 SoC/GPU”能跑的关键在于：装的是含 freedreno/turnip 的 Mesa（带 KGSL kmd）、Wayland 会话里应用别被迫走 Zink，kwin_wayland 用 x11 后端输出到 Termux:X11。
- 若你给我下述信息，我可以给你更精确的命令和排错点：Debian 包名清单（kwin-wayland 是否已装）、当前 Mesa 包来源与版本、glxinfo/eglinfo/vulkaninfo 的关键输出。
