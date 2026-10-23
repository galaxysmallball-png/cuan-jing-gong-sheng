# 源码运行与双端构建

## 共同准备

安装 Godot Engine 4.7.2 和匹配的导出模板，以及 Python 3.11+。在工程根目录执行 `python tools/setup_submission.py`。该命令先无损还原分块的大资源，再从曲靖珠江网原发布地址获取所用字体并校验固定哈希；字体仅按其原有教育、学习等非商业用途范围使用。

导入 `project.godot` 等待完成首次资源导入，然后 F5 运行。`assets/characters/` 使用已导出的 GLB，不必安装 Blender 才能启动游戏；修改角色原始模型时，可另用 Blender 打开 `character-source/` 的 `.blend` 文件。

## Windows

在 PowerShell 执行：

```powershell
./tools/build_portable.ps1 -GodotExe 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe' -Platform Windows
```

输出 `builds/Windows/CuanParty.exe` 和 `.pck`。将二者一起分发。

## 安卓

安装 JDK 17、Android SDK、API 36 和 build-tools 36.0.0，并在 Godot 编辑器的安卓导出设置中填写本机 SDK 与 Java 路径。导出预设采用 ARM64，最低 API 24、目标 API 36。开发测试可使用自己本机的调试签名：

```powershell
./tools/build_portable.ps1 -GodotExe 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe' -Platform Android -DebugBuild
```

发布签名使用构建者自己的密钥，不能将 `.jks`、密码或个人凭据提交到仓库。原发布 APK 的签名与版本检查见 `docs/validation/双端验证记录.json`；重新构建的 APK 应以构建者自己的签名信息为准。

## 工具与验证范围

`tools/verify_*.gd` 保留各阶段的实际验证工具；部分历史美术导出脚本记录开发机路径，复用时需按本机修改。双端通用构建入口为上面的 `build_portable.ps1`。参赛运行包及其测试记录使用同一版本工程，安卓尚未实体手机实测，不将电脑触屏模拟描述为真机测试。
