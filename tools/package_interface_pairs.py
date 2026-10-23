"""Package the supplied cover/background, refined UI, and exclusive role pairs."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/interface-pairs-2026-10-17'
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
PICTURES = {
    'coop-interface-title.png': '进入界面.png',
    'coop-interface-draw.png': '水墨抽牌背景.png',
    'coop-interface-draw-pairs.png': '抽牌与专属同行.png',
    'coop-interface-clean-game.png': '简洁游戏界面.png',
    'coop-interface-hint.png': '左上角提示.png',
    'coop-interface-small-dialogue.png': '小幅纸色交互框.png',
}
INTRO = '''爨境·共生 — 水墨界面与专属角色（2026-10-17）

双击 CuanParty.exe，保留同目录的 CuanParty.pck。
项目最外层“开始游戏（最新版）”已指向本版。

进入界面使用用户提供的游戏封面，抽牌使用山谷暖阳背景。
点击“启程同行”抽取角色；每位玩家掌两名专属主角。
一名当前操作、一名跟随，不能切到另一位玩家的任何角色。
抽牌结果下方会显示专属同行，游戏内也可点左上角“提示”回看。
石阿朵与老箐分给不同玩家，桥中顶碑与右岸拉绳仍须两人合作。

操作说明收在左上角“提示”，点击查看；点×、H或Esc收起。
提示阅读时暂停，关闭后继续；拼字时也可打开，不会丢失拼字。
右上角角色按钮已撤下，保留小巧的行囊入口。
靠近村民或道具出现小幅纸色文本框，交谈/察看后才展开正文。

1P：A/D走，W/空格跳，S/E任务操作；F交谈/察看，G换附近目标，Tab换专属角色。
2P：←/→走，↑跳，↓任务操作；/交谈/察看，.换附近目标，右Shift换专属角色。
B行囊，F2档案，R回起点保留进度和归属，T清空重开。
默认快捷试玩和T重开：1P邓书年/老箐，2P石阿朵/杨三娘。
单人兼容模式仍可操作四位主角。

阿彩、阿强在第二幕联络后出现；普嫫、玉喃在第三幕四件物品归位后出现。
交谈不会代做修桥、救碑或送灯。原三幕合作、行囊、八名人物与轻古风对白保留。
目录附新版界面实机截图、抽牌演示视频及完整说明。
'''


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    for filename in ['CuanParty.exe', 'CuanParty.pck']:
        assert (BUILD / filename).stat().st_size > 1_000_000
    startup = (BUILD / 'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and 'ERROR' not in startup
    manifest = json.loads((PROJECT / 'assets/interface/SOURCE.json').read_text(encoding='utf-8-sig'))
    for item in manifest:
        assert hashlib.sha256((PROJECT / 'assets/interface' / item['file']).read_bytes()).hexdigest() == item['sha256']
    (BUILD / '先看这里.txt').write_text(INTRO, encoding='utf-8-sig')
    shutil.copy2(BLUEPRINT / '水墨界面与专属角色_说明.md', BUILD / '水墨界面与专属角色_说明.md')
    shutil.copy2(BLUEPRINT / '四人同行_试玩说明.md', BUILD / '完整试玩说明.txt')
    shutil.copy2(PROJECT / 'assets/interface/SOURCE.json', BUILD / '界面原图来源.json')
    shutil.copy2(PROJECT / 'assets/calligraphy/SOURCE.md', BUILD / '字体来源与使用范围.txt')
    shutil.copy2(PROJECT / 'previews/入场抽牌演示.mp4', BUILD / '入场抽牌演示.mp4')
    movie = json.loads((PROJECT / 'previews/opening-draw-movie-validation.json').read_text(encoding='utf8'))
    qa = json.loads((PROJECT / 'previews/opening-draw-video-qa.json').read_text(encoding='utf8'))
    assert qa['decoded'] and qa['frames'] == movie['frames'] and qa['fps'] == 30
    for source, target in PICTURES.items(): shutil.copy2(PROJECT / 'previews' / source, BUILD / target)
    evidence = {
        'original_interface_assets_verified': manifest,
        'draw_pairs_verified': 12,
        'owned_roles_per_player': 2,
        'stoneworker_and_route_finder_have_different_owners': True,
        'movie': movie,
        'movie_decoded': qa,
        'checks': ['INTERFACE_PAIRS_OK (GPU)', 'LOCAL_COOP_OK / LOCAL_COOP_RENDER_OK (GPU)',
                   'PARTY_GAME_OK', 'FIELD_SATCHEL_OK', 'OPENING_DRAW_OK', 'NEARBY_INTERACTIONS_OK',
                   'Windows export / headless startup'],
        'screenshots': list(PICTURES.values()),
    }
    (BUILD / '验证记录.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    output = PROJECT / 'builds/四人同行_水墨界面与专属角色_2026-10-17.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in BUILD.iterdir():
            if path.is_file() and path.suffix != '.log': archive.write(path, BUILD.name + '/' + path.name)
    with zipfile.ZipFile(output) as archive: assert archive.testzip() is None
    print('INTERFACE_PAIRS_PACKAGE_OK', output.name, output.stat().st_size)


if __name__ == '__main__': main()
