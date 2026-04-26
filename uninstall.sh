#!/bin/bash
# Linux Lunch 启动器卸载脚本
# 使用方法：curl -fsSL <url> | sudo bash
# 或：bash uninstall.sh

main() {

set -eu

# 初始化变量
SUDO_USER="${SUDO_USER:-}"

red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"
green="$( (/usr/bin/tput setaf 2 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() { echo "${red}ERROR:${plain} $*"; exit 1; }
success() { echo "${green}✓${plain} $*" >&2; }

INSTALL_DIR="/opt/linux-lunch"

if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        error "此脚本需要 root 权限。请使用 root 用户或 sudo 运行。"
    fi
    SUDO="sudo"
else
    SUDO=""
fi

status "正在卸载 Linux Lunch 启动器..."

$SUDO rm -rf "$INSTALL_DIR" 2>/dev/null || true
success "安装目录已删除"

$SUDO rm -f /usr/share/applications/python-launcher.desktop 2>/dev/null || true
$SUDO rm -f /usr/share/applications/sh-launcher.desktop 2>/dev/null || true
success "系统桌面文件已删除"

rm -f "$HOME/.local/share/applications/python-launcher.desktop" 2>/dev/null || true
rm -f "$HOME/.local/share/applications/sh-launcher.desktop" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
success "用户桌面文件已删除"

if command -v xdg-mime >/dev/null 2>&1; then
    $SUDO xdg-mime default text-x-python.desktop text/x-python 2>/dev/null || true
    $SUDO xdg-mime default text-x-python.desktop text/x-python3 2>/dev/null || true
    $SUDO xdg-mime default text-x-shellscript.desktop text/x-shellscript 2>/dev/null || true
    $SUDO xdg-mime default gnome-terminal.desktop application/x-shellscript 2>/dev/null || true
fi
success "MIME 类型关联已清除"

if command -v update-desktop-database >/dev/null 2>&1; then
    $SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# 刷新文件管理器和桌面环境
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
if command -v pkill >/dev/null 2>&1; then
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
# 刷新桌面数据库（系统级）
$SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
# 刷新桌面数据库（用户级）
if [ -d "$REAL_HOME/.local/share/applications" ]; then
    if [ -n "$SUDO_USER" ]; then
        # 使用 sudo -u 而不是 su，避免再次输入密码
        sudo -u "$SUDO_USER" update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
    else
        update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
    fi
fi
# 刷新 MIME 数据库（系统级）
if command -v update-mime-database >/dev/null 2>&1; then
    $SUDO update-mime-database /usr/share/mime 2>/dev/null || true
    # 刷新 MIME 数据库（用户级）
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

echo
echo "======================================"
success "  卸载完成！"
echo "======================================"
echo
echo "已清除："
echo "  ✓ /opt/linux-lunch"
echo "  ✓ /usr/share/applications/*-launcher.desktop"
echo "  ✓ ~/.local/share/applications/*-launcher.desktop"
echo "  ✓ MIME 类型关联"
echo "  ✓ 系统已刷新"
echo

}

main
