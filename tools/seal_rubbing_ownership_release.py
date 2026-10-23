from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/rubbing-ownership-2026-10-19'
previews = root / 'previews'
environment = 'ERROR: Failed to read the root certificate store.'
checks = {
    'rubbing-ownership-gpu.log': 'RUBBING_OWNERSHIP_OK',
    'rubbing-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
    'rubbing-single.log': 'PARTY_GAME_OK',
    'rubbing-keepsakes-gpu.log': 'JOURNEY_KEEPSAKES_OK',
    'rubbing-guide-gpu.log': 'COOPERATIVE_EXPERIENCE_OK',
}


def verify_log(path, marker):
    text = path.read_text(encoding='utf-8-sig')
    assert marker in text, (path, marker)
    diagnostics = [line for line in text.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(previews / name, marker)
    shutil.copy2(previews / name, release / name)
verify_log(previews / 'rubbing-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'),
                     ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['cooperative_rubbing_before_reading_and_no_role_clue_bypass_verified']
assert bundle['owner_only_keepsake_pickup_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots = {
    'coop-rubbing-wrong-owner-reminder.png': '拾取_须由物主本人.png',
    'coop-rubbing-paper-alignment.png': '第一关_两人覆纸定位.png',
    'coop-rubbing-phase-1.png': '第一关_分区择机扑墨.png',
    'coop-rubbing-phase-2.png': '第一关_墨色均匀待揭纸.png',
    'coop-rubbing-shared-peel-progress.png': '第一关_两边共同揭纸.png',
    'coop-rubbing-phase-3.png': '第一关_拓字显影后再合读.png',
    'coop-rubbing-new-cut-stone-pier.png': '桥头_新方石墩全景.png',
    'coop-rubbing-pier-masonry-detail.png': '桥头_错缝砌石与承梁.png',
}
for source, target in shots.items(): shutil.copy2(previews / source, release / target)
note = '合作传拓_物主拾取与桥墩重塑_说明.md'
description = '''# 合作传拓、物主拾取与桥墩重塑 · 2026-10-19

最新导出 builds/rubbing-ownership-2026-10-19，根目录两个“开始游戏”入口同步；EXE与PCK保持同目录，本轮不新增ZIP。

四件随身物品改为物主本人拾取：邓书年拓片、石阿朵錾子、老箐马铃、杨三娘红线。按键、鼠标和附近交互都检查当前角色；不能由跟随状态的物主自动代收。鼠标会寻找在范围内且由玩家操控的物主，错误角色在场时提示名字、所属玩家及Tab/右Shift。换人保留角色物理位置，须走近站稳，不能隔空领取。地面标签、B包裹、附近说明和情境引导同步。21件特色器物的介绍／实物图／收藏仍是见闻机制，与四件主线随身物品分开。

第一关由“点分享、摆字”扩展为“覆纸—扑墨—揭纸—四人合读—六字归位”。点击小爨碑打开练习刻板：两位玩家分别调整纸的上下边，到金线后各自压稳；每人控制一列三格，指针进入绿色区时逐次轻扑，每格两次，按住不连发，错时可重试。两人同时按住操作键托住两边揭纸，中途松手回落，有百分比与纸边折起；取拓按钮之后才进入原四人线索和拼字，显影六字保持乱序/不同朝向，不替代见闻。合读仍需要四人，字序和方向都正确才开门；单格放入不再即时亮绿报对错，整幅核对仍有纠错反馈。阶段编号和左下目标同步。

单人依次压两边、A/D换列与W/S选格、E轻扑及揭纸；鼠标可点方向按钮、压纸按钮与纸格，侧边按住揭纸可与键盘配合。Esc离开保留纸边与墨色，未完成的揭纸回落；H/档案暂停时冻结节拍。R保留本轮，重开第一关/T重新传拓；直达第二/三关仍按原显式预置流程。没有延长原移动速度、1.6秒主线操作、推运或庭院暖光参数。

传拓操作发生在练习刻板上，使用现有梁培生现代小爨字库节选，不在文物原碑上涂墨，也不冒称原碑裁字。玩法根据传拓的覆纸、轻扑与揭纸过程简化，计时条、六区域和双人分工属于原创游戏机制，不代表真实技艺的全部工序。
参考：故宫博物院《浓墨拓》https://www.dpm.org.cn/lemmas/239766.html （扑包沾墨轻扑，接触纸面不滑动）；故宫讲坛《金石传拓技艺》https://www.dpm.org.cn/classify_detail/180778.html 。未新增外部图片或改写既有二爨史实。

桥头修筑目标由碎石堆改为可辨的砌石桥墩：双层宽基座、三层错缝方石、厚压顶和木梁承托。新dressed_stone原生网格为切石倒角轮廓，颜色提亮与背景分离；岸壁加连续砌石墩脚。松动上层及歪压顶随石阿朵修筑逐步归正。仍在原世界X30.5工作点，七块活动石，纯视觉无新碰撞，保留站位、时长及架桥条件。

验证：新NVIDIA显卡专项覆盖四物错误角色的按键／鼠标／附近入口拒绝、专属换人后本人拾取、真实纸边移动／压纸、错误与长按扑墨不能跳过、鼠标扑墨、六区逐次上墨、双人揭纸中间状态与一人不可代做、暂停／退出重进、取拓不泄露分享、四人六字实际开门、桥墩修筑和T清零。逐张查看第一关三阶段与桥墩近景。完整双人三关、单人三关与重新传拓、拾物／回桥补找／包裹归位／本轮成就重置、情境引导和共同布置回归通过；独立导出PCK再次操作传拓与核对角色拾取，原生Windows EXE离线启动通过。自动检查使用Dummy音频，不代替真人听感与陌生玩家试玩。

保留此前大爨独立纪年题签、无答案听音、六色烟花、指定卷轴纸底、小键盘Enter、实物图和人物对话。原用户图片、字库及角色源字节保留。日志只允许既有系统根证书读取诊断，未忽略其它脚本／引擎错误、警告或泄漏，也未修改系统证书。证据见本目录五组原始日志、八张截图与验证记录.json。备份 backups/before-rubbing-ownership-2026-10-19。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-19 最新合作传拓与物归其主：四件随身物品限定对应本人，按键/鼠标/附近入口统一，提示物主和所属玩家；第一关新增两人覆纸定位、分列节拍扑墨、共同揭纸和乱序拓字显影，之后四人分享/六字归位才开门，单人/暂停/中断重进/重玩兼容。取消单格即时亮绿，目标编号同步；石墩重做宽基座、错缝倒角方石、厚压顶与承梁及岸壁墩脚，保留修筑条件和碰撞。新显卡专项、单双人完整三关、回桥补拾/本轮成就与引导布置、独立PCK和原生启动通过。当前 `builds/rubbing-ownership-2026-10-19/CuanParty.exe`，根启动入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录，此前“任一玩家代拾”规则已被本轮取代。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md',
             blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新合作传拓与物归其主：' in text: continue
    backup = root / 'backups/before-rubbing-ownership-2026-10-19/docs' / (path.parent.name + '-' + path.name)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists(): shutil.copy2(path, backup)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/rubbing-ownership-', '`../cuan-game/builds/rubbing-ownership-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md': paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(release / '验证记录.json').write_text(json.dumps(dict(
    result='RUBBING_OWNERSHIP_RELEASE_VERIFIED', date='2026-10-19', checks=checks,
    bundle=bundle, native_startup=startup, font_sha256=font_sha, files=files,
    environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']: (release / name).unlink(missing_ok=True)
print('RUBBING_OWNERSHIP_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
