"""Package the current executable and the NPC/prop interaction instructions."""
from pathlib import Path
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/nearby-interactions-2026-10-17'
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
PICTURES = {
    'coop-nearby-two-steles.png': '靠近两碑_双人提示.png',
    'coop-nearby-creek-villagers.png': '阿彩与阿强_头顶交谈.png',
    'coop-nearby-garden-villagers.png': '普嫫与玉喃_头顶交谈.png',
    'coop-nearby-lamp-table.png': '灯桌道具_靠近察看.png',
}
INTRO = '''爨境·共生 — 村民与道具靠近交互版（2026-10-17）

双击 CuanParty.exe。CuanParty.exe 和 CuanParty.pck 必须放在一起。
项目最外层另有“开始游戏（最新版）”快捷方式。

靠近村民或道具，上方会出现文本框。
1P：F 交谈/察看/下一句/收起，G 切换附近目标。
2P：/ 交谈/察看/下一句/收起，. 切换附近目标。
2P 亦可用小键盘 0 / 1；文本框下方第一行可直接点击。
金色框对应 1P，蓝色框对应 2P，细线指向实际村民或物件。
对白没有自动倒计时，走开后自动收起。

任务操作仍为 1P S/E、2P ↓，需要按住时请看文本框说明。
查看道具和交谈不会自动修桥、拿灯或安放物件。
两碑可靠近按 F 或 / 放大查看，也可以直接点击碑身。
附近有多件道具时，用 G / . 切换，每件都有自己的说明。

四位村民的出场：
阿彩（苗族）、阿强（壮族）：第二幕，由杨三娘回入口联络后到桥边。
普嫫（彝族）、玉喃（傣族）：第三幕四件随身物品归位后出现。
标题页可直接试玩第二/三幕；人物仍按以上进度出现。
碑院、古道、共庭中的器物及村民随身器物均可靠近察看。

八牌入场、四位可选主角、双人合作、行囊及轻古风对白均保留。
1P A/D 行走，W/空格跳，Tab/数字1—4换人。
2P ←/→ 行走，↑跳，右Shift换人。
B 行囊；F2档案；R回出生点保留进度；T清空重开。

本目录附四张实机交互截图、详细说明和原开场抽牌演示视频。
'''


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    for name in ['CuanParty.exe', 'CuanParty.pck']:
        assert (BUILD / name).stat().st_size > 1_000_000
    startup = (BUILD / 'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and 'ERROR' not in startup
    (BUILD / '先看这里.txt').write_text(INTRO, encoding='utf-8-sig')
    shutil.copy2(BLUEPRINT / '村民与道具_靠近交互说明.md', BUILD / '村民与道具_靠近交互说明.md')
    shutil.copy2(BLUEPRINT / '四人同行_试玩说明.md', BUILD / '完整试玩说明.txt')
    shutil.copy2(PROJECT / 'assets/calligraphy/SOURCE.md', BUILD / '字体来源与使用范围.txt')
    shutil.copy2(PROJECT / 'previews/入场抽牌演示.mp4', BUILD / '入场抽牌演示.mp4')
    for source, target in PICTURES.items():
        shutil.copy2(PROJECT / 'previews' / source, BUILD / target)
    (BUILD / '验证记录.json').write_text(json.dumps({
        'feature': 'nearby_villagers_and_props',
        'npc_names': ['阿彩（苗族）', '阿强（壮族）', '普嫫（彝族）', '玉喃（傣族）'],
        'reachable_targets_in_fixture': 64,
        'checks': ['NEARBY_INTERACTIONS_OK (GPU)', 'LOCAL_COOP_OK / LOCAL_COOP_RENDER_OK (GPU)', 'PARTY_GAME_OK', 'FIELD_SATCHEL_OK', 'OPENING_DRAW_OK', 'Windows export / headless startup'],
        'images': list(PICTURES.values()),
    }, ensure_ascii=False, indent=2), encoding='utf8')
    output = PROJECT / 'builds/四人同行_村民与道具交互_2026-10-17.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in BUILD.iterdir():
            if path.is_file() and path.suffix != '.log': archive.write(path, BUILD.name + '/' + path.name)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
    print('NEARBY_INTERACTIONS_PACKAGE_OK', output.name, output.stat().st_size)


if __name__ == '__main__':
    main()
