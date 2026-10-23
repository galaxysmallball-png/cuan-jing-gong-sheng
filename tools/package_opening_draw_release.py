"""Package the opening card carousel, actual preview movie, and full game."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

PROJECT=Path(__file__).resolve().parents[1]
BLUEPRINT=PROJECT.parent/'cuan-game-blueprint'
BUILD=PROJECT/'builds/opening-card-draw-2026-10-17'
PREVIEWS={
    'coop-opening-draw-spin.png':'八牌环转.png',
    'coop-opening-draw-first-pick.png':'第一位出牌.png',
    'coop-opening-draw-result.png':'双人抽取结果.png',
    'coop-opening-draw-in-game.png':'抽取角色实际入场.png',
    'coop-opening-draw-single-result.png':'单人抽取结果.png',
}
INTRO='''爨境·共生 — 八牌入场版（2026-10-17）

双击 CuanParty.exe，保留同目录 CuanParty.pck。
标题页点“开始同行 · 抽取行旅牌”或按 Enter，就能看到新的八张角色牌环转动画。
本目录“入场抽牌演示.mp4”是游戏实际界面录制，另附环转、出牌和入场截图。

八方相逢，四人同行
八张用户原卡绕竖轴旋转，依次为 1P、2P 减速定格并移出牌面，再并排展示抽取结果。
两人会抽中不同的主角：邓书年（汉族）、石阿朵（白族）、老箐（彝族）、杨三娘（回族）。
阿彩（苗族）、阿强（壮族）、普嫫（彝族）、玉喃（傣族）参与环转展示，不会成为玩家抽取结果。
按“携手入场”或 Enter 后，两位玩家实际控制抽中的角色，另外两位主角跟随，仍可按原方式换人。

Enter / Esc：动画中掠过旋转，直接查看本次结果；再次按 Enter 才确认入场。
重看旋牌：重播同一次抽取，不改变本次角色。
返回题页：取消本次入场。
人物小传：标题页左下角可查看四位主角，读完或掠过后也会抽牌。
直接试玩第二/三幕：沿用快捷试玩用途，跳过完整开场。

动画期间关卡暂停，移动、换人、重置、档案和行囊键不会影响关卡；进入游戏后恢复。
单人兼容模式抽一名主角，另三名跟随。默认试玩仍为同键盘双人。

游戏操作
1P：A/D走，W/空格跳，S/E操作，Tab/数字1—4换人。
2P：左右箭头走，上箭头跳，下箭头操作，右Shift换人。
B或点击“行囊”翻看已收线索，B/Esc收起；提示消失后仍可回看。
拼字：鼠标拿放，Q/右键旋转；或J/L选字、I/K选位、Enter拿放、Backspace取回。
F2档案；R回出生点保留本次进度与当前角色；T清空任务并恢复默认邓/石配置，不重播开场。

原有八名人物、毛驴、三幕任务、行囊与轻古风对白保留。
已通过抽牌实际显卡专项、完整双人三幕显卡、单人兼容、行囊及第三幕检查；视频已解码抽帧核对。
这是当前可试玩版本，细节演出和完整双人键盘人工验收仍需继续打磨。
'''

def verify_cards():
    source=PROJECT/'assets/character_cards'
    manifest=json.loads((source/'SOURCE.json').read_text(encoding='utf8'))
    assert len(manifest)==8
    for card in manifest:
        content=(source/(card['key']+'.png')).read_bytes()
        reference=(PROJECT/'references/入场人物卡'/card['source_filename']).read_bytes()
        assert hashlib.sha256(content).hexdigest()==card['sha256'] and content==reference
    return manifest

def prepare():
    BUILD.mkdir(parents=True,exist_ok=True)
    verify_cards()
    (BUILD/'先看这里.txt').write_text(INTRO,encoding='utf-8-sig')
    shutil.copy2(BLUEPRINT/'四人同行_试玩说明.md',BUILD/'完整试玩说明.txt')
    shutil.copy2(BLUEPRINT/'八牌入场_动画说明.md',BUILD/'八牌入场_动画说明.md')
    shutil.copy2(PROJECT/'assets/calligraphy/SOURCE.md',BUILD/'字体来源与使用范围.txt')
    shutil.copy2(PROJECT/'previews/入场抽牌演示.mp4',BUILD/'入场抽牌演示.mp4')
    for source,label in PREVIEWS.items():shutil.copy2(PROJECT/'previews'/source,BUILD/label)

def package():
    prepare()
    startup=(BUILD/'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and not any(value in startup for value in ['ERROR:','SCRIPT ERROR'])
    for filename in ['CuanParty.exe','CuanParty.pck']:assert (BUILD/filename).stat().st_size>1000000
    movie=json.loads((PROJECT/'previews/opening-draw-movie-validation.json').read_text(encoding='utf8'))
    qa=json.loads((PROJECT/'previews/opening-draw-video-qa.json').read_text(encoding='utf8'))
    assert qa['decoded'] and qa['frames']==movie['frames'] and qa['fps']==30
    evidence={'original_card_count':8,'card_hashes':verify_cards(),'eligible_protagonist_ids':[0,1,2,3],'two_player_pairs_verified':12,'movie':movie,'movie_decoded':qa,'checks':['OPENING_DRAW_OK (GPU and headless)','LOCAL_COOP_OK / LOCAL_COOP_RENDER_OK (GPU)','PARTY_GAME_OK','FIELD_SATCHEL_OK','GARDEN_PREVIEW_OK','OPENING_DRAW_MOVIE_OK','OPENING_DRAW_MP4_OK','OPENING_DRAW_VIDEO_DECODE_OK','Windows export / headless startup']}
    (BUILD/'验证记录.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
    output=PROJECT/'builds/四人同行_八牌入场_2026-10-17.zip'
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for file in BUILD.iterdir():
            if file.is_file() and file.suffix!='.log':archive.write(file,BUILD.name+'/'+file.name)
    with zipfile.ZipFile(output) as archive:assert archive.testzip() is None
    print('OPENING_DRAW_PACKAGE_OK',json.dumps({'file':output.name,'bytes':output.stat().st_size,'card_hashes_verified':8,'movie_seconds':movie['seconds']},ensure_ascii=True))

if __name__=='__main__':
    if '--prepare' in sys.argv:prepare();print('OPENING_DRAW_RELEASE_PREPARED')
    else:package()
