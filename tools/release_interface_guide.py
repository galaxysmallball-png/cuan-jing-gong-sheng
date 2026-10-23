from pathlib import Path
import hashlib
import json
import shutil
import sys

root = Path(__file__).resolve().parents[1]
previous = 'builds/gate-motion-2026-10-20'
current = 'builds/interface-guide-2026-10-20'
release = root / current
backup = root / 'backups/before-interface-guide-2026-10-20'
if '--prepare' in sys.argv:
    release.mkdir(parents=True, exist_ok=True)
    (release / '.gdignore').touch()
    for name in ['先看这里_启动与操作.txt', '资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
        shutil.copy2(root / previous / name, release / name)
    path = release / '先看这里_启动与操作.txt'
    text = path.read_text(encoding='utf-8-sig').replace('瓦檐细节与动作优化版', '界面与同行引导版')
    text += '\n本轮界面：上方三关路线标记，左下本关目标，右下分别显示两位玩家的角色、下一步和有效长按进度。可点击切到自己所需角色；对应角色由另一位玩家控制时，会提示对方操作。按一下拾物/取灯与长按任务分开说明。H 帮助页包含当前目标、真实角色归属与按键。走过入门操作后教学自动收起，可点击同行引导恢复；对白和过场期间会让出画面。\n'
    path.write_text(text, encoding='utf-8')
    export = (root / 'tools/export_gate_motion_release.ps1').read_text(encoding='utf-8-sig')
    (root / 'tools/export_interface_guide_release.ps1').write_text(export.replace(previous, current), encoding='utf-8-sig')
    path = root / 'export_presets.cfg'
    path.write_text(path.read_text(encoding='utf-8').replace(previous, current), encoding='utf-8')
    for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
        source = root.parent.parent / name
        if source.exists() and not (backup / name).exists(): shutil.copy2(source, backup / name)
    print('INTERFACE_GUIDE_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
environment = 'ERROR: Failed to read the root certificate store.'
checks = {'interface-guide-gpu.log': 'INTERFACE_GUIDE_OK', 'interface-guide-cooperation-gpu.log': 'COOPERATIVE_EXPERIENCE_OK',
          'interface-guide-carried-gpu.log': 'CARRIED_ARRIVAL_OK', 'interface-guide-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
          'interface-guide-single.log': 'PARTY_GAME_OK'}


def verify_log(path, marker):
    text = path.read_text(encoding='utf-8-sig')
    assert marker in text, (path, marker)
    diagnostics = [line for line in text.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(root / 'previews' / name, marker)
    shutil.copy2(root / 'previews' / name, release / name)
verify_log(root / 'previews/interface-guide-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'), ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['three_chapter_per_player_next_step_guidance_owner_switch_and_current_goal_help_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
shots = {'coop-guide-first-act.png': '界面_第一关与双人下一步.png',
         'coop-guide-help-current-goal.png': '界面_当前目标与操作帮助.png',
         'coop-guide-creek-owner-and-hold.png': '引导_角色归属与有效长按.png',
         'coop-guide-rope-roles.png': '引导_护碑与收放绳分工.png',
         'coop-guide-court-missing-keepsake.png': '引导_缺失物件一起返程.png',
         'coop-guide-take-lamp-once.png': '引导_取灯按一下.png'}
for source, target in shots.items(): shutil.copy2(root / 'previews' / source, release / target)
note = '界面与同行引导_三关路线双人下一步与帮助_说明.md'
description = '''# 界面与同行引导 · 2026-10-20

最新导出 builds/interface-guide-2026-10-20，根目录两个“开始游戏”入口同步。EXE/PCK保持同目录，本轮不新增ZIP。

上方三关路线按真实任务完成状态标记，进入过某关不算完成。左下保留用户纸底的本关目标并适当加宽；右下两张同行卡分清各自角色、下一步、所需目标与有效长按百分比，单人只留一张。换人按钮只切到该玩家自己所需角色，另一位玩家拥有该角色时明确提示对方，不能抢人、代收线索或代拾物件；附近操作与键盘任务规则不变。

第一关明确小爨主线，完成后提示对应物主拾取拓片/錾子；第二关随水痕、备料、识路、推料、砌墩、联络、架桥、护碑与交接更新任务，桥心顶碑长按与右岸收放绳分开说明；第三关先合力立碑，再各人物件归位、共同布置和三灯送达。缺少物件时按真实散落关卡提示两人一起返程、B查位置；安放完当前角色会建议自己的另一位未完成同行，携灯角色也会准确提示换回。拾物和取灯写按一下，站稳长按和放绳写清楚；有效操作角色才显示长按百分比，不把同伴的进度显示成自己在操作。不给听音小游戏答案。

走过入门移动后教学自动收起，同行引导入口/H可恢复；彩幔待布置时保留必要继续入口。靠近浮窗会避让路线、教学、绳张力与通知，并保留物件连线。对白时同行卡让出阅读区，搬运/立碑/长卷/帮助/其它模态自动收起相关HUD，避免叠纸。原第三幕的重复个人进度卡收起，场景站位标记不改。

H帮助页重新排版：当前目标两行摘要、实际两位玩家专属角色、两列按键与重开说明；暂停世界并收起其它任务面板，关闭准确恢复。单人模式不显示2P操作。爨体与标题轻微加粗、用户按钮和通知纸图、右上声音设置及所有角色模型/动作/物理和主线任务参数保留。

验证：新NVIDIA实机专项覆盖三关路线、第一关指引、真实点击按归属切换且无拾物/任务副作用、真实水痕长按百分比和松手清零、不向另一玩家错记百分比、顶碑/收绳分工、缺失物件返回位置、取灯按一下、帮助目标和角色/单人适配、移动后收起/恢复/T清理、对白优先与点击遮罩。六张截图检查文本和按钮间距、帮助各段和固定/附近面板避让。合作玩法专项、四人搬运和统一通知专项、完整双人GPU与单人三关通过。独立PCK检查新三关/双人引导与帮助暂停和隐藏，原有21物件/实物图/归属/成就本轮重置/字体/动作/场景检查保留；原生Windows启动通过。导出目录含日志、截图及SHA256。只允许既有系统根证书读取诊断，不忽略其它错误、警告或泄漏；测试Dummy音频不代替真人听感。备份 backups/before-interface-guide-2026-10-20。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-20 最新界面与同行引导：真实完成状态三关路线、左下本关目标与右下双人下一步；按归属切到所需角色，按一下/长按/收放绳分清，百分比只记有效角色。缺物提示一起返程与B查位置、安放后建议自己的未完成同行。入门移动后教学收起可恢复，附近浮窗避让固定HUD、对白/过场/模态让出画面，收起旧第三幕重复卡。H帮助展示当前目标摘要、真实归属和两列键位，单人适配。新实机引导专项、合作专项、搬运专项、完整单双人、独立PCK与原生启动通过。当前 `builds/interface-guide-2026-10-20/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md', blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新界面与同行引导：' in text: continue
    doc_backup = backup / 'docs' / (path.parent.name + '-' + path.name)
    doc_backup.parent.mkdir(parents=True, exist_ok=True)
    if not doc_backup.exists(): shutil.copy2(path, doc_backup)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/interface-guide-', '`../cuan-game/builds/interface-guide-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md': paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
(release / '验证记录.json').write_text(json.dumps(dict(result='INTERFACE_GUIDE_RELEASE_VERIFIED', date='2026-10-20',
    checks=checks, bundle=bundle, native_startup=startup, font_sha256=font_sha, files=files,
    environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']: (release / name).unlink(missing_ok=True)
print('INTERFACE_GUIDE_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
