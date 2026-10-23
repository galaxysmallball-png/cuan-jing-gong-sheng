from pathlib import Path
import hashlib, json, re, shutil, zipfile

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'builds/github-submission-2026-10-23'
SOURCE = BASE / 'source'
RELEASE = ROOT / 'builds/scroll-guidance-correction-2026-10-22'
URL = 'https://github.com/galaxysmallball-png/cuan-jing-gong-sheng'
FONT = 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf'
FONT_SHA = '6a8f3a0e4142afbd4729a0825875d833e28def3ffd51f95a0cd379a2ffaf511b'

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def write(relative, value):
    path = SOURCE / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding='utf-8')

SOURCE.mkdir(parents=True, exist_ok=True)
(BASE / '.gdignore').touch()
for directory in ['assets', 'scripts', 'shaders', 'scenes', 'tools', 'character-source']:
    for path in sorted((ROOT / directory).rglob('*')):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative == FONT or path.suffix in ['.blend1', '.log', '.pyc'] or '__pycache__' in path.parts:
            continue
        assert path.suffix.lower() not in ['.jks', '.keystore', '.p12', '.pem'], relative
        assert path.name not in ['credentials.json', '.env'], relative
        dest = SOURCE / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dest)
for filename in ['project.godot', 'export_presets.cfg']:
    shutil.copy2(ROOT / filename, SOURCE / filename)
presets = (SOURCE / 'export_presets.cfg').read_text(encoding='utf-8-sig')
presets = presets.replace('builds/scroll-guidance-correction-2026-10-22/Windows/', 'builds/Windows/').replace('builds/scroll-guidance-correction-2026-10-22/Android/', 'builds/Android/')
write('export_presets.cfg', presets)
write('.gitignore', '''.godot/
builds/
previews/
backups/
__pycache__/
*.pyc
*.blend1
*.jks
*.keystore
*.p12
credentials.json
.env
assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf
''')
write('.gitattributes', '* text=auto\n*.png binary\n*.jpg binary\n*.webp binary\n*.glb binary\n*.blend binary\n*.ogv binary\n*.wav binary\n*.part binary\n')
write('README.md', f'''# 爨境·共生

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

1. [下载完整源码工程 ZIP]({URL}/archive/refs/heads/main.zip) 并解压，或克隆本仓库。
2. 使用 Python 3.11+ 运行 `python tools/setup_submission.py`，还原大资源分块，并从字库原发布方获取项目所用字体。字库有使用范围限制，本公开仓库不设字体下载镜像；脚本会核对原字体 SHA-256。
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
''')
write('docs/ANDROID.md', f'''# 安卓安装与操作

使用参赛运行附件 `CuanJingGongSheng-Android-v0.2.1.apk`，传到手机，在文件管理器打开并按系统提示安装。最低 Android 7.0、64 位 ARM、横屏。首次启动后不需要联网下载游戏资源。源码下载与附件对应关系见 [运行附件说明](DOWNLOADS.md)。

摇杆移动；“跳跃”跳起；“操作”点击或按住完成任务；“交谈”与附近人物交互；“换人”切换同伴。封面可切单人 / 双人触屏。对话、视频与谜题按画面按钮操作。

当前 APK 版本 0.2.1 / versionCode 3，包名 `org.cuanjing.gongsheng`。沿用既有发布签名，签名私钥不公开上传。已核对 APK 签名、ARM64、资源、图标和五段视频；触屏截图与交互检查来自 APK 资源在电脑上的触摸模拟，尚未完成实体安卓手机安装测试。
''')
write('docs/WINDOWS.md', f'''# Windows 启动与操作

使用参赛运行附件 `CuanJingGongSheng-Windows-v0.2.1.zip`，完整解压后双击 `CuanParty.exe`，保留同目录 `CuanParty.pck`。这是可直接运行的 Windows 软件，不要求评委安装开发引擎。源码下载与附件对应关系见 [运行附件说明](DOWNLOADS.md)。

- 1P：WASD 移动，空格跳跃，E 操作，F 交谈，Tab 换人。
- 2P：方向键移动，小键盘 Enter 跳跃，P 操作，/ 交谈，右 Shift 换人。
- B 包裹，C 见闻，H 帮助，F2 暂停；R 回位并保留本轮进度，T 重新开始本轮。

Windows 原生启动、独立 PCK 资源加载、GPU 场景与奖励专项已经验证。运行包无联网依赖。
''')
write('docs/BUILD.md', '''# 源码运行与双端构建

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
''')
write('docs/ASSETS.md', '''# 素材与许可说明

本工程提供可审阅、可修改和可构建的源码，不将全部素材统一标为 MIT 或其他自由开源许可。

- Godot 引擎及第三方组件：见 `assets/legal/Godot引擎与第三方许可.txt`。
- 字库为梁培生小爨-简，原发布方为曲靖珠江网，来源与使用范围见 `assets/calligraphy/SOURCE.md`。公开仓库不镜像该字体，`tools/setup_submission.py` 从原站下载并核对原字节哈希。商业使用等其他用途须按权利方原声明处理。
- 实物照片：按 `assets/legal/实物照片_来源与授权.md` 及各照片资料文件记录。
- 用户提供的剧情视频及游戏美术按本项目参赛展示和学习使用整理，不额外声明第三方权利已经转让。
- `.godot` 缓存、Android SDK、引擎二进制、签名私钥、密码和个人凭据不属于项目源码，未上传。
''')
write('docs/DOWNLOADS.md', f'''# 运行包与源码对应关系

本 GitHub 仓库用于交付和审阅完整源码。安卓 APK 与 Windows ZIP 是本作品另外提交的可运行软件附件，不需要评委自行编译。

| 提交顺序 | 附件 | 运行方式 |
| --- | --- | --- |
| 1 | `CuanJingGongSheng-Android-v0.2.1.apk` | 安卓手机安装，横屏触控 |
| 2 | `CuanJingGongSheng-Windows-v0.2.1.zip` | Windows 完整解压后启动 EXE |
| 3 | `CuanJingGongSheng-Source-v0.2.1.zip` | 完整源码评审附件，导入 Godot 4.7.2 |

本仓库的 [Code → Download ZIP]({URL}/archive/refs/heads/main.zip) 也可下载全部公开源码。先运行 `python tools/setup_submission.py` 还原大文件并从原发布方准备字体，再在 Godot 4.7.2 中打开 `project.godot`。安卓与 Windows 的逻辑、场景与资源共用同一工程，平台差异在移动控制层与导出预设中。

运行附件来自已验证的 0.2.1（3）版本，SHA-256：

- Android APK：`5ba36b27ca06fde932669158755ffcba8fb0fd8efab64d7a686e2a6e7e0bf9ab`
- Windows ZIP：`68936a39c0658d49f4612e8976036b8006d82b3ae60c096d6f82ce7fa8f33a4c`

上述安装包目前作为参赛附件提供，未声称已经上传到 GitHub Releases。源码与运行包的验证范围见 `docs/validation/`，安卓尚未实体手机实测。
''')
write('tools/setup_submission.py', '''from pathlib import Path
import hashlib, io, json, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf"
EXPECTED = "6a8f3a0e4142afbd4729a0825875d833e28def3ffd51f95a0cd379a2ffaf511b"

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def restore_parts():
    manifest = ROOT / ".source-parts/manifest.json"
    if not manifest.exists():
        return
    for entry in json.loads(manifest.read_text(encoding="utf-8")):
        target = ROOT / entry["path"]
        assert target.resolve().is_relative_to(ROOT.resolve())
        if target.exists() and digest(target) == entry["sha256"]:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_suffix(target.suffix + ".rebuilding")
        with temporary.open("wb") as out:
            for part in entry["parts"]:
                source = ROOT / part["path"]
                assert source.resolve().is_relative_to(ROOT.resolve())
                assert digest(source) == part["sha256"], source
                with source.open("rb") as incoming:
                    while chunk := incoming.read(1024 * 1024):
                        out.write(chunk)
        assert digest(temporary) == entry["sha256"], target
        temporary.replace(target)
        print("Restored", entry["path"])

def prepare_font():
    if FONT.exists() and digest(FONT) == EXPECTED:
        print("Original font checksum OK")
        return
    print("Downloading font from its original publisher; see assets/calligraphy/SOURCE.md")
    request = urllib.request.Request("https://www.zjw.cn/html/ziti/jian.zip", headers={"User-Agent": "CuanJingSourceSetup/0.2.1"})
    with urllib.request.urlopen(request, timeout=90) as response:
        data = response.read(64 * 1024 * 1024 + 1)
    if len(data) > 64 * 1024 * 1024:
        raise RuntimeError("Unexpectedly large publisher download")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for entry in archive.infolist():
            if entry.filename.lower().endswith(".ttf") and entry.file_size < 32 * 1024 * 1024:
                raw = archive.read(entry)
                if hashlib.sha256(raw).hexdigest() == EXPECTED:
                    FONT.parent.mkdir(parents=True, exist_ok=True)
                    FONT.write_bytes(raw)
                    print("Original font checksum OK")
                    return
    raise RuntimeError("Publisher download changed: expected font was not found; obtain it from https://www.zjw.cn/html/ziti/index.html and check the documented SHA-256")

if __name__ == "__main__":
    restore_parts()
    prepare_font()
    print("Open project.godot with Godot 4.7.2")
''')
write('tools/build_portable.ps1', '''param([Parameter(Mandatory=$true)][string]$GodotExe,[ValidateSet('Android','Windows')][string]$Platform='Android',[switch]$DebugBuild)
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$folder=Join-Path $project ('builds/'+$Platform)
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$preset=if($Platform -eq 'Android'){'Android'}else{'Windows Desktop'}
$output=Join-Path $folder $(if($Platform -eq 'Android'){'CuanJingGongSheng.apk'}else{'CuanParty.exe'})
$mode=if($DebugBuild){'--export-debug'}else{'--export-release'}
& $GodotExe --headless --path $project $mode $preset $output
if($LASTEXITCODE -ne 0){throw 'Godot export failed; check engine templates, SDK paths and signing configuration'}
Write-Output $output
''')
for name, source in [('android-dual.png', RELEASE/'Android/shipped-android-nonpickup-guidance-dual.png'), ('windows.png', RELEASE/'Windows/shipped-nonpickup-prop-guidance.png'), ('scroll.png', RELEASE/'Windows/shipped-scroll-final-single-taiwan.png')]:
    target=SOURCE/'docs/images'/name
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)
for relative in ['双端验证记录.json','安装与验证说明.md','Windows/bundle-check.json','Windows/startup-check.json','Android/launcher-pixel-check.json']:
    dest=SOURCE/'docs/validation'/relative
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(RELEASE/relative,dest)

# Keep the original video byte-for-byte while meeting GitHub's regular blob limit.
parts=[]
for path in sorted(SOURCE.rglob('*')):
    if path.is_file() and '.source-parts' not in path.parts and path.stat().st_size > 8*1024*1024:
        relative=path.relative_to(SOURCE).as_posix()
        entry={'path':relative,'bytes':path.stat().st_size,'sha256':sha(path),'parts':[]}
        with path.open('rb') as stream:
            for index in range(1000):
                data=stream.read(8*1024*1024)
                if not data:break
                part=SOURCE/'.source-parts'/f'{relative}.part{index:03d}'
                part.parent.mkdir(parents=True,exist_ok=True)
                part.write_bytes(data)
                entry['parts'].append({'path':part.relative_to(SOURCE).as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        parts.append(entry)
        path.unlink()
write('.source-parts/manifest.json',json.dumps(parts,ensure_ascii=False,indent=2))

files=[]
binary_extensions={'.png','.jpg','.jpeg','.webp','.glb','.blend','.ogv','.ogg','.wav','.mp3','.part','.ttf'}
for path in sorted(SOURCE.rglob('*')):
    if not path.is_file():continue
    relative=path.relative_to(SOURCE).as_posix()
    if '.godot' in path.parts or relative==FONT:continue
    data=path.read_bytes()
    try:
        data.decode('utf-8-sig')
        binary=path.suffix.lower() in binary_extensions or '.part' in path.name
    except UnicodeDecodeError:
        binary=True
    if not binary:
        assert not re.search(rb'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----',data),relative
    files.append({'path':relative,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_sha':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest(),'binary':binary})
(BASE/'source-inventory.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'result':'SUBMISSION_SOURCE_PREPARED','files':len(files),'binary_files':sum(e['binary'] for e in files),'bytes':sum(e['bytes'] for e in files),'source':str(SOURCE)},ensure_ascii=False))
