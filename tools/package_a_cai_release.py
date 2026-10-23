"""Prepare and package the A Cai model and Windows playtest artifacts."""
from pathlib import Path
import json
import shutil
import sys
import zipfile

PROJECT=Path(__file__).resolve().parents[1]
BUILD=PROJECT/'builds/a-cai-character-2026-10-17'
BLUEPRINT=PROJECT.parent/'cuan-game-blueprint'
PREVIEWS={
    'coop-a-cai-three-views.png':'阿彩_模型三视图.png',
    'coop-a-cai-portrait.png':'阿彩_面部与服饰.png',
    'coop-a-cai-apron-detail.png':'阿彩_背婴布与婴儿.png',
    'coop-a-cai-walk-studio.png':'阿彩_行走姿态.png',
    'coop-a-cai-in-game.png':'阿彩_桥头实景.png',
    'coop-a-cai-build.png':'阿彩_协助架桥.png',
}
INTRO='''爨境·共生 — 阿彩（苗族）角色版（2026-10-17）

双击 CuanParty.exe，保留同目录 CuanParty.pck。
查看模型：打开本目录“阿彩_模型三视图.png”和“阿彩_背婴布与婴儿.png”。

在游戏里见到阿彩
标题页点“试玩第二幕”（第二幕直达入口），两位玩家按下方提示完成桥基察看、备料、推木、辨路、稳墩。
随后 1P 换杨三娘（数字4），回古道入口联络村民；阿彩会随帮手走近桥头。
双方玩家回桥前会合，按住自己的操作键架桥。阿彩是帮手，不占四人的选角位置。
姓名与短对白均标注“阿彩（苗族）”。其他三名村民的独立模型此次未制作。

阿彩的黑布盘头与花带、蜡染领袖、红腰带、百褶裙、竹篓、背婴布、婴儿和小锄均已做成模型。
走近、待机和架桥协助使用基础骨骼动作，架桥时收起锄头。当前是风格化首版，尚非原画级精雕或真实负重演出。

原有行囊与三幕
B / 点击“行囊”打开“行囊·拾闻笺”，B / Esc 收起。已收线索留在纸笺里，提示消失后仍可查看。
拼字时可开行囊，阅读会暂停，收起后保留原字卡与选中状态。
R 回出生点保留本次进度，T 重开清空。未加入关闭程序后的存档。

1P：A/D走、W/空格跳、S/E操作、Tab/数字1—4换人。
2P：左右箭头走、上箭头跳、下箭头操作、右Shift换人。
拼字：鼠标拿放、Q/右键旋转；或J/L选字、I/K选位、Enter拿放、Backspace取回。
F2查看档案，F1切换关卡提示。完整流程为碑院解谜、断溪修桥扶碑、共庭七灯与结尾。

已检查：阿彩实际显卡专项、完整双人三幕显卡流程、单人兼容、行囊、Blender源文件重开。
自动流程和截图不能替代真实双人键盘试玩；首次通关时长仍待实测。
'''
SOURCE_README='''阿彩（苗族）模型源包

直接用 Blender 打开 cuan-game/character-source/a_cai/阿彩_角色工程.blend。
工程包含可编辑网格、材质、蒙皮、26骨骼与6动作，参考图和织物图已打包，无需额外寻找贴图。
Action Editor 中可选 idle、walk、jump、push、carry、inspect。
网格名 ACai_CharacterMesh；骨架名 ACai_Armature。
网格已合并，可在编辑模式按材质或相连部分选取；骨骼与配件顶点组保留。

GLB在 cuan-game/assets/characters/a_cai/a_cai_rigged.glb，可独立导入支持GLB的软件。
Godot场景与脚本保留原工程相对路径；将这些目录合入原项目即可继续接入，不是另一个完整游戏工程。
生成工具依赖原项目中的邓书年v3拓扑库。要手工继续修改，直接编辑本包的blend并另存导出即可。
手工修改后不要重跑生成脚本覆盖成果。详见随附阿彩_模型美术说明.md。

这是风格化游戏角色首版，未完整复刻参考图手绘质感；基础骨骼动作无布料或负重物理。
'''

def prepare():
    BUILD.mkdir(parents=True,exist_ok=True)
    (BUILD/'先看这里.txt').write_text(INTRO,encoding='utf-8-sig')
    shutil.copy2(BLUEPRINT/'四人同行_试玩说明.md',BUILD/'完整试玩说明.txt')
    shutil.copy2(PROJECT/'assets/calligraphy/SOURCE.md',BUILD/'字体来源与使用范围.txt')
    shutil.copy2(BLUEPRINT/'阿彩_模型美术说明.md',BUILD/'阿彩_模型说明.md')
    for original,label in PREVIEWS.items():shutil.copy2(PROJECT/'previews'/original,BUILD/label)

def package():
    prepare()
    for item in ['CuanParty.exe','CuanParty.pck','startup.log']:
        assert (BUILD/item).exists(),item
    startup=(BUILD/'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and 'ERROR:' not in startup and 'SCRIPT ERROR' not in startup
    binaries={file.name:file.stat().st_size for file in BUILD.glob('CuanParty.*')}
    report=json.loads((PROJECT/'character-source/a_cai/validation.json').read_text(encoding='utf8'))
    report['checks']=['A_CAI_CHARACTER_OK (GPU)','LOCAL_COOP_OK / LOCAL_COOP_RENDER_OK (GPU)','PARTY_GAME_OK','FIELD_SATCHEL_OK','A_CAI_SOURCE_REOPEN_OK','Windows export / headless startup']
    report['build_files']=binaries
    (BUILD/'验证记录.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    game_zip=PROJECT/'builds/四人同行_阿彩角色美术_2026-10-17.zip'
    with zipfile.ZipFile(game_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for file in BUILD.iterdir():
            if file.is_file() and file.suffix!='.log':archive.write(file,BUILD.name+'/'+file.name)
    source_zip=PROJECT/'builds/阿彩_模型与Blender工程_2026-10-17.zip'
    files=[
        'character-source/a_cai/阿彩_角色工程.blend','character-source/a_cai/validation.json',
        'character-source/a_cai/reopen-validation.json','assets/characters/a_cai/a_cai_rigged.glb',
        'references/阿彩_用户三视图.png','scenes/characters/a_cai_character.tscn',
        'scenes/villagers/a_cai_villager.tscn','scripts/a_cai_character_controller.gd',
        'scripts/character_animation_controller.gd','tools/build_a_cai_blender.py',
        'tools/a_cai_geometry.py','tools/a_cai_rig.py','tools/character_geometry.py','tools/check_a_cai_source.py'
    ]
    with zipfile.ZipFile(source_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        archive.writestr('先看这里.txt',SOURCE_README.encode('utf-8-sig'))
        for file in files:archive.write(PROJECT/file,'cuan-game/'+file)
        archive.write(BLUEPRINT/'阿彩_模型美术说明.md','阿彩_模型美术说明.md')
        for original,label in PREVIEWS.items():archive.write(PROJECT/'previews'/original,'预览/'+label)
    for file in [game_zip,source_zip]:
        with zipfile.ZipFile(file) as archive:assert archive.testzip() is None
    print('A_CAI_PACKAGES_OK',json.dumps({p.name:p.stat().st_size for p in [game_zip,source_zip]},ensure_ascii=True))

if __name__=='__main__':
    if '--prepare' in sys.argv:prepare();print('A_CAI_RELEASE_PREPARED')
    else:package()
