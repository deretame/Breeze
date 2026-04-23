# Breeze

## 💖 鸣谢与赞助

感谢以下组织对开源社区的支持：

| [![Sentry Logo](asset/sentry-wordmark-dark-400x119.png)](https://sentry.io/) | 本项目由 **[Sentry](https://sentry.io/)** 提供全方位的错误监控赞助，其 Sponsored Business 计划帮助我们更快速地捕获并修复崩溃，提升用户体验。 |
| :--------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |

## 项目开发指南

### 1. 核心工具链安装

在开始之前，请确保基础工具已正确安装并处于最新稳定版：

- **Flutter SDK**: 需通过 `flutter doctor` 验证。
- **Rust Toolchain**: 通过 `rustup` 安装，并添加相应的交叉编译 Target（如 `aarch64-linux-android`）。
- **LLVM / Clang**: 由于涉及 `rustqjs` 等需要解析 C 头的库，必须安装 LLVM 环境（Windows 下推荐使用 `choco install llvm` 或从官网下载），并确保 `LIBCLANG_PATH` 环境变量已配置。

### 2. 环境变量配置

针对不同的编译需求，必须在系统中配置以下环境变量：

| 变量名               | 说明                                  | 示例路径 (参考)                                   |
| :------------------- | :------------------------------------ | :------------------------------------------------ |
| **JAVA_HOME**        | 编译 Android windows 和 Linux必需     | `C:\Program Files\Android\Android Studio\jbr`     |
| **ANDROID_NDK_HOME** | Rust 交叉编译 Android 库必需          | `...\AppData\Local\Android\Sdk\ndk\29.0.14206865` |
| **LIBCLANG_PATH**    | 供 `bindgen` (Rust) 生成 FFI 绑定使用 | `C:\Program Files\LLVM\bin`                       |

> **注意**：请确保 `PATH` 变量中包含 `javac` 和 `clang` 的二进制文件路径。

### 3. 依赖初始化流程

由于项目采用了 Rust 插件模式（`rust_builder` 分离设计），依赖获取需要分步执行。

> `rquickjs_playground` 目前尚未发布到 crates.io，且处于持续迭代阶段。  
> 本项目通过源码路径依赖直接接入：`rust/Cargo.toml` 中为 `rquickjs_playground = { path = "../rquickjs_playground" }`。  
> 因此请确保项目根目录存在 `rquickjs_playground/` 源码目录。

1.  **拉取 `rquickjs_playground` 源码（首次开发必做）**:
    在项目根目录下执行：
    ```bash
    git clone https://github.com/deretame/rquickjs_playground.git ./rquickjs_playground
    ```
    若目录已存在，可跳过此步骤；若需更新可在该目录执行 `git pull`。

2.  **根项目依赖**:
    在项目根目录下执行，下载 Flutter 相关依赖：
    ```bash
    flutter pub get
    ```
3.  **桥接层依赖**:
    进入 Rust 编译辅助目录执行，确保桥接层的 Pub 依赖同步（这对生成某些 `bridge_generated` 文件至关重要）：
    ```bash
    cd rust_builder
    flutter pub get
    ```

### 4. 各平台特定说明

- **Android**: 确保 `local.properties` 中已指向正确的 SDK 路径。
- **Windows/Linux**: 确保安装了 Visual Studio (C++) 或相应的 GCC 工具链，以支持 Rust 的本地编译。

# 🚀 如何安装

### 📱 Android

- 前往 [Releases 页面](https://github.com/deretame/Breeze/releases) 下载 `app-arm64-v8a-release.apk`。
- **提示**：安装时若提示“风险来源”，请在设置中允许“安装未知应用”。

### 🪟 Windows

- 下载 `windows-installer.exe` 后直接运行即可完成安装。

### 🐧 Linux (Flatpak)

Linux 版本通过 Flatpak 分发，以确保在不同发行版上的兼容性。

#### 1. 准备环境

如果你的系统尚未配置 Flatpak，请先参考 [Flatpak 快速设置指南](https://flathub.org/zh-Hans/setup) 完成基础安装。

> **加速建议**：中国大陆用户建议配置 [CERNET 镜像源](https://help.mirrors.cernet.edu.cn/flathub/) 以提升下载速度。

#### 2. 安装运行时 (Runtime)

本项目基于 Freedesktop 24.08 构建。在安装应用前，请确保系统中存在对应的运行时环境：

```shell
flatpak install flathub org.freedesktop.Platform//24.08
```

#### 3. 安装应用

下载 Release 界面的 `breeze.flatpak` 文件，在终端执行：

```shell
# 安装至用户目录下
flatpak install --user breeze.flatpak
```

#### 4. 运行程序

安装完成后，你可以通过应用菜单找到 **Breeze**，或者在终端输入：

```shell
flatpak run io.github.windy.breeze
```

### 💻 macOS

macOS 用户推荐使用 Homebrew 来安装和管理 Breeze。当然，你也可以直接下载 DMG 文件手动安装。

#### 方法 1: 使用 Homebrew 安装（推荐）

**1. 添加软件源 (Tap)**
首先，将本仓库添加到你的 Homebrew 源列表中：

```bash
brew tap deretame/breeze
```

**2. 安装 Breeze**
执行以下命令，Homebrew 会自动下载并安装最新版本到你的“应用程序”目录：

```bash
brew install --cask breeze
```

**3. 更新 Breeze**
当 Breeze 发布新版本后，你可以通过以下命令一键升级：

```bash
brew upgrade breeze
```

**4. 彻底卸载**
如果你需要卸载 Breeze，并希望同时清理底层的数据库、缓存和配置文件，请务必加上 `--zap` 参数（**注意：这不会删除你手动导出的文件，但会清空 App 内部数据**）：

```bash
brew uninstall --zap breeze
```

#### 方法 2: 手动下载 DMG 安装

1. 前往 [Releases 页面](https://github.com/deretame/Breeze/releases) 下载最新的 `Breeze-macOS.dmg`。
2. 双击打开 `.dmg` 文件，将 `Breeze.app` 拖入 `Applications`（应用程序）文件夹。

> ⚠️ **首次启动注意事项 (macOS Gatekeeper)**
> 由于本项目为开源免费软件，未进行 Apple 开发者签名。首次打开时，如果系统提示 **“应用已损坏”** 或 **“无法验证开发者”**，请在终端中执行以下命令予以放行，之后即可正常使用：
>
> ```bash
> xattr -cr /Applications/Breeze.app
> ```
>
> _(备选方法：在“应用程序”文件夹中找到 Breeze，按住 `Control` 键点击应用图标，然后在弹出的菜单中选择“打开”。)_

### 📱 iOS / iPadOS

由于 iOS 系统的封闭性，未上架 App Store 的应用需要通过“侧载 (Sideloading)”并自行签名才能安装。请前往 [Releases 页面](https://github.com/deretame/Breeze/releases) 下载无签名的 `Breeze-iOS.ipa` 文件，并使用以下工具之一进行安装：

#### 🌟 推荐方案：AltStore

AltStore 是目前最稳定且对新手友好的 iOS 侧载工具，支持通过同一局域网下的电脑实现应用自动续签。

- **官网下载**：[AltStore 官方网站](https://altstore.io/)
- **使用教程**：
- [AltStore 官方图文指南（英文）](https://faq.altstore.io/)
- [知乎：基于 AltStore 的越狱工具自签教程](https://zhuanlan.zhihu.com/p/143936759)

#### 🔧 其他自签/免签备选方案

如果你由于某些原因无法使用 AltStore，也可以考虑以下途径：

- **Sideloadly**：免越狱、支持 Windows 和 macOS 的强大桌面自签工具。([官网与教程](https://sideloadly.io/))
- **TrollStore (巨魔商店)**：如果你的 iOS 系统版本在特定的漏洞支持范围内，**强烈推荐**使用巨魔商店实现永久免签安装，永不掉签。([TrollStore 支持版本及安装指南](https://ios.cfw.guide/installing-trollstore/))

---

# **开源项目免责声明**

1. **项目性质与声明**
   本项目为开源软件，由本人独立开发并维护。项目以“原样”形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。
2. **责任限制**
   开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。
3. **用户责任**
   用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。
4. **第三方依赖与资源**
   本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。
5. **无担保声明**
   开发者明确声明不对本项目提供任何形式的担保，包括但不限于：

- 适销性担保；
- 特定用途适用性担保；
- 不侵犯第三方权利担保；
- 无错误或无中断运行担保。

6. **项目修改与终止**
   开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。
7. **贡献者责任**
   如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。
8. **法律合规性**
   用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。

---

**重要提示**
在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。

---

**开发者信息**

- 开发者：**[windy](https://github.com/deretame)**
- 项目仓库：**[Breeze](https://github.com/deretame/Breeze)**
- 联系方式：**[telegram(电报)](https://t.me/breeze_zh_cn)**
