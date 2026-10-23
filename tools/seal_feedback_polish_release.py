from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/feedback-polish-2026-10-19'
previews = root / 'previews'
environment = 'ERROR: Failed to read the root certificate store.'
checks = {
    'feedback-polish-gpu.log': 'FEEDBACK_POLISH_OK',
    'feedback-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
    'feedback-keepsakes-gpu.log': 'JOURNEY_KEEPSAKES_OK',
    'feedback-single.log': 'PARTY_GAME_OK',
    'feedback-guide-gpu.log': 'COOPERATIVE_EXPERIENCE_OK',
}


def verify_log(path, marker):
    text = path.read_text(encoding='utf-8-sig')
    assert marker in text, (path, marker)
    diagnostics = [line for line in text.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(previews / name, marker)
    shutil.copy2(previews / name, release / name)
verify_log(previews / 'feedback-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'),
                     ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['distinct_chronology_ear_only_listening_keypad_enter_floral_world_scroll_six_colour_sparks_and_visible_pier_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
paper_sha = hashlib.sha256((root / 'assets/interface/scroll_cover.png').read_bytes()).hexdigest()
assert paper_sha.upper() == '97DA6714D37FC799E706B32F61B2711822B96984CACDE8B8BB181E3ED5C1377E'
shots = {
    'coop-feedback-distinct-big-stele-reward.png': '大爨_独立二爨合读奖励.png',
    'coop-feedback-visible-broken-pier.png': '桥头_可见待修石墩.png',
    'coop-feedback-pier-repair-progress.png': '桥头_修筑中的石块.png',
    'coop-feedback-zhuang-collection-directions.png': '收藏_阿强器物获取位置.png',
    'coop-feedback-collected-a_qiang_beam.png': '收藏_扛梁时点击木梁.png',
    'coop-feedback-collected-a_qiang_knife.png': '收藏_点击腰间柴刀.png',
    'coop-feedback-ear-only-listening.png': '听音_不显示音序答案.png',
    'coop-feedback-multicolour-finale.png': '终幕_多色烟花与卷轴.png',
    'coop-feedback-ornate-world-scroll.png': '终幕_指定牡丹纸与纪年题签.png',
}
for source, target in shots.items():
    shutil.copy2(previews / source, release / target)
note = '二爨独立奖励_听音与桥头交互修正_说明.md'
description = '''# 二爨奖励与互动修正版 · 2026-10-19

当前导出 builds/feedback-polish-2026-10-19，项目根两个“开始游戏”入口指向本版。EXE与PCK须在同目录，本轮不新增ZIP。

大爨碑合读奖励与人物主线分开：三题后收入二爨对照笺，记载405/458年、地点与书体差异，并解锁终幕场景卷轴下方“二爨一脉 · 405—458”纪年题签；F2档案也记下题签。移除小爨碑凹位的淡字答案，不代收四人见闻，也不代开主线门。小爨碑六字仍由四人提供间隔、辨向和顺序线索。现有史实来源及字库示意说明不变。

五项听音小艺不再画音序和数字答案；播放中不亮对应乐器，错误后也不提示看答案。玩家凭音色回应，保留“再听一次”和玩家自己的按键反馈。自动测试使用Dummy音频检验调用与状态，不代替实际听感验收。

终幕烟花保持原240粒/四组规模，改用六色顶点材质，红、金、青绿、蓝、紫、粉轮换，避免原橙色材质冲淡其它颜色；爆点略高于檐口。场景内结束卷轴正面使用用户指定牡丹彩纹图，与已有长卷封面共用scroll_cover.png，原PNG字节不改。原卷轴木轴、正文和展卷过程保留。

图中的阿强木梁、木鞘柴刀是器物收录卡。第二关先让杨三娘联络帮手，再点击阿强肩上木梁或腰间柴刀即可收入本轮收藏；进入庭院后可以沿已修桥返回右岸寻找他。修正扛梁时木梁被禁用的问题，精调木梁/柴刀点选框，并在人物点选处理中优先判断近处工具，避免身体大框抢走柴刀点击；点脸仍可交谈，后排器物不抢走面部点击。锁定卡片明确写出获取方式。21件器物、七族关联/共用器物与8项成就数量保持。

界面“点击小碑”等文案明确为“点击小爨碑”。2P跳跃由右Ctrl改为数字键盘右下角的小键盘Enter；方向键移动、P/小键盘0操作及其它控制不变，帮助和引导同步更新。

第二关世界X30.5修筑点新增松动石墩、错开的压顶石，未修时即可见；石阿朵持续操作时七块石逐渐归位，完成后固定。已有桥下墩石也不再等修完才显示。新石墩为视觉模型，无新增行走碰撞；站位、角色条件、1.6秒持续操作和桥梁主线保留。

验证：新显卡专项真实按键检验右Ctrl无跳/小键盘Enter起跳、鼠标大爨三题/不泄露小爨答案、石墩修筑中间状态、杨三娘实际呼叫帮手、阿强扛梁与腰刀鼠标收录/脸部对话、五项无答案听音及重播、实际终幕卷轴/题签和多色烟花；逐张查看近景与全景截图。完整双人三关与单人三关通过，沿途拾物/包裹/回桥/本轮成就重置回归通过，引导与共同布置排版通过。独立导出PCK合约和原生Windows EXE离线启动通过。日志保留既有系统根证书读取诊断，只允许这一项，不忽略其它错误/警告或资源泄漏，也未修改系统证书。最终日志、9张截图、资源哈希见验证记录.json。

备份 backups/before-feedback-polish-2026-10-19。角色源、字库、原始图片与实物授权文件保留。自动验收不代替陌生玩家试玩。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-19 最新二爨奖励与互动修正：大爨合读改独立对照笺和终幕纪年题签，不给小爨六字淡字答案；听音不显示答案或播放亮牌，可重听。场景卷轴用用户牡丹纸，六色烟花；阿强扛梁/柴刀点选与脸部对话分流，收藏册说明杨三娘联络后点肩梁/腰刀；明确小爨碑，2P小键盘Enter跳。桥头修筑点新增可见松动石墩与过程归位。专项、完整双人/单人、拾物回桥/成就清零与引导排版、独立PCK和原生启动通过。当前 `builds/feedback-polish-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录，此前大爨淡字参照与右Ctrl键位已被本轮取代。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md',
             blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新二爨奖励与互动修正：' in text:
        continue
    backup = root / 'backups/before-feedback-polish-2026-10-19/docs' / (path.parent.name + '-' + path.name)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(path, backup)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/feedback-polish-', '`../cuan-game/builds/feedback-polish-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md':
        paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(release / '验证记录.json').write_text(json.dumps(dict(
    result='FEEDBACK_POLISH_RELEASE_VERIFIED', date='2026-10-19', checks=checks, bundle=bundle,
    native_startup=startup, font_sha256=font_sha, supplied_scroll_cover_sha256=paper_sha,
    files=files, environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']:
    (release / name).unlink(missing_ok=True)
print('FEEDBACK_POLISH_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
