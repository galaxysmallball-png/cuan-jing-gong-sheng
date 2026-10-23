from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/stone-roof-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
old=root/'builds/craft-polish-2026-10-19'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(old/name,release/name)
p=release/'先看这里_启动与操作.txt'
s=p.read_text(encoding='utf-8-sig').replace('craft-polish-2026-10-19','stone-roof-2026-10-19')
p.write_text('2026-10-19 岩岸瓦檐与立碑细化版：岩岸改为错落岩层，远处瓦檐补叠瓦/瓦当/木构，印花从素布逐次显纹，立碑增加木架牵绳、缓抬与落座。\n\n'+s,encoding='utf-8')
p=root/'export_presets.cfg'
p.write_text(p.read_text(encoding='utf-8').replace('builds/craft-polish-2026-10-19/CuanParty.exe','builds/stone-roof-2026-10-19/CuanParty.exe'),encoding='utf-8')
script=(root/'tools/export_craft_release.ps1').read_text(encoding='utf-8-sig')
(root/'tools/export_stone_roof_release.ps1').write_text(script.replace('craft-polish-2026-10-19','stone-roof-2026-10-19'),encoding='utf-8-sig')
print('STONE_ROOF_RELEASE_PREPARED')
