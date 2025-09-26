#!/bin/bash

# ==============================================================================
# 脚本名称: uninstall_from_tar.sh
# 脚本功能: 读取一个 .tar.gz 压缩包，并从系统中删除其中包含的所有文件。
# 警告: 这是一个危险的操作，可能破坏您的系统。请务必谨慎使用。
# ==============================================================================

# --- 检查和设置 ---

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "错误：此脚本需要 root 权限才能删除系统文件。"
  echo "请使用 'sudo ./uninstall_mesa.sh <path_to_tar_file>' 运行。"
  exit 1
fi

# 检查是否提供了 tar 包路径作为参数
if [ "$#" -ne 1 ]; then
  echo "用法: sudo $0 /path/to/your/mesa-driver.tar.gz"
  exit 1
fi

TAR_ARCHIVE="$1"

# 检查 tar 包文件是否存在
if [ ! -f "$TAR_ARCHIVE" ]; then
  echo "错误: 找不到指定的 tar 包文件: $TAR_ARCHIVE"
  exit 1
fi

echo "--- Mesa 驱动卸载脚本 ---"
echo "将从以下 tar 包中读取文件列表进行卸载："
echo "  $TAR_ARCHIVE"
echo ""
echo "⚠️  警告：此操作将从您的系统中永久删除文件，且无法撤销。"
echo "⚠️  请确保您提供的 tar 包是您当初安装时使用的那一个。"
echo "---------------------------------"
read -p "您理解风险并希望继续吗? (yes/no): " CONFIRMATION
if [ "$CONFIRMATION" != "yes" ]; then
  echo "操作已取消。"
  exit 0
fi

# --- 演练（Dry Run）阶段 ---

echo ""
echo "--- 步骤 1: 演练 (Dry Run) ---"
echo "正在分析 tar 包，以下是将被删除的文件和目录列表..."
echo "请仔细检查此列表！"
sleep 2

# 使用 tar -tf 列出所有文件和目录
# 使用 tee 将列表输出到屏幕并同时保存到临时文件
TEMP_FILE_LIST=$(mktemp)
tar -tf "$TAR_ARCHIVE" | tee "$TEMP_FILE_LIST"

FILE_COUNT=$(wc -l < "$TEMP_FILE_LIST")

echo ""
echo "---------------------------------"
echo "分析完成。总共找到 $FILE_COUNT 个待删除的路径。"
echo "请再次仔细检查上面的列表。"
read -p "确认列表无误，并准备执行删除操作吗? (输入 'YES I AM SURE' 以继续): " FINAL_CONFIRMATION

if [ "$FINAL_CONFIRMATION" != "YES I AM SURE" ]; then
  echo "操作已取消。临时文件已删除。"
  rm -f "$TEMP_FILE_LIST"
  exit 0
fi

# --- 执行删除阶段 ---

echo ""
echo "--- 步骤 2: 执行删除 ---"

# 分离文件和目录
FILES_TO_DELETE=()
DIRS_TO_DELETE=()

while IFS= read -r path; do
  # 构造绝对路径
  full_path="/$path"

  # 跳过奇怪的空路径
  if [ -z "$path" ]; then
    continue
  fi

  # 判断是文件还是目录
  if [ -f "$full_path" ]; then
    FILES_TO_DELETE+=("$full_path")
  elif [ -d "$full_path" ]; then
    DIRS_TO_DELETE+=("$full_path")
  fi
done < "$TEMP_FILE_LIST"

# 1. 删除所有文件
echo "--> 正在删除文件..."
if [ ${#FILES_TO_DELETE[@]} -eq 0 ]; then
  echo "没有找到需要删除的文件。"
else
  for file in "${FILES_TO_DELETE[@]}"; do
    echo "  删除文件: $file"
    rm -f "$file"
  done
fi

# 2. 删除所有目录
# 为了确保先删除子目录，再删除父目录，我们按路径深度逆序排序
# 这样 /usr/lib/dri 会在 /usr/lib 之前被处理
echo ""
echo "--> 正在尝试删除目录（仅当目录为空时）..."
if [ ${#DIRS_TO_DELETE[@]} -eq 0 ]; then
  echo "没有找到需要删除的目录。"
else
  # 将数组转换为带有换行符的字符串，然后排序和处理
  printf '%s\n' "${DIRS_TO_DELETE[@]}" | sort -r | while IFS= read -r dir; do
    # rmdir 是一个更安全的命令，它只在目录为空时才会成功
    if rmdir "$dir" 2>/dev/null; then
      echo "  成功删除空目录: $dir"
    else
      echo "  跳过非空目录: $dir"
    fi
  done
fi

# --- 清理和收尾 ---
echo ""
echo "--- 步骤 3: 清理 ---"
# 更新动态链接库缓存
echo "--> 正在运行 ldconfig 更新链接库缓存..."
ldconfig

rm -f "$TEMP_FILE_LIST"

echo ""
echo "卸载操作完成。"
echo "建议您现在重启系统，以确保所有服务都加载了新的（或系统的）驱动程序。"