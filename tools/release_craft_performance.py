from pathlib import Path
import hashlib
import json
import shutil
import sys

root = Path(__file__).resolve().parents[1]
previous = 'builds/interface-guide-2026-10-20'
current = 'builds/craft-performance-2026-10-20'
release = root / current
backup = root / 'backups/before-clean-hud-pier-2026-10-20'
environment = 'ERROR: Failed to read the root certificate store.'

if '--prepare' in sys.argv:
    release.mkdir(parents=True, exist_ok=True)
    (release / '.gdignore').touch()
    for name in ['资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
        shutil.copy2(root / previous / name, release / name)
    for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
        path = root.parent.parent / name
        if path.exists() and not (backup / name).exists(): shutil.copy2(path, backup / name)
    export = (root / 'tools/export_interface_guide_release.ps1').read_text(encoding='utf-8-sig')
    (root / 'tools/export_craft_performance_release.ps1').write_text(export.replace(previous, current), encoding='utf-8-sig')
    path = root / 'export_presets.cfg'
    path.write_text(path.read_text(encoding='utf8').replace(previous, current), encoding='utf8')
    print('CRAFT_PERFORMANCE_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
checks = {
    'court-performance-native-crafts-gpu.log': 'NATIVE_CRAFTS_OK',
    'court-performance-clean-hud-gpu.log': 'CLEAN_HUD_PIER_OK',
    'court-performance-gpu.log': 'COURT_PERFORMANCE_OK',
    'court-performance-carried-gpu.log': 'CARRIED_ARRIVAL_OK',
    'court-performance-cooperation-gpu.log': 'COOPERATIVE_EXPERIENCE_OK',
    'court-performance-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
    'court-performance-single.log': 'PARTY_GAME_OK',
}


def verify_log(path, marker):
    contents = path.read_text(encoding='utf-8-sig')
    assert marker in contents, (path, marker)
    diagnostics = [line for line in contents.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(root / 'previews' / name, marker)
    shutil.copy2(root / 'previews' / name, release / name)
verify_log(root / 'previews/court-performance-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'), ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf8'))
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
audio = json.loads((root / 'assets/audio/folk_cues_20261020/SOURCE.json').read_text(encoding='utf8'))
assert len(audio['effects']) == 24 and audio['scroll_track']['transpose_semitones'] == 2
assert audio['scroll_track']['bpm'] == 126
for item in audio['effects'] + [audio['scroll_track']]:
    assert item['peak_dbfs'] < -3 and item['rms_dbfs'] > -35
    path = root / 'assets/audio/folk_cues_20261020' / item['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256']
(release / '原创音效与长卷音乐_来源与校验.json').write_text(json.dumps(audio, ensure_ascii=False, indent=2), encoding='utf8')
shots = {
    'coop-refine-performance-four-people-raising.png': '四人合力扶碑.png',
    'coop-refine-performance-crafted-stele-alcove.png': '碑座与保护架细节.png',
    'coop-performance-slower-four-person-carry.png': '放慢四人合抬.png',
    'coop-native-craft-finished-bai_tiedye.png': '小艺_扎结染布拆线.png',
    'coop-native-craft-finished-miao_batik.png': '小艺_描蜡浸染显花.png',
    'coop-native-craft-finished-dai_brocade.png': '小艺_往复引梭织锦.png',
    'coop-native-craft-finished-a_cai_hoe.png': '小艺_转沟引水入畦.png',
    'coop-native-craft-finished-a_qiang_beam.png': '小艺_旋转拖合榫卯.png',
    'coop-native-locate-baby_carrier.png': '收藏册_明确物件位置与标记.png',
    'coop-native-pumo-click-tea_jar.png': '黑陶茶罐_独立模型与故事.png',
    'coop-native-court-guest-a_cai_hoe.png': '第三关阿彩_锄头可补访.png',
    'coop-refine-clean-villagers-front-of-goods.png': '村民在物件前方.png',
    'coop-clean-small-centered-work-progress.png': '右下小型居中进度.png',
    'coop-clean-first-person-chisel.png': '本人拾物第一人称.png',
}
for source, target in shots.items(): shutil.copy2(root / 'previews' / source, release / target)

note = '器物小艺重做_寻访定位_抬碑音画与精简界面_说明.md'
description = '''# 器物小艺、寻访与抬碑音画 · 2026-10-20

导出：builds/craft-performance-2026-10-20，根目录两个“开始游戏”入口同步。EXE/PCK放在同一目录，本轮不新增ZIP。备份：backups/before-clean-hud-pier-2026-10-20。

21件器物保留实物照片切换、人物故事与每件完成记录，14件小艺改用新的动作机制；全体从原4类扩为12类玩法。不是只换配重数字或按钮名称。扎染要在素布三处扎结、按住入染、逐处拆线；蜡染按住并沿轮廓描蜡，偏离要重画，再入染与脱蜡；农具小游戏旋转沟段使溪水绕石流入田畦；竹编、织锦、织带选样带颜色并来回拖梭，几组样带不同；背布拖两侧系带到适中再稳住试背；木梁旋转、拖入卯口并压销；茶具先控制温茶再给三杯斟到各自刻线，两套茶具刻线不同；红线交叉绕柱、穿回绳圈后收紧；火石需择时击火星，再收放风量护炭、传火三灯，火盆直接从护炭开始。保留三套不同货担配重、檐下马铃只听不亮答案及少量工具整理。共21件均有实际鼠标完成检查，重试回人物故事，小游戏不会代做主线。

这些小艺是艺术化的短体验，非完整工艺教学、育儿指导或历史场景复原。竹编、农具、榫卯、茶席、绳结等共用器物按剧中人物归档，不暗示某民族独有。故事用阿彩与阿朵对照留白、玉喃与众人共同配色、阿强与石匠接梁、普嫫向同行分茶传灯体现交流。扎染与蜡染的留白原理和工艺次序参考：[白族扎染技艺·云南非遗网](https://www.ynich.cn/item/148.html)、[苗族蜡染工坊·中国非遗网](https://www.ihchina.cn/news_1_details/26903.html)；织锦背景参考[傣族织锦技艺·中国非遗网](https://www.ihchina.cn/project_details/14495.html)。未下载网页图片或传统录音。

器物说明与小艺分区，去重复的小艺副标题，说明放在独立可滚动区域，文字不会被下方游戏盖住。爨体字号与标题轻微增重保留。阿彩锄头新增厚刃、颈部、套口、木柄与绑缠，原GLB不改；抬碑时锄头立在她身侧。竹篓、背布、刀鞘、茶罐、火盆、布袋、锦带等点击框跟随实际骨骼，鼠标按精确投影优先选物件，不把点击工具误当点脸交谈。随身器物观察时单独放大该器物，实物照片及来源入口保留。

收藏册全部21件均补具体地点；阿彩、阿强未到场、桥头护送和已送碑入院有不同说明；四物归位后第三关左廊/右廊的两位村民也接通同一套物件交互，五个补访入口仍只计原21件。未见物件写清所属人物、身体部位和任务前提，不再只写“在对应场景点击”。已收录和未收录都能“标记位置”，返回场景在实物处显示小标记，追随物件移动；标记不传送、不代收录，不会跳过联络/归位前提。阿彩三件在她肩/身侧、腰篓和背部；普嫫的罐、盆、袋分别在手边和腰侧；马帮驮架在第二关入口、旧桥基左侧。附近仍可用G/句号轮选、F/斜杠查看。新旅程清除标记与本轮成就。

第三关四名实际角色抬碑入院从3.2秒放慢到6.4秒，行走步频按真实速度同步。最后4.8秒由两人靠前扶碑、两人向后收绳，手部动作与八条手绳跟随真实骨架，碑脚缓转入座；结束恢复物理和控制，暂停、R回出生点与T新旅程覆盖中途清理。碑亭增加多层台座、边栏、侧格栅、承檐连接、工具托盘和保护架细节，不增加新的行走障碍。

17个交互短音与7个长按音换成原创竹木打击、拨弦、清亮铃音，替掉低沉摩擦/嗡响；溪流底音和原三幕音乐保留。场景长卷展开与长卷阅读时渐入升高两个半音、126BPM的庆典编曲（原终幕116BPM），场景长卷仍展开时保持庆典，新旅程与关卡重开回到对应场景音乐；音量、静音和渐变保留。新音频为原创合成的民乐音色，没有把它称作某民族传统曲目或实地录音。PCM峰值低于-3dBFS，清单附SHA256。测试使用Dummy音频，不代替玩家实际听感。

前一轮截图问题一起完成：获得线索/物件/成就通知去“按B/C查看”；删除顶部三关路线、闲置下一步卡和直接切角色按钮；只有正在实际长按操作时，右下显示小型居中进度。字卡拿起后再点空白可放回，点凹槽可放入，拖放和缩放查看保留。四位本人拾物对白用第一人称。桥墩补行走及跳跃阻挡，仍能砌墩并从前方通行；两位村民从货物前方接近、停留，再沿桥面前侧护送。

验证包含：NVIDIA实机21件小艺逐件实际鼠标操作/错误路线/重试/记录/实物图；阿彩三物与普嫫三物的实体点击、收藏册定位回场景及重置；精简UI、字卡第二次点击和缩放；桥墩实际行走/跳跃与村民前行；四人抬碑、扶碑手部与绳索、暂停/R/T恢复；实际长卷升调编曲切换；完整双人与单人三关、合作主线专项、独立PCK及原生Windows启动。只允许本机既有根证书读取诊断，其余脚本错误、警告和泄漏会阻止封包。原人物源工程、GLB、用户原图、字库保持。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf8')
guide = '''《爨境·共生》器物小艺与抬碑音画版（2026-10-20）

双击 CuanParty.exe，EXE 与 PCK 保持同一目录；也可用工程根目录的“开始游戏（最新版）”。
1P：WASD移动，空格跳，E操作，Tab换角色；2P：方向键移动，小键盘Enter跳，P/小键盘0操作，右Shift换角色。
B包裹，C共生见闻成就，H帮助，F2暂停，R回出生点保留进度，T重走旅程并清本轮收藏。
第一关先点击小爨碑传拓，再四人合读和六字归位；鼠标字卡再点空白放回、点凹槽放入，Q/右键旋转。
沿途随身物件须本人拾取：书年的拓片与阿朵的錾子在第一关，老箐的马铃、三娘的红线在第二关。
第二关备木、识路、砌墩、联络村民、架桥护碑；护碑时阿朵顶碑、老箐收放绳，不要一直拉紧。
第三关等四人合抬入院，再共同扶正；四物归位后共同布置、分送三灯并共看长卷。
器物小艺：按鼠标实际扎结染布、描蜡、转接水沟、引梭、调带、榫卯、斟茶、绕绳与护火，界面逐步说明。听音玩法只听不亮答案，可再听；可重试，完成小艺不代做主线。
物件难找：C打开收藏册，点器物卡看具体位置，再点“标记位置”返回场景。标记跟随实物；未到场/未归位的物件先完成对应任务。G/句号轮选附近物件，F/斜杠查看。
阿彩的锄头、腰篓、背布在第二关她身上，抬碑时锄头立在身侧；入院后也可回第二关桥右岸、城门外补看；四物归位后，还能直接查看第三关左廊阿彩、右廊阿强身上的物件。普嫫的黑陶罐、火盆、布袋在第三关她的手边/腰侧；马帮驮架在第二关入口、旧桥基左侧。
每件可切换实物照片与三维查看。右上声音设置分别调音乐与交互音效。
'''
(release / '先看这里_启动与操作.txt').write_text(guide, encoding='utf8')
with (release / '资料与鸣谢.txt').open('a', encoding='utf8') as out:
    out.write('\n本轮原创音频：tools/compose_clear_folk_audio.py；来源与校验见原创音效与长卷音乐_来源与校验.json。无外部音频采样。工艺参考链接见本轮改动与验证.md。\n')
entry = ('2026-10-20 最新器物小艺与抬碑音画：21物件扩为12类玩法，14件按扎染/描蜡/引梭/理沟/托背/榫卯/斟茶/结绳/护火重做，保留故事/实物图/逐件记录。说明独立滚动不遮字，锄头细化、随身点击跟骨骼，单独放大器物，收藏册21件具体位置与标记。删除三关路线/闲置大卡/直接切人，实际长按右下小进度；字卡二次点击放回，拾物第一人称，桥墩真阻挡/村民前行。四人入院6.4秒、实际四人扶碑4.8秒，碑亭细化；24个原创清亮交互/长按音，长卷另升两半音126BPM庆典编曲。新12玩法逐21件GPU、定位点击与UI/桥墩/抬碑/主线专项、完整单双人、独立PCK及原生启动通过。当前 `'+current+'/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md', blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新器物小艺与抬碑音画：' in text: continue
    target = backup / 'docs' / (path.parent.name + '-' + path.name)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists(): shutil.copy2(path, target)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/', '`../cuan-game/builds/').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md': paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
(release / '验证记录.json').write_text(json.dumps(dict(result='CRAFT_PERFORMANCE_RELEASE_VERIFIED', date='2026-10-20',
    checks=checks, bundle=bundle, native_startup=startup, audio=audio, font_sha256=font_sha, files=files,
    environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']: (release / name).unlink(missing_ok=True)
print('CRAFT_PERFORMANCE_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
