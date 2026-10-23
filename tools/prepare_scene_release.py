"""Prepare reviewable local build notes and preserve the user's original concept boards."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
base = root.parent.parent
release = root / 'builds/scene-atmosphere-2026-10-18'
release.mkdir(parents=True, exist_ok=True)
(release / '.gdignore').touch()
refs = root / 'references/scene-concepts-2026-10-18'
refs.mkdir(parents=True, exist_ok=True)
(refs / '.gdignore').touch()
originals = Path('C:/Users/26845/Desktop/树莓比赛美工/人物和场景/场景图')
records = []
for name in ['雾廊碑院：古寺遗迹概念设定.png', '第三幕：灯火共庭概念设定板.png', '月下断溪古道概念设定图.png']:
    source = originals / name
    target = refs / name
    shutil.copy2(source, target)
    records.append(dict(source=str(source), copy=name, sha256=hashlib.sha256(source.read_bytes()).hexdigest(), use='用户提供的场景风格参考；原生三维演绎，非历史建筑复原'))
(refs / 'SOURCE.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')

# Preserve the pre-change grand-court block (the only removed geometry).
p = root / 'scripts/grand_court.gd'
t = p.read_text(encoding='utf-8')
backup = root / 'backups/before-scene-atmosphere-2026-10-18/scripts_grand_court.gd'
if not backup.exists(): backup.write_text(t.replace('for layer in range(0):','for layer in range(2):',1), encoding='utf-8')
a = t.find('\tfor layer in range(0):')
if a >= 0:
    b = t.index('\tfor side in [-1, 1]:', a)
    p.write_text(t[:a]+t[b:], encoding='utf-8', newline='\n')

old = root / 'builds/planar-transport-2026-10-18'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt']:
    shutil.copy2(old/name, release/name)
info = release / '先看这里_启动与操作.txt'
info.write_text('爨境·共生 / 三幕场景细化与桥栏修正版\n\n声音设置已缩至右上角，点开后分别调整音乐与音效。\n桥面跳跃与跟随过桥已修正，人物不会落到绳子上。\n三关按新概念图细化夕照残院、月下溪谷和灯火庭院。\n\n'+info.read_text(encoding='utf-8'), encoding='utf-8')
shutil.copy2(root.parent/'cuan-game-blueprint/三幕设定图_场景细化与桥栏修正_说明.md', release/'本轮改动与验证.md')

note = '2026-10-18 最新三幕场景细化与桥栏修正：声音设置纸面板缩至右上角（顶栏下方），音乐/音效独立开关与滑条保留。桥两侧改不可登顶的安全边界，跟随者在岸边先对准桥端，桥内停止自动跳障，避免站上绳子。按用户三图加入夕照雾山与阔叶树、月下崖壁瀑布及绕石泡沫、共庭远村灯火与瓦垄木构/水光；原生三维装饰合并材质批次，人物源与关卡参数保留。新实机专项、完整双人及声音/对话/器物 GPU、四向石碑/单人/附近交互检查通过，导出资源与启动验证见构建日志。当前 `builds/scene-atmosphere-2026-10-18/CuanParty.exe`，根最新版快捷方式同步；本轮未另做压缩包。见 [本轮说明](../cuan-game-blueprint/三幕设定图_场景细化与桥栏修正_说明.md)。下方为历史记录。'
for rel in ['README.md','制作记录.md','AGENTS.md']:
    p = root / rel
    t = p.read_text(encoding='utf-8')
    if note not in t:
        h, rest = t.split('\n',1)
        p.write_text(h+'\n\n'+('- ' if rel=='AGENTS.md' else '')+note+'\n'+rest, encoding='utf-8', newline='\n')
for rel in ['README.md','四人同行_试玩说明.md']:
    p = root.parent/'cuan-game-blueprint'/rel
    t = p.read_text(encoding='utf-8')
    n = note.replace('`builds/','`../cuan-game/builds/').replace('../cuan-game-blueprint/','./')
    if n not in t:
        h, rest = t.split('\n',1)
        p.write_text(h+'\n\n'+n+'\n'+rest, encoding='utf-8', newline='\n')
p = root.parent/'AGENTS.md'
t = p.read_text(encoding='utf-8')
n = note.replace('../cuan-game-blueprint/','cuan-game-blueprint/')
if n not in t:
    h, rest = t.split('\n',1)
    p.write_text(h+'\n\n- '+n+'\n'+rest, encoding='utf-8', newline='\n')
print('SCENE_RELEASE_PREPARED', len(records), 'original concept boards preserved')
