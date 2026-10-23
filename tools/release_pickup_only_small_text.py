from pathlib import Path
import hashlib,json,shutil,sys

root=Path(__file__).resolve().parents[1]
name='pickup-only-small-text-2026-10-21'
old_name='small-labels-dark-foundations-2026-10-21'
release=root/'builds'/name
prior=root/'builds'/old_name

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

if '--prepare' in sys.argv:
    release.mkdir(parents=True,exist_ok=True)
    (release/'.gdignore').touch()
    for file in ['安卓版暂缓.json','实物照片_来源与授权.md','实物照片目录.json','资料与鸣谢.txt','firework_launch.wav','firework_burst.wav','新增烟花音效说明.txt']:
        shutil.copy2(prior/file,release/file)
    export=(root/'tools/export_small_labels_dark_ground_release.ps1').read_text(encoding='utf-8-sig').replace(old_name,name)
    (root/'tools/export_pickup_only_small_text_release.ps1').write_text(export,encoding='utf-8-sig')
    focus=(root/'tools/verify_celebration_rewards.gd').read_text(encoding='utf-8-sig')
    helpers=(root/'tools/verify_shipped_celebration_rewards.gd').read_text(encoding='utf-8-sig')
    standalone=helpers[:helpers.index('var check_done')]+focus[focus.index('var check_done'):]+'\n'+helpers[helpers.index('func _frames'):]
    (root/'tools/verify_shipped_pickup_only_small_text.gd').write_text(standalone,encoding='utf-8')
    print('PICKUP_ONLY_SMALL_TEXT_RELEASE_PREPARED')
    sys.exit()

checks=[(root/'previews/pickup-only-small-names-gpu.log','SMALL_NEARBY_NAMES_NO_POINTERS_OK'),(release/'shipped-pickup-only-small-names-gpu.log','SMALL_NEARBY_NAMES_NO_POINTERS_OK'),(release/'pck-check.log','PLAYTEST_BUNDLE_OK'),(release/'export-console.log',None),(release/'startup.log',None)]
for path,marker in checks:
    value=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in value,(path,marker)
    assert 'SCRIPT ERROR' not in value and 'WARNING:' not in value,path
    assert all('ERROR: Failed to read the root certificate store.' in line for line in value.splitlines() if 'ERROR:' in line),path
    if 'small-names-gpu.log' in path.name:assert 'CELEBRATION_REWARDS_OK' in value and 'NONPICKUP_ORIGINAL_GUIDANCE_RESTORED_OK' in value,path
shutil.copy2(root/'previews/pickup-only-small-names-gpu.log',release/'pickup-only-small-names-gpu.log')
assert json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
assert (release/'CuanParty.pck').stat().st_mtime>=max(p.stat().st_mtime for p in [*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader'))])
apk=root/'builds/android-2026-10-21/CuanJingGongSheng.apk'
android=json.loads((release/'安卓版暂缓.json').read_text(encoding='utf-8'))
assert sha(apk)==android['existing_apk_sha256'] and apk.stat().st_mtime_ns==android['existing_apk_mtime_ns']
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
note='''# 仅拾取物使用小字 · 电脑版

2026-10-21。按用户最新澄清，缩小小字提示的适用范围。

仅前两关需要本人拾取的拓片、錾子、马铃、红线使用无框小字，不带连线和箭头；两位玩家同时靠近同一件物品时只显示一份。其他正常互动恢复原来的提示框、连线、箭头及阅读方式。此前要求隐藏名字的独立小器物继续保持原有发现方式。

地面以下逐渐压暗、水平贴地步花、落座修正、任务续做/完成重听及十发烟花与音效保留。

真实GPU专项同时验证：拾取物显示小字、无大卡与指引；两碑等非拾取目标恢复原框与指引、无额外小字。另回归本人拾取、落座、任务继续与重听、烟花点击和整段混音、水平步花和重置。独立PCK、原生EXE启动及导出包GPU复查通过；完整人工试玩仍由用户验收。

双击 CuanParty.exe，保留同目录 CuanParty.pck。根目录最新版入口同步。本轮只生成电脑版，旧APK未动。
'''
(release/'本轮改动与测试.md').write_text(note,encoding='utf-8')
(release/'先看这里_启动与操作.txt').write_text('双击 CuanParty.exe，保留同目录 CuanParty.pck。\n本轮仅待拾取物用小字，其他互动恢复原提示框与指引；地下压暗、水平贴地步花保留。\n手机版等待你测试电脑版之后再生成。\n\n1P：WASD、空格跳、E操作、F交谈、Tab换人。\n2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停；R回位保留本轮，T重新开始本轮。\n',encoding='utf-8-sig')
shots=[('待拾取物保留无框小字','shipped-small-labels-keepsake.png'),('非拾取互动恢复原框与指引','shipped-original-nonpickup-guidance.png'),('地下压暗与原提示保留','shipped-reward-glowing-stele-and-button.png')]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境·共生 · 仅拾取物用小字</title><style>body{margin:0;background:#142027;color:#efdfbd;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:22px;margin-top:32px}img{display:block;width:100%;border-radius:4px}p{color:#c6ccbf}a{color:#ecc477}</style><main><h1>爨境·共生 · 仅拾取物用小字</h1><p><a href="CuanParty.exe">打开新版电脑版</a> · <a href="本轮改动与测试.md">改动与检查说明</a></p><p>仅待拾取物使用小字；其他互动恢复原框和指引。地下压暗、水平贴地步花保留。以下为导出电脑版实际渲染，近景使用场景摄像机放大。手机版等待电脑版试玩后再做。</p>'''
for title,file in shots:
    assert (release/file).is_file(),file
    html+=f'<h2>{title}</h2><img src="{file}">'
html+='<p><a href="本轮验证记录.json">检查记录</a></p></main></html>'
(release/'本轮效果预览.html').write_text(html,encoding='utf-8')
record={'date':'2026-10-21','result':'PICKUP_ONLY_SMALL_TEXT_WINDOWS_OK','checks':[p.name for p,m in checks],'nearby_idle':'small text for keepsakes only; original cards and pointers for other interactions','foundation_shading':'deeper below the walk surface','footflower_normal':'world up','surface_clearance_m':.018,'vertical_drift':False,'android_generated':False,'old_apk_unchanged':True,'artifacts':{file:{'bytes':(release/file).stat().st_size,'sha256':sha(release/file)} for file in ['CuanParty.exe','CuanParty.pck']}}
(release/'本轮验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'仅拾取物小字_其他提示恢复_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新电脑版：按最新澄清，只有前两关四件本人拾取物使用无框小字、不带连线箭头；其他正常互动恢复之前的提示框与指引。独立小器物仍无闲置名；地下压暗、水平步花与原奖励保留。拾取/非拾取两类GPU对照、原奖励专项、独立PCK/原生启动/成品GPU通过。只生成电脑版，旧APK未动。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    current=path.read_text(encoding='utf-8-sig')
    first,rest=current.split('\n',1)
    path.write_text(first+'\n\n'+('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/{name}/CuanParty.exe`。下方为历史记录。\n'+rest,encoding='utf-8')
for file in ['startup-test-profile.json','bundle-achievements-profile.json']:(release/file).unlink(missing_ok=True)
for path in release.glob('*.log.*'):path.unlink()
print('PICKUP_ONLY_SMALL_TEXT_WINDOWS_SEALED')
print(json.dumps(record['artifacts']))
