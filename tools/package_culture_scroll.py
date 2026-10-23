"""Verify supplied art provenance and package the culture/scroll Windows release."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/culture-scroll-2026-10-17'
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
STORY = PROJECT / 'assets/story'
ART_ROOT = Path('C:/Users/26845/Desktop/树莓比赛美工/共生长卷')
SOURCES = {
    'story_paper.png': Path('C:/Users/26845/AppData/Local/Temp/codex-clipboard-f25bd8ae-cb74-4f57-822b-36886db0d449.png'),
    'scroll_bridge.png': ART_ROOT / '369f9499-f92d-4022-8332-13648c9d4714.png',
    'scroll_symbols.png': ART_ROOT / '58db497e-a6db-4603-b330-a9d74c922727.png',
    'scroll_generations.png': ART_ROOT / '187018be-208c-45a5-b2c2-5e56b92a5d72.png',
    'scroll_lights.png': ART_ROOT / '87e12e10-d49d-4ad3-9e3f-7c8a0e2d9d4a.png',
}
PICTURES = {
    'coop-culture-title.png': '进入界面.png',
    'coop-culture-plaque-road.png': '爨体风格路牌.png',
    'coop-culture-high-dialogue.png': '抬高透明箭头交互框.png',
}
for index in range(1, 5):
    PICTURES[f'coop-culture-page-{index}.png'] = f'文化记_{index}.png'
    PICTURES[f'coop-culture-scroll-{index}.png'] = f'共生长卷_{index}.png'
for index, name in enumerate(['邓书年', '石阿朵', '老箐', '杨三娘', '阿彩', '普嫫', '玉喃', '阿强'], 1):
    PICTURES[f'coop-culture-person-{index}.png'] = f'人物小传_{name}.png'

CHECKS = {
    'culture-visual-check.log': ['CULTURE_SCROLL_OK', 'NVIDIA'],
    'culture-garden-check.log': ['GARDEN_PREVIEW_OK', 'NVIDIA'],
    'culture-coop-check.log': ['LOCAL_COOP_OK', 'LOCAL_COOP_RENDER_OK', 'NVIDIA'],
    'culture-verify_interface_pairs.log': ['INTERFACE_PAIRS_OK'],
    'culture-verify_party_game.log': ['PARTY_GAME_OK'],
    'culture-verify_field_satchel.log': ['FIELD_SATCHEL_OK'],
    'culture-verify_opening_draw.log': ['OPENING_DRAW_OK'],
    'culture-verify_nearby_interactions.log': ['NEARBY_INTERACTIONS_OK', 'props=64'],
}
INTRO = '''爨境·共生 — 爨文化与共生长卷（2026-10-17）

双击 CuanParty.exe，保留同目录 CuanParty.pck。
项目最外层“开始游戏（最新版）”已指向本版。

封面左上角“识爨·文化记”：四页爨文化知识、交流意义与可点击来源。
“人物小传”：八张原人物卡，详细的家乡、行当、衣饰、日常与此行所愿。
两处阅读页使用本次上传的花卉祥云旧纸；返回封面再启程抽牌。

共生长卷：四幅原图，左右木卷轴与金边，亮色画面上保留清楚的升华文字。
顺序为合力过桥、七族器物、代代守护、万家灯火。
最后一页等玩家读完，不自动离开。八位人物对应七个民族。
可在封面“试玩·灯火共庭”进入第三幕，但须完成扶碑、归位与送灯才展开长卷。
目录附四页实机截图，可直接看美术效果。

牌匾统一采用墨青金边与现代小爨字库。交互框抬高、加箭头、纸底更加透明。
两人独立交谈/察看，交谈不代做修桥、救碑与送灯任务。

1P：A/D走，W/空格跳，S/E任务；F交谈/察看，G换目标，Tab换自己的角色。
2P：←/→走，↑跳，↓任务；/交谈/察看，.换目标，右Shift换自己的角色。
每人只管两名主角，不可操作另一人的角色。
左上角“提示”/H看键位与目标，B行囊，F2档案。
R回起点保留进度，T清空；T默认1P邓/老、2P石/杨。
长卷中A/D或左右箭头翻页，Enter/空格下一页，末页确认返回；Esc回庭院。

文化资料为公开资料转述，人物和护碑情节为原创，画面为艺术创作。
详细出处与字体使用范围随包保存。完整双人人工试玩可继续反馈体验问题。
'''


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare():
    manifest = []
    for name, source in SOURCES.items():
        asset = STORY / name
        assert digest(asset) == digest(source), f'Original image differs: {name}'
        manifest.append({'file': name, 'source': str(source), 'sha256': digest(asset),
                         'bytes': asset.stat().st_size, 'altered': False})
    (STORY / 'SOURCE.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf8')
    print('STORY_ORIGINAL_ART_OK', len(manifest))
    return manifest


def main():
    manifest = prepare()
    if '--prepare' in sys.argv:
        return
    for name in ['CuanParty.exe', 'CuanParty.pck']:
        assert (BUILD / name).stat().st_size > 1_000_000
    startup = (BUILD / 'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and 'ERROR' not in startup
    validation = {}
    for filename, markers in CHECKS.items():
        log = (PROJECT / 'previews' / filename).read_text(encoding='utf8')
        assert all(marker in log for marker in markers), filename
        assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, filename
        validation[filename] = markers
    (BUILD / '先看这里.txt').write_text(INTRO, encoding='utf-8-sig')
    for filename in ['爨文化与共生长卷_说明.md', '爨文化_资料整理与引用.md']:
        shutil.copy2(BLUEPRINT / filename, BUILD / filename)
    shutil.copy2(BLUEPRINT / '四人同行_试玩说明.md', BUILD / '完整试玩说明.txt')
    shutil.copy2(STORY / 'SOURCE.json', BUILD / '本次背景原图来源.json')
    shutil.copy2(PROJECT / 'assets/calligraphy/SOURCE.md', BUILD / '字体来源与使用范围.txt')
    for source, target in PICTURES.items():
        shutil.copy2(PROJECT / 'previews' / source, BUILD / target)
    evidence = {'original_story_art': manifest, 'verified_logs': validation,
                'culture_pages': 4, 'original_card_biographies': 8, 'scroll_pages': 4,
                'ethnicities_among_eight_characters': 7, 'world_plaques': 4,
                'bubble_opacity': 0.79, 'scroll_text_backing_opacity': 0.91,
                'screenshots': list(PICTURES.values()), 'exported_headless_startup': True}
    (BUILD / '验证记录.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    output = PROJECT / 'builds/四人同行_爨文化与共生长卷_2026-10-17.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in BUILD.iterdir():
            if path.is_file() and path.suffix != '.log':
                archive.write(path, BUILD.name + '/' + path.name)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
    print('CULTURE_SCROLL_PACKAGE_OK', output.name, output.stat().st_size)


if __name__ == '__main__':
    main()
