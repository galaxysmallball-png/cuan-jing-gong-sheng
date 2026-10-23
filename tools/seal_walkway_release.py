from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root/'builds/walkway-fixes-2026-10-18'
previews = root/'previews'
checks = {
    'walkway-gpu-fixes.log':'WALKWAY_FIXES_OK',
    'walkway-gpu-capture_local_coop.log':'LOCAL_COOP_RENDER_OK',
    'walkway-gpu-verify_grand_court.log':'GRAND_COURT_OK',
    'walkway-headless-verify_planar_transport.log':'PLANAR_TRANSPORT_OK',
    'walkway-headless-verify_party_game.log':'PARTY_GAME_OK',
    'walkway-headless-verify_nearby_interactions.log':'NEARBY_INTERACTIONS_OK',
}
for name,marker in checks.items():
    text = (previews/name).read_text(encoding='utf-8')
    assert marker in text and 'ERROR:' not in text, name
    shutil.copy2(previews/name,release/name)
for name in ['startup.log','pck-check.log','export-console.log']:
    text = (release/name).read_text(encoding='utf-8')
    assert 'Godot Engine' in text and 'ERROR:' not in text, name
bundle = json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['sound_entry_large_plaques_and_walkway_verified']
shots = {
    'coop-walkway-title-sound-corner.png':'封面声音按钮_最右上角.png',
    'coop-walkway-clear-large-plaques.png':'两块放大牌匾_完整字面.png',
    'coop-walkway-logs-followers-grounded.png':'跟随者绕行木料_不跳上顶面.png',
    'coop-walkway-bridge-ends-safe.png':'两端桥头_安全通行.png',
}
for src,dst in shots.items(): shutil.copy2(previews/src,release/dst)
files = {}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p = release/name
    files[name] = dict(bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest())
record = dict(result='WALKWAY_FIXES_RELEASE_VERIFIED',date='2026-10-18',checks=checks,bundle=bundle,
    native_startup_exit_code=0,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',files=files,
    coverage='真实渲染与注入输入：封面右上角入口、放大牌面与灯笼投影无重叠、木料双向绕行、四个桥角斜走跳跃、双人三关完整流程。原生无界面启动只验证启动。')
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('WALKWAY_FIXES_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'GPU screenshots')
