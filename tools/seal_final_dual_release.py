from pathlib import Path
import hashlib,json,re,shutil,struct,zipfile

root=Path(__file__).resolve().parents[1]
base=root/'builds/scroll-guidance-correction-2026-10-22'
windows=base/'Windows'
android=base/'Android'

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def verify_log(path,marker=None):
    value=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in value,(path,marker)
    assert 'SCRIPT ERROR' not in value and 'WARNING:' not in value,path
    assert all('ERROR: Failed to read the root certificate store.' in line for line in value.splitlines() if 'ERROR:' in line),path
    return value

for folder in [windows,android]:verify_log(folder/'export-console.log')
verify_log(windows/'pck-check.log','PLAYTEST_BUNDLE_OK')
verify_log(windows/'startup.log')
assert json.loads((windows/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
reward=verify_log(windows/'shipped-final-rewards-gpu.log','CELEBRATION_REWARDS_OK')
for marker in ['SMALL_NEARBY_NAMES_NO_POINTERS_OK','NONPICKUP_ORIGINAL_GUIDANCE_RESTORED_OK','NONPICKUP_PROP_GUIDANCE_RESTORED_OK','FINAL_SCROLL_CORRECTED_ARTWORK_OK','FOOTFLOWERS_FLAT_ON_GROUND_OK','SOLID_STELE_SEATED_OK','ACTIVITY_PARTIAL_CONTINUE_AND_COMPLETED_REPLAY_OK','FIREWORK_FULL_VOLUME_SHOW_OK']:assert marker in reward,marker
touch=verify_log(android/'apk-assets-touch-gpu.log','ANDROID_TOUCH_OK')
for dual in ['false','true']: assert 'ANDROID_SCROLL_AND_NONPICKUP_GUIDANCE_OK dual='+dual in touch
verify_log(android/'launcher-check.log','PACKAGED_USER_LAUNCHER_ALL_VARIANTS_OK')
source_icon=root/'assets/interface/user_launcher_20261021.png'
assert sha(source_icon)==sha(root/'references/app-icon/用户应用图标_20261021.png')==sha(base/'手机图标.png')
signature=(android/'signature-check.txt').read_text(encoding='utf-8-sig')
assert signature.startswith('Verifies') and 'Verified using v2 scheme (APK Signature Scheme v2): true' in signature
previous_signature=(root/'builds/android-2026-10-21/signature-check.txt').read_text(encoding='utf-8-sig')
pattern=r'Signer #1 certificate SHA-256 digest: ([0-9a-f]+)'
certificate=re.search(pattern,signature).group(1)
assert certificate==re.search(pattern,previous_signature).group(1),'Update signing certificate changed'
manifest=(android/'apk-manifest.txt').read_text(encoding='utf-8-sig')
for value in ["name='org.cuanjing.gongsheng'","versionCode='3'","versionName='0.2.1'","sdkVersion:'24'","targetSdkVersion:'36'","native-code: 'arm64-v8a'"]:assert value in manifest,value
assert 'android.permission.INTERNET' not in manifest
apk=android/'CuanJingGongSheng.apk'
latest_runtime=max(p.stat().st_mtime for p in [*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader'))])
assert apk.stat().st_mtime>=latest_runtime and (windows/'CuanParty.pck').stat().st_mtime>=latest_runtime
films=[]
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None
    names=archive.namelist()
    assert not any(name.endswith(('.jks','.keystore')) or 'credentials.json' in name or '-profile.json' in name for name in names)
    libraries=[name for name in names if name.startswith('lib/') and name.endswith('.so')]
    assert libraries and all('/arm64-v8a/' in name for name in libraries)
    with archive.open(next(name for name in libraries if 'godot' in name.lower())) as f:header=f.read(20)
    assert header[:4]==b'\x7fELF' and header[4]==2 and struct.unpack_from('<H',header,18)[0]==183
    for name,placement in [('opening_story','启程后、选牌前'),('chapter_01','第一关前'),('chapter_02','第二关前'),('chapter_03','第三关碑立正落座后'),('epilogue','读完共生长卷后')]:
        resource=root/f'assets/video/{name}.ogv'
        entry=next(n for n in names if n.endswith(f'assets/video/{name}.ogv'))
        assert archive.getinfo(entry).compress_type==zipfile.ZIP_STORED
        with archive.open(entry) as f:digest=hashlib.file_digest(f,'sha256').hexdigest()
        assert digest==sha(resource)
        films.append({'name':name,'placement':placement,'bytes':resource.stat().st_size,'sha256':digest})
    assert any('/assets/legal/' in n for n in names)
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
note='''# 爨境·共生 · 电脑与安卓运行包

2026-10-22。共生长卷末图移除下方重复的台湾岛，保留上方的一处；原图另存保留。只有前两关本人拾取的四件物品使用无框小字、不带连线和箭头；其余互动、普通可查看器物恢复原提示框、连线与箭头。没有给远处物件新增常驻名称。保留地下压暗、水平贴地步花、碑脚落座、未完成继续任务/完成后重听、全成就彩碑发光与十发烟花及增强音效。

电脑版：解压“爨境共生_电脑版.zip”，打开解压后的文件夹，双击 CuanParty.exe。必须保留同目录 CuanParty.pck。支持原来的键盘单人/双人。

安卓：将 Android/CuanJingGongSheng.apk 传到手机，用文件管理器打开并按系统提示安装。适用于64位ARM安卓、Android 7.0及以上，横屏，默认单人触屏，封面可选双人。沿用旧版应用签名，版本号0.2.1、版本代码3，可作为旧版更新安装。包内含全部模型、音乐和五段剧情，不需联网下载资源。

手机图标直接使用用户提供的原图；原图内容和字节保留。普通及圆形/自适应图标由导出器缩放，系统主题图标使用原图墨色生成的单色透明蒙版。图标已从实际APK中提取，四种图层均与对应素材逐像素核对一致。双人触屏烟花按钮移到摇杆触区下方；对话时收起触控按钮，点击续话后自动恢复，去掉手机界面重复的旧引导。

剧情顺序：总开场→选牌→第一关前剧情→第一关→第二关前剧情→第二关→第三关实际合抬和碑立正落座→第三段剧情→后续第三关任务→读完共生长卷→结尾视频。

已验证：Windows独立PCK、原生EXE启动、导出包内GPU奖励与提示专项；从实际APK解出的资源运行触屏专项，覆盖单/双人、多点触摸、松手、换人、弹窗/后台释放、返回键和烟花按钮避让。APK发布签名、旧版签名连续性、版本/架构/最低系统、ZIP完整性、五段视频逐字节一致与未压缩可流式播放、实际图标像素检查，以及电脑版ZIP内每个文件的CRC与SHA256一致性均通过。

安卓尚未在实体手机上安装运行；手机帧率、触控手感与长时间运行仍待用户实测。触屏截图来自APK资源在电脑上的触摸事件模拟。原APK和旧电脑版保留，签名私钥不在运行包里。
'''
(base/'安装与验证说明.md').write_text(note,encoding='utf-8')
for folder in [windows,android]:
    (folder/'本轮改动与验证.md').write_text(note,encoding='utf-8')
    first='解压后双击 CuanParty.exe，保留同目录 CuanParty.pck。\n' if folder==windows else '将 CuanJingGongSheng.apk 传到64位ARM安卓手机，打开并按系统提示安装。最低Android7.0，横屏，离线使用。\n目前尚未真机实测，需在你的手机上确认实际运行。\n'
    (folder/'先看这里_启动与操作.txt').write_text(first+'\n手机：虚拟摇杆、跳跃、操作、交谈、换人；封面可切单人/双人。\n电脑1P：WASD、空格跳、E操作、F交谈、Tab换人。\n电脑2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停；R回位保留本轮，T重开本轮。\n视频可暂停或跳过；第三段在碑立正落座后播放，结尾在共生长卷读完后播放。\n',encoding='utf-8-sig')
files=['CuanParty.exe','CuanParty.pck','先看这里_启动与操作.txt','本轮改动与验证.md','资料与鸣谢.txt','Godot引擎与第三方许可.txt','实物照片_来源与授权.md','实物照片目录.json']
zip_path=base/'爨境共生_电脑版.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as archive:
    for name in files:archive.write(windows/name,'爨境共生_电脑版/'+name)
with zipfile.ZipFile(zip_path) as archive:
    assert archive.testzip() is None
    for name in files:
        with archive.open('爨境共生_电脑版/'+name) as f:assert hashlib.file_digest(f,'sha256').hexdigest()==sha(windows/name)
record={'date':'2026-10-22','result':'FINAL_WINDOWS_AND_ANDROID_PACKAGES_OK','scroll_final_art':{'file':'assets/story/scroll_lights_single_taiwan_20261022.png','sha256':sha(root/'assets/story/scroll_lights_single_taiwan_20261022.png'),'lower_duplicate_removed':True,'original_preserved':True,'desktop_and_apk_resources_gpu_checked':True},'android':{'version':'0.2.1','version_code':3,'minimum_sdk':24,'target_sdk':36,'abi':'arm64-v8a','same_signing_certificate_as_previous':True,'certificate_sha256':certificate,'signed':True,'physical_device_tested':False,'apk_extracted_runtime_touch_test':True,'launcher_from_user':True},'films':films,'artifacts':{name:{'bytes':path.stat().st_size,'sha256':sha(path)} for name,path in [('windows_zip',zip_path),('windows_exe',windows/'CuanParty.exe'),('windows_pck',windows/'CuanParty.pck'),('android_apk',apk)]}}
(base/'双端验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境·共生 · 电脑与安卓运行包</title><style>body{margin:0;background:#142027;color:#efdfbd;font:17px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1100px;margin:auto;padding:28px}h1{font-size:30px}a{color:#ecc477}img{max-width:100%;display:block;margin:18px 0}nav a{display:inline-block;padding:12px 22px;margin:6px 12px 6px 0;background:#263a3c;border:1px solid #9a7a42;border-radius:8px}.icon{width:192px;border-radius:30px}p{color:#cbd0c1}</style><main><h1>爨境·共生 · 电脑与安卓运行包</h1><nav><a href="爨境共生_电脑版.zip">电脑版 ZIP</a><a href="Android/CuanJingGongSheng.apk">安卓 APK</a></nav><p>电脑完整解压后双击 CuanParty.exe；安卓安装APK。手机版图标已换成你提供的图片。</p><img class="icon" src="Android/launcher-preview.png"><p><a href="Windows/CuanParty.exe">直接启动本机电脑版</a> · <a href="安装与验证说明.md">安装与检查说明</a> · <a href="双端验证记录.json">验证记录</a></p><h2>安卓触屏布局</h2><p>以下为实际APK解出的资源在电脑上的触摸事件模拟，尚未在实体手机上安装运行。</p><img src="Android/shipped-android-touch-single.png"><img src="Android/shipped-android-touch-dual.png"></main></html>'''
html=html.replace('<h2>安卓触屏布局</h2>','<h2>本轮修正</h2><p>长卷末图去掉下方重复的台湾岛；只有待拾取物用小字，其他附近互动保留提示框、连线和箭头。</p><img src="长卷末图.png"><img src="Windows/shipped-scroll-final-single-taiwan.png"><img src="Windows/shipped-original-nonpickup-guidance.png"><img src="Windows/shipped-nonpickup-prop-guidance.png"><img src="Windows/shipped-small-labels-keepsake.png"><h2>安卓触屏布局</h2>')
shutil.copy2(root/'assets/story/scroll_lights_single_taiwan_20261022.png',base/'长卷末图.png')
(base/'下载与预览.html').write_text(html,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'双端最终运行包_用户手机图标_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-22 最新双端修正版：共生长卷末图去掉下方重复台湾岛、原图保留；只有前两关四件本人拾取物使用无框小字且不带连线箭头，其余附近互动及普通查看器物恢复原框/线/箭头，远处不增常驻名。Windows ZIP与安卓0.2.1(3) APK保留用户图标、原签名、五视频及原玩法奖励。Windows原生启动/独立PCK/成品GPU，实际APK资源单双人触屏/末页/指引GPU，签名/版本/ARM64/CRC/五视频/图标像素与ZIP逐文件哈希通过。安卓未真机实测。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    content=path.read_text(encoding='utf-8-sig')
    first,rest=content.split('\n',1)
    line=('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/scroll-guidance-correction-2026-10-22/`。下方为历史记录。'
    path.write_text(first+'\n\n'+line+'\n'+rest,encoding='utf-8')
for name in ['startup-test-profile.json','bundle-achievements-profile.json']:(windows/name).unlink(missing_ok=True)
print('FINAL_WINDOWS_AND_ANDROID_PACKAGES_SEALED')
print(json.dumps(record['artifacts'],ensure_ascii=False))
