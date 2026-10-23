from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
previous = root / 'builds/cooperative-experience-2026-10-19'
release = root / 'builds/scene-art-2026-10-19'
release.mkdir(parents=True, exist_ok=True)
(release / '.gdignore').touch()
for name in ['先看这里_启动与操作.txt', '资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
    shutil.copy2(previous / name, release / name)
instructions = (release / '先看这里_启动与操作.txt').read_text(encoding='utf-8-sig')
instructions = instructions.replace('合作玩法与同行引导版', '三幕场景美工版')
instructions += '\n本版场景：连续暮色/月夜天空、分层岩山、可见日月、碑院藤蕨残瓦与木构、溪谷旧石岸及薄雾、共庭格扇与有山坡承接的远村灯火。保留上一版全部合作玩法和收藏。\n'
(release / '先看这里_启动与操作.txt').write_text(instructions, encoding='utf-8')
old_path = 'builds/cooperative-experience-2026-10-19'
new_path = 'builds/scene-art-2026-10-19'
export = (root / 'tools/export_cooperative_release.ps1').read_text(encoding='utf-8-sig')
(root / 'tools/export_scene_art_release.ps1').write_text(export.replace(old_path, new_path), encoding='utf-8-sig')
preset = root / 'export_presets.cfg'
preset.write_text(preset.read_text(encoding='utf-8').replace(old_path, new_path), encoding='utf-8')
backup = root / 'backups/before-scene-art-2026-10-19'
for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
    path = root.parent.parent / name
    if path.exists() and not (backup / name).exists():
        shutil.copy2(path, backup / name)
print('SCENE_ART_RELEASE_PREPARED')
