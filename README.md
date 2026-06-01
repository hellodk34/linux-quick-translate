# linux-quick-translate linux 快速翻译

选中文本 → 复制（`Ctrl+C`）→ 按 `Super+C` 弹出结果。

- **单个英文单词**：本地 `sdcv` 词典查询
- **句子/段落**：百度翻译 API 在线翻译

> **注意**
>
> - 本文是在 debian testing(debian forky) + gnome49 with Wayland 上做的测试，但本 flow 可适用几乎所有 Linux 发行版以及不同 DE（桌面环境），如果你用的不同发行版或不同桌面环境，遇到问题请自行变通
> - 快捷键绑定可以是任何你喜欢的，不一定非要'Super+C'
> - 百度翻译个人使用完全足够，完成个人认证之后每月有免费额度100万字符，QPS 10次/秒，超出免费额度费用是49元/百万字符。我们使用的是`通用文本翻译API`

## 运行截图

![presentation](./assets/presentation.webp)

## 安装依赖

```bash
# 词典 sdcv means: star dict console version
sudo apt install sdcv

# 安装剪贴板读取工具（选一种即可）
sudo apt install wl-clipboard    # Wayland 原生（推荐）
# wl-clipboard 提供 wl-copy 和 wl-paste 命令，但本脚本只用了 wl-paste 命令。
# wl-copy: 往剪贴板里写（copy to clipboard）
# wl-paste: 从剪贴板里读（paste from clipboard）

# 或安装 xclip，相比 xsel 更常用，X11 和 Wayland 均可
sudo apt install xclip
# 或安装 xsel，与 xclip 功能类似，二选一即可
sudo apt install xsel              

# 注：xclip 和 xsel 都是 X11 时代的剪贴板工具，它们在 Wayland 下通过 XWayland 兼容层工作。
#     wl-clipboard 是 Wayland 原生方案，性能更好，Wayland 用户优先推荐。

# 弹窗
sudo apt install zenity

# 通知（通常已预装）
sudo apt install libnotify-bin

# 翻译 API 所需
sudo apt install curl python3
```

> **不同发行版的差异**：以上是 Debian/Ubuntu 的包名。Fedora 用 `dnf`，其中 `libnotify` 包名不带 `-bin`；Arch 用 `pacman`，`libnotify` 也不带 `-bin`。其他包（`sdcv`、`zenity`、`wl-clipboard`、`curl`、`python3`）各发行版包名一致。KDE 下 `zenity` 功能正常，若想原生弹窗可将 `zenity` 替换为 `kdialog`（需改脚本）。

## 安装辞典（仅查词需要，翻译不需要）

```bash
mkdir -p ~/.stardict/dic
wget https://github.com/skywind3000/ECDICT/releases/download/1.0.28/ecdict-stardict-28.zip
unzip ecdict-stardict-28.zip -d ~/.stardict/dic/
sdcv --list-dicts   # 验证
```

## 注册百度翻译 API

1. 打开 https://fanyi-api.baidu.com/ 注册并登录
2. 进入控制台 → 开发者中心，获取 **APP ID** 和 **密钥**
3. 打开脚本 `linux-quick-translate.sh`，在顶部配置区填入：

```bash
APPID="你的APPID"
SECRET="你的密钥"
```

## 设置脚本

```bash
chmod +x /path/to/linux-quick-translate.sh
```

打开 **GNOME 设置 → 键盘 → 键盘快捷键 → 自定义快捷键**，添加：

| 名称 | 命令 | 快捷键 |
|------|------|--------|
| 查词翻译 | `/path/to/linux-quick-translate.sh` | `Super+C` |

## 使用

1. 选中文本 → `Ctrl+C` 复制
2. 按 `Super+C`
3. 单个英文单词弹出词典结果，句子弹出原文+译文

## 说明

- 单个英文单词走 `sdcv` 本地查词，无需网络
- 两个以上单词或句子走百度翻译 API，需要网络
- 翻译窗口按文字长度自适应：≤100 字符（600×400）、101-500（800×500）、>500（1000×600）
- 未复制内容时按快捷键提示请先复制
- 未安装 zenity 自动回退 `notify-send` 通知
