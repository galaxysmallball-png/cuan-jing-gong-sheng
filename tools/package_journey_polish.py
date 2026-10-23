"""Package the verified level goals, refined escort, restart and music build."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/journey-polish-2026-10-17'
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
PAPER_SOURCE = Path('C:/Users/26845/AppData/Local/Temp/codex-clipboard-6cf4867d-d5d7-4691-835a-fa79879afd72.png')
PICTURES = {
    'coop-journey-first-goal.png': '第一关_右下角此刻所往.png',
    'coop-journey-small-bubble.png': '缩小后的交互框.png',
    'coop-journey-second-goal.png': '第二关_任务与重新开始.png',
    'coop-journey-bridge-litter.png': '第二关_合力护碑.png',
    'coop-journey-bridge-detail.png': '第二关_木托绑绳近景.png',
    'coop-journey-bridge-pull.png': '第二关_顶碑与牵绳.png',
    'coop-journey-third-goal.png': '第三关_任务与重新开始.png',
    'coop-journey-finale.png': '结尾_共生长卷.png',
}
CHECKS = {
    'journey-check-visual.log': ['JOURNEY_POLISH_OK', 'NVIDIA'],
    'journey-check-headless.log': ['JOURNEY_POLISH_OK'],
    'journey-check-coop.log': ['LOCAL_COOP_OK', 'LOCAL_COOP_RENDER_OK', 'NVIDIA'],
    'journey-check-garden.log': ['GARDEN_PREVIEW_OK', 'NVIDIA'],
    'journey-verify_interface_pairs.log': ['INTERFACE_PAIRS_OK'],
    'journey-verify_party_game.log': ['PARTY_GAME_OK'],
    'journey-verify_field_satchel.log': ['FIELD_SATCHEL_OK'],
    'journey-verify_opening_draw.log': ['OPENING_DRAW_OK'],
    'journey-verify_nearby_interactions.log': ['NEARBY_INTERACTIONS_OK'],
    'journey-verify_culture_scroll.log': ['CULTURE_SCROLL_OK'],
    'journey-verify_creek_preview.log': ['CREEK_PREVIEW_OK'],
}
INTRO = '''爨境·共生 — 关卡指引、运碑与场景配乐（2026-10-17）

双击 CuanParty.exe，保留同目录 CuanParty.pck。
项目最外层“开始游戏（最新版）”已指向本版。

此刻所往：右下角纸底任务面板，使用本次上传的背景图。
左上角改为第一关、第二关、第三关；操作键仍收在“提示”中。
附近交互框进一步缩小，正文分段读，保留高位箭头。

第二关过桥：倒角碑身、碑文示意、软垫木托、绑绳绳结与缠绳把手。
村民随木托护送；绳索逐渐拉紧、碑身逐渐扶正，镜头平缓聚焦。
石阿朵在桥心、老箐在右岸，双方同时按住操作键完成救碑。
一方松手会中断；没有跳过原来的合作条件。

右上角“重新开始”：只重开当前关，保留前面已通关、拾闻笺和本轮角色分组。
第一关重开会清本关线索与拼字；第二关重开修桥护碑；第三关重开扶碑和七灯。
每次重开取消旧进度、对话箭头和任务动画，并恢复移动。
R仍是回起点保留进度，T仍是彻底从第一关重玩。

四段原创合成器乐：碑院听风、断溪同行、庭前暖灯、万家共生。
各关不同，结尾增加弦乐、铜管合成音色、鼓与镲层次。
场景间渐变切换，循环播放；点“乐声”或按M随时开关。
长卷里也能按M，不必退出阅读。配乐不是第三方歌曲或采样拼接。

1P：A/D走，W/空格跳，S/E任务，F交谈/察看，G换附近目标，Tab换自己的角色。
2P：←/→走，↑跳，↓任务，/交谈/察看，.换附近目标，右Shift换自己的角色。
B行囊，F2档案，H提示；每位玩家只管自己的两名主角。
封面的文化记、八张原卡人物小传和四幅共生长卷继续保留。

目录附实机截图与完整说明。音乐可根据实际试听反馈继续调音量与音色。
'''


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    paper = PROJECT / 'assets/interface/objective_paper.png'
    assert digest(paper) == digest(PAPER_SOURCE)
    art = {'file': 'objective_paper.png', 'source': str(PAPER_SOURCE), 'sha256': digest(paper), 'altered': False}
    (PROJECT / 'assets/interface/OBJECTIVE_SOURCE.json').write_text(json.dumps(art, ensure_ascii=False, indent=2), encoding='utf8')
    music = json.loads((PROJECT / 'assets/audio/SOURCE.json').read_text(encoding='utf8'))
    assert len(music['tracks']) == 4 and len({entry['sha256'] for entry in music['tracks']}) == 4
    for entry in music['tracks']:
        assert digest(PROJECT / 'assets/audio' / entry['file']) == entry['sha256']
        assert entry['duration_seconds'] >= 40 and entry['peak_dbfs'] < -1
    validation = {}
    for filename, markers in CHECKS.items():
        log = (PROJECT / 'previews' / filename).read_text(encoding='utf8')
        assert all(marker in log for marker in markers), filename
        assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, filename
        validation[filename] = markers
    for filename in ['CuanParty.exe', 'CuanParty.pck']:
        assert (BUILD / filename).stat().st_size > 1_000_000
    startup = (BUILD / 'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and 'ERROR' not in startup
    (BUILD / '先看这里.txt').write_text(INTRO, encoding='utf-8-sig')
    for filename in ['关卡指引_运碑与场景配乐_说明.md', '爨文化与共生长卷_说明.md', '爨文化_资料整理与引用.md']:
        shutil.copy2(BLUEPRINT / filename, BUILD / filename)
    shutil.copy2(BLUEPRINT / '四人同行_试玩说明.md', BUILD / '完整试玩说明.txt')
    shutil.copy2(PROJECT / 'assets/interface/OBJECTIVE_SOURCE.json', BUILD / '任务面板原图来源.json')
    shutil.copy2(PROJECT / 'assets/audio/SOURCE.json', BUILD / '四首配乐验证数据.json')
    shutil.copy2(PROJECT / 'assets/audio/配乐来源.md', BUILD / '配乐来源.md')
    shutil.copy2(PROJECT / 'assets/calligraphy/SOURCE.md', BUILD / '字体来源与使用范围.txt')
    for source, target in PICTURES.items():
        shutil.copy2(PROJECT / 'previews' / source, BUILD / target)
    evidence = {'original_goal_art': art, 'music': music, 'verified_logs': validation,
                'exported_headless_startup': True, 'goal_size': [306, 170], 'bubble_width': 228,
                'restart_scope': 'current chapter only; earlier completion and assigned roles retained',
                'render_checks_audio_driver': 'Dummy (no speaker playback during automated screenshots)',
                'audio_checks': 'PCM signal stats and playback/loop/crossfade/mute states; no human listening claim',
                'screenshots': list(PICTURES.values())}
    (BUILD / '验证记录.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    output = PROJECT / 'builds/四人同行_关卡指引与场景配乐_2026-10-17.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in BUILD.iterdir():
            if path.is_file() and path.suffix != '.log': archive.write(path, BUILD.name + '/' + path.name)
    with zipfile.ZipFile(output) as archive: assert archive.testzip() is None
    print('JOURNEY_POLISH_PACKAGE_OK', output.stat().st_size)


if __name__ == '__main__': main()
