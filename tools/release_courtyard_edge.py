from pathlib import Path
import hashlib, json, shutil, sys

root = Path(__file__).resolve().parents[1]
previous = 'builds/art-audit-2026-10-20'
current = 'builds/courtyard-edge-original-draw-2026-10-20'
release = root / current
backup = root / 'backups/before-courtyard-edge-original-draw-2026-10-20'
allowed = 'ERROR: Failed to read the root certificate store.'

if '--prepare' in sys.argv:
    release.mkdir(parents=True, exist_ok=True)
    (release / '.gdignore').touch()
    for name in ['资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
        shutil.copy2(root / previous / name, release / name)
    source = (root / 'tools/export_art_audit_release.ps1').read_text(encoding='utf-8-sig')
    (root / 'tools/export_courtyard_edge_release.ps1').write_text(source.replace(previous, current), encoding='utf-8-sig')
    preset = root / 'export_presets.cfg'
    preset.write_text(preset.read_text(encoding='utf-8').replace(previous, current), encoding='utf-8')
    print('COURTYARD_EDGE_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
checks = {
    'courtyard-edge-after.log': 'COURTYARD_EDGE_OK edge-after',
    'courtyard-edge-steles-original-audio.log': 'TWIN_STELES_ART_OK',
    'courtyard-edge-coop.log': 'LOCAL_COOP_RENDER_OK',
    'courtyard-edge-single.log': 'PARTY_GAME_OK',
    'original-opening-audio.log': 'ORIGINAL_OPENING_AUDIO_OK',
}
for name, marker in checks.items():
    log = (root / 'previews' / name).read_text(encoding='utf-8-sig')
    assert marker in log, name
    assert all(allowed in line for line in log.splitlines() if 'ERROR:' in line), name
    assert 'SCRIPT ERROR' not in log and 'WARNING:' not in log, name
    shutil.copy2(root / 'previews' / name, release / name)
for name in ['pck-check.log', 'startup.log', 'export-console.log']:
    log = (release / name).read_text(encoding='utf-8-sig')
    assert all(allowed in line for line in log.splitlines() if 'ERROR:' in line), name
    assert 'SCRIPT ERROR' not in log and 'WARNING:' not in log, name
assert json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))['exit_code'] == 0
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8-sig'))
assert bundle and all(value is not False for value in bundle.values())
audio = json.loads((root / 'previews/original-opening-audio.json').read_text(encoding='utf-8'))
assert audio['original_assets'] and not audio['continuous_rotation_playing'] and audio['rms_dbfs'] > -48
shutil.copy2(root / 'previews/original-opening-audio.json', release / '选牌原音效_输出校验.json')

images = ['coop-refine-edge-before-right.png', 'coop-refine-edge-after-right.png',
          'coop-refine-edge-before-garden.png', 'coop-refine-edge-after-garden.png',
          'coop-refine-stele-thickness-flat.png', 'coop-refine-stele-thickness-standing.png',
          'coop-edge-after-game-camera.png']
for name in images:
    assert (root / 'previews' / name).stat().st_size > 10000
    shutil.copy2(root / 'previews' / name, release / name)

gallery = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>共庭右侧与碑身修正</title>
<style>body{margin:0;background:#111c21;color:#eadbc0;font:17px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:26px}h1{font-size:28px}h2{font-size:21px;margin-top:36px}p{color:#c8c6b7}img{display:block;width:100%;border-radius:5px}figure{margin:0}figcaption{padding:8px 0;color:#c8c6b7}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}a{color:#e7bb70}audio{width:min(100%,520px)}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style>
<main><h1>共庭右侧与碑身修正</h1><p>2026年10月20日 · 本轮更新。右侧铺地、三道台阶与岩基接到镜头外，补低墙、压顶和植石收边；碑身修正反面剔除、增加实际厚度与倒角；选牌恢复最初的逐牌翻动与选定声音。</p>
<h2>右侧收边 · 相同镜头</h2><div class="pair"><figure><img src="coop-refine-edge-before-right.png"><figcaption>修正前</figcaption></figure><figure><img src="coop-refine-edge-after-right.png"><figcaption>修正后</figcaption></figure></div>
<h2>完整院落</h2><img src="coop-refine-edge-after-garden.png">
<h2>平放的碑身</h2><img src="coop-refine-stele-thickness-flat.png"><p>实体侧边与倒角可见，石碑放在木架上方。</p>
<h2>立起的碑身</h2><img src="coop-refine-stele-thickness-standing.png">
<h2>游戏正常镜头</h2><img src="coop-edge-after-game-camera.png">
<h2>最初的选牌声音</h2><p>逐牌翻动，停牌选定；转动时不再播放后来添加的连续旋转声。</p><audio controls src="opening-original-flip.wav"></audio><audio controls src="opening-original-pick.wav"></audio>
<p><a href="CuanParty.exe">最新版游戏</a> · <a href="../art-audit-2026-10-20/美术前后对照.html">上一轮三幕美术对照</a></p></main></html>'''
(release / '本轮修正预览.html').write_text(gallery, encoding='utf-8')
audio_hashes = {}
for kind in ['flip', 'pick']:
    source = root / f'assets/audio/interactions/card_{kind}.wav'
    shutil.copy2(source, release / f'opening-original-{kind}.wav')
    audio_hashes[kind] = hashlib.sha256(source.read_bytes()).hexdigest()

note = '''# 共庭右侧收边、碑身厚度与选牌原音效

2026-10-20，回应本轮三项反馈。

- 右侧断口：庭院装饰地基从局部X20.3延长到28，增加右端实体岩面；地砖、三道台阶接续到画面外，后侧补错缝石墙、压顶木栏、碎岩与叶片，避免在正常镜头和更宽对照镜头中露出切口。
- 石碑：原石碑三角面朝向反转，靠近镜头的侧面被剔除，看起来只有薄面。修正碑身与碑冠朝向；第三幕碑身实际深度由0.30改为0.42，新增小倒角，碑文跟随正面深度。保留原碑座、木架高度与四人搬运/扶碑时长，扶碑逐帧检查最低点仍高于台阶。
- 选牌：按用户最新要求恢复最早有声版的原始card_flip/card_pick文件，牌经过正面时触发短翻牌，停牌/跳过时使用选定声音，不再调用连续旋转声。声音开关、音量、重抽与跳过有效。其余交互声音保持当前版本。

本轮验证：相同镜头与正常最大镜头GPU检查、平放/立起近景；两碑实际点选及强制合验、R/T/重抽/静音/跳过；平放与扶碑每帧净空；完整双人GPU三关及单人三关；独立PCK资源与原生EXE启动。新增收边没有碰撞节点，保持原通行边界与任务位置。

实际音频总线采样确认翻牌和选定均有输出，使用原始文件并记录SHA256。日志只保留本机已有的系统根证书读取环境诊断，无新增脚本错误/警告。原GLB、Blender工程、图片和爨体字库保持原样。场景是游戏美术表达。

启动：同目录CuanParty.exe与CuanParty.pck须保留在一起。根目录两处游戏入口将同步指向本版；旧构建和修改前备份保留。本轮没有新建ZIP。
'''
(release / '本轮改动与验证.md').write_text(note, encoding='utf-8')
(release / '先看这里_启动与操作.txt').write_text('双击 CuanParty.exe 启动，请保留同目录 CuanParty.pck。\n\n本轮：庭院右侧收边、石碑实体厚度、最初选牌音效。\n1P：WASD 移动，空格跳，E 操作，F 交谈，Tab 换同行。\n2P：方向键移动，小键盘 Enter 跳，P/小键盘0 操作，/ 交谈，右 Shift 换同行。\nB 包裹，C 见闻，H 帮助，F2 暂停。\nR 回位保留本轮，T 新旅程清空；成就每次进入游戏重置。\n\n打开 本轮修正预览.html 查看对照和原音效试听。\n', encoding='utf-8-sig')
doc = root.parent / 'cuan-game-blueprint/共庭右侧收边_碑身实体与选牌原音效_说明.md'
doc.write_text(note, encoding='utf-8')
entry = '2026-10-20 最新共庭收边与碑身修正：右侧铺地/三道台阶/岩基延至镜头外并补低墙植石，石碑修正被剔除的外侧面、实体深度0.42与小倒角，碑文随正面。选牌按最新要求恢复最初逐牌翻动与选定原声，取代连续旋转声。两碑/重抽/静音/跳过、扶碑逐帧净空、单双人三关、音频实际输出、独立PCK及原生启动通过。'
for path, prefix in [(root/'README.md',''), (root/'AGENTS.md',''), (root.parent/'AGENTS.md','cuan-game/'), (root.parent/'cuan-game-blueprint/README.md','../cuan-game/'), (root.parent/'cuan-game-blueprint/四人同行_试玩说明.md','../cuan-game/')]:
    old = path.read_text(encoding='utf-8-sig')
    first, rest = old.split('\n', 1)
    bullet = '- ' if path.name == 'AGENTS.md' else ''
    path.write_text(first+'\n\n'+bullet+entry+f' 当前 `{prefix}{current}/CuanParty.exe`，根入口同步。下方为历史记录。\n'+rest, encoding='utf-8')
record = {'date':'2026-10-20', 'build':current, 'checks':checks, 'audio':audio, 'original_audio_sha256':audio_hashes, 'screenshots':images,
          'files':{name:{'bytes':(release/name).stat().st_size,'sha256':hashlib.sha256((release/name).read_bytes()).hexdigest()} for name in ['CuanParty.exe','CuanParty.pck']}}
(release / '验证记录.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:
    (release/name).unlink(missing_ok=True)
print('COURTYARD_EDGE_RELEASE_SEALED')
