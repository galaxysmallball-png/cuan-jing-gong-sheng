from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/craft-polish-2026-10-19'
previews=root/'previews'
checks={
    'craft-polish-gpu.log':'CRAFT_POLISH_OK',
    'craft-stories-gpu.log':'FOLK_STORIES_CUAN_OK',
    'craft-culture-gpu.log':'CULTURE_SCROLL_OK',
    'craft-story-gpu.log':'STORY_SOUND_OK',
    'craft-achievements-gpu.log':'ACHIEVEMENT_BOOK_OK',
    'craft-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
    'craft-planar-gpu.log':'PLANAR_TRANSPORT_OK',
    'craft-satchel-gpu.log':'FIELD_SATCHEL_OK',
    'craft-photo-gpu.log':'PHOTO_GUIDE_OK',
    'craft-single.log':'PARTY_GAME_OK',
}
environment='ERROR: Failed to read the root certificate store.'


def verify_log(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line]
    assert all(line==environment for line in errors),(path,errors)


for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
verify_log(previews/'craft-single-stdout.log','PARTY_GAME_OK')
shutil.copy2(previews/'craft-single-stdout.log',release/'craft-single-stdout.log')
for name in ['export-console.log','pck-check.log','startup.log']:
    verify_log(release/name,'Godot Engine')
verify_log(release/'pck-stdout.log','PLAYTEST_BUNDLE_OK')
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['larger_text_woven_crafts_curved_waterfall_stone_arrival_and_bird_paper_receipts_verified']
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font=root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf'
font_sha=hashlib.sha256(font.read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
sources=json.loads((root/'assets/interface/SOURCE.json').read_text(encoding='utf-8'))
notice=next(item for item in sources if item['file']=='notice_bird_paper.png')
assert hashlib.sha256((root/'assets/interface/notice_bird_paper.png').read_bytes()).hexdigest()==notice['sha256']
shots={
    'coop-folk-stories-weight-caravan_pack.png':'驮架配重_货包木秤与吊筐.png',
    'coop-folk-stories-finished-dai_brocade.png':'锦纹相映_织纹卡片.png',
    'coop-craft-indigo-motifs.png':'蓝底纹样_开始界面.png',
    'coop-craft-cargo-balance.png':'配重_点击换边.png',
    'coop-craft-curved-waterfall.png':'岩缝起瀑_向左弯落.png',
    'coop-craft-stone-enters.png':'运碑衔接_随木橇进院.png',
    'coop-craft-stone-ready-to-lift.png':'运碑衔接_等待合力扶正.png',
    'coop-craft-clue-receipt.png':'线索通知_花鸟按钮.png',
    'coop-craft-achievement-receipt.png':'成就通知_花鸟按钮.png',
    'coop-achievements-bai-collected-photo.png':'成就册_放大字体与实物署名.png',
    'coop-culture-person-1.png':'人物小传_放大爨体.png',
}
for source,destination in shots.items(): shutil.copy2(previews/source,release/destination)
note='爨体放大_织纹配重与送碑入院_说明.md'
description='''# 爨体放大、器物小艺美化与送碑入院

2026-10-19。项目根“开始游戏（最新版）”及“开始游戏（八牌入场版）”进入 `cuan-game/builds/craft-polish-2026-10-19/CuanParty.exe`。EXE与PCK保留同目录。

可排版的游戏文字整体按1.16倍计算字号，覆盖正文、按钮、文化/小传、对白、包裹、成就、提示、小游戏与三维指示。保留爨体和标题轻微增重；牌匾通过字面占比扩大、保持在框内。调整紧凑对白高度和成就册照片/署名分区，文化四页、八位小传、长卷、21件物品说明及实物署名检查通过。原始用户图片、拓片照片和字库文件未改。

纹样小艺改为有织线、缝边与清楚明暗反馈的靛蓝/赭红布片，菱形、花叶、回旋纹均重画。步骤圆点与完成数展示当前进度，整块卡片都能点击。配重改为绑绳货包、编号、左右筐标记、木秤支座和编织吊筐；秤杆随两边重量倾斜，选中货包改变颜色，悬停轻抬并显示手形指针。应声与顺序准备也采用一致的卡片样式。仍保留21件物品各自的人物故事、开始门、独特题目和重试；六组配重均可解，不代做主线。

瀑布保留上细下宽，中心线沿下落逐渐向左偏移0.95米；顶端藏在连续岩壁的窄缝及两侧岩唇中，补出暗色出水口，落水雾移到新的落点。使用原生三维网格与既有水流材质，没有增加场景行走碰撞。

第三关在第二关交接前不显示碑与运输橇。第二关原运输碑隐藏后，同一叙事碑从溪桥侧随木橇进入庭院，约3.2秒落到院中碑座；此刻所往显示送入进度，等到达后才允许石阿朵与同伴合力扶正。暂停会停止移动，回桥不重生运输碑；重开第二关清掉交接和第三关碑，重开第三关重演入院过程，保留此前主线与永久收藏。

新花鸟原图保存为assets/interface/notice_bird_paper.png，来源及SHA256在SOURCE.json。成就与线索通知的纸面、可点击的“翻看成就/C”和“查看包裹/B”按钮、成就册操作按钮及收起包裹按钮使用该图；包裹内部线索卡仍保留原花卉纸。看碑时的线索通知缩窄，避开关闭按钮；成就与线索同时出现时上下错开。相关按钮真实输入与暂停返回已检查。

验证包含：新专项真实显卡检查、21件故事与小艺逐件点击、文化/长卷、半身像对白与声音、21类实物照片切换、成就册21物与八成就、包裹、完整双人三关、四向移动/桥栏/重复返回/重开生命周期，以及单人三关与重开。单人快速测试在销毁场景前停止测试音频并等待混音线程清理，避免Dummy驱动在退出时留下尚未回收的播放引用；游戏音频行为未改。独立导出PCK核对文字放大、重画的小艺、花鸟按钮、瀑布曲线与送碑动画，Windows原生启动退出码0。

日志原样保留既有Godot系统根证书读取环境诊断，未忽略其他错误，未改系统证书或网络。测试收藏使用独立文件，未覆盖玩家收藏。截图、校验和与日志见验证记录.json。自动输入及画面检查不等于同学的人工试玩反馈。

保留2026-10-19场景合批/材质分离及第三幕中轴X50，原模型、图片与旧可运行目录均保留。修改前备份backups/before-craft-polish-2026-10-19。本轮更新可运行目录及最新版入口。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新字体放大与小艺美化：爨体约放大16%，调整对白/成就署名排版；纹样为织纹卡，配重为绑绳货包/木秤/吊筐，四种小艺风格统一且21题保留。瀑布从连续岩缝上细下宽向左弯落。第三关交接前空碑座，第二关交接后碑随橇入院3.2秒、暂停冻结、到位才可扶正，回桥不重生。用户花鸟图用于成就/线索通知和相关按钮，实际点击能进成就/包裹。十项GPU/单人回归、独立PCK和原生启动通过；保留今日中轴X50及场景优化。当前 `builds/craft-polish-2026-10-19/CuanParty.exe`，根最新版入口同步。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    text=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新字体放大与小艺美化：' in text: continue
    first,rest=text.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/craft-polish-','`../cuan-game/builds/craft-polish-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    path=release/name
    files[name]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
record=dict(result='CRAFT_POLISH_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,
            font_sha256=font_sha,notice_source=notice,text_scale=1.16,files=files,
            renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',environment_diagnostic=environment)
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('CRAFT_POLISH_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
