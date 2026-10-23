from pathlib import Path
import hashlib,json,shutil,sys

root=Path(__file__).resolve().parents[1]
name='ground-flat-footflowers-2026-10-21'
old_name='seated-stele-grand-celebration-2026-10-21'
release=root/'builds'/name
prior=root/'builds'/old_name

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

if '--prepare' in sys.argv:
    release.mkdir(parents=True,exist_ok=True)
    (release/'.gdignore').touch()
    for file in ['安卓版暂缓.json','实物照片_来源与授权.md','实物照片目录.json','资料与鸣谢.txt','firework_launch.wav','firework_burst.wav','新增烟花音效说明.txt']:
        shutil.copy2(prior/file,release/file)
    export=(root/'tools/export_grand_celebration_release.ps1').read_text(encoding='utf-8-sig').replace(old_name,name)
    (root/'tools/export_flat_footflowers_release.ps1').write_text(export,encoding='utf-8-sig')
    focus=(root/'tools/verify_celebration_rewards.gd').read_text(encoding='utf-8-sig')
    helpers=(root/'tools/verify_shipped_celebration_rewards.gd').read_text(encoding='utf-8-sig')
    standalone=helpers[:helpers.index('var check_done')]+focus[focus.index('var check_done'):]+'\n'+helpers[helpers.index('func _frames'):]
    (root/'tools/verify_shipped_flat_footflowers.gd').write_text(standalone,encoding='utf-8')
    print('FLAT_FOOTFLOWERS_RELEASE_PREPARED')
    sys.exit()

checks=[(root/'previews/flat-footflowers-gpu.log','FOOTFLOWERS_FLAT_ON_GROUND_OK'),(release/'shipped-flat-footflowers-gpu.log','FOOTFLOWERS_FLAT_ON_GROUND_OK'),(release/'pck-check.log','PLAYTEST_BUNDLE_OK'),(release/'export-console.log',None),(release/'startup.log',None)]
for path,marker in checks:
    value=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in value,(path,marker)
    assert 'SCRIPT ERROR' not in value and 'WARNING:' not in value,path
    assert all('ERROR: Failed to read the root certificate store.' in line for line in value.splitlines() if 'ERROR:' in line),path
    if 'footflowers-gpu.log' in path.name:assert 'CELEBRATION_REWARDS_OK' in value,path
shutil.copy2(root/'previews/flat-footflowers-gpu.log',release/'flat-footflowers-gpu.log')
assert json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
assert (release/'CuanParty.pck').stat().st_mtime>=max(p.stat().st_mtime for p in [*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader'))])
apk=root/'builds/android-2026-10-21/CuanJingGongSheng.apk'
android=json.loads((release/'安卓版暂缓.json').read_text(encoding='utf-8'))
assert sha(apk)==android['existing_apk_sha256'] and apk.stat().st_mtime_ns==android['existing_apk_mtime_ns']
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
note='''# 脚下花平铺地面 · 电脑版

2026-10-21。本轮按用户要求，将步花从竖立花面改为与地面平行的水平花纹。

花面法线朝上，纹样在水平面内转向；在脚步落点向下检测实际地面，贴在地面上方约1.8厘米防止地砖重叠闪烁。删除原来的向上漂浮，保留内外瓣、花脉、花蕊、彩色渐开及淡去。通关、行走与落地触发条件，以及站住/跳跃/传送不持续刷花和128朵上限均保留。

本轮检查：真实GPU正常镜头及近景、花面水平与贴地高度、通关前后触发、步花淡去和新一轮清理；同一专项也验证碑脚落座、未完成继续/完成重听、烟花按钮/静音/冷却/模态保护和最大音量整段混音。独立PCK、原生EXE启动和导出包内GPU再次检查通过。上版完整单双人、21小艺和视频顺序检查见上版记录，本轮未重复所有全流程。此为自动检查，等待用户实际试玩。

双击 CuanParty.exe，保留同目录 CuanParty.pck。根目录最新版入口已同步。本轮仍只生成电脑版，原APK没有修改。
'''
(release/'本轮改动与测试.md').write_text(note,encoding='utf-8')
(release/'先看这里_启动与操作.txt').write_text('双击 CuanParty.exe，保留同目录 CuanParty.pck。\n本轮将步花改为水平贴地，删除竖立和上浮；通关后行走触发。\n手机版等待你测试电脑版之后再生成。\n\n1P：WASD、空格跳、E操作、F交谈、Tab换人。\n2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停；R回位保留本轮，T重新开始本轮。\n',encoding='utf-8-sig')
shots=[('正常游戏镜头 · 花纹水平贴地','shipped-reward-rainbow-footflowers.png'),('近看水平花瓣与花蕊','shipped-reward-footflower-detail.png')]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境·共生 · 水平贴地步花</title><style>body{margin:0;background:#142027;color:#efdfbd;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:22px;margin-top:32px}img{display:block;width:100%;border-radius:4px}p{color:#c6ccbf}a{color:#ecc477}</style><main><h1>爨境·共生 · 水平贴地步花</h1><p><a href="CuanParty.exe">打开新版电脑版</a> · <a href="本轮改动与测试.md">改动与检查说明</a></p><p>花纹已改为水平铺在脚下，保留彩色渐开与淡去。以下为导出电脑版实际渲染，近景使用场景摄像机放大。手机版等待电脑版试玩后再做。</p>'''
for title,file in shots:
    assert (release/file).is_file(),file
    html+=f'<h2>{title}</h2><img src="{file}">'
html+='<p><a href="本轮验证记录.json">检查记录</a></p></main></html>'
(release/'本轮效果预览.html').write_text(html,encoding='utf-8')
record={'date':'2026-10-21','result':'FLAT_FOOTFLOWERS_WINDOWS_OK','checks':[p.name for p,m in checks],'footflower_normal':'world up','surface_clearance_m':.018,'vertical_drift':False,'android_generated':False,'old_apk_unchanged':True,'artifacts':{file:{'bytes':(release/file).stat().st_size,'sha256':sha(release/file)} for file in ['CuanParty.exe','CuanParty.pck']}}
(release/'本轮验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'步花水平贴地_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新电脑版：按用户要求，步花改为水平贴地，纹样绕竖轴转向；向下检测实际地面、留1.8cm避闪，取消向上漂浮。保留精细彩色花瓣/花脉/花蕊及渐开淡去、通关行走落地触发与128朵上限。正常镜头/近景GPU、贴地高度和水平法线、同套奖励专项、独立PCK/原生启动/成品GPU通过。只生成电脑版，旧APK未动。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    current=path.read_text(encoding='utf-8-sig')
    first,rest=current.split('\n',1)
    path.write_text(first+'\n\n'+('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/{name}/CuanParty.exe`。下方为历史记录。\n'+rest,encoding='utf-8')
for file in ['startup-test-profile.json','bundle-achievements-profile.json']:(release/file).unlink(missing_ok=True)
for path in release.glob('*.log.*'):path.unlink()
print('FLAT_FOOTFLOWERS_WINDOWS_SEALED')
print(json.dumps(record['artifacts']))
