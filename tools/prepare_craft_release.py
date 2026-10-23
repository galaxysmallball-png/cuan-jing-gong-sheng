from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/craft-polish-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
old=root/'builds/all-cuan-2026-10-19'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(old/name,release/name)
p=release/'先看这里_启动与操作.txt'
s=p.read_text(encoding='utf-8-sig').replace('all-cuan-2026-10-19','craft-polish-2026-10-19')
p.write_text('2026-10-19 字体放大与器物小艺美化版：文字整体约增大16%，纹样/配重重画，瀑布从岩缝向左弯落，第二关碑随木橇送入第三关，新成就/线索通知按钮采用花鸟图。\n\n'+s,encoding='utf-8')
p=root/'export_presets.cfg'
s=p.read_text(encoding='utf-8').replace('builds/all-cuan-2026-10-19/CuanParty.exe','builds/craft-polish-2026-10-19/CuanParty.exe')
p.write_text(s,encoding='utf-8')
print('CRAFT_RELEASE_PREPARED')
