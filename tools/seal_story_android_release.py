from pathlib import Path
import hashlib,json,re,shutil,struct,zipfile

root=Path(__file__).resolve().parents[1]
windows=root/'builds/opening-film-2026-10-21'
android=root/'builds/android-2026-10-21'
allowed='ERROR: Failed to read the root certificate store.'
checks={'chapter-films-gpu.log':'CHAPTER_FILMS_OK',
        'chapter-films-final-render.log':'CHAPTER_PREVIEW_ENTRIES_OK',
        'opening-film-gpu.log':'OPENING_FILM_OK',
        'android-touch-gpu.log':'ANDROID_TOUCH_OK',
        'opening-film-coop.log':'LOCAL_COOP_RENDER_OK',
        'opening-film-single.log':'PARTY_GAME_OK',
        'exported-story-video.log':'EXPORTED_STORY_VIDEO_OK'}

def sha(path):
    digest=hashlib.sha256()
    with path.open('rb') as stream:
        while chunk:=stream.read(1024*1024):digest.update(chunk)
    return digest.hexdigest()

def log_check(path,marker=None):
    text=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in text,(path,marker)
    assert 'SCRIPT ERROR' not in text and 'WARNING:' not in text,path
    assert all(allowed in line for line in text.splitlines() if 'ERROR:' in line),path
    return text

for name,marker in checks.items():
    log_check(root/'previews'/name,marker)
    for folder in [windows,android]:shutil.copy2(root/'previews'/name,folder/name)
chapter_log=(root/'previews/chapter-films-gpu.log').read_text(encoding='utf-8-sig')
for label in ['chapter-first','chapter-second','chapter-third','chapter-epilogue']:
    assert 'CHAPTER_FILM_NATURAL_OK '+label in chapter_log
for folder in [windows,android]:log_check(folder/'export-console.log')
log_check(windows/'pck-check.log','PLAYTEST_BUNDLE_OK')
log_check(windows/'startup.log')
assert json.loads((windows/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
signature=(android/'signature-check.txt').read_text(encoding='utf-8-sig')
assert signature.startswith('Verifies') and 'Verified using v2 scheme (APK Signature Scheme v2): true' in signature
manifest=(android/'apk-manifest.txt').read_text(encoding='utf-8-sig')
for marker in ["name='org.cuanjing.gongsheng'","sdkVersion:'24'","targetSdkVersion:'36'","native-code: 'arm64-v8a'"]:
    assert marker in manifest,marker
assert "android.permission.INTERNET" not in manifest

films=[('opening_story',36.99,'总开场','references/opening-film/用户剧情原片_2026-10-21.mp4'),
       ('chapter_01',40.22,'第一关前','references/opening-film/用户分幕原片_1_2026-10-21.mp4'),
       ('chapter_02',25.47,'第二关前','references/opening-film/用户分幕原片_2_2026-10-21.mp4'),
       ('chapter_03',33.95,'第三关前','references/opening-film/用户分幕原片_3_2026-10-21.mp4'),
       ('epilogue',63.95,'读完共生长卷后','references/opening-film/用户分幕原片_4_2026-10-21.mp4')]
film_records=[]
apk=android/'CuanJingGongSheng.apk'
runtime_files=[root/'project.godot',*list((root/'scripts').glob('*.gd'))]
latest_runtime=max(path.stat().st_mtime for path in runtime_files)
for artifact in [apk,windows/'CuanParty.pck']:
    assert artifact.stat().st_mtime>=latest_runtime,'Artifact predates runtime changes: '+str(artifact)
assert (android/'zipalign-check.txt').exists(),'Final APK alignment check is missing'
assert 'APK_VIDEO_STORAGE_OK' in (android/'video-storage-check.txt').read_text(encoding='utf-8-sig')
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None,'APK CRC failure'
    names=archive.namelist()
    assert not any(name.endswith(('.jks','.keystore')) or 'credentials.json' in name or '-profile.json' in name for name in names)
    libs=[name for name in names if name.startswith('lib/') and name.endswith('.so')]
    assert libs and all('/arm64-v8a/' in name for name in libs),libs
    godot=next(name for name in libs if 'godot' in name.lower())
    with archive.open(godot) as stream:
        header=stream.read(20)
    assert header[:4]==b'\x7fELF' and header[4]==2 and struct.unpack_from('<H',header,18)[0]==183
    for name,seconds,placement,source in films:
        native=root/f'assets/video/{name}.ogv'
        entry=next(item for item in names if item.endswith(f'assets/video/{name}.ogv'))
        item=archive.getinfo(entry)
        assert item.compress_type==zipfile.ZIP_STORED,'Video should stream without ZIP decompression: '+entry
        digest=hashlib.sha256()
        with archive.open(entry) as stream:
            while chunk:=stream.read(1024*1024):digest.update(chunk)
        assert digest.hexdigest()==sha(native),'APK video differs from verified runtime film'
        film_records.append({'name':name,'placement':placement,'seconds':seconds,'runtime_sha256':sha(native),'source_sha256':sha(root/source),'runtime_bytes':native.stat().st_size})
    assert any('/assets/legal/' in name for name in names),'Bundled legal notices missing'
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'

records={'date':'2026-10-21','films':film_records,'checks':checks,
         'android':{'minimum_sdk':24,'target_sdk':36,'abi':'arm64-v8a','package':'org.cuanjing.gongsheng','signed':True,'zip_crc_verified':True,'videos_stored_uncompressed':True,'internet_permission':False,'physical_device_tested':False},
         'artifacts':{name:{'bytes':path.stat().st_size,'sha256':sha(path)} for name,path in [('windows_exe',windows/'CuanParty.exe'),('windows_pck',windows/'CuanParty.pck'),('android_apk',apk)]}}
note='''# 五段剧情与安卓触屏版

2026-10-21。保留先前的总开场，并按用户最新顺序加入四段视频。

| 位置 | 用户原片 | 约时长 |
| --- | --- | --- |
| 启程同行后、选牌前 | 10月21日 (1).mp4 | 37秒 |
| 第一关前 | 10月21日 (1)(1).mp4 | 40秒 |
| 第二关前 | 10月21日 (1)(2).mp4 | 25秒 |
| 第三关前、实际合抬入院之前 | 10月21日 (1)(3).mp4 | 34秒 |
| 共生长卷读到最后、收起之后 | 10月21日 (1)(4).mp4 | 64秒 |

原片保存在工程 references/opening-film，D盘原文件未改。运行版转换为720p/30fps Theora与Vorbis，保留原配音、字幕、全画幅比例。四段分幕逐段自然播完通过，五段均完成打包后实际解码和非黑帧检查。每段可暂停、继续或掠过；空格暂停，Enter/Esc跳过。剧情期间停场景音乐、冻结任务和角色，并停渲染被覆盖的3D世界；结束恢复。第三段完成才交接并合抬；长卷提前收起不播结尾，同次旅程重看长卷或往返不强制重复，T新旅程重置记录。关卡直达也会播放对应视频。

安卓包是横屏、ARM64、最低API24（Android7.0），应用名“爨境·共生”，本地发布签名；包内含全部五段视频和许可说明，不请求联网或外部存储。默认单人触屏，另三人跟随；封面可改双人同屏。虚拟摇杆、跳跃、长按操作、交谈、换人、解碑旋转、当前目标及有效劳作进度均有触屏入口；多点触摸独立释放，后台或弹窗释放按键，系统返回键用于收起/暂停。保留原键盘双人电脑版。

验证：原总开场及四段分幕的GPU播放/自然结束/暂停/静音/跳过/复看/T重开，关卡直达及抬碑延后，长卷结束条件，单双人三关，触屏事件路由与后台/返回；独立Windows PCK、原生启动及五段打包后GPU实际解码；APK签名、Manifest、ARM64 ELF、全ZIP CRC和五段逐字节SHA256核对。字体与指定纸底哈希保持不变。

安卓目前没有连接真机，未实测手机上的安装、帧率、触控手感和长时间运行。触屏布局图片来自电脑模拟，不能作为真机测试结论。

安卓：将 CuanJingGongSheng.apk 传到安卓手机，用文件管理器打开并按系统提示安装。电脑：CuanParty.exe 与同目录CuanParty.pck保留在一起。根目录两处最新版入口已同步电脑版。未上传应用商店，也未创建新的ZIP。

构建使用现有Godot4.7.2标准模板、JDK17与官方Android SDK36；SDK工具通过工程临时英文入口处理中文路径，保留安全保存设置。重建请使用 tools/export_android_release.ps1；本机数媒/.tools/android/signing下的签名材料须保留供后续更新，未放入安装包或试玩目录。
'''
images=['coop-opening-film-early.png','coop-chapter-first.png','coop-chapter-second.png','coop-chapter-third.png','coop-chapter-epilogue.png','coop-android-touch-single.png','coop-android-touch-dual.png']
for folder in [windows,android]:
    for name in images:shutil.copy2(root/'previews'/name,folder/name)
    (folder/'验证记录.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
    (folder/'本轮改动与验证.md').write_text(note,encoding='utf-8')
    (folder/'剧情与手机版预览.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境共生 · 剧情与安卓版</title><style>body{margin:0;background:#132027;color:#efdfbd;font:17px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:24px}h1{font-size:28px}h2{font-size:21px;margin-top:32px}img{display:block;width:100%;border-radius:5px}p{color:#c7c8b7}a{color:#edc785}</style><main><h1>爨境·共生 · 五段剧情与安卓触屏版</h1><p>总开场 → 选牌 → 第一关前剧情 → 第一关 → 第二关前剧情 → 第二关 → 第三关前剧情 → 合抬入院与第三关 → 共生长卷 → 结尾视频。</p><p><a href="../opening-film-2026-10-21/CuanParty.exe">电脑版游戏</a> · <a href="../android-2026-10-21/CuanJingGongSheng.apk">安卓APK</a> · <a href="本轮改动与验证.md">改动与测试说明</a></p>'''+''.join(f'<h2>{title}</h2><img src="{name}">' for title,name in zip(['总开场','第一关前','第二关前','第三关前','共生长卷后的结尾','单人触屏布局模拟','双人触屏布局模拟'],images))+'''<p>视频为游戏内实际解码画面。触屏布局来自电脑模拟；安卓APK尚未真机实测。</p></main></html>''',encoding='utf-8')
    start='将 CuanJingGongSheng.apk 传到64位安卓手机，用文件管理器打开并按系统提示安装。最低Android7.0，横屏，五段视频已内置，可离线播放。\n尚未连接真机，安装、流畅度和手感需在你的手机上验收。\n' if folder==android else '双击 CuanParty.exe，请保留同目录CuanParty.pck。\n'
    (folder/'先看这里_启动与操作.txt').write_text(start+'\n点击启程同行后先看总开场，再选牌；三段分别在对应关卡前，结尾在共生长卷读完后。\n视频可暂停/继续/掠过，电脑空格暂停，Enter/Esc跳过。\n手机默认单人触屏，封面可选双人同屏；移动、跳跃、长按操作、交谈、换人均在屏幕上。\n电脑1P：WASD、空格、E、F、Tab；2P：方向键、小键盘Enter、P、/、右Shift。\nB 包裹，C 见闻，H 帮助，F2 档案；R 回位保留，T新旅程清空本轮，成就每次进入重置。\n',encoding='utf-8-sig')
    for name in ['startup-test-profile.json','bundle-achievements-profile.json']:(folder/name).unlink(missing_ok=True)
    for item in folder.glob('*.log.*'):item.unlink()

(root/'assets/video/SOURCE.json').write_text(json.dumps({'provided_by':'user','films':film_records,'conversion':'720p,30fps,Theora8,Vorbis5,aspect preserved; no original content edits'},ensure_ascii=False,indent=2),encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'五段剧情接入与安卓触屏版_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新五段剧情与安卓触屏版：保留总开场，三关前各播对应用户视频，第三段后才实际合抬，读完共生长卷后播第四段；完整原配音字幕、暂停/跳过、往返不重复及T重置。新增横屏单/双人触屏、摇杆/跳跃/长按/换人/交谈/解碑旋转/目标与进度，后台和返回处理。四分幕自然结束、五片打包GPU解码、完整单双人、触屏模拟、独立PCK/原生启动以及APK签名/清单/ARM64/CRC/视频哈希检查通过；安卓尚未真机实测。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    text=path.read_text(encoding='utf-8-sig')
    first,rest=text.split('\n',1)
    bullet='- ' if path.name=='AGENTS.md' else ''
    path.write_text(first+'\n\n'+bullet+entry+f' 电脑版 `{prefix}builds/opening-film-2026-10-21/CuanParty.exe`，安卓 `{prefix}builds/android-2026-10-21/CuanJingGongSheng.apk`。下方为历史记录。\n'+rest,encoding='utf-8')
print('STORY_ANDROID_RELEASE_SEALED')
print(json.dumps(records['artifacts'],ensure_ascii=False))
