# 运行包与源码对应关系

本 GitHub 仓库用于交付和审阅完整源码。安卓 APK 与 Windows ZIP 是本作品另外提交的可运行软件附件，不需要评委自行编译。

| 提交顺序 | 附件 | 运行方式 |
| --- | --- | --- |
| 1 | `CuanJingGongSheng-Android-v0.2.1.apk` | 安卓手机安装，横屏触控 |
| 2 | `CuanJingGongSheng-Windows-v0.2.1.zip` | Windows 完整解压后启动 EXE |
| 3 | `CuanJingGongSheng-Source-v0.2.1.zip` | 完整源码评审附件，导入 Godot 4.7.2 |

本仓库的 [Code → Download ZIP](https://github.com/galaxysmallball-png/cuan-jing-gong-sheng/archive/refs/heads/main.zip) 也可下载全部公开源码。先运行 `python tools/setup_submission.py` 还原大文件并从原发布方准备字体，再在 Godot 4.7.2 中打开 `project.godot`。安卓与 Windows 的逻辑、场景与资源共用同一工程，平台差异在移动控制层与导出预设中。

运行附件来自已验证的 0.2.1（3）版本，SHA-256：

- Android APK：`5ba36b27ca06fde932669158755ffcba8fb0fd8efab64d7a686e2a6e7e0bf9ab`
- Windows ZIP：`68936a39c0658d49f4612e8976036b8006d82b3ae60c096d6f82ce7fa8f33a4c`

上述安装包目前作为参赛附件提供，未声称已经上传到 GitHub Releases。源码与运行包的验证范围见 `docs/validation/`，安卓尚未实体手机实测。
