# 爨境·共生

民族交往交流交融主题的三维互动游戏。使用 Godot Engine 4.7.2、GDScript、Blender 模型和 Shader 实现，提供安卓与 Windows 两端体验。

## 先体验安卓版本

[安卓安装与操作](docs/ANDROID.md) · [运行附件说明](docs/DOWNLOADS.md)

安卓版本：0.2.1（3），Android 7.0 / API 24 及以上，64 位 ARM，横屏，离线运行。默认单人触屏，也可选择双人触屏。支持移动、跳跃、长按操作、交谈、切换角色、解碑和物件小艺。图标使用项目提供的美术图片。

**测试范围：**安装包签名、架构、资源完整性和 APK 资源触屏模拟已检查；尚未在实体安卓手机上安装测试，真机表现需要实测。

![安卓双人触屏界面](docs/images/android-dual.png)

## Windows 电脑版本

[电脑启动与操作](docs/WINDOWS.md) · [运行附件说明](docs/DOWNLOADS.md)

完整解压 Windows ZIP，保持 `CuanParty.exe` 与 `CuanParty.pck` 在同一目录，双击 EXE。支持键盘单人 / 同屏双人，无需先安装 Godot。已完成原生程序启动及成品包 GPU 检查。

![电脑游戏界面](docs/images/windows.png)

## 游戏内容

四名同行角色在碑院合读、断溪护碑、灯火共庭三个连续场景中合作，完成传拓、辨字、修路、救碑、安放随身物品、点灯及共读长卷；沿途提供器物故事和不同的小艺互动。主线通关后有彩色步花，全成就后解锁发光彩碑和可交互烟花。

## 完整源代码与运行

安卓与 Windows **共用本仓库的同一个完整 Godot 工程**，分别通过移动端控制层和导出预设适配。它们不是两份互不相关的源码。

1. [下载完整源码工程 ZIP](https://github.com/galaxysmallball-png/cuan-jing-gong-sheng/archive/refs/heads/main.zip) 并解压，或克隆本仓库。
2. 使用 Python 3.11+ 运行 `python tools/setup_submission.py`，还原大资源分块，并从字库原发布方获取项目所用字体。字库有使用范围限制，本仓库不设字体下载镜像；脚本会核对原字体 SHA-256。
3. 在 Godot **4.7.2** 中导入根目录 `project.godot`，等待原始资源导入，按 F6/F5 运行场景 / 工程。
4. 分别导出安卓或 Windows，见 [源码构建说明](docs/BUILD.md)。`tools/build_portable.ps1` 提供不依赖开发机目录的双端导出入口。

GitHub 的 Code → Download ZIP 可下载本仓库完整源码。它包含 GDScript、Shader、场景、项目配置、模型、图片、音频、五段剧情视频、Blender 源文件、工具及资料来源；字体作为第三方依赖由原站获取。大资源分块可无损还原，不改变原始文件内容。安卓 APK、Windows 运行包与可直接导入的评审源码压缩包作为参赛附件另行提交。

| 路径 | 内容 |
| --- | --- |
| `project.godot` | 可导入运行的 Godot 工程入口 |
| `scripts/` | 游戏、合作、谜题、小游戏、界面、触屏及剧情逻辑 |
| `shaders/` | 水体、石材、光晕、烟花、步花等着色代码 |
| `scenes/` | 场景与角色入口 |
| `assets/` | 运行时模型、图像、音频、剧情与资料来源 |
| `character-source/` | 可编辑的 Blender 模型源文件 |
| `tools/` | 美术制作、验证、依赖准备和构建工具 |
| `docs/` | 安装、操作、双端构建及验证范围 |

## 参赛材料建议

主要成果填写“可运行的三维互动游戏软件系统（安卓 APK + Windows 程序）”。安卓可放在展示顺序前面，电脑版本同样是可运行的软件系统。源码仓库地址填写本仓库链接，并同时提交可运行包、运行说明和必要的演示材料。最终项目、格式及其他条件仍以完整赛事通知为准。

## 素材与使用范围

源码公开不等于全部素材采用自由开源许可。第三方图片、字体和引擎各按其原有说明使用；参见 [素材与许可](docs/ASSETS.md)、`assets/legal/` 和 `assets/references/`。作品情节、游戏机制、长卷与场景为艺术创作，不作为民族生活的普遍描述或历史建筑复原。
