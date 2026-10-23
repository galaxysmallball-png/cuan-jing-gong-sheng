from pathlib import Path
import runpy

root = Path(__file__).resolve().parents[1]
old = 'desktop-android-final-2026-10-21'
new = 'scroll-guidance-correction-2026-10-22'
for name in ['prepare_final_dual_release.py', 'extract_final_apk.py', 'verify_final_dual_artifacts.ps1', 'seal_final_dual_release.py']:
    path = root / 'tools' / name
    value = path.read_text(encoding='utf-8-sig').replace(old, new).replace('final-android-assets-v2', 'scroll-guidance-android-assets-20261022')
    path.write_text(value, encoding='utf-8-sig' if name.endswith('.ps1') else 'utf-8')
presets = root / 'export_presets.cfg'
value = presets.read_text(encoding='utf-8-sig').replace(old, new).replace('version/code=2', 'version/code=3').replace('version/name="0.2.0"', 'version/name="0.2.1"')
presets.write_text(value, encoding='utf-8')
runpy.run_path(str(root / 'tools/prepare_final_dual_release.py'))
print('SCROLL_GUIDANCE_RELEASE_PREPARED')
