"""Package the already exported Yang Sanniang build and editable source."""
from pathlib import Path
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/yang-character-2026-10-17'
SOURCE = PROJECT / 'builds/yang-model-source-2026-10-17'
SOURCE.mkdir(parents=True, exist_ok=True)
assert all((BUILD / name).is_file() for name in ['CuanParty.exe', 'CuanParty.pck', 'CuanParty.console.exe'])


def write(path, text):
    path.write_text(text, encoding='utf-8-sig')


read_first = '''爨境·共生 — 杨三娘角色美术版（2026-10-17）

双击本目录 CuanParty.exe，点“开始同行”，Esc 可跳过介绍。
请保留同目录 CuanParty.pck；旧包不会自动更新，请运行这个新目录。

开局为 1P 邓书年、2P 石阿朵，杨三娘作为同伴出现。
1P 按数字 4 控制杨三娘；2P 点击下排“杨三娘”，或右 Shift 换到空闲角色。
不能占用另一位玩家正在控制的人。

四名角色现在均为独立风格化模型。杨三娘有深色头巾与蓝灰内帽、蓝衣棕马甲、
卷袖围布、布鞋、扁担竹篮、布卷/包裹/干果及腰间货郎用具。
27 根骨骼和六组基础动作，正侧背均为实际三维模型。
向左走可看背面，停步和换人后保留朝向。
推运、搬护、跳跃时整副货担收起，待机/行走/观察时恢复。

1P：A/D 行走，W/空格跳，S/E 操作，Tab 或数字 1—4 换人。
2P：左右箭头行走，上箭头跳，下箭头操作，右 Shift 换人。
F2 档案暂停，R 回出生点保留进度，T 清空三幕重玩。

已通过杨三娘显卡专项、Blender 源重开、完整双人三幕、单人兼容及三位旧角色专项检查。
独立程序已做有限启动检查。真实双人手感、键盘多键响应和首次通关 5—6 分钟仍待实际试玩。
当前为风格化角色首版，完整表情、精细搬护演出和布料物理仍待后续制作。

附三视图、服装/面部/腰具近景、行走姿态和实际游戏正背面画面。
可编辑源包：杨三娘_模型与Blender工程_2026-10-17.zip。
本程序直接运行即可，无需安装 Godot 或 Blender。
'''
write(BUILD / '先看这里.txt', read_first)
write(BUILD / '完整试玩说明.txt', (PROJECT.parent / 'cuan-game-blueprint/四人同行_试玩说明.md').read_text(encoding='utf8'))
description = (PROJECT.parent / 'cuan-game-blueprint/杨三娘_模型美术说明.md').read_text(encoding='utf8')
write(BUILD / '角色美术说明.txt', description)
write(SOURCE / '模型美术说明.txt', description)
shutil.copy2(PROJECT / 'builds/lao-character-2026-10-16/字体来源与使用范围.txt', BUILD)

pictures = {
    'coop-yang-three-views.png': '杨三娘模型三视图.png',
    'coop-yang-portrait.png': '面部与服装预览.png',
    'coop-yang-face-detail.png': '面部近景.png',
    'coop-yang-neck-detail.png': '头巾与光影近景.png',
    'coop-yang-apron-detail.png': '腰间货郎用具近景.png',
    'coop-yang-walk-studio.png': '行走姿态.png',
    'coop-yang-in-game.png': '游戏实际画面.png',
    'coop-yang-in-game-back.png': '游戏实际背面.png',
}
for origin, name in pictures.items():
    shutil.copy2(PROJECT / 'previews' / origin, BUILD / name)
    shutil.copy2(PROJECT / 'previews' / origin, SOURCE / name)
for origin, name in [
    ('character-source/yang_sanniang/杨三娘_角色工程.blend', '杨三娘_角色工程.blend'),
    ('character-source/yang_sanniang/validation.json', 'validation.json'),
    ('assets/characters/yang_sanniang/yang_sanniang_rigged.glb', '杨三娘_骨骼模型.glb'),
    ('references/杨三娘_用户三视图.png', '杨三娘_用户原始参考.png'),
]:
    shutil.copy2(PROJECT / origin, SOURCE / name)

write(SOURCE / '打开与编辑.txt', '''杨三娘 — 可编辑模型源包（2026-10-17）

使用 Blender 打开“杨三娘_角色工程.blend”。建议 Blender 5.2.2 LTS 或兼容版本。
选中 YangSanniang_CharacterMesh，小键盘句点聚焦，Z 选择材质预览。
参考图和织物图已打包在工程内，不依赖桌面或本机绝对路径。
参考集合 REFERENCE_杨三娘用户三视图；原图也随包另附。

骨架 YangSanniang_Armature 共 27 根骨骼，包含独立裙摆、垂巾、布囊、挂饰、扁担和货篮。
六动作 idle/walk/jump/push/carry/inspect，可在动作编辑器中切换。
货篮 cargo.L/cargo.R 是 yoke 的子骨骼，推运、搬护及跳跃动画缩小收起整个货担。
这是基础骨骼动画，没有布料、吊绳、负重或真实物理解算。

“杨三娘_骨骼模型.glb”包含网格、材质、蒙皮及六动作，可导入其他支持 glTF 的软件。
Godot 项目中的入口是 res://scenes/characters/yang_sanniang_character.tscn。
本包侧重模型编辑，完整可玩程序在独立“杨三娘角色美术”试玩包中。

风格化角色首版，完整表情、逐指骨骼、精细搬护演出、手绘图集及布料模拟尚待制作。
请从手工编辑后的源继续另存和导出，不要重跑生成脚本覆盖自己的修改。
''')

log_names = {
    'verify-party_game.log': 'PARTY_GAME_OK',
    'verify-deng_character.log': 'DENG_CHARACTER_OK',
    'verify-shi_character.log': 'SHI_CHARACTER_OK',
    'verify-lao_character.log': 'LAO_CHARACTER_OK',
}
for name, marker in log_names.items():
    path = PROJECT / 'character-source/yang_sanniang' / name
    contents = path.read_text(encoding='utf8')
    assert marker in contents and 'SCRIPT ERROR' not in contents and 'ERROR:' not in contents


def package(directory, name):
    path = PROJECT / 'builds' / name
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for child in sorted(directory.rglob('*')):
            if child.is_file():
                archive.write(child, Path(directory.name) / child.relative_to(directory))
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
    return {'file': str(path), 'bytes': path.stat().st_size}


report = {
    'playable': package(BUILD, '四人同行_杨三娘角色美术_2026-10-17.zip'),
    'source': package(SOURCE, '杨三娘_模型与Blender工程_2026-10-17.zip'),
    'pictures': len(pictures),
    'regression_markers': list(log_names.values()),
}
print('YANG_RELEASE_PACKAGED_OK', json.dumps(report, ensure_ascii=False))
