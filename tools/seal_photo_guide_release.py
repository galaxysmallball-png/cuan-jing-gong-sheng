"""Record successful tests and point local documentation at this matching build."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/photo-guide-2026-10-18'
previews = root / 'previews'
checks = {
    'photo-guide-gpu-main.log': 'PHOTO_GUIDE_OK',
    'photo-guide-gpu-capture_local_coop.log': 'LOCAL_COOP_RENDER_OK',
    'photo-guide-gpu-capture_garden.log': 'GARDEN_PREVIEW_OK',
    'photo-guide-headless-verify_party_game.log': 'PARTY_GAME_OK',
    'photo-guide-headless-verify_folk_play.log': 'FOLK_PLAY_OK',
    'photo-guide-headless-verify_culture_scroll.log': 'CULTURE_SCROLL_OK',
    'photo-guide-headless-verify_story_sound.log': 'STORY_SOUND_OK',
    'photo-guide-headless-verify_walkway_fixes.log': 'WALKWAY_FIXES_OK',
}
for name, marker in checks.items():
    log = (previews / name).read_text(encoding='utf-8')
    assert marker in log and 'ERROR:' not in log and 'SCRIPT ERROR:' not in log, name
    shutil.copy2(previews / name, release / name)
for name in ['export-console.log', 'pck-check.log', 'startup.log']:
    log = (release / name).read_text(encoding='utf-8')
    assert 'Godot Engine' in log and 'ERROR:' not in log, name
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['all_21_cultural_items_18_photos_supplied_cover_and_tapered_waterfall_verified']
assert bundle['sound_entry_large_plaques_and_walkway_verified']
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
shots = {
    'coop-photo-guide-first-start.png': '第一关_四人分享与双人按钮.png',
    'coop-photo-guide-first-clues-ready.png': '第一关_线索齐备与归位指引.png',
    'coop-photo-guide-first-correction.png': '第一关_具体指出错误方向.png',
    'coop-photo-guide-object-bai_tiedye.png': '白族扎染_可切换实物照片.png',
    'coop-photo-guide-object-dai_brocade.png': '傣锦_馆藏实物照片.png',
    'coop-photo-guide-object-cloth_loom.png': '织机_实拍与来源.png',
    'coop-photo-guide-scroll-cover.png': '共生长卷_用户新图封面.png',
    'coop-photo-guide-scroll-final-mural.png': '共生长卷_保留原四幅画面.png',
    'coop-photo-guide-tapered-waterfall.png': '溪谷瀑布_上窄下宽.png',
}
for source, destination in shots.items():
    shutil.copy2(previews / source, release / destination)

description = '''# 实物照片、第一关指引与共生长卷封面

2026-10-18。启动项目根“开始游戏（最新版）”，或 `cuan-game/builds/photo-guide-2026-10-18/CuanParty.exe`。EXE 与同目录 PCK 一起保留。

瀑布从等宽平面改为随落差展开的网格：顶部约 0.18 米、底部约 1.35 米，下方加散开的水雾与泡沫。溪谷原有水面、绕石水纹和近水声仍保留。

共生长卷新增卷首封面，直接使用本轮图二（ff8a7c2a…png）。金木卷轴包住完整花卉边框，中央排“共生长卷”、副题与展卷提示；点“展卷共读”或 Enter 后，从原第一幅开始阅读四幅画面。末幅仍停留等玩家读完，亮背景上的正文保持深色承托。

第一关分四步：寻到小碑、四人交流、六字归位、开门出院。大爨碑标为选看对照，关闭后回小碑继续主线。顶部显示当前步骤与缺少的角色；底部两张卡分别显示每位玩家控制的人物、分享状态、长按百分比和专属换人按钮。可用原键位，也可鼠标长按按钮分享、点击换人。共享任务仍需四人各完成一次，换人仍受各自角色归属约束。字卡始终显示朝向箭头，槽位始终编号；拿字时提示 Q/右键转向，放齐后具体指出第几格次序或方向错误。错误卡可取回重放。查看碑面时收起重复的场景任务栏，让当前步骤、两位玩家进度和人物半身像对白各占独立位置。

21 类特色物件全部加入实物照片切换，18 张照片随资源包离线携带。点“实物照片·切换查看”显示照片，点“回到三维·拖动转看”恢复模型；驮架、苗族蜡染、共饮茶具等组合可再点“下一张”。照片下方可看实拍对象、作者、来源和授权。白族扎染、苗族蜡染、傣锦有对应实物图；通用竹篮、木作、火具、锄、錾子、马铃等按工艺或器型提供参照。美国驮鞍、孟加拉国柴刀、越南馆藏背婴布、其他年代的工具等均写明地区或对照用途，不充当剧中民族原物。完整条目在 `assets/references/folk/CREDITS.md` 和构建目录《实物照片_来源与授权.md》。原始网络元数据与下载记录保存在 references/folk-photos-2026-10-18。

验证包括真实显卡绘制及输入注入：第一关大小碑分流、两位玩家独立鼠标长按/键盘分享与换人、四线索转入归位、具体纠错和开门；21 类物件逐个切实拍/三维、有多图时翻图、署名不裁切；新封面接回原四幅；上窄下宽网格。另完成双人三关 GPU 流程、共庭 GPU 流程，以及单人、声音与长按、器物小艺、文化介绍/长卷、四桥角安全通行和跟随地面绕行检查。所有检查逐项完成；独立导出 PCK 检查全部照片、图二封面、旧牌匾/右上声音/桥面与石碑交接，原生 Windows 程序无界面启动正常。具体日志、截图和哈希见同目录《验证记录.json》。自动输入检查与启动检查不代表已经由其他同学完整试玩。

主要改动：scene_atmosphere.gd、waterfall.gdshader、garden_art.gd、glyph_puzzle.gd、stele_inspector.gd、story_dialogue.gd、party_ui.gd、world.gd、folk_collection.gd、照片目录与导出包含规则。工具 verify_photo_guide.gd 负责新增专项；旧长卷检查适配卷首，文化检查补齐现有第五块牌匾。修改前脚本备份在 backups/before-photo-guide-2026-10-18；原人物 Blender/GLB 与用户图片源文件保留。
'''
blueprint = root.parent / 'cuan-game-blueprint'
note_name = '实物照片_第一关指引与长卷封面_说明.md'
(blueprint / note_name).write_text(description, encoding='utf-8')
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')

entry = ('2026-10-18 最新实物图与关卡指引：瀑布改上窄下宽并加落水雾；共生长卷用本轮花卉图做卷首，展卷后保留原四画。第一关明确小碑主线/大碑选看、四步目标、两位玩家长按百分比与专属换人按钮、字卡箭头/编号和具体纠错，碑面中重复任务栏收起。21 类特色物件全部可切实物照片/三维，18 张离线图及作者/来源/授权，跨地区器型明示对照。新增专项 GPU、完整双人/共庭 GPU 与单人/器物音效/文化/桥面回归、独立 PCK 和原生启动均通过。当前 `builds/photo-guide-2026-10-18/CuanParty.exe`，根最新版快捷方式同步。见 [本轮说明](../cuan-game-blueprint/'+note_name+')。下方为历史记录。')
targets = [root/'README.md', root/'制作记录.md', root/'AGENTS.md', root.parent/'AGENTS.md', blueprint/'README.md', blueprint/'四人同行_试玩说明.md']
for path in targets:
    content = path.read_text(encoding='utf-8-sig')
    if '2026-10-18 最新实物图与关卡指引：' in content:
        continue
    first, rest = content.split('\n', 1)
    text = entry
    if path.name == 'AGENTS.md':
        text = '- '+text
    if path.parent == blueprint:
        text = text.replace('`builds/photo-guide-', '`../cuan-game/builds/photo-guide-').replace('../cuan-game-blueprint/'+note_name, './'+note_name)
    elif path == root.parent/'AGENTS.md':
        text = text.replace('../cuan-game-blueprint/'+note_name, 'cuan-game-blueprint/'+note_name)
    path.write_text(first+'\n\n'+text+'\n'+rest, encoding='utf-8')

files = {}
for name in ['CuanParty.exe','CuanParty.pck','实物照片_来源与授权.md','实物照片目录.json',*shots.values()]:
    p = release/name
    files[name] = dict(bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest())
record = dict(result='PHOTO_GUIDE_RELEASE_VERIFIED', date='2026-10-18', checks=checks, bundle=bundle,
              native_startup=startup,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',
              files=files, coverage='GPU 实际渲染、注入鼠标/键盘及逐对象切图；无界面原生启动另检。未以此代称人工试玩完成。')
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('PHOTO_GUIDE_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'GPU screenshots')
