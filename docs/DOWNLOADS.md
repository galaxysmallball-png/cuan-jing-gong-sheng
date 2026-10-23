# 工程与运行包

| 文件 | 内容与使用方式 |
| --- | --- |
| `CuanJingGongSheng-Android-v0.2.1.apk` | Android 7.0 及以上、ARM64 手机安装，横屏触控 |
| `CuanJingGongSheng-Windows-v0.2.1.zip` | 完整解压，保持 EXE 与 PCK 同目录后启动 |
| `CuanJingGongSheng-Source-v0.2.1.zip` | 含全部资源和依赖的 Godot 工程，解压后导入 `project.godot` |

安卓与 Windows 共用同一套游戏逻辑、场景和资源，通过控制层与导出预设适配。

GitHub 仓库提供程序源码、场景配置和制作工具；Code → Download ZIP 不包含全部运行素材。运行或重新构建请使用完整源码工程包，Godot 版本为 4.7.2。

安装与操作见 [安卓说明](ANDROID.md) 和 [Windows 说明](WINDOWS.md)，构建步骤见 [构建说明](BUILD.md)。验证范围见 `validation/`；安卓尚未实体手机实测。
