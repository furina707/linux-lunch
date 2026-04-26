#!/bin/bash
# Linux Lunch 启动器一键安装脚本
# 使用方法：curl -fsSL <url> | sudo bash
# 或：bash install-system.sh

# Wrap script in main function so that a truncated partial download doesn't end
# up executing half a script.
main() {

set -eu

# 初始化变量
SUDO_USER="${SUDO_USER:-}"

red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"
green="$( (/usr/bin/tput setaf 2 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() { echo "${red}ERROR:${plain} $*"; exit 1; }
warning() { echo "${red}WARNING:${plain} $*"; }
success() { echo "${green}✓${plain} $*" >&2; }

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf $TEMP_DIR; }
trap cleanup EXIT

available() { command -v $1 >/dev/null; }
require() {
    local MISSING=''
    for TOOL in $*; do
        if ! available $TOOL; then
            MISSING="$MISSING $TOOL"
        fi
    done
    echo $MISSING
}

INSTALL_DIR="/opt/linux-lunch"

###########################################
# 检查系统
###########################################

OS="$(uname -s)"
case "$OS" in
    Linux) ;;
    Darwin)
        warning "macOS 支持正在开发中，某些功能可能不可用"
        ;;
    *)
        error "不支持的操作系统：$OS"
        ;;
esac

###########################################
# 检查依赖
###########################################

NEEDS=$(require bash cp chmod mkdir)
if [ -n "$NEEDS" ]; then
    status "ERROR: 缺少必要的工具:"
    for NEED in $NEEDS; do
        echo "  - $NEED"
    done
    exit 1
fi

###########################################
# 检查 root 权限
###########################################

if [ "$(id -u)" -ne 0 ]; then
    if ! available sudo; then
        error "此脚本需要 root 权限。请使用 root 用户或 sudo 运行。"
    fi
    SUDO="sudo"
    # 初始化 SUDO_USER 变量
    if [ -z "$SUDO_USER" ]; then
        SUDO_USER="$(whoami)"
    fi
else
    SUDO=""
    SUDO_USER=""
fi

###########################################
# 确定安装模式
###########################################

# 检查是否在本地目录运行
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/python_launcher.py" ]; then
    # 本地安装模式
    INSTALL_MODE="local"
    status "检测到本地安装模式"
else
    # 远程安装模式 - 使用内嵌代码
    INSTALL_MODE="remote"
    status "检测到远程安装模式"
fi

###########################################
# 创建安装目录
###########################################

status "正在创建安装目录..."
$SUDO mkdir -p "$INSTALL_DIR"
success "安装目录：$INSTALL_DIR"

###########################################
# 安装启动器文件
###########################################

status "正在安装启动器文件..."

if [ "$INSTALL_MODE" = "local" ]; then
    # 本地模式：复制文件
    $SUDO cp "$SCRIPT_DIR/python_launcher.py" "$INSTALL_DIR/"
    $SUDO cp "$SCRIPT_DIR/sh_launcher.sh" "$INSTALL_DIR/"
    $SUDO cp "$SCRIPT_DIR/python-launcher.desktop" "$INSTALL_DIR/"
    $SUDO cp "$SCRIPT_DIR/sh-launcher.desktop" "$INSTALL_DIR/"
else
    # 远程模式：创建内嵌文件
    
    # Python 启动器
    cat > "$TEMP_DIR/python_launcher.py" << 'PYEOF'
#!/usr/bin/env python3
import subprocess
import sys
import os

def find_python_executable():
    python_commands = ['python3', 'python']
    for cmd in python_commands:
        try:
            result = subprocess.run(['which', cmd], capture_output=True, text=True)
            if result.returncode == 0:
                return cmd.strip()
        except Exception:
            continue
    return None

def run_script(script_path, args=None, python_cmd='python3'):
    if not os.path.exists(script_path):
        print(f"Error: Script '{script_path}' not found")
        sys.exit(1)
    cmd = [python_cmd, script_path]
    if args:
        cmd.extend(args)
    try:
        result = subprocess.run(cmd, cwd=os.getcwd())
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Error running script: {e}")
        sys.exit(1)

def main():
    python_cmd = find_python_executable()
    if not python_cmd:
        print("Error: Python not found. Please install Python.")
        sys.exit(1)
    if len(sys.argv) < 2:
        print("Usage: python_launcher.py <script.py> [args...]")
        print("Error: No script specified")
        sys.exit(1)
    script_path = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else None
    run_script(script_path, args=args, python_cmd=python_cmd)

if __name__ == '__main__':
    main()
PYEOF
    $SUDO cp "$TEMP_DIR/python_launcher.py" "$INSTALL_DIR/"
    
    # Shell 启动器
    cat > "$TEMP_DIR/sh_launcher.sh" << 'SHEOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "错误：未指定脚本文件"
    echo "用法：sh_launcher.sh <脚本文件>"
    exit 1
fi
SCRIPT_PATH="$1"
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "错误：文件 '$SCRIPT_PATH' 不存在"
    exit 1
fi
if [[ ! "$SCRIPT_PATH" =~ \.sh$ ]]; then
    echo "警告：这不是一个 .sh 文件"
fi
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "正在添加执行权限..."
    chmod +x "$SCRIPT_PATH"
fi
cd "$(dirname "$SCRIPT_PATH")"
echo "正在运行：$SCRIPT_PATH"
echo "================================"
bash "$SCRIPT_PATH"
EXIT_CODE=$?
echo "================================"
echo "脚本执行完成，退出码：$EXIT_CODE"
exit $EXIT_CODE
SHEOF
    $SUDO cp "$TEMP_DIR/sh_launcher.sh" "$INSTALL_DIR/"
    
    # Python 桌面文件
    cat > "$TEMP_DIR/python-launcher.desktop" << 'DESKTOP1EOF'
[Desktop Entry]
Type=Application
Name=Python Launcher
Name[zh_CN]=Python 启动器
Comment=Launch Python scripts directly
Comment[zh_CN]=直接运行 Python 脚本
Exec=/opt/linux-lunch/python_launcher.py %F
Icon=text-x-python
Terminal=true
Categories=Development;Utility;Application;
MimeType=text/x-python;text/x-python3;application/x-python;
NoDisplay=false
X-GNOME-Autostart-enabled=false
StartupNotify=true
Keywords=python;script;launcher;run;
DESKTOP1EOF
    $SUDO cp "$TEMP_DIR/python-launcher.desktop" "$INSTALL_DIR/"
    
    # Shell 桌面文件
    cat > "$TEMP_DIR/sh-launcher.desktop" << 'DESKTOP2EOF'
[Desktop Entry]
Type=Application
Name=Shell 脚本启动器
Comment=Run shell scripts directly
Comment[zh_CN]=直接运行 Shell 脚本
Exec=/opt/linux-lunch/sh_launcher.sh %F
Icon=utilities-terminal
Terminal=true
Categories=Utility;System;Application;
MimeType=application/x-shellscript;text/x-shellscript;application/x-sh;application/x-bash;
NoDisplay=false
X-GNOME-Autostart-enabled=false
StartupNotify=true
Keywords=shell;bash;script;launcher;run;
DESKTOP2EOF
    $SUDO cp "$TEMP_DIR/sh-launcher.desktop" "$INSTALL_DIR/"
fi

success "启动器文件已安装"

###########################################
# 设置执行权限
###########################################

$SUDO chmod +x "$INSTALL_DIR/python_launcher.py"
$SUDO chmod +x "$INSTALL_DIR/sh_launcher.sh"
$SUDO chmod +x "$INSTALL_DIR/python-launcher.desktop"
$SUDO chmod +x "$INSTALL_DIR/sh-launcher.desktop"
success "执行权限已设置"

###########################################
# 配置系统
###########################################

status "正在配置系统..."

# 复制桌面文件到系统目录
$SUDO mkdir -p /usr/share/applications
$SUDO cp "$INSTALL_DIR/python-launcher.desktop" /usr/share/applications/
$SUDO cp "$INSTALL_DIR/sh-launcher.desktop" /usr/share/applications/
success "桌面文件已复制到系统目录"

# 复制桌面文件到用户目录（确保应用程序菜单显示）
if [ -w "$HOME/.local/share/applications" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp "$INSTALL_DIR/python-launcher.desktop" "$HOME/.local/share/applications/"
    cp "$INSTALL_DIR/sh-launcher.desktop" "$HOME/.local/share/applications/"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    success "桌面文件已复制到用户目录"
else
    warning "无法访问用户目录，跳过复制到用户目录的步骤"
    warning "请手动复制：cp $INSTALL_DIR/*.desktop ~/.local/share/applications/"
fi

# 更新桌面数据库
if available update-desktop-database; then
    $SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
    success "桌面数据库已更新"
fi

# 更新 MIME 数据库
if available update-mime-database; then
    $SUDO mkdir -p /usr/local/share/mime/packages 2>/dev/null || true
    $SUDO update-mime-database /usr/local/share/mime 2>/dev/null || true
    success "MIME 数据库已更新"
fi

# 设置默认打开方式
if available xdg-mime; then
    $SUDO xdg-mime default python-launcher.desktop text/x-python 2>/dev/null || true
    $SUDO xdg-mime default python-launcher.desktop text/x-python3 2>/dev/null || true
    success "Python 文件默认启动器已设置"
    
    $SUDO xdg-mime default sh-launcher.desktop application/x-shellscript 2>/dev/null || true
    $SUDO xdg-mime default sh-launcher.desktop text/x-shellscript 2>/dev/null || true
    success "Shell 文件默认启动器已设置"
fi

# 刷新系统以立即显示启动器
status "正在刷新系统..."
# 获取实际用户的 HOME 目录
if [ -n "$SUDO_USER" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME="$HOME"
fi
if [ -z "$REAL_HOME" ]; then
    REAL_HOME="$HOME"
fi
# 刷新文件管理器（使用实际用户权限）
if available pkill; then
    if [ -n "$SUDO_USER" ]; then
        # 使用 sudo -u 而不是 su，避免再次输入密码
        sudo -u "$SUDO_USER" pkill -HUP nautilus 2>/dev/null || true
        sudo -u "$SUDO_USER" pkill -HUP nemo 2>/dev/null || true
        sudo -u "$SUDO_USER" pkill -HUP caja 2>/dev/null || true
        sudo -u "$SUDO_USER" pkill -HUP dolphin 2>/dev/null || true
        sudo -u "$SUDO_USER" pkill -HUP thunar 2>/dev/null || true
    else
        pkill -HUP nautilus 2>/dev/null || true
        pkill -HUP nemo 2>/dev/null || true
        pkill -HUP caja 2>/dev/null || true
        pkill -HUP dolphin 2>/dev/null || true
        pkill -HUP thunar 2>/dev/null || true
    fi
fi
# 刷新桌面数据库
$SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
if [ -d "$REAL_HOME/.local/share/applications" ]; then
    if [ -n "$SUDO_USER" ]; then
        # 使用 sudo -u 而不是 su，避免再次输入密码
        sudo -u "$SUDO_USER" update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
    else
        update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
    fi
fi
# 刷新 MIME 数据库
if available update-mime-database; then
    $SUDO update-mime-database /usr/share/mime 2>/dev/null || true
    if [ -d "$REAL_HOME/.local/share/mime" ]; then
        if [ -n "$SUDO_USER" ]; then
            # 使用 sudo -u 而不是 su，避免再次输入密码
            sudo -u "$SUDO_USER" update-mime-database "$REAL_HOME/.local/share/mime" 2>/dev/null || true
        else
            update-mime-database "$REAL_HOME/.local/share/mime" 2>/dev/null || true
        fi
    fi
fi
success "系统已刷新"

###########################################
# 安装完成
###########################################

echo
echo "======================================"
success "  安装完成！"
echo "======================================"
echo
echo "安装位置：$INSTALL_DIR"
echo
echo "现在您可以："
echo "  ✓ 双击 .py 文件使用 Python 启动器运行"
echo "  ✓ 双击 .sh 文件使用 Shell 启动器运行"
echo

echo "命令行使用："
echo "  $INSTALL_DIR/python_launcher.py script.py"
echo "  $INSTALL_DIR/sh_launcher.sh script.sh"
echo

echo "系统已自动刷新，启动器应该立即显示。"
echo

echo "如需卸载，运行："
echo "  $SUDO bash uninstall.sh"
echo

}

main
