"""Copy verified evidence into this local release. Does not create an archive."""
from pathlib import Path
import json
import hashlib
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/scene-atmosphere-2026-10-18'
previews = root / 'previews'
checks = {
    'atmosphere-gpu-scene.log': 'SCENE_ATMOSPHERE_OK',
    'atmosphere-gpu-coop.log': 'LOCAL_COOP_RENDER_OK',
    'atmosphere-gpu-grand.log': 'GRAND_COURT_OK',
    'atmosphere-headless-verify_planar_transport.log': 'PLANAR_TRANSPORT_OK',
    'atmosphere-headless-verify_party_game.log': 'PARTY_GAME_OK',
    'atmosphere-headless-verify_nearby_interactions.log': 'NEARBY_INTERACTIONS_OK',
}
for name, marker in checks.items():
    text = (previews/name).read_text(encoding='utf-8')
    assert marker in text and 'ERROR:' not in text, name
    shutil.copy2(previews/name, release/name)
for name in ['startup.log','pck-check.log','export-console.log']:
    text = (release/name).read_text(encoding='utf-8')
    assert 'Godot Engine' in text and 'ERROR:' not in text, name
check = json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert check['upper_right_sound_and_concept_scenery_verified']
shots = {
    'coop-atmosphere-sunset-court.png': '第一关_雾廊碑院.png',
    'coop-atmosphere-upper-right-sound.png': '右上角声音设置.png',
    'coop-atmosphere-moonlit-trail.png': '第二关_月下古道.png',
    'coop-atmosphere-bridge-safe-deck.png': '桥面通行_不站绳索.png',
    'coop-atmosphere-shared-finale.png': '第三关_灯火共庭.png',
}
for src, dst in shots.items(): shutil.copy2(previews/src,release/dst)
files = {}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p = release/name
    files[name] = dict(bytes=p.stat().st_size, sha256=hashlib.sha256(p.read_bytes()).hexdigest())
record = dict(result='SCENE_ATMOSPHERE_RELEASE_VERIFIED', date='2026-10-18',
    renderer='NVIDIA GeForce RTX 5060 Laptop GPU / Godot OpenGL Compatibility',
    checks=checks, bundle=check, native_startup_exit_code=0, files=files,
    limits='GPU截图与自动输入检查；无界面原生启动只验证启动。装饰为游戏演绎，不作历史建筑复原。')
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('SCENE_ATMOSPHERE_RELEASE_VERIFIED',len(checks),'checks;',len(shots),'GPU images;',len(files),'hashed files')
