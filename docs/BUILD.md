# 完整工程构建

先解压完整源码 ZIP；从 GitHub 下载的代码审阅包需先从完整工程补齐 assets/ 和 character-source/。用 Godot 4.7.2 导入 project.godot，等待导入完成后按 F5 运行。

安装匹配的导出模板，Windows 导出入口为 tools/build_portable.ps1，传入 -GodotExe 本机Godot路径 -Platform Windows；导出 EXE 与 PCK 需配套分发。

安卓配置 JDK 17、Android SDK API 36 和 build-tools 36.0.0 后，通过同脚本 -Platform Android -DebugBuild 导出测试 APK。预设 ARM64、最低 API 24、目标 API 36。构建者使用自己的签名，原发布私钥、密码、引擎与 SDK 均未上传。已有包的验证记录见 validation/，安卓尚未真机实测。

GLB 用于运行；完整 ZIP 中的 .blend 用于 Blender 编辑。部分历史制作脚本含开发机路径，复用需自行修改。
