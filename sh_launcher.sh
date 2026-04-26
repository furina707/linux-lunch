#!/bin/bash

# Shell 脚本启动器
# 用于直接运行 shell 脚本文件

# 检查是否传递了脚本路径
if [ -z "$1" ]; then
    echo "错误：未指定脚本文件"
    echo "用法：sh_launcher.sh <脚本文件>"
    exit 1
fi

SCRIPT_PATH="$1"

# 检查文件是否存在
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "错误：文件 '$SCRIPT_PATH' 不存在"
    exit 1
fi

# 检查是否为 shell 脚本
if [[ ! "$SCRIPT_PATH" =~ \.sh$ ]]; then
    echo "警告：这不是一个 .sh 文件"
fi

# 确保脚本有执行权限
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "正在添加执行权限..."
    chmod +x "$SCRIPT_PATH"
fi

# 切换到脚本所在目录
cd "$(dirname "$SCRIPT_PATH")"

# 执行脚本
echo "正在运行：$SCRIPT_PATH"
echo "================================"
bash "$SCRIPT_PATH"
EXIT_CODE=$?
echo "================================"
echo "脚本执行完成，退出码：$EXIT_CODE"

exit $EXIT_CODE
