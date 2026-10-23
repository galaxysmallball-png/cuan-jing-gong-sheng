from pathlib import Path
import hashlib,json,re,shutil
root=Path(__file__).resolve().parents[1]
release=root/'builds/route-wall-film-after-raise-2026-10-21'
allowed='ERROR: Failed to read the root certificate store.'
checks={'route-wall-after.log':'ROUTE_WALL_RELEASE_OK','dispersed-items-gpu.log':'DISPERSED_ITEMS_OK','collection-color-egg-gpu.log':'COLLECTION_COLOR_EGG_OK','raise-story-films-gpu.log':'CHAPTER_FILMS_OK','raise-story-films-final.log':'CHAPTER_FILMS_OK','dispersed-native-crafts.log':'NATIVE_CRAFTS_OK','route-wall-coop.log':'LOCAL_COOP_RENDER_OK','route-wall-single.log':'PARTY_GAME_OK'}
def check(path,marker=None):
    text=path.read_text(encoding='utf-8-sig')
    if marker: assert marker in text,(path,marker)
    assert 'SCRIPT ERROR' not in text and 'WARNING:' not in text,path
    assert all(allowed in line for line in text.splitlines() if 'ERROR:' in line),path
    return text
def sha(path):
    with path.open('rb') as stream: return hashlib.file_digest(stream,'sha256').hexdigest()
for name,marker in checks.items():
    check(root/'previews'/name,marker)
    shutil.copy2(root/'previews'/name,release/name)
for label in ['chapter-first','chapter-second','chapter-third','chapter-epilogue']:
    assert 'CHAPTER_FILM_NATURAL_OK '+label in (release/'raise-story-films-gpu.log').read_text(encoding='utf-8-sig')
for name,marker in [('export-console.log',None),('pck-check.log','PLAYTEST_BUNDLE_OK'),('startup.log',None),('shipped-color-gpu.log','COLLECTION_COLOR_EGG_OK'),('shipped-videos-gpu.log','EXPORTED_STORY_VIDEO_OK')]: check(release/name,marker)
assert json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code']==0
latest_runtime=max(p.stat().st_mtime for p in [root/'project.godot',*list((root/'scripts').glob('*.gd')),*list((root/'shaders').glob('*.gdshader')),*list((root/'shaders').glob('*.gdshaderinc'))])
assert (release/'CuanParty.pck').stat().st_mtime>=latest_runtime
old_android=json.loads((release/'安卓版暂缓.json').read_text(encoding='utf-8'))
apk=root/'builds/android-2026-10-21/CuanJingGongSheng.apk'
assert sha(apk)==old_android['existing_apk_sha256'] and apk.stat().st_mtime_ns==old_android['existing_apk_mtime_ns'],'Existing Android release changed despite user deferral'
assert sha(root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
assert sha(root/'assets/interface/parcel_paper.png').upper()=='352D56A350DC0FA9802E7E962F1EEB376A2438BE8BC988B2ED316F990D9CAFA4'
images=['coop-route-wall-detail-before.png','coop-route-wall-detail-after.png','coop-gate-background-detail-before.png','coop-gate-background-detail-after.png','coop-dispersed-fire_basin-world.png','coop-dispersed-tea_jar-world.png','coop-dispersed-flint_pouch-world.png','coop-third-film-before-settling.png','coop-third-film-after-settling.png']
for name in images: shutil.copy2(root/'previews'/name,release/name)
records={'date':'2026-10-21','result':'WINDOWS_ROUTE_ITEMS_COLOR_EGG_OK','checks':checks,'android_generated_this_round':False,'existing_android_unchanged':True,'artifacts':{name:{'bytes':(release/name).stat().st_size,'sha256':sha(release/name)} for name in ['CuanParty.exe','CuanParty.pck']}}
shutil.copy2(root/'assets/rewards/stele_mineral_pigment_20261021.png',release/'彩碑矿物彩绘纹理.png')
shutil.copy2(root/'references/stele-reward-art/生成说明.md',release/'彩绘纹理_生成说明.md')
records['reward_art']={'texture':'彩碑矿物彩绘纹理.png','sha256':sha(release/'彩碑矿物彩绘纹理.png'),'generation':'Built-in image_gen tool, imagegen skill; final prompt in 彩绘纹理_生成说明.md'}
(release/'本轮验证记录.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
note='''# 岩壁、背景、器物寻访与集齐彩碑 · 电脑版

2026-10-21。本轮只生成Windows电脑版，手机版等用户测试本轮后再生成；原有APK未改动。

## 本轮内容

- 旧路岩壁重新做凹凸、断层和侧厚，后移到火把之后，移除旧的重复石块/悬浮箭头；“岩壁·辨认旧路”与交互小牌互相避让。原辨路角色、交互位置与任务时长保留。
- 相邻关卡的远山由重叠面片改成横跨三关的四层连续山体，消除门口重复横纹，昼夜颜色在交界平滑衔接。
- 第三个分幕视频改在真实搬运、合力扶碑动画完成、碑脚落座后播放；第三关直达也先搬与立，再播放。第一、二段仍在对应关卡前，总开场与长卷结尾保留。暂停、跳过、往返不重复与新旅程重置继续可用。
- 火盆分放左廊，茶罐放右廊茶席左边小几，火石布袋放圆窗下、织架前方小几，避开花盆；马帮驮架保留第二关入口。原先普嫫身上难点中的三件微小道具在运行模型中移除，原GLB文件保留。21项收藏、照片、小艺和所属文化说明保持，位置说明与实际点击一同更新。
- 按最新要求，小器物没有常驻名称和未操作时的悬浮标题，交互后阅读及收藏册中主动查看的位置说明仍可用。
- 收齐本轮8个成就后，共庭中央石碑缓缓显出矿物彩绘、细金边、云纹与七色镶点，少量浮光沿碑侧上升。碑文、立体厚度和护碑动作保留。T或新一轮进入游戏清空成就并恢复石色；普通回位/本关重开保留本轮收藏与彩蛋。
- 彩绘石面使用内置image_gen工具和imagegen技能生成的原创纹理，贴回实际碑体；最终提示词和素材见同目录“彩绘纹理_生成说明.md”“彩碑矿物彩绘纹理.png”。它是当代游戏彩蛋效果，不作为历史碑刻原有彩绘的依据。

## 验证与文件

已完成GPU岩壁/灯/字/连续山体检查、真实鼠标点击三件分散器物及其模型/位置标记、21件器物12类小艺、8成就阈值/渐显/暂停/重置、第三段扶碑后触发与直达/自然结束/跳过、完整单双人三关流程。电脑版独立PCK、原生启动、五段视频在成品中实际解码，以及成品包彩碑实机渲染均检查通过。对应原始日志和散列见同目录。本轮未生成新的APK。

双击同目录 CuanParty.exe，保留 CuanParty.pck。根目录两处“开始游戏”最新版入口指向本轮。
'''
(release/'本轮改动与测试.md').write_text(note,encoding='utf-8')
(release/'先看这里_启动与操作.txt').write_text('电脑版：双击 CuanParty.exe，保留同目录 CuanParty.pck。\n本轮只生成电脑版，手机版等待你测试后再生成。\n\n第三段剧情在碑扶正落座后播放。收齐本轮8成就可发现彩碑彩蛋，新一轮恢复石色。\n1P：WASD、空格跳、E操作、F交谈、Tab换人；2P：方向键、小键盘Enter跳、P操作、/交谈、右Shift换人。\nB包裹、C见闻、H帮助、F2暂停档案；R回位保留本轮，T重新开始本轮。\n',encoding='utf-8-sig')
panels=[('岩壁与标题','coop-route-wall-detail-before.png','coop-route-wall-detail-after.png'),('门口背景横纹','coop-gate-background-detail-before.png','coop-gate-background-detail-after.png')]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>爨境共生 · 本轮电脑版画面</title><style>body{margin:0;background:#132027;color:#efdfbd;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:22px;margin-top:32px}img{width:100%;display:block}a{color:#f1c67d}.pair{position:relative}.pair .new{position:absolute;inset:0;clip-path:inset(0 0 0 50%)}input{width:100%;accent-color:#c98b4a}summary{cursor:pointer;font-size:21px}p{color:#c4c9bd}</style><main><h1>爨境·共生 · 电脑版修整</h1><p><a href="CuanParty.exe">启动电脑版</a> · <a href="本轮改动与测试.md">改动与测试说明</a></p><p>这轮只交付电脑版，等你测试后再做手机版。</p>'''
for title,before,after in panels:
    html+=f'<h2>{title}</h2><p>拖动比较：左为修改前，右为修改后。</p><div class="pair"><img src="{before}"><img class="new" src="{after}"></div><input type="range" value="50" min="0" max="100" oninput="this.previousElementSibling.lastElementChild.style.clipPath=\'inset(0 0 0 \'+this.value+\'%)\'">'
for title,name in [('左廊火盆','coop-dispersed-fire_basin-world.png'),('右廊茶罐','coop-dispersed-tea_jar-world.png'),('织架旁布袋','coop-dispersed-flint_pouch-world.png')]: html+=f'<h2>{title}</h2><p>画面中没有常驻器物名称，保留自行探索。</p><img src="{name}">'
html+='''<h2>剧情顺序</h2><p>先搬运 → 合力扶碑 → 碑脚落座 → 第三段视频 → 后续归置；读完并收起长卷后播放结尾视频。</p><details><summary>彩碑彩蛋预览（点击展开，有剧透）</summary><p>以下为导出的电脑版成品包实际渲染。收齐8个成就触发，新一轮恢复石色。</p><img src="shipped-collection-egg-stone-after.png"><p><a href="彩碑矿物彩绘纹理.png">矿物彩绘纹理</a> · <a href="彩绘纹理_生成说明.md">生成方式与最终提示词</a></p></details><p><a href="本轮验证记录.json">检查记录</a></p></main></html>'''
(release/'本轮画面对照.html').write_text(html,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/'岩壁背景修正_分散器物与集齐彩碑_说明.md').write_text(note,encoding='utf-8')
entry='2026-10-21 最新电脑版：旧路岩壁后移重塑，标题/小牌避让、左火把可见；远山接成连续四层消除交界横纹。第三段视频改在真实合抬与扶正落座后；三件小器物分散摆放、移除常驻名称与未阅读的悬浮标题。收齐本轮8成就显彩碑（金边云纹/矿物色/浮光），T及新一轮恢复石色。单双人、21小艺、真实点击、视频顺序、彩蛋、独立PCK/原生启动/成品GPU渲染通过。仅生成电脑版，手机版按用户要求等待试玩后再生成；旧APK未改。'
for path,prefix in [(root/'README.md',''),(root/'AGENTS.md',''),(root.parent/'AGENTS.md','cuan-game/'),(blueprint/'README.md','../cuan-game/'),(blueprint/'四人同行_试玩说明.md','../cuan-game/')]:
    current=path.read_text(encoding='utf-8-sig')
    first,rest=current.split('\n',1)
    path.write_text(first+'\n\n'+('- ' if path.name=='AGENTS.md' else '')+entry+f' 当前 `{prefix}builds/route-wall-film-after-raise-2026-10-21/CuanParty.exe`。下方为历史记录。\n'+rest,encoding='utf-8')
for name in ['startup-test-profile.json','bundle-achievements-profile.json','exported-film-profile.json']:(release/name).unlink(missing_ok=True)
for path in release.glob('*.log.*'):path.unlink()
print('WINDOWS_ROUTE_ITEMS_COLOR_EGG_SEALED')
print(json.dumps(records['artifacts'],ensure_ascii=False))
