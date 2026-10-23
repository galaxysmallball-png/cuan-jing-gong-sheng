from pathlib import Path
import hashlib
import json
import shutil
import sys

root = Path(__file__).resolve().parents[1]
previous = 'builds/carried-arrival-2026-10-20'
current = 'builds/gate-motion-2026-10-20'
release = root / current
backup = root / 'backups/before-gate-motion-2026-10-20'
if '--prepare' in sys.argv:
    release.mkdir(parents=True, exist_ok=True)
    (release / '.gdignore').touch()
    for name in ['先看这里_启动与操作.txt', '资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
        shutil.copy2(root / previous / name, release / name)
    path = release / '先看这里_启动与操作.txt'
    text = path.read_text(encoding='utf-8-sig').replace('合抬入院与通知统一版', '瓦檐细节与动作优化版')
    text += '\n本轮：往城中门屋补曲面叠瓦、瓦当、椽头、木梁和承檐支架；动作新增原地持重、备木/砌墩/拉绳/安放手部节奏、跳跃下落与落地缓冲，劳作朝向目标，合抬加减速与步伐同步。移动、跳跃、任务时长及按键规则保持原参数。\n'
    path.write_text(text, encoding='utf-8')
    export = (root / 'tools/export_carried_arrival_release.ps1').read_text(encoding='utf-8-sig')
    (root / 'tools/export_gate_motion_release.ps1').write_text(export.replace(previous, current), encoding='utf-8-sig')
    path = root / 'export_presets.cfg'
    path.write_text(path.read_text(encoding='utf-8').replace(previous, current), encoding='utf-8')
    for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
        source = root.parent.parent / name
        if source.exists() and not (backup / name).exists(): shutil.copy2(source, backup / name)
    print('GATE_MOTION_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
environment = 'ERROR: Failed to read the root certificate store.'
checks = {'gate-motion-gpu.log': 'GATE_MOTION_OK', 'gate-motion-carried-gpu.log': 'CARRIED_ARRIVAL_OK',
          'gate-motion-coop-gpu.log': 'LOCAL_COOP_RENDER_OK', 'gate-motion-single.log': 'PARTY_GAME_OK'}


def verify_log(path, marker):
    text = path.read_text(encoding='utf-8-sig')
    assert marker in text, (path, marker)
    diagnostics = [line for line in text.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(root / 'previews' / name, marker)
    shutil.copy2(root / 'previews' / name, release / name)
verify_log(root / 'previews/gate-motion-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'), ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['city_gate_tiled_roof_and_runtime_planted_work_jump_motion_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
shots = {'coop-refine-gate-roof.png': '门屋_曲瓦檐口与承檐木构.png',
         'coop-refine-jump-rise.png': '动作_跳跃上升.png',
         'coop-refine-jump-fall.png': '动作_下落伸腿.png',
         'coop-refine-timber-work.png': '动作_备木捆扎.png',
         'coop-refine-stone-work.png': '动作_砌墩稳石.png',
         'coop-motion-rope-and-stone-support.png': '动作_拉绳与护碑.png',
         'coop-carried-four-people-walking.png': '动作_合抬同步步伐.png',
         'coop-carried-lowering-at-plinth.png': '动作_放架屈膝.png'}
for source, target in shots.items(): shutil.copy2(root / 'previews' / source, release / target)
note = '门屋瓦檐细化_人物动作与持重优化_说明.md'
description = '''# 门屋瓦檐细化与人物动作优化 · 2026-10-20

最新导出 builds/gate-motion-2026-10-20，根目录两个“开始游戏”入口同步。EXE/PCK保持同目录，本轮不新增ZIP。

用户截图中“往城中”门屋属于断溪出口的creek_art._build_exit。原两块平屋面换为与共庭一致的曲面筒瓦：双坡搭接瓦垄、逐瓦轻微色差、圆瓦当/滴水边、脊瓦、翘角与凹进的椽头。额外补横梁、穿枋、三层承檐托木与斜撑，直接承接原墙墩，避免屋顶是一块悬浮平板。新增部分沿用合批网格，不增加可走碰撞，牌匾仍露在檐口下方。

动作直接在现有骨架上生成运行时动画变体，原GLB、Blender工程和原六动作不改。原地持重保留上肢持握、使用静止下肢；抬起与放架加屈膝姿态。备木用单手短行程，砌墩/扶碑用双臂受力，拉绳用双臂收放，物件安放用小幅手部节奏；有效任务才播放，松手、离开、换人、重开会退出，劳作时平滑朝向任务目标，脚底不循环踏步。平时走停以实际速度调整步频并平滑过渡，上身有轻微前倾。

跳跃按实际垂直速度区分起跳与下落，下落下肢向站姿舒展，非循环动作结束后保持最后姿态，不在半空重复起跳；落地有0.24秒轻缓压缩恢复。合抬保持四名真实角色与原手杠/八绳套，以搬运距离同步携带步相，短加减速接起止，木架与碑同步轻起伏，放架屈膝后恢复控制。原3.2秒入院、2.8秒立碑、1.6秒长按、移动/跳跃物理与所有按键参数保留；这些动作属于游戏表现，不声称复原历史劳动仪式。

验证：新显卡专项检查真实按键走停、上升/下落、落地缓冲、暂停冻结，真实备木和砌墩任务触发各自动作，备木双脚和人物位置稳定且右手确有行程，实际护碑与拉绳角色分工、站定持重与松手/重开清理；屋顶组成和不增加碰撞。原搬运专项复测真实交接、四人手杠与绳套、暂停和换人隔离、恢复控制、平放后立碑、R/T中断。完整双人GPU与单人三关通过；独立PCK检查四位角色新动作、静止下肢/非循环下落和门屋瓦顶，同时保留21类器物、照片、爨体、角色拾物、成就重置等原校验；原生Windows启动通过。八张实机截图、原始日志和二进制哈希在发布目录。自动检查用Dummy音频，不替代真人听感。日志仅允许既有系统根证书读取诊断，未修改系统证书。备份 backups/before-gate-motion-2026-10-20。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-20 最新门屋瓦檐与动作优化：往城中门屋两片平板换曲面叠瓦、瓦当/脊瓦/翘角与椽头，补承檐木梁托木斜撑、合批无新碰撞。现有骨架运行时增加原地持重/屈膝、备木/砌墩/拉绳/安放手部节奏，劳作朝向目标，走停步频平滑；跳跃区分实际上升下落且不反复重播，落地缓冲；合抬步相同步与架碑共起伏、短加减速。原GLB/Blender、图片/字库、物理与任务时长保持。新GPU动作专项、搬运专项、完整单双人三关、独立PCK与原生启动通过。当前 `builds/gate-motion-2026-10-20/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md', blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新门屋瓦檐与动作优化：' in text: continue
    doc_backup = backup / 'docs' / (path.parent.name + '-' + path.name)
    doc_backup.parent.mkdir(parents=True, exist_ok=True)
    if not doc_backup.exists(): shutil.copy2(path, doc_backup)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/gate-motion-', '`../cuan-game/builds/gate-motion-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md': paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
(release / '验证记录.json').write_text(json.dumps(dict(result='GATE_MOTION_RELEASE_VERIFIED', date='2026-10-20',
    checks=checks, bundle=bundle, native_startup=startup, font_sha256=font_sha, files=files,
    environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']: (release / name).unlink(missing_ok=True)
print('GATE_MOTION_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
