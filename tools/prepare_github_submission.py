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
write('README.md', '''# 爨境·共生

民族交往交流交融主题的三维互动游戏，使用 Godot Engine 4.7.2、GDScript、Shader 与 Blender 模型实现，适配安卓和 Windows。

> **工程文件：**本仓库提供安卓与 Windows 共用的程序源码、Godot 场景、Shader、配置、制作工具和构建说明，供代码审阅。完整可运行工程（包含全部模型、图片、音频、剧情视频、Blender 源文件与所需依赖）见完整工程包 **CuanJingGongSheng-Source-v0.2.1.zip**。本仓库的 Code → Download ZIP 是代码审阅包，不等同于上述完整工程附件。

## 1. 安卓端展示

[安卓安装与操作](docs/ANDROID.md)

版本 0.2.1（3），Android 7.0 / API 24 及以上，64 位 ARM，横屏，离线运行。默认单人触屏，也可选择双人触屏。支持移动、跳跃、长按操作、交谈、切换角色、解碑与器物小艺。

安装包签名、架构、资源完整性和 APK 资源触屏模拟已经检查；尚未在实体安卓手机上安装测试。

![安卓双人触屏界面](docs/images/android-dual.png)

## 2. Windows 电脑端

[电脑启动与操作](docs/WINDOWS.md)

完整解压运行附件，保持 CuanParty.exe 与 CuanParty.pck 在同一目录，双击 EXE；支持键盘单人与同屏双人，无需预先安装 Godot。已完成 Windows 原生启动、独立 PCK 加载及成品包 GPU 检查。

![电脑游戏界面](docs/images/windows.png)

## 3. 源码与完整工程

安卓与电脑端共用一套完整 Godot 工程，分别通过移动控制层、键盘控制和导出预设适配。

- scripts/：游戏、合作、谜题、小艺、界面、触屏和剧情的 GDScript 源码。
- shaders/：材质、水体、光晕、步花和烟花等 Shader 源码。
- scenes/：场景和角色入口。
- project.godot、export_presets.cfg：工程入口与双端导出配置。
- tools/：制作、检查和构建工具。
- docs/、assets/legal/：运行、构建、验证范围和素材来源。
- 完整模型、剧情、美术资源及 Blender 工程：见完整源码 ZIP。

**直接运行或重新构建：**解压完整源码 ZIP，使用 Godot **4.7.2** 导入根目录 project.godot，等待资源导入后按 F5 运行。ZIP 内资源已还原、依赖已备齐。[构建说明](docs/BUILD.md)

如果以本仓库为开发起点，先从完整工程附件补齐 assets/ 与 character-source/，再导入工程。仓库中部分资源元数据及来源记录保留供审阅，不能替代实际资源文件。

## 4. 游戏内容

四位同行在碑院合读、断溪护碑、灯火共庭三个连续场景中合作，完成传拓、辨字、修路、救碑、物件归位、点灯与共读长卷。沿途提供器物故事和不同的小艺互动；通关后有彩色步花，全成就后解锁发光彩碑与可交互烟花。

![共生长卷](docs/images/scroll.png)

## 5. 素材与使用范围

代码可审阅不代表全部素材采用自由开源许可。字体、照片和引擎组件按原有说明使用，见 [素材说明](docs/ASSETS.md) 和 assets/legal/。字库不设公开下载镜像；官方获取及校验工具随工程保留。签名私钥、密码、SDK、开发机缓存和个人凭据未上传。故事、长卷、场景为艺术创作，不作为民族生活的普遍描述或历史建筑复原。
''')
write('docs/ANDROID.md', '''# 安卓安装与操作

使用安装包 `CuanJingGongSheng-Android-v0.2.1.apk`，传到手机，在文件管理器打开并按系统提示安装。最低 Android 7.0、64 位 ARM、横屏。首次启动后不需要联网下载游戏资源。源码下载与附件对应关系见 [运行附件说明](DOWNLOADS.md)。

摇杆移动；“跳跃”跳起；“操作”点击或按住完成任务；“交谈”与附近人物交互；“换人”切换同伴。封面可切单人 / 双人触屏。对话、视频与谜题按画面按钮操作。

当前 APK 版本 0.2.1 / versionCode 3，包名 `org.cuanjing.gongsheng`。沿用既有发布签名，签名私钥不公开上传。已核对 APK 签名、ARM64、资源、图标和五段视频；触屏截图与交互检查来自 APK 资源在电脑上的触摸模拟，尚未完成实体安卓手机安装测试。
''')
write('docs/WINDOWS.md', '''# Windows 启动与操作

使用运行包 `CuanJingGongSheng-Windows-v0.2.1.zip`，完整解压后双击 `CuanParty.exe`，保留同目录 `CuanParty.pck`。无需安装 Godot 引擎。源码下载与附件对应关系见 [运行附件说明](DOWNLOADS.md)。

- 1P：WASD 移动，空格跳跃，E 操作，F 交谈，Tab 换人。
- 2P：方向键移动，小键盘 Enter 跳跃，P 操作，/ 交谈，右 Shift 换人。
- B 包裹，C 见闻，H 帮助，F2 暂停；R 回位并保留本轮进度，T 重新开始本轮。

Windows 原生启动、独立 PCK 资源加载、GPU 场景与奖励专项已经验证。运行包无联网依赖。
''')
write('docs/BUILD.md', '''# 完整工程构建

先解压完整源码 ZIP；从 GitHub 下载的代码审阅包需先从完整工程补齐 assets/ 和 character-source/。用 Godot 4.7.2 导入 project.godot，等待导入完成后按 F5 运行。

安装匹配的导出模板，Windows 导出入口为 tools/build_portable.ps1，传入 -GodotExe 本机Godot路径 -Platform Windows；导出 EXE 与 PCK 需配套分发。

安卓配置 JDK 17、Android SDK API 36 和 build-tools 36.0.0 后，通过同脚本 -Platform Android -DebugBuild 导出测试 APK。预设 ARM64、最低 API 24、目标 API 36。构建者使用自己的签名，原发布私钥、密码、引擎与 SDK 均未上传。已有包的验证记录见 validation/，安卓尚未真机实测。

GLB 用于运行；完整 ZIP 中的 .blend 用于 Blender 编辑。部分历史制作脚本含开发机路径，复用需自行修改。
''')
write('docs/ASSETS.md', '''# 素材与许可说明

本工程提供可审阅、可修改和可构建的源码，不将全部素材统一标为 MIT 或其他自由开源许可。

- Godot 引擎及第三方组件：见 `assets/legal/Godot引擎与第三方许可.txt`。
- 字库为梁培生小爨-简，原发布方为曲靖珠江网，来源与使用范围见 `assets/calligraphy/SOURCE.md`。公开仓库不镜像该字体，`tools/setup_submission.py` 从原站下载并核对原字节哈希。商业使用等其他用途须按权利方原声明处理。
- 实物照片：按 `assets/legal/实物照片_来源与授权.md` 及各照片资料文件记录。
- 用户提供的剧情视频及游戏美术按本项目参赛展示和学习使用整理，不额外声明第三方权利已经转让。
- `.godot` 缓存、Android SDK、引擎二进制、签名私钥、密码和个人凭据不属于项目源码，未上传。
''')
write('docs/DOWNLOADS.md', '''# 工程与运行包

| 文件 | 内容与使用方式 |
| --- | --- |
| `CuanJingGongSheng-Android-v0.2.1.apk` | Android 7.0 及以上、ARM64 手机安装，横屏触控 |
| `CuanJingGongSheng-Windows-v0.2.1.zip` | 完整解压，保持 EXE 与 PCK 同目录后启动 |
| `CuanJingGongSheng-Source-v0.2.1.zip` | 含全部资源和依赖的 Godot 工程，解压后导入 `project.godot` |

安卓与 Windows 共用同一套游戏逻辑、场景和资源，通过控制层与导出预设适配。

GitHub 仓库提供程序源码、场景配置和制作工具；Code → Download ZIP 不包含全部运行素材。运行或重新构建请使用完整源码工程包，Godot 版本为 4.7.2。

安装与操作见 [安卓说明](ANDROID.md) 和 [Windows 说明](WINDOWS.md)，构建步骤见 [构建说明](BUILD.md)。验证范围见 `validation/`；安卓尚未实体手机实测。
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
