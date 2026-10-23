"""Document and finalize the local folk-play release; never creates a ZIP."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

PROJECT = Path(__file__).resolve().parents[1]
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
RELEASE = PROJECT / 'builds/folk-play-2026-10-18'
TITLE = '音量滑条_同行小艺与华彩共庭_说明.md'


def prepend(path, note):
    text = path.read_text(encoding='utf-8-sig')
    if note in text:
        return
    heading, body = text.split('\n', 1)
    path.write_text(heading + '\n\n' + note + '\n' + body, encoding='utf8')


def prepare():
    content = '''# 音量滑条、同行小艺与华彩共庭

2026-10-18。当前可直接运行：`../cuan-game/builds/folk-play-2026-10-18/CuanParty.exe`。项目最外层“开始游戏（最新版）”已更新，不制作压缩包，旧版保留。

音效开关下方新增可拖动滑条和百分比，范围0—100%，默认85%。N仍独立静音全部音效，M仍控制配乐；拖动滑条可同时调整按钮、牌、物件、跳跃、持续任务和溪流，不改变配乐。重开关卡与T重玩保留本次音量选择。普通物件基础电平提高9 dB，按钮提高9 dB，跳跃提高17 dB，长按工作声提高16 dB，再统一乘滑条系数。跳跃只在实际起跳时触发，不在空中反复叠加。

长按任务沿用无缝循环音频，基于实际工作状态贯穿整次有效长按，不是只在按下时响一次。识字、备木、推橇、砌墩、架桥、顶碑拉绳、立碑、物件归位和点灯均按材质发声，两位玩家可同时有不同声音。改为同时读取三幕有效工作状态，跨场景边界站位也不会漏声；单人兼容的桥中救碑也有循环声。松手、暂停、浮窗阅读、任务完成和重开时停止。

左下“此刻所往”加入实时交互百分比与细进度条，包含识字、备木、辨路、砌墩、架桥、推运、护碑、立碑及各物件安放；两人并行时可显示两项百分比。松手中断就归零。碑面查看时任务面板缩为88像素高，仍显示百分比，保留放大拓影与六字操作区；查看器底部说明重新排版，避开左下进度和右下人物对白。

附近小提示去掉整个“察看/附近几处”页脚，只保留目标名称和已经展开的内容；点击范围为整张小框。民族特色器物可直接点击场景实物，或点其名称框，弹出纸底介绍浮窗。浮窗内展示该实物的三维模型，可以按住鼠标拖动转看；右侧介绍其人物来处、日用功能和同行意义。可读21类器物，包括八组新手作陈设、村民随身物件、驮布毛驴、錾子、马铃和红线。隐藏或施工收起的器物不参与点击。阅读时暂停两位玩家，Esc/收起返回原进度，不替玩家完成任务。

三关各增加一项可重复的“同行小艺”：第一关点击或划过三处花纹，体验蓝白留纹；第二关把1、2、3、4、6份货包分到两边，各8份即配平；第三关先听示范，再按①③②③①回应木击、马铃和竹音，也可用1/2/3键。答错可重试，完成后收入独立的3份手艺记录；它们不代替识字拼碑、双人救碑和七灯任务。重开当前关只清本关及后续小艺与见闻，先前关卡保留；T全清这些记录，退出程序后无跨运行存档。

共庭新增54盏悬灯组成三层灯阵，蓝白花布与红金织锦彩幔、金色花轮、花席和地面连环纹、56点微光及随七灯进度增强的暖光。完成小艺可再增一分灯彩；阿彩与阿强在四件随身物品归位后入院，连同四位主角、普嫫、玉喃共八位人物、七个民族相聚，两位桥边村民在庭中也可靠近交谈。新增对白谈及抬梁、识字和互学手艺。原四幅共生长卷、升华文字、卷轴和末页等待读完的行为保留。

织物与器物延续用户原设定和既有资料，不将虚构角色的个人习惯推及整个民族。花纹小艺为艺术化互动，并非完整扎染工序教学；配重份数为游戏单位；合奏是原创短句，不冒称某一传统曲牌。[云南非遗·白族扎染](https://www.ynich.cn/item/148.html)、[中国非遗·傣族织锦](https://www.ihchina.cn/project_details/11358/)是此前陈设设计资料。新增竹音由 `tools/compose_folk_note.py` 程序合成，无外部录音或采样，参数/哈希见 `assets/audio/interactions/FOLK_NOTE_SOURCE.json`。人物原Blender工程、GLB和用户图片未修改。

实现：`folk_collection.gd`处理21类实物的独立第8层射线点击、三维浮窗和见闻；`folk_playboard.gd`绘制并处理三项小游戏；`festival_court.gd`提供灯阵、彩幔、微光和两名来客。浮窗为新增INSPECT枚举，保留已有枚举序号；预览只复制场景节点、清除脚本及碰撞，共用原模型资源。保存本轮前的普通目录备份为 `backups/before-folk-play-2026-10-18`。

验证：实际鼠标拖音量、地面起跳、超过一轮音频时长的连续长按（同一播放流不重启）、第一关紧凑百分比、双人扶碑与并行物件百分比、松手与暂停取消、去页脚、实物鼠标点击、所有可见器物浮窗的文字/模型、三项小游戏正确与错误反馈、不跳过主线、八人共庭、重开隔离均通过。另有完整双人三幕、第三幕显卡、单人兼容、全部角色归属、附近物件遍历、八牌入场、原指引和半身像回归。截图使用Dummy音频驱动；验证信号与播放状态，实际听感由试玩确认。
'''
    (BLUEPRINT / TITLE).write_text(content, encoding='utf8')
    summary = '2026-10-18 最新同行小艺与华彩共庭：音效整体调响，开关下有0—100%拖动滑条（默认85%）；跳跃更清楚，有效长按循环贯穿全过程，跨场景站位及单人救碑也发声。左下此刻所往实时百分比/进度条，碑面查看时缩为88高；提示去整行察看页脚。21类特色器物支持直接点实物、可旋转三维浮窗和介绍。三关增加留纹、驮架配重、迎灯合奏，独立小艺3份，可重试，不代做主线。共庭54悬灯、彩幔花席、微光暖光与八人七民族相聚，新增入院村民交谈。当前 `builds/folk-play-2026-10-18/CuanParty.exe`，根最新快捷方式直达；不创建压缩包。见 [本轮说明](../cuan-game-blueprint/' + TITLE + ')。下方为历史记录。'
    for path in [PROJECT / 'README.md', PROJECT / '制作记录.md']:
        prepend(path, summary)
    for path in [BLUEPRINT / 'README.md', BLUEPRINT / '四人同行_试玩说明.md']:
        prepend(path, summary.replace('`builds/', '`../cuan-game/builds/').replace('../cuan-game-blueprint/', './'))
    for path in [PROJECT / 'AGENTS.md', PROJECT.parent / 'AGENTS.md']:
        prepend(path, '- ' + summary + ' 脚本folk_collection/folk_playboard/festival_court；INSPECT枚举追加8，物件射线第8层不碰原两碑第4层及行走碰撞。小游戏原生绘制，preview复制剥脚本/碰撞。旧角色源、资源与图片保留；T清小艺且音量保留。')
    print('FOLK_PLAY_DOCUMENTATION_OK')


def finalize():
    logs = {
        'folk-play-check-gpu.log': ['FOLK_PLAY_OK', 'NVIDIA'],
        'folk-play-capture_local_coop.log': ['LOCAL_COOP_OK', 'LOCAL_COOP_RENDER_OK', 'NVIDIA'],
        'folk-play-capture_garden.log': ['GARDEN_PREVIEW_OK', 'NVIDIA'],
        'folk-play-verify_folk_play.log': ['FOLK_PLAY_OK'],
        'folk-play-verify_party_game.log': ['PARTY_GAME_OK'],
        'folk-play-verify_nearby_interactions.log': ['NEARBY_INTERACTIONS_OK'],
        'folk-play-verify_interface_pairs.log': ['INTERFACE_PAIRS_OK'],
        'folk-play-verify_opening_draw.log': ['OPENING_DRAW_OK'],
        'folk-play-verify_journey_polish.log': ['JOURNEY_POLISH_OK'],
        'folk-play-verify_story_sound.log': ['STORY_SOUND_OK'],
    }
    for name, markers in logs.items():
        path = PROJECT / 'previews' / name
        text = path.read_text(encoding='utf-8-sig')
        assert all(marker in text for marker in markers), name
        assert not any(error in text for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
        shutil.copy2(path, RELEASE / name)
    for name in ['startup.log', 'pck-check.log', 'export-console.log']:
        text = (RELEASE / name).read_text(encoding='utf-8-sig')
        assert not any(error in text for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
    assert 'Godot Engine' in (RELEASE / 'startup.log').read_text(encoding='utf8')
    assert 'PLAYTEST_BUNDLE_OK' in (RELEASE / 'pck-check.log').read_text(encoding='utf8')
    pictures = {'folk-first-hold-percent': '识字长按与实时百分比.png', 'folk-stamp-popup': '物品浮窗与蓝白留纹.png',
                'folk-balance-popup': '古道驮架配重.png', 'folk-music-popup': '共庭迎灯合奏.png',
                'folk-joint-progress': '双人扶碑与进度条.png', 'folk-festival-court': '华彩共庭_八人相聚.png'}
    for name, target in pictures.items():
        shutil.copy2(PROJECT / 'previews' / ('coop-' + name + '.png'), RELEASE / target)
    shutil.copy2(BLUEPRINT / TITLE, RELEASE / '本轮改动与来源.md')
    (RELEASE / '先看这里_启动与操作.txt').write_text('''爨境·共生 / 2026-10-18 同行小艺与华彩共庭版

双击 CuanParty.exe；与CuanParty.pck放在同一目录。Windows64位，两位玩家共用电脑和键盘。
1P：A/D走，W/空格跳，S/E任务，F交谈/阅读，G换目标，Tab切自己的角色。
2P：左右方向键走，↑跳，↓任务，/交谈/阅读，.换目标，右Shift切自己的角色。
左下目标显示长按百分比；松手中断归零。H看提示，B行囊，F2档案，V续话。
N开关音效，音效开关下拖滑条调0—100%；M独立开关配乐。
点特色实物或名称框看介绍，按住预览拖动可转身；Esc/收起返回。
三关小艺：三处留纹、货包左右各8份、迎灯回应①③②③①（可用1/2/3）。
可重复玩，独立收集3份小艺，不替代拼字、护碑、七灯主线。
每关“重新开始”保留前关；R回起点保留进度，T从头重玩；音量选择本次运行保留。
长卷左右翻页，末页Enter继续，Esc回庭院。退出后没有续关存档。
没有制作压缩包。自动检查与导出启动通过，音效实际听感请试玩确认。
''', encoding='utf-8-sig')
    manifest = {'version': '2026-10-18 / folk-play', 'archive_created': False, 'verified_logs': logs,
                'exported_headless_startup': True, 'exported_pck_loaded': True, 'inspectable_cultural_items': 21,
                'optional_activities': ['blue-white pattern', 'balanced packs', 'lantern ensemble'], 'lanterns': 54,
                'volume_default': .85, 'volume_range': [0, 1], 'muting': {'N': 'effects', 'M': 'music'},
                'screenshots': list(pictures.values()), 'render_audio_driver': 'Dummy; no human listening claim',
                'files': {name: {'bytes': (RELEASE / name).stat().st_size,
                    'sha256': hashlib.sha256((RELEASE / name).read_bytes()).hexdigest()} for name in ['CuanParty.exe', 'CuanParty.pck']}}
    (RELEASE / '验证记录.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf8')
    print('FOLK_PLAY_LOCAL_RELEASE_OK: ten checked logs, six screenshots, real export startup and isolated PCK; no ZIP')


if __name__ == '__main__':
    prepare() if '--prepare' in sys.argv else finalize()
