from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
name='seated-stele-grand-celebration-2026-10-21'
release=root/'builds'/name
prior=root/'builds/glowing-rewards-fireworks-2026-10-21'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
for entry in ['安卓版暂缓.json','实物照片_来源与授权.md','实物照片目录.json','资料与鸣谢.txt']:
    shutil.copy2(prior/entry,release/entry)
export=(root/'tools/export_glowing_rewards_release.ps1').read_text(encoding='utf-8-sig').replace('glowing-rewards-fireworks-2026-10-21',name)
(root/'tools/export_grand_celebration_release.ps1').write_text(export,encoding='utf-8-sig')
focus=(root/'tools/verify_celebration_rewards.gd').read_text(encoding='utf-8-sig')
old=(root/'tools/verify_shipped_celebration_rewards.gd').read_text(encoding='utf-8-sig')
standalone=old[:old.index('var check_done')]+focus[focus.index('var check_done'):]+ '\n'+old[old.index('func _frames'):]
(root/'tools/verify_shipped_grand_celebration.gd').write_text(standalone,encoding='utf-8')
source=root/'assets/audio/grand_fireworks_20261021/SOURCE.txt'
source.write_text(source.read_text(encoding='utf-8').replace('提高6–7 dB','提高5 dB'),encoding='utf-8')
print(str(release))
