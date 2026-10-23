"""Document supplied UI art, native scene details and the local release. No ZIP."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

PROJECT = Path(__file__).resolve().parents[1]
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
RELEASE = PROJECT / 'builds/world-detail-sound-2026-10-18'
TITLE = '按钮底图_场景细节与动态音效_说明.md'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepend(path, note):
    text = path.read_text(encoding='utf-8-sig')
    if note in text:
        return
    head, body = text.split('\n', 1)
    path.write_text(head + '\n\n' + note + '\n' + body, encoding='utf8')


def prepare():
    source_file = PROJECT / 'assets/interface/SOURCE.json'
    records = json.loads(source_file.read_text(encoding='utf8'))
    for filename, original, use in [
        ('title_button_paper.png', '0cb7ce86-c38b-4311-91b6-e6ee8b495c1b.png', '进入界面按钮背景'),
        ('game_button_paper.png', '32c9be7b-078a-4b3a-9b04-3546cb9362d0.png', '游戏按钮、展开的操作提示及附近物件阅读框背景')]:
        source = Path('C:/Users/26845/Desktop/树莓比赛美工/按钮和提示框背景') / original
        target = PROJECT / 'assets/interface' / filename
        assert source.read_bytes() == target.read_bytes()
        records = [entry for entry in records if entry['file'] != filename]
        records.append({'file': filename, 'source': str(source), 'sha256': sha(target), 'use': use, 'altered': False,
                        'rendering': 'Original image scaled by native Godot UI; no bitmap editing'})
    source_file.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf8')
    note = '''# 按钮底图、场景细节与动态音效

2026-10-18，当前可运行版本：`../cuan-game/builds/world-detail-sound-2026-10-18/CuanParty.exe`。根目录“开始游戏（最新版）”指向此版本。按用户要求不创建压缩包，前版保留。

第一张梅竹双鹤纸图用于封面按钮；第二张回纹祥云纸图用于游戏按钮、点开“提示”后的操作界面，以及展开的物件阅读框。两张原图逐字节复制，运行时缩放，SHA256和原路径在 `assets/interface/SOURCE.json`。操作提示重新留出装饰边距，原半身像对白纸底、左下任务面板和左上关卡编号保留。

音效有独立的“音效·开/关”按钮，封面、游戏内与操作提示里可见，也可在所有界面按 N 切换。它控制按钮、翻牌、物件、跳跃、长按任务和溪流，原 M/“乐声”只控制配乐，两者互不影响。开启音效后，仍在有效操作中的工作声和附近水声可恢复；重开当前关保留声音偏好并清除旧任务声。

所有按钮共用按下音效，新增按钮也自动接入；键盘翻阅与关闭阅读页也有轻提示。八牌环转经过牌位时有纸牌掠动声，抽中及最终展示有收束提示，掠过、重看与单人入场沿用原规则。跳跃音效只在角色实际从地面起跳时触发，音量比普通物件声低10 dB，空中重复按键不会叠加声音。

长按音效由有效任务状态驱动，不靠按键机械重复：识字用纸声，备木/推橇/架桥用木声，察看桥基/砌墩/顶碑/立碑用石声，牵引与系线用绳声，灯火和其他物品各依材质。两条工作音轨可同时播放不同任务声；松手、停下有效工作、暂停、切入长卷或重开关卡时停止，不改变1.6秒合作条件。

溪流声取两位人类玩家里离溪岸较近者的距离渐变，约离河道9米外无声，接近溪岸逐渐增强；一人靠近也能听见。暂停和阅读时停下，音效开关关闭时立即停止。不会因跟随者留在河边而始终有水声。全部新增声音为程序合成，无外部录音、歌曲或采样；`assets/audio/interactions/ACTION_SOURCE.json`记录12个新增音频的时长、SHA256、声道、峰值、RMS和循环属性，生成入口 `tools/compose_action_audio.py`。

三幕新增八组可直接看见、可以靠近察看的器物：蓝白扎染布架、货郎竹筐与小秤、竹筒书卷与拓包、马帮木驮架与披毡、阿彩花布与竹筐、玉喃织锦布架、围火茶席与黑陶罐、锦布织架与线团。原64处目标增加为72处登记目标，施工时暂收起的道具仍不留下空提示。各组包含布纹、流苏、编筐横竖编条、布卷卷芯、秤盘悬绳、驮架捆带与铜铃、茶碗和织架经线等立体细节，均为Godot原生几何和着色器，不依赖文字冒充实物。保持原行走通道、碰撞与角色模型。

旧路岩壁改为约2.8米宽、2.65米高的缺角石面，刻槽带暗部和磨亮边、三处马蹄形磨痕、细碎凿痕与下方补石，路面补上两道磨损带。它是虚构关卡里的路线证据，不冒称真实碑文或考古遗迹。原“岩壁旧路刻痕”靠近目标、辨路任务位置和解谜条件不变。

织物花样是艺术化表现，图案与生活用具参考用户人物设定，并查阅：[云南非物质文化遗产保护网·白族扎染技艺](https://www.ynich.cn/item/148.html)、[中国非物质文化遗产网·大理周城白族的扎染工艺](https://www.ihchina.cn/news_1_details/11139.html)、[中国非物质文化遗产网·傣族织锦](https://www.ihchina.cn/project_details/11358/)。蓝白花纹和孔雀意象用于呈现不同手艺在行旅中相遇；物件不代表某一民族所有人的生活，也不作具体古代器物的测绘复原。

验证包括：真实点击按钮、环转/抽中牌音、实际起跳、八组实物的靠近交互、新纸底、两名玩家距离水声、暂停时N开关、长按木料与双人扶碑持续声、松手/暂停/重开取消、M与N独立。完整双人三幕与第三关显卡回归、全部72目标遍历（当前施工可见70）、八牌自然播放/掠过/单人、12种角色归属、单人三幕、旧指引和半身像对白检查通过。截图和状态测试使用Dummy音频驱动；音频信号和播放状态已检查，实际听感仍由试玩确认。
'''
    (BLUEPRINT / TITLE).write_text(note, encoding='utf8')
    summary = '2026-10-18 最新按钮与场景音效：封面按钮用新梅竹双鹤图，游戏按钮/展开提示用新回纹祥云图。独立“音效”按钮/N控制操作与溪流，M仍控制配乐；新增按钮、环转与抽中牌、轻微起跳声，有效长按任务持续工作声，松手/暂停/重开即停，靠近溪流按两位玩家中较近者渐变。八组原生立体生活器物与互动新增至72目标，旧路改大幅缺角石面、清晰凿槽/马蹄磨痕/补石和路辙。人物模型、三幕合作和左下任务保留。当前 `builds/world-detail-sound-2026-10-18/CuanParty.exe`，根最新快捷方式直达；不创建压缩包。详见 [本轮说明](../cuan-game-blueprint/' + TITLE + ')。下方为历史记录。'
    for path in [PROJECT / 'README.md', PROJECT / '制作记录.md']:
        prepend(path, summary)
    for path in [BLUEPRINT / 'README.md', BLUEPRINT / '四人同行_试玩说明.md']:
        prepend(path, summary.replace('`builds/', '`../cuan-game/builds/').replace('../cuan-game-blueprint/', './'))
    for path in [PROJECT / 'AGENTS.md', PROJECT.parent / 'AGENTS.md']:
        prepend(path, '- ' + summary + ' 入口interaction_audio.gd为PROCESS_ALWAYS，动态Button信号钩子；continuous有pause/game/record/muted保护；cultural_scene_details.gd+trade_textile.gdshader不改旧模型/碰撞。原音频不重生，新增ACTION_SOURCE.json；备份为普通目录before-world-detail-sound-2026-10-18，未作ZIP。')
    audio_note = PROJECT / 'assets/audio/配乐来源.md'
    prepend(audio_note, '2026-10-18 新增按钮/翻牌/轻跳/溪流及七种长按工作声，12个附加音频由 `tools/compose_action_audio.py` 程序合成，无第三方录音。参数见 `interactions/ACTION_SOURCE.json`。原四曲配乐与此前12种物件音效保留；N只控制音效，M只控制配乐。')
    print('WORLD_DETAIL_DOCUMENTATION_OK')


def finalize():
    logs = {
        'world-detail-check-gpu.log': ['WORLD_DETAIL_SOUND_OK', 'NVIDIA'],
        'world-detail-capture_local_coop.log': ['LOCAL_COOP_OK', 'LOCAL_COOP_RENDER_OK', 'NVIDIA'],
        'world-detail-capture_garden.log': ['GARDEN_PREVIEW_OK', 'NVIDIA'],
        'world-detail-verify_nearby_interactions.log': ['NEARBY_INTERACTIONS_OK', 'reachable props=70'],
        'world-detail-verify_opening_draw.log': ['OPENING_DRAW_OK'],
        'world-detail-verify_interface_pairs.log': ['INTERFACE_PAIRS_OK'],
        'world-detail-verify_party_game.log': ['PARTY_GAME_OK'],
        'world-detail-verify_journey_polish.log': ['JOURNEY_POLISH_OK'],
        'world-detail-verify_story_sound.log': ['STORY_SOUND_OK'],
    }
    for name, markers in logs.items():
        source = PROJECT / 'previews' / name
        text = source.read_text(encoding='utf-8-sig')
        assert all(marker in text for marker in markers), name
        assert not any(error in text for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
        shutil.copy2(source, RELEASE / name)
    for name in ['startup.log', 'pck-check.log', 'export-console.log']:
        text = (RELEASE / name).read_text(encoding='utf-8-sig')
        assert not any(error in text for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
    assert 'Godot Engine' in (RELEASE / 'startup.log').read_text(encoding='utf8')
    assert 'PLAYTEST_BUNDLE_OK' in (RELEASE / 'pck-check.log').read_text(encoding='utf8')
    for name, target in [('details-title-buttons', '封面按钮.png'), ('details-card-turn', '翻牌.png'),
                         ('details-help-background', '操作提示新底图.png'), ('details-dyed-cloth-and-trade', '扎染布与货郎竹筐.png'),
                         ('details-route-grooves', '岩壁旧路刻痕.png'), ('details-brocade', '织锦布架.png'),
                         ('details-tea-and-loom', '茶席与织架.png')]:
        shutil.copy2(PROJECT / 'previews' / ('coop-' + name + '.png'), RELEASE / target)
    shutil.copy2(BLUEPRINT / TITLE, RELEASE / '本轮改动与来源.md')
    (RELEASE / '先看这里_启动与操作.txt').write_text('''爨境·共生 / 2026-10-18 按钮、场景细节与动态音效版

双击 CuanParty.exe。exe和pck放在同一目录；两位玩家共用一台Windows64位电脑和键盘。
1P：A/D行走，W/空格跳跃，S/E任务操作，F察看/交谈，G换附近目标，Tab换专属角色。
2P：左右方向键行走，↑跳跃，↓任务操作，/察看/交谈，.换附近目标，右Shift换专属角色。
左下“此刻所往”是目标；左上“提示”/H查看操作。靠近物件能察看新增器物。
N/“音效”控制按钮、翻牌、任务、跳跃、溪流；M/“乐声”独立控制背景音乐。
V/“续话”可读下一句，B行囊，F2档案。
右上“重新开始”重开当前关；R回起点保留进度；T全清从第一关重玩。
长卷左右箭头翻页、末页Enter继续、Esc返回庭院。退出后没有续关存档。
本轮不创建压缩包，旧版本保留。自动检查通过，最终音效听感请实际试听。
''', encoding='utf-8-sig')
    record = {'version': '2026-10-18 / world-detail-sound', 'archive_created': False,
              'verified_logs': logs, 'exported_headless_startup': True, 'exported_pck_loaded': True,
              'interaction_targets': 72, 'new_craft_groups': 8, 'independent_mute': {'M': 'music', 'N': 'effects and creek'},
              'new_audio': json.loads((PROJECT / 'assets/audio/interactions/ACTION_SOURCE.json').read_text(encoding='utf8')),
              'ui_sources': json.loads((PROJECT / 'assets/interface/SOURCE.json').read_text(encoding='utf8')),
              'render_audio_driver': 'Dummy; no human listening claim',
              'executables': {name: {'bytes': (RELEASE / name).stat().st_size, 'sha256': sha(RELEASE / name)} for name in ['CuanParty.exe', 'CuanParty.pck']}}
    (RELEASE / '验证记录.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf8')
    print('WORLD_DETAIL_LOCAL_RELEASE_OK: native startup and PCK resources, nine verified regression logs, seven game screenshots; no archive')


if __name__ == '__main__':
    prepare() if '--prepare' in sys.argv else finalize()
