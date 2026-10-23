from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/scene-art-2026-10-19'
previews = root / 'previews'
environment = 'ERROR: Failed to read the root certificate store.'
checks = {
    'scene-art-gpu.log': 'SCENE_ART_OK',
    'scene-art-coop-gpu.log': 'LOCAL_COOP_RENDER_OK',
    'scene-art-walkway-gpu.log': 'WALKWAY_FIXES_OK',
    'scene-art-single.log': 'PARTY_GAME_OK',
}

def verify_log(path, marker):
    content = path.read_text(encoding='utf-8-sig')
    assert marker in content, path
    diagnostics = [line for line in content.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line == environment for line in diagnostics), (path, diagnostics)

for name, marker in checks.items():
    verify_log(previews / name, marker)
    shutil.copy2(previews / name, release / name)
verify_log(previews / 'scene-art-single-stdout.log', 'PARTY_GAME_OK')
for name, marker in [('export-console.log', 'Godot Engine'), ('export-stdout.log', 'Godot Engine'), ('pck-check.log', 'PLAYTEST_BUNDLE_OK'), ('pck-stdout.log', 'PLAYTEST_BUNDLE_OK'), ('startup.log', 'Godot Engine')]:
    verify_log(release / name, marker)
bundle = json.loads((release / 'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['continuous_panorama_native_architectural_foliage_details_and_lamp_aureoles_verified']
assert all(value is True for key, value in bundle.items() if key.endswith('_verified'))
startup = json.loads((release / 'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code'] == 0
font = hashlib.sha256((root / 'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font.upper() == '6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots = {}
for number, label in [('01', 'stele-court'), ('02', 'moonlit-creek'), ('03', 'lantern-court')]:
    for state in ['before', 'after']:
        shots[f'coop-art-{state}-{number}-{label}.png'] = f'{state}-{number}-{label}.png'
shots['coop-art-after-04-play-interface.png'] = 'after-04-play-interface.png'
for source, dest in shots.items():
    shutil.copy2(previews / source, release / dest)
note = '三幕场景美工_连续天幕木构植被与远村灯火_说明.md'
description = '''# 三幕场景美工第一轮 · 2026-10-19

本轮已进入实际游戏场景，导出目录 builds/scene-art-2026-10-19。EXE 和 PCK 须保留同目录，根目录两个“开始游戏”入口指向此版。旧版仍保留，不创建新压缩包。

三幕共用一张72米宽的连续天幕，以世界位置平滑衔接夕照、月夜和共庭暮色，取消原先重叠天空板的硬接缝。日月改为世界坐标定位，调整半径和云层遮罩，解决原来在山体后面看不到的问题；远山轮廓增加小尺度起伏和岩面明暗。终幕高远山降低到实际侧向镜头可见范围，移除上方被高山填成黑板的观感。

雾廊碑院：现有柱檐增加层叠承托、斜撑，残墙露出石砌墙脚，月洞门附近补残瓦、藤蔓、带细叶的蕨草和边缘落叶。四处现有灯位有柔和暖晕，不修改两块爨碑的文字或点击目标。

断溪古道：桥两岸增加分层崖石、旧石护岸、断裂压顶、贴岸藤蕨及溪面薄雾。日月、溪谷与落水源头的构图在真实显卡中检查。保留岩缝出水、向左弯、上细下宽的瀑布，以及已有绕石泡沫；不改变桥板、桥栏或行走碰撞。

灯火共庭：沿现有高门和前亭柱位补木构，左右开间增加细格扇、几何木饰与侧门，保留九处按梁檐分组的挂灯，中央两牌不被遮挡。远村仍为60座、180点窗光，增加连续山坡承接，降低窗光尺寸并区分暖色，避免房子悬在空中。六处暖晕随七灯进度逐步增强；庭院彩幔仍实时表现两位玩家的纹样选择。

新增美术由原生网格和着色器组成，无新外部图片或模型。静态藤叶、构件与碎石按材质合批，新增静态批次不超过26，灯晕不投射方形阴影；装饰不增加实体碰撞。角色模型、用户原图、全界面爨体、21类器物/实物图/成就、二爨合读、三关合作和同行引导保留。建筑和几何装饰为游戏美术化创作，不称为历史建筑复原。

验证：三幕前后同机位实机截图；完整双人三关；桥头四角斜走/跳跃及跟随绕行、两块大牌无遮挡；完整单人流程。导出后从独立PCK检查新天幕、合批美术、灯晕、装饰无碰撞及既有各项功能，Windows原生EXE启动退出码0。见同目录日志、七张图片和验证记录.json。自动检查未代替陌生玩家试玩。

日志保留既有Godot系统根证书读取诊断，未忽略其他脚本/引擎错误或资源泄漏，未改系统证书/网络。本轮修改前源文件和快捷方式备份在 backups/before-scene-art-2026-10-19。
'''
(release / '本轮改动与验证.md').write_text(description, encoding='utf-8')
blueprint = root.parent / 'cuan-game-blueprint'
(blueprint / note).write_text(description, encoding='utf-8')
entry = ('2026-10-19 最新三幕场景美工：共用连续夕照/月夜天幕，日月露出、山体岩面层次；碑院柱檐残瓦藤蕨、溪谷旧石护岸薄雾、共庭格扇木构与山坡远村，十二处柔和暖晕。新增静态细节合批、不加碰撞；九组挂灯、双牌及合作玩法保留。实机三幕、完整双人/单人与桥面牌匾检查、独立PCK和原生启动通过。当前 `builds/scene-art-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/' + note + ')。下方为历史记录。')
for path in [root / 'README.md', root / '制作记录.md', root / 'AGENTS.md', root.parent / 'AGENTS.md', blueprint / 'README.md', blueprint / '四人同行_试玩说明.md']:
    content = path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新三幕场景美工：' in content:
        continue
    backup = root / 'backups/before-scene-art-2026-10-19/docs' / (path.parent.name + '-' + path.name)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(path, backup)
    first, rest = content.split('\n', 1)
    paragraph = ('- ' if path.name == 'AGENTS.md' else '') + entry
    if path.parent == blueprint:
        paragraph = paragraph.replace('`builds/scene-art-', '`../cuan-game/builds/scene-art-').replace('../cuan-game-blueprint/' + note, './' + note)
    elif path == root.parent / 'AGENTS.md':
        paragraph = paragraph.replace('../cuan-game-blueprint/' + note, 'cuan-game-blueprint/' + note)
    path.write_text(first + '\n\n' + paragraph + '\n' + rest, encoding='utf-8')
files = {}
for name in ['CuanParty.exe', 'CuanParty.pck', *shots.values()]:
    path = release / name
    files[name] = {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(release / '验证记录.json').write_text(json.dumps(dict(result='SCENE_ART_RELEASE_VERIFIED', date='2026-10-19', checks=checks, bundle=bundle, native_startup=startup, font_sha256=font, files=files, renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility', environment_diagnostic=environment), ensure_ascii=False, indent=2), encoding='utf-8')
for name in ['bundle-achievements-profile.json', 'startup-test-profile.json']:
    (release / name).unlink(missing_ok=True)
print('SCENE_ART_RELEASE_VERIFIED', len(checks), 'checks,', len(shots), 'screenshots')
