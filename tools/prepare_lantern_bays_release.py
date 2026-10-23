from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/lantern-bays-steles-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
old=root/'builds/stone-roof-2026-10-19'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(old/name,release/name)
p=release/'先看这里_启动与操作.txt'
s=p.read_text(encoding='utf-8-sig').replace('stone-roof-2026-10-19','lantern-bays-steles-2026-10-19')
p.write_text('2026-10-19 灯笼分组与二爨合读版：下方岩层压深，灯笼依门楼/廊檐分组。点击大爨碑可读两碑介绍并合读三题，收对照笺、为小碑添字形参照；包裹B可回看。线索通知只留居中文字，取消右侧按钮。\n\n'+s,encoding='utf-8')
p=root/'export_presets.cfg'
p.write_text(p.read_text(encoding='utf-8').replace('builds/stone-roof-2026-10-19/CuanParty.exe','builds/lantern-bays-steles-2026-10-19/CuanParty.exe'),encoding='utf-8')
s=(root/'tools/export_stone_roof_release.ps1').read_text(encoding='utf-8-sig')
(root/'tools/export_lantern_bays_release.ps1').write_text(s.replace('stone-roof-2026-10-19','lantern-bays-steles-2026-10-19'),encoding='utf-8-sig')
print('LANTERN_BAYS_RELEASE_PREPARED')
