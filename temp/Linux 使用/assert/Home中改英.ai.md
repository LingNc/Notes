您好，这是一个非常常见的需求，在命令行下使用中文目录确实很不方便。在Linux桌面环境中，这个功能是由一个名为 `xdg-user-dirs` 的标准工具管理的。

您可以按照以下步骤，安全地将这些目录从中文切换为英文。

-----

### **操作步骤**

#### **第一步：确保 `xdg-user-dirs` 已安装**

通常桌面环境会默认安装它，但以防万一，可以先执行以下命令确保它存在：

```shell
sudo apt update
sudo apt install xdg-user-dirs -y
```

#### **第二步：执行关键命令，切换为英文目录**

这是最核心的一步。我们将临时在一个**英文语言环境**下，强制更新用户目录的配置。请打开一个终端，执行以下命令：

```shell
LANG=en_US.UTF-8 xdg-user-dirs-update --force
```

  * `LANG=en_US.UTF-8`： 这部分是临时将当前命令的运行环境设置为美式英语。`xdg-user-dirs-update` 会根据这个设置来生成英文的目录名。
  * `xdg-user-dirs-update`： 这是执行更新的命令。
  * `--force`： 这个参数会强制覆盖掉您现有的中文目录配置。

执行完毕后，系统会自动在您的 Home 文件夹下创建 `Desktop`, `Downloads`, `Documents`, `Music`, `Pictures`, `Videos` 等新的英文目录。

#### **第三步：验证配置是否已更新**

您可以查看一下配置文件，确认更改是否生效：

```shell
cat ~/.config/user-dirs.dirs
```

您应该会看到类似下面的内容，所有的路径都变成了英文：

```
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
```

#### **第四步：手动迁移文件并删除旧目录**

上一步的操作**只会修改配置并创建新目录**，它不会自动帮您移动文件，也不会删除旧的中文目录。您需要手动完成这一步。

1.  **移动文件：** 将旧中文目录里的所有文件，移动到对应的新英文目录中。

    ```shell
    mv ~/桌面/* ~/Desktop/
    mv ~/下载/* ~/Downloads/
    mv ~/文档/* ~/Documents/
    mv ~/音乐/* ~/Music/
    mv ~/图片/* ~/Pictures/
    mv ~/视频/* ~/Videos/
    # 公共 和 模板 目录通常是空的，但以防万一
    mv ~/公共/* ~/Public/
    mv ~/模板/* ~/Templates/
    ```

    *注意：如果某个中文目录是空的，执行 `mv` 命令时系统可能会提示“没有那个文件或目录”，这是正常现象，直接忽略即可。*

2.  **删除空的中文目录：** 确认文件都已移走后，就可以删除这些空目录了。

    ```shell
    rmdir ~/桌面
    rmdir ~/下载
    rmdir ~/文档
    rmdir ~/音乐
    rmdir ~/图片
    rmdir ~/视频
    rmdir ~/公共
    rmdir ~/模板
    ```

    *(`rmdir` 是一个更安全的命令，它只能删除空目录，可以防止您误删文件。)*

#### **第五步：重新登录桌面**

最后，也是最重要的一步：**完全退出您当前的KDE桌面会話，然后重新登录。**

重新登录后，KDE Plasma（包括Dolphin文件管理器等）会读取新的配置，左侧边栏的“位置”以及桌面图标等都会正确地显示为英文名称（Desktop, Downloads 等）。

-----

这样，您就完成了所有目录的英文切换，以后在命令行里操作就会方便很多了。