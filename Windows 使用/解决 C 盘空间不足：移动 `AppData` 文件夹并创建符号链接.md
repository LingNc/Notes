# 解决 C 盘空间不足：移动 `AppData` 文件夹并创建符号链接

> 通过 `robocopy` 和 `mklink` 实现无损迁移

日期：2024-1-12  
> [!NOTE]
> 1. [问题](#问题)
> 2. [思考方案](#思考方案)
> 3. [方法实现](#方法实现)
>    1. [使用 `robocopy` 无损复制文件](#使用`robocopy`无损复制文件)
>    2. [使用 `mklink` 创建符号链接](#使用`mklink`创建符号链接)
>    3. [删除旧文件夹](#删除旧文件夹)
---

## 问题

在 Windows 系统中，`AppData` 文件夹通常位于 `C:\Users\YourUserName\AppData`，存储了许多应用程序的配置和数据文件。随着使用时间的增加，`AppData` 文件夹可能会占用大量空间，导致系统盘（通常是 C 盘）空间不足。

## 思考方案

为了释放系统盘空间，可以将 `AppData` 文件夹移动到其他磁盘（如 D 盘），并通过创建符号链接的方式，使系统和应用程序仍然可以正常访问 `AppData` 文件夹的内容。具体方案如下：
1. 使用 `robocopy` 命令无损复制 `AppData` 文件夹到新位置。
2. 使用 `mklink` 命令创建符号链接，将原始路径指向新位置。
3. 验证符号链接是否正常工作，并清理旧文件夹。

> [!IMPORTANT]
> 1. 在进行任何操作之前，建议备份重要数据，以防意外。
> 2. 确保以管理员身份运行命令提示符，否则可能无法创建符号链接或复制文件。
> 3. 某些应用程序可能依赖于 `AppData` 文件夹的原始路径，移动后可能导致部分功能异常。
---
## 方法实现

### 使用 `robocopy` 无损复制文件

`robocopy` 是 Windows 自带的强大文件复制工具，支持无损复制文件并避免递归问题。

1. **以管理员身份打开命令提示符**：
   - 按 `Win + X`，选择“命令提示符（管理员）”或“Windows PowerShell（管理员）”。

2. **使用 `robocopy` 复制 `AppData` 文件夹**：
   - 假设将 `AppData` 从 `C:\Users\YourUserName\AppData` 复制到 `D:\AppData`，运行以下命令：
     ```cmd
     robocopy "C:\Users\YourUserName\AppData" "D:\AppData" /E /COPYALL /XJ
     ```
   > 参数说明：
   >  - `/E`：复制所有子目录，包括空目录。
   >  - `/COPYALL`：复制所有文件属性（包括权限、时间戳等）。
   >  - `/XJ`：排除交接点（避免递归问题）。

3. **重命名原始文件夹**：
   - 复制完成后，将原始 `AppData` 文件夹重命名，例如：
     ```cmd
     ren "C:\Users\YourUserName\AppData" "AppData_Old"
     ```

### 使用 `mklink` 创建符号链接

通过 `mklink` 命令创建符号链接，使系统仍然可以访问移动后的 `AppData` 文件夹。

1. **创建符号链接**：
   - 运行以下命令，将 `AppData` 文件夹的路径指向新的位置：
     ```cmd
     mklink /J "C:\Users\YourUserName\AppData" "D:\AppData"
     ```
   > 参数说明：
   >  - `/J`：创建目录联接（Junction），适用于文件夹。

2. **验证符号链接**：
   - 打开 `C:\Users\YourUserName\AppData`，确认它指向 `D:\AppData` 的内容。

### 删除旧文件夹

如果确认新位置的文件和符号链接正常工作，可以删除旧文件夹。

1. **删除旧文件夹**：
   - 运行以下命令：
     ```cmd
     rmdir /s /q "C:\Users\YourUserName\AppData_Old"
     ```

---
> 参考：
> [如何在 Windows 10 上移动 AppData 文件夹](https://cn.windows-office.net/?p=31595)  
> [电脑上AppData数据迁移（解决C盘空间不足的问题）](https://cloud.tencent.com/developer/article/2245362)  
> [在Windows中创建软链接和硬链接（mklink 命令使用教程）](https://lykqq.com/tutorial/533.html)  