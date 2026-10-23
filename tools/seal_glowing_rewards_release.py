from pathlib import Path
import hashlib,json,re,shutil,wave

root=Path(__file__).resolve().parents[1]
release=root/'builds/glowing-rewards-fireworks-2026-10-21'
allowed='ERROR: Failed to read the root certificate store.'

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def check(path,marker=None):
    value=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in value,(path,marker)
    assert 'SCRIPT ERROR' not in value and 'WARNING:' not in value,path
    assert all(allowed in line for line in value.splitlines() if 'ERROR:' in line),path
    return value

checks={'celebration-rewards-gpu.log':'CELEBRATION_REWARDS_OK','reward-pouch-items-gpu.log':'DISPERSED_ITEMS_OK','celebration-full-coop.log':'LOCAL_COOP_RENDER_OK','celebration-full-single.log':'PARTY_GAME_OK'}
for name,marker in checks.items():
    check(root/'previews'/name,marker)
    shutil.copy2(root/'previews'/name,release/name)
for name,marker in [('export-console.log',None),('pck-check.log','PLAYTEST_BUNDLE_OK'),('startup.log',None),('shipped-celebration-gpu.log','CELEBRATION_REWARDS_OK')]:check(release/name,marker)
audio_log=check(release/'shipped-celebration-gpu.log','FIREWORK_AUDIO_MIX_OK')
assert float(re.search(r'peak=([0-9.]+)',audio_log).group(1))>.005
assert json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
latest_runtime=max(p.stat().st_mtime for p in [root/'project.godot',*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader'))])
assert (release/'CuanParty.pck').stat().st_mtime>=latest_runtime
prior=json.loads((release/'安卓版暂缓.json').read_text(encoding='utf-8'))
apk=root/'builds/android-2026-10-21/CuanJingGongSheng.apk'
assert sha(apk)==prior['existing_apk_sha256'] and apk.stat().st_mtime_ns==prior['existing_apk_mtime_ns']
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
for name in ['firework_launch.wav','firework_burst.wav']:
    with wave.open(str(root/'assets/audio/reward_celebration_20261021'/name),'rb') as sound:
        assert sound.getnchannels()==2 and sound.getsampwidth()==2 and sound.getframerate()==44100
shutil.copy2(root/'assets/audio/reward_celebration_20261021/SOURCE.txt',release/'新增烟花音效说明.txt')
records={'date':'2026-10-21','result':'GLOWING_REWARDS_FIREWORKS_WINDOWS_OK','checks':checks,'shipped_gpu':'CELEBRATION_REWARDS_OK / FIREWORK_AUDIO_MIX_OK','android_generated':False,'old_apk_unchanged':True,'artifacts':{name:{'bytes':(release/name).stat().st_size,'sha256':sha(release/name)} for name in ['CuanParty.exe','CuanParty.pck']}}
(release/'本轮验证记录.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
note='''# 发光彩碑、拾物光晕、烟花与脚底生花 · 电脑版

2026-10-21。只生成电脑版，安卓包依用户要求等待电脑版试玩后再做，现有APK没有变化。

- 彩碑：保留矿物彩绘、碑文、金边云纹与七色镶点，新增暖金光晕、真实补光与增强发光材质。仍由本轮8个成就触发，新一轮恢复石色。
- 拾物：前两关的拓片、錾子、马铃、红线都有柔和地面光圈、上升光点和近处照明；本人拾取后整体消失，重开本轮后恢复，角色归属和站稳条件保留。没有新增常驻器物名称。
- 烟花：本轮全8成就后，游戏画面右下角出现居中文字的“放烟花”纸框按钮，一次放三发，有升空、彩色爆开与渐散光尾；2.8秒冷却，冷却仍保留纸框。升空与绽放声均为本轮原创合成音，随原有效果音量和静音设置变化。弹窗、剧情、长卷与移动锁定时隐藏/禁用，不穿透点击场景；新一轮清理余焰、按钮和相关声音。
- 脚底生花：完成主线、到达结尾后，两位当前玩家走路会在脚边留下彩色六瓣光花，并照亮脚下地面；花光短暂上浮后淡去。站住后不再产生，跳跃/传送不拖长线，最多128朵，切角色仍可用。单人模式只作用于当前玩家；新一轮清除。
- 火石布袋：独立重做三维模型，增加立体收口褶皱、开口、翻边、编绳结、垂穗、针脚和凸起的花形刺绣、青色中心、露出的棱角火石与抗闪烁织纹。场景位置、实际点击、实物参照和原小艺保留，原GLB文件未覆盖。

验证包括：四件拾取物发光/本人拾取/重置、布袋几何与实际点击、全成就阈值、右下按钮真实鼠标点击/冷却/弹窗保护、烟花实际混音采样/静音、主线通关前后步花差异/步花淡去/新一轮清理，完整双人和单人三关。独立电脑版PCK与原生启动通过，并在导出PCK里再次使用真实GPU与鼠标输入完成本轮专项，取得实际音频样本。截图是该成品包的渲染画面。

双击 CuanParty.exe，保留同目录 CuanParty.pck。根目录两处最新版启动入口已更新。
'''
(release/'本轮改动与测试.md').write_text(note,encoding='utf-8')
(release/'先看这里_启动与操作.txt').write_text('双击 CuanParty.exe，保留同目录 CuanParty.pck。\n本轮只交付电脑版，手机版等你测试后再做。\n\n本轮8成就全齐后：彩碑发光，右下“放烟花”按钮可使用。\n完成主线后：行走留下短暂彩色光花。\n前两关的待拾物带光晕，须对应人物本人拾取；新一轮恢复待拾状态。\n\n1P：WASD、空格跳、E操作、F交谈、Tab换人；2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停；R回位保留本轮，T重新开始本轮。\n',encoding='utf-8-sig')
shots=[('四件随身物的拾取光晕','shipped-reward-keepsake-glow.png'),('发光彩碑与全成就按钮','shipped-reward-glowing-stele-and-button.png'),('玩家手动放烟花','shipped-reward-player-fireworks.png'),('通关后行走的彩色光花','shipped-reward-rainbow-footflowers.png'),('重做的火石小布袋','shipped-reward-flint-pouch-detail.png'),('布袋侧面与收口','shipped-reward-flint-pouch-side.png')]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境共生 · 发光与庆典</title><style>body{margin:0;background:#142027;color:#efdfbd;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:22px;margin-top:32px}img{display:block;width:100%;border-radius:4px}p{color:#c6ccbf}a{color:#ecc477}</style><main><h1>爨境·共生 · 发光与庆典</h1><p><a href="CuanParty.exe">启动电脑版</a> · <a href="本轮改动与测试.md">改动与测试说明</a></p><p>以下均为导出的电脑版成品实际渲染；本轮尚未生成手机版。</p>'''
for title,name in shots:
    assert (release/name).is_file(),name
    html+=f'<h2>{title}</h2><img src="{name}">'
html+='<p><a href="本轮验证记录.json">检查记录</a></p></main></html>'
(release/'本轮效果预览.html').write_text(html,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'发光彩碑_拾物光晕_烟花与脚底生花_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新电脑版：彩碑加真实光晕与补光；前两关四件本人拾取物带光圈/上升光点，收走消失、T恢复。全8成就后右下纸框按钮放三发彩色烟花，带原创升空/绽放声、冷却与模态隔离；主线通关后当前玩家走路生彩色光花，短暂淡去、池上限128。火石布袋独立重做收口/编绳/针脚/刺绣/火石与织纹，原GLB保留。专项GPU/实际混音、单双人全流程、独立PCK/原生启动及成品包GPU实际操作通过。仅生成电脑版，原APK未动，等用户试玩后再生成手机版。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    current=path.read_text(encoding='utf-8-sig')
    first,rest=current.split('\n',1)
    path.write_text(first+'\n\n'+('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/glowing-rewards-fireworks-2026-10-21/CuanParty.exe`。下方为历史记录。\n'+rest,encoding='utf-8')
for name in ['startup-test-profile.json','bundle-achievements-profile.json']:(release/name).unlink(missing_ok=True)
for path in release.glob('*.log.*'):path.unlink()
print('GLOWING_REWARDS_FIREWORKS_WINDOWS_SEALED')
print(json.dumps(records['artifacts'],ensure_ascii=False))
