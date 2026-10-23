from pathlib import Path
import shutil
root=Path('数媒/cuan-game');backup=root/'backups/before-stone-roof-animation-2026-10-19'
backup.mkdir(parents=True,exist_ok=True)
for folder in ['scripts','shaders']:
    shutil.copytree(root/folder,backup/folder,dirs_exist_ok=True)
shutil.copy2(root/'export_presets.cfg',backup/'export_presets.cfg')
print('STONE_ROOF_ANIMATION_BACKUP_OK')
