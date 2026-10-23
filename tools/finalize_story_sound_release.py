"""Collect already completed checks and a local runnable release, without ZIP."""
from pathlib import Path
import hashlib
import json
import shutil

project = Path(__file__).resolve().parents[1]
release = project / 'builds/story-sound-2026-10-18'
blueprint = project.parent / 'cuan-game-blueprint'
logs = {
    'story-sound-check-visual.log': ['STORY_SOUND_OK', 'NVIDIA'],
    'story-sound-check-coop.log': ['LOCAL_COOP_OK', 'LOCAL_COOP_RENDER_OK', 'NVIDIA'],
    'story-sound-check-garden.log': ['GARDEN_PREVIEW_OK', 'NVIDIA'],
    'story-sound-verify_interface_pairs.log': ['INTERFACE_PAIRS_OK'],
    'story-sound-verify_party_game.log': ['PARTY_GAME_OK'],
    'story-sound-verify_field_satchel.log': ['FIELD_SATCHEL_OK'],
    'story-sound-verify_opening_draw.log': ['OPENING_DRAW_OK'],
    'story-sound-verify_nearby_interactions.log': ['NEARBY_INTERACTIONS_OK'],
    'story-sound-verify_culture_scroll.log': ['CULTURE_SCROLL_OK'],
    'story-sound-verify_journey_polish.log': ['JOURNEY_POLISH_OK'],
}
for name, markers in logs.items():
    source = project / 'previews' / name
    content = source.read_text(encoding='utf-8-sig')
    assert all(marker in content for marker in markers), name
    assert not any(error in content for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
    shutil.copy2(source, release / name)
for name in ['startup.log', 'pck-check.log', 'export-console.log']:
    content = (release / name).read_text(encoding='utf-8-sig')
    assert not any(error in content for error in ['ERROR:', 'SCRIPT ERROR', 'Parse Error']), name
assert 'Godot Engine' in (release / 'startup.log').read_text(encoding='utf8')
assert json.loads((release / 'bundle-check.json').read_text(encoding='utf8'))['result'] == 'PLAYTEST_BUNDLE_OK'

pictures = {
    'coop-story-portrait-0.png': '邓书年_半身像对白.png',
    'coop-story-portrait-1.png': '石阿朵_半身像对白.png',
    'coop-story-portrait-2.png': '老箐_半身像对白.png',
    'coop-story-portrait-3.png': '杨三娘_半身像对白.png',
    'coop-story-villager-portraits.png': '村民对话与自适应提示.png',
    'coop-story-puzzle-portrait.png': '小爨拓影与拼字.png',
    'coop-story-aged-steles.png': '旧化碑面与碑冠.png',
    'coop-story-garden-exchange.png': '共庭交流.png',
}
for source, target in pictures.items():
    shutil.copy2(project / 'previews' / source, release / target)
for source, target in [(blueprint / '半身像剧情_古碑与民乐音效_说明.md', '本轮改动与来源.md'),
                       (blueprint / '四人同行_试玩说明.md', '完整试玩说明.txt'),
                       (project / 'assets/audio/配乐来源.md', '音乐音效来源.md')]:
    shutil.copy2(source, release / target)
(release / '先看这里_启动与操作.txt').write_text('''爨境·共生 / 2026-10-18 半身像剧情与民乐音效版

双击 CuanParty.exe。CuanParty.exe 与 CuanParty.pck 保留在同一目录。
Windows64位，无需安装Godot或Blender；两人共用一台电脑、一把键盘。

1P：A/D移动，W/空格跳跃，S/E任务操作，F交谈/察看，G换目标，Tab切换自己的两名角色。
2P：左右方向键移动，↑跳跃，↓任务操作，/交谈/察看，.换目标，右Shift切换自己的两名角色。
靠近人物和物件出现提示，亦可点击。闲谈不代替任务操作。
左下“此刻所往”显示目标；左上“提示”或H查看完整键位。
对白自动轮流显示，V/“续话”可读下一句。B查看行囊，M开关配乐，F2档案。
右上“重新开始”重开当前关并保留前关；R回起点保留进度，T全清从头开始。
长卷左右箭头翻页，末页Enter继续，Esc回庭院。
目前没有退出后续关的存档功能。

本轮没有制作压缩包。自动检查已通过，音乐最终听感待实际试听。
''', encoding='utf-8-sig')

def data(relative):
    return json.loads((project / relative).read_text(encoding='utf8'))

record = {
    'version': '2026-10-18 / story-sound', 'compressed_archive_created': False,
    'verified_logs': logs, 'exported_headless_startup': True, 'isolated_exported_pck_loaded': True,
    'dialogue_images': data('assets/dialogue/SOURCE.json'),
    'historical_steles': data('assets/historical_steles/SOURCE.json'),
    'music': data('assets/audio/SOURCE.json'), 'effects': data('assets/audio/interactions/SOURCE.json'),
    'goal_position': [24, 528], 'bubble_background_opacity': .62,
    'dialogue_crop': 'runtime AtlasTexture; original bytes unchanged',
    'interaction_targets': 64, 'audio_effects': 12,
    'render_checks_audio_driver': 'Dummy; no human listening claim', 'screenshots': list(pictures.values()),
    'executable_files': {name: {'bytes': (release / name).stat().st_size,
        'sha256': hashlib.sha256((release / name).read_bytes()).hexdigest()} for name in ['CuanParty.exe', 'CuanParty.pck']},
}
(release / '验证记录.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf8')
print('STORY_SOUND_LOCAL_RELEASE_OK: export startup, shipped resources, ten successful verification logs, eight screenshots; no ZIP')
