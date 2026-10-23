from pathlib import Path
import hashlib
import json
import shutil
import sys

root = Path(__file__).resolve().parents[1]
previous = 'builds/rubbing-ownership-2026-10-19'
current = 'builds/carried-arrival-2026-10-20'
release = root / current
backup = root / 'backups/before-carried-arrival-2026-10-19'
if '--prepare' in sys.argv:
    release.mkdir(parents=True, exist_ok=True)
    (release / '.gdignore').touch()
    for name in ['先看这里_启动与操作.txt', '资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
        shutil.copy2(root / previous / name, release / name)
    path = release / '先看这里_启动与操作.txt'
    text = path.read_text(encoding='utf-8-sig').replace('合作传拓与物归其主版', '合抬入院与通知统一版').replace(' · 2026-10-19', ' · 2026-10-20')
    text = text.replace('第三关：随碑入院，合力立碑；由四位角色安放前两关亲自拾得的对应物件。',
        '第三关：四位同行会合抬架，合抬石碑入院、到碑座前放稳，然后由石阿朵与同伴合力立碑。\n入院短演出中暂收移动、换人；结束后自动恢复。H/档案等暂停会同时冻结人物与石碑。\n之后由四位角色安放前两关亲自拾得的对应物件。')
    text += '\n成就与线索通知统一：花鸟纸底、爨体朱红文字居中、纸框随内容调宽高；同时出现上下错开。成就不再显示右侧按钮，按C或顶栏入口查看。\n'
    path.write_text(text, encoding='utf-8')
    export = (root / 'tools/export_rubbing_ownership_release.ps1').read_text(encoding='utf-8-sig')
    (root / 'tools/export_carried_arrival_release.ps1').write_text(export.replace(previous, current).replace("date='2026-10-19'", "date='2026-10-20'"), encoding='utf-8-sig')
    preset = root / 'export_presets.cfg'
    preset.write_text(preset.read_text(encoding='utf-8').replace(previous, current).replace('builds/carried-arrival-2026-10-19', current), encoding='utf-8')
    for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
        source = root.parent.parent / name
        if source.exists() and not (backup / name).exists(): shutil.copy2(source, backup / name)
    print('CARRIED_ARRIVAL_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
environment = 'ERROR: Failed to read the root certificate store.'
checks = {'carried-arrival-gpu.log': 'CARRIED_ARRIVAL_OK', 'carried-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
          'carried-single.log': 'PARTY_GAME_OK', 'carried-keepsakes-gpu.log': 'JOURNEY_KEEPSAKES_OK'}


def verify_log(path, marker):
    text = path.read_text(encoding='utf-8-sig')
    assert marker in text, (path, marker)
    diagnostics = [line for line in text.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)


for name, marker in checks.items():
    verify_log(root / 'previews' / name, marker)
    shutil.copy2(root / 'previews' / name, release / name)
verify_log(root / 'previews/carried-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'),
                     ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'), ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['shared_centered_receipts_and_four_real_bearers_flat_arrival_restore_controls_and_raise_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
font_sha = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots = {'coop-carried-matching-receipts.png': '通知_成就与线索统一.png',
         'coop-carried-long-achievement-receipt.png': '通知_长文居中与自适应.png',
         'coop-carried-gather-and-lift.png': '入院_四人会合抬起.png',
         'coop-carried-four-people-walking.png': '入院_四人同步抬碑.png',
         'coop-carried-lowering-at-plinth.png': '入院_碑座前放稳抬架.png',
         'coop-carried-stone-raised-after-delivery.png': '入院_衔接合力立碑.png'}
for source, target in shots.items(): shutil.copy2(root / 'previews' / source, release / target)
note = '统一获得通知_四人合抬入院_说明.md'
description = '''# 获得通知统一与四人合抬入院 · 2026-10-20

最新导出 builds/carried-arrival-2026-10-20，根目录两个“开始游戏”入口同步。EXE/PCK保持同目录，本轮不新增ZIP。

成就通知与线索/物件获得通知统一使用interface_skin.layout_notice：用户花鸟纸底、现有爨体标题字重、16号基准放大字号、朱红文字、水平/垂直居中、相同内边距；宽340—570随内容、长文高度自适应。删除成就通知右侧可见按钮，文案保留“按C查看”；顶栏入口与C均有效。原来新收录/成就名称/器物分组和进度信息保留，多项成就不截字；同时出现的两纸框右对齐、上下留空。搬运过场暂收通知及情境引导，避免遮挡动作。

第二关真实交接后，第三关改为四位现有主角会合、合抬、迈步、到位放下的3.2秒短演出。直接使用同一组实际人物，临时接管位置与动作，前后排错开；携带步态收起手持工具，四根手中短杠与八条绳套连接木抬架，位置随实际手部更新。碑平放在抬架上，与架同路移动和起落；到碑座前连架放稳。结束恢复四人原物理更新和两人控制，再由玩家执行原有合力立碑。

立碑木架保留碑脚枢转、双绳收放和最终落座；起始姿态改为接纳平放石碑，使用完整旋转过渡，避免抬完突然翻面或立起。到位前不能提前扶碑。暂停同时冻结演员和石碑；换人不能拆散演出，R中断安全恢复操作且保留已送达状态，T/本关重开清理临时抬架绑定、工具动作和控制接管。直达第三关与正常交接复用流程；回桥不重新生成运输碑。未修改原人物GLB/Blender、用户图片、字库及三关主线操作参数。

验证：新NVIDIA GPU专项检查真实器物收录触发成就通知、两类通知字体字号/居中/纸框一致、长文不截字、双通知不重叠、C开册；真实右岸交接、四个实际人物携带姿态与手杠/绳套、抬起和行走/放下中间画面、暂停和换人隔离、恢复四人物理与双人控制、平放到合力立碑、演出中T/R清理。完整双人与单人三关、沿途物主拾取/回桥补找/包裹归位/本轮成就重置回归通过，独立PCK核对四人搬运/结束恢复/平放起碑和通知统一，原生Windows启动通过。截图六张及原始日志、哈希见验证记录.json；自动检查用Dummy音频，不替代真人试玩听感。日志只允许既有系统根证书读取诊断，不忽略其它错误、警告或资源泄漏；未修改系统证书。备份 backups/before-carried-arrival-2026-10-19。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-20 最新统一获得通知与四人合抬入院：成就与线索共用花鸟纸、爨体朱红居中和随字自适应框，去成就右侧按钮、C保留，双通知错开。第三关四名实际角色会合、手杠/八绳套连接平放碑与木架、同步步态运至碑座前放下，再接完整旋转的扶碑落座；暂停、换人隔离、R/T/本关重开安全恢复物理和控制，过场收起遮挡引导。新GPU专项、完整单双人、拾物回桥/成就重置、独立PCK和原生启动通过。当前 `builds/carried-arrival-2026-10-20/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录，木橇自行平移及成就侧按钮已由本轮取代。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md', blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    text = path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新统一获得通知与四人合抬入院：' in text: continue
    doc_backup = backup / 'docs' / (path.parent.name + '-' + path.name)
    doc_backup.parent.mkdir(parents=True, exist_ok=True)
    if not doc_backup.exists(): shutil.copy2(path, doc_backup)
    first, rest = text.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/carried-arrival-', '`../cuan-game/builds/carried-arrival-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md': paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(release / '验证记录.json').write_text(json.dumps(dict(result='CARRIED_ARRIVAL_RELEASE_VERIFIED', date='2026-10-20',
    checks=checks, bundle=bundle, native_startup=startup, font_sha256=font_sha, files=files,
    environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']: (release / name).unlink(missing_ok=True)
print('CARRIED_ARRIVAL_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
