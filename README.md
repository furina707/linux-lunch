# Linux Lunch - Python & Shell 启动器

一键安装，让所有 `.py` 和 `.sh` 文件都可以通过双击直接运行！

## 🚀 快速安装

### 方法一：curl 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/furina707/linux-lunch/master/install-system.sh | sudo bash
```

### 方法二：克隆仓库后安装

```bash
# 克隆仓库
git clone https://github.com/furina707/linux-lunch.git

# 进入目录
cd linux-lunch

# 运行安装脚本
sudo bash install-system.sh
```

## ✨ 功能特点

### Python 启动器
- ✅ 双击 `.py` 文件直接运行
- ✅ 支持命令行参数
- ✅ 无菜单，简洁高效
- ✅ 自动查找 Python 解释器

### Shell 启动器
- ✅ 双击 `.sh` 文件直接运行
- ✅ 自动添加执行权限
- ✅ 显示执行状态和退出码
- ✅ 切换到脚本目录执行

## 📁 安装位置

- **系统目录**：`/opt/linux-lunch`
- **桌面文件**：`/usr/share/applications/`

## 🎯 使用方式

### 图形界面
- 双击任何 `.py` 或 `.sh` 文件即可运行
- 右键菜单选择启动器选项

### 命令行
```bash
# 运行 Python 脚本
/opt/linux-lunch/python_launcher.py script.py [参数...]

# 运行 Shell 脚本
/opt/linux-lunch/sh_launcher.sh script.sh
```

## 🗑️ 卸载

### 方法一：curl 一键卸载

```bash
curl -fsSL https://raw.githubusercontent.com/furina707/linux-lunch/master/uninstall.sh | sudo bash
```

### 方法二：使用卸载脚本

```bash
# 在项目目录中运行
sudo bash uninstall.sh
```

### 方法三：手动卸载

```bash
sudo rm -rf /opt/linux-lunch
sudo rm /usr/share/applications/python-launcher.desktop
sudo rm /usr/share/applications/sh-launcher.desktop
```

## 🔧 系统要求

- Linux 操作系统
- Python 3
- Bash
- XDG 兼容的桌面环境（GNOME、KDE、XFCE 等）

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

- GitHub: [furina707](https://github.com/furina707)

---

**享受 Linux Lunch 带来的便捷体验！** 🎉