from pathlib import Path
import hashlib,json,re,shutil,wave

root=Path(__file__).resolve().parents[1]
name='seated-stele-grand-celebration-2026-10-21'
release=root/'builds'/name
allowed='ERROR: Failed to read the root certificate store.'

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def check(path,marker=None):
    value=path.read_text(encoding='utf-8-sig')
    if marker:assert marker in value,(path,marker)
    assert 'SCRIPT ERROR' not in value and 'WARNING:' not in value,path
    assert all(allowed in line for line in value.splitlines() if 'ERROR:' in line),path
    return value

checks={'grand-celebration-gpu.log':'CELEBRATION_REWARDS_OK','grand-craft-buttons-gpu.log':'NATIVE_CRAFTS_OK','grand-full-coop.log':'LOCAL_COOP_RENDER_OK','grand-full-single.log':'PARTY_GAME_OK','grand-chapter-films-gpu.log':'CHAPTER_FILMS_OK'}
for file,marker in checks.items():
    check(root/'previews'/file,marker)
    shutil.copy2(root/'previews'/file,release/file)
for file,marker in [('export-console.log',None),('pck-check.log','PLAYTEST_BUNDLE_OK'),('startup.log',None),('shipped-grand-celebration-gpu.log','CELEBRATION_REWARDS_OK')]:check(release/file,marker)
proof=check(release/'shipped-grand-celebration-gpu.log','SOLID_STELE_SEATED_OK')
assert 'ACTIVITY_PARTIAL_CONTINUE_AND_COMPLETED_REPLAY_OK' in proof
assert 'FIREWORK_FULL_VOLUME_SHOW_OK' in proof
audio_peak=float(re.search(r'FIREWORK_FULL_VOLUME_SHOW_OK peak=([0-9.]+)',proof).group(1))
assert .10<audio_peak<.99
assert json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
latest_runtime=max(p.stat().st_mtime for p in [root/'project.godot',*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader'))])
assert (release/'CuanParty.pck').stat().st_mtime>=latest_runtime
prior=json.loads((release/'安卓版暂缓.json').read_text(encoding='utf-8'))
apk=root/'builds/android-2026-10-21/CuanJingGongSheng.apk'
assert sha(apk)==prior['existing_apk_sha256'] and apk.stat().st_mtime_ns==prior['existing_apk_mtime_ns']
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
for sound in ['firework_launch.wav','firework_burst.wav']:
    source=root/'assets/audio/grand_fireworks_20261021'/sound
    with wave.open(str(source),'rb') as clip:
        assert clip.getnchannels()==2 and clip.getsampwidth()==2 and clip.getframerate()==44100
    shutil.copy2(source,release/sound)
shutil.copy2(root/'assets/audio/grand_fireworks_20261021/SOURCE.txt',release/'新增烟花音效说明.txt')
records={'date':'2026-10-21','result':'SEATED_STELE_GRAND_CELEBRATION_WINDOWS_OK','checks':checks,'shipped_gpu':True,'full_volume_firework_mix_peak':audio_peak,'android_generated':False,'old_apk_unchanged':True,'artifacts':{file:{'bytes':(release/file).stat().st_size,'sha256':sha(release/file)} for file in ['CuanParty.exe','CuanParty.pck']}}
(release/'本轮验证记录.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
note='''# 碑脚落座、继续任务与盛大烟花 · 电脑版

2026-10-21。本轮只生成电脑版，手机版等待电脑版试玩后再做；旧APK未改变。

- 碑脚：光晕曾被误计为承重部分，导致石碑被抬高。现在落座只计算实体碑身、碑首、碑脚等石材，排除金光与漂浮装饰。真实四人合抬、扶正、每帧净空及最后缓落保留；实体底部精确落在碑座顶面，不靠抬高台阶掩盖。
- 小艺按钮：每件器物各自记录是否实际完成，未完成统一显示“继续任务”，点击继续保留当前操作进度；实际完成才显示“重听故事”，可回到人物故事重玩。仅打开器物或收录收藏不算完成小艺。21件小艺逐项检查。
- 烟花：全8成就后的原右下按钮保留，一次演出10发，分彩色双层花球、金色垂柳与五发收尾；增加连续拖尾、二次小爆花、散落金星和柔和染色光雾。演出约7.4秒，结束才可再次燃放。固定12000粒子上限，弹窗/暂停/新一轮保护保留。
- 声音：重新合成喷气升空、瞬态炸响、低频冲击、空间回声与分散噼啪尾音，专用音量比原版提高5 dB。仍受音效音量与静音控制；最大音量下实际采集整段十发齐放混音，峰值低于削波。声音为原创合成拟音，非实地录音，尚未人工听审。
- 一路生花：六瓣外花与错开的内花、细亮边、花脉、花蕊、花粉光点与尖叶，花光随脚步渐开、渐隐。只在完成主线后当前玩家落地行走时出现，站立、跳跃与传送不持续刷花，最多128朵。

已检查：真实石材逐帧净空和最终接触高度；未完成/部分完成继续/完成后重听；21件小艺实际鼠标输入；完整双人、单人三关；视频顺序和落座后才播放第三段；烟花真实按钮、全音量整段混音、静音、冷却、弹窗保护和重置；步花触发、淡去和新一轮清理。另检查独立PCK、原生EXE启动和导出包内真实GPU渲染。此处为自动输入与渲染检查，完整人工试玩仍由用户验收。

双击 CuanParty.exe，保留同目录 CuanParty.pck。根目录两处最新版入口已同步。原角色GLB、爨字字库、用户纸底和旧版游戏均保留。
'''
(release/'本轮改动与测试.md').write_text(note,encoding='utf-8')
(release/'先看这里_启动与操作.txt').write_text('双击 CuanParty.exe，保留同目录 CuanParty.pck。\n本轮只交付电脑版，手机版等你测试后再做。\n\n本轮更新：碑脚真正落座；未完成小艺显示继续任务，实际完成后显示重听故事；十发分段烟花与更响的炸响/噼啪声；精细彩色步花。\n全8成就解锁烟花，主线通关后走路生花。\n\n1P：WASD、空格跳、E操作、F交谈、Tab换人；2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停；R回位保留本轮，T重新开始本轮。\n',encoding='utf-8-sig')
shots=[('碑脚落在碑座上，彩碑光效保留','shipped-reward-glowing-stele-and-button.png'),('未完成：继续任务','shipped-activity-unfinished-continue.png'),('实际完成：重听故事','shipped-activity-complete-replay.png'),('十发烟花 · 分段齐放与双层拖尾','shipped-reward-player-fireworks.png'),('五发收尾 · 染色光雾与散落金星','shipped-reward-fireworks-finale.png'),('一路生花 · 正常游戏镜头','shipped-reward-rainbow-footflowers.png'),('花瓣、花脉与花蕊 · 实际场景近看','shipped-reward-footflower-detail.png')]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境共生 · 落座与盛大烟花</title><style>body{margin:0;background:#142027;color:#efdfbd;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:22px;margin-top:32px}img{display:block;width:100%;border-radius:4px}p{color:#c6ccbf}a{color:#ecc477}audio{width:min(100%,500px);display:block;margin:12px 0}</style><main><h1>爨境·共生 · 落座与盛大烟花</h1><p><a href="CuanParty.exe">启动新版电脑版</a> · <a href="本轮改动与测试.md">改动与测试说明</a></p><p>以下均为本轮导出电脑版实际渲染。近看图片使用场景摄像机放大；正常游玩尺寸见上一张。手机版等待电脑版试玩后再做。</p><h2>烟花声音</h2><p>升空呼啸与炸响、低频冲击、回声、噼啪尾音。原创合成拟音；游戏中随发射和绽放触发，受音效设置控制。</p><audio controls src="firework_launch.wav"></audio><audio controls src="firework_burst.wav"></audio>'''
for title,file in shots:
    assert (release/file).is_file(),file
    html+=f'<h2>{title}</h2><img loading="lazy" src="{file}">'
html+='<p><a href="本轮验证记录.json">检查记录</a></p></main></html>'
(release/'本轮效果预览.html').write_text(html,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'碑脚落座_任务重听状态_盛大烟花与精细步花_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新电脑版：实体碑脚排除光晕装饰边界，扶正后精确落座；小艺未实际完成显示继续任务且保留部分操作，完成才显示重听故事。全成就烟花扩为10发三段、双层光尾/垂柳/二次爆花/彩雾，音效重做炸响低频回声噼啪并提高5dB，整段最大音量混音通过；通关步花增加内外瓣/花脉/花蕊/花粉尖叶。21小艺、实际点击/落座逐帧、完整单双人、视频顺序、独立PCK/原生启动与成品GPU通过。只生成电脑版，原APK未动，等待用户试玩。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    current=path.read_text(encoding='utf-8-sig')
    first,rest=current.split('\n',1)
    if f'当前 `{prefix}builds/{name}/CuanParty.exe`' not in current:
        path.write_text(first+'\n\n'+('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/{name}/CuanParty.exe`。下方为历史记录。\n'+rest,encoding='utf-8')
for file in ['startup-test-profile.json','bundle-achievements-profile.json']:(release/file).unlink(missing_ok=True)
for path in release.glob('*.log.*'):path.unlink()
print('SEATED_STELE_GRAND_CELEBRATION_WINDOWS_SEALED')
print(json.dumps(records['artifacts'],ensure_ascii=False))
