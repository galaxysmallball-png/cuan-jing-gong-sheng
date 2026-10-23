"""Package three new villagers and an independent pack donkey, retaining older builds."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

PROJECT=Path(__file__).resolve().parents[1]
BLUEPRINT=PROJECT.parent/'cuan-game-blueprint'
BUILD=PROJECT/'builds/village-characters-2026-10-17'
CHARACTERS={'a_qiang':'阿强','yu_nan':'玉喃','pu_mo':'普嫫','pack_donkey':'驮布毛驴'}
PREVIEWS={'coop-villagers-lineup.png':'三位村民_模型合影.png','coop-villagers-creek.png':'桥头_阿彩与阿强.png','coop-villagers-creek-work.png':'桥头_协助架桥.png','coop-villagers-garden-handoff.png':'共庭_玉喃取灯对白.png','coop-villagers-seven-lights.png':'七灯_普嫫对白.png'}
for key,name in CHARACTERS.items():
    for suffix,label in [('three-views','三视图'),('portrait','面部与服装'),('apron-detail','配件近景'),('walk-studio','行走姿态')]:
        PREVIEWS['coop-'+key.replace('_','-')+'-'+suffix+'.png']=name+'_'+label+'.png'

INTRO='''爨境·共生 — 村民角色版（2026-10-17）

双击 CuanParty.exe，保留同目录 CuanParty.pck。试玩无需安装 Godot 或 Blender。
先看本目录“三位村民_模型合影.png”，另有三人及毛驴各自的三视图和配件近景。

这次新增
阿强（壮族）：露额头巾、对襟短衣、红腰带、杉木梁、木鞘砍刀和草鞋。
玉喃（傣族）：低髻木梳、水红交领衣、银腰带、孔雀傣锦筒裙、锦布和驮布毛驴。
普嫫（彝族）：黑布包头与灰发、彩边蓝衣、旧羊毛披毡、黑陶茶罐和三足铜火盆。
毛驴含独立骨架、笼头、驮筐、布卷和傣锦，可单独复用。

在哪里见到他们
第二幕：标题页可点“直接试玩第二幕”。完成察看桥基、备杉木、推运、辨路和稳墩后，杨三娘回入口联络村民。
阿彩和阿强会走到桥头，四位主角会合并操作才开始架桥；后续扶碑与拉绳仍需玩家完成。
第三幕：标题页可点“直接试玩第三幕”。合力立碑，再将四件物件归位，普嫫和玉喃随后出现在取灯区域。
三盏油灯由玩家实际领取、运送和安放，玉喃在取灯时说送灯位置；七灯齐亮后保留普嫫“火点着了，就不散了”。

现在四名主角和四名村民均有独立模型，姓名后标民族；可操作角色仍是邓书年、石阿朵、老箐、杨三娘。
四名村民为配角，不增加选角槽。原有行囊、轻古风台词与三幕玩法保留。

操作
1P：A/D走，W/空格跳，S/E操作，Tab/数字1—4换人。
2P：左右箭头走，上箭头跳，下箭头操作，右Shift换人。
行囊：B或点击“行囊”，B/Esc收起；已收线索会保留在拾闻笺里，提示消失后仍可查看。
拼字：鼠标拿放，Q/右键旋转；或J/L选字、I/K选位、Enter拿放、Backspace取回。
F2档案，R回出生点并保留本次进度，T清空三幕重玩。未加入关闭程序后的存档。

已检查新角色、完整双人三幕显卡流程、单人兼容、行囊、第三幕专项及四个Blender源文件重开。
这是风格化游戏模型首版，精细表情、逐指握持、真实搬护/煮茶/系锦演出和布料物理仍待打磨。
自动检查与截图不能替代真实双人键盘人工试玩；首次通关时长仍待实测。
'''
SOURCE_INTRO='''三位村民与毛驴 — 可编辑模型源包

用 Blender 分别打开 cuan-game/character-source 下四个文件夹中的 .blend：阿强、玉喃、普嫫、驮布毛驴。
每个工程的参考图和织物图均已打包；保留网格、材质、蒙皮、骨架和基础片段。
网格对象前缀分别为 AQiang、YuNan、PuMo、PackDonkey；编辑模式按材质或相连部分选取，Pose Mode/Action Editor查看绑定和片段。
玉喃与毛驴是两个独立工程和GLB，通过Godot的 yu_nan_character.tscn 组合，毛驴也可单独复用。

GLB位于 cuan-game/assets/characters 下。Godot场景与控制器保留原项目目录结构，合入原项目即可继续使用。
本包是模型源包，不是另一个完整Godot项目。完整游戏请用单独的试玩包或原项目。
生成工具依赖原项目内的邓书年v3源作为只读拓扑库；可直接编辑本包现有blend，手工修改后不要重跑生成脚本覆盖。
详见“三位村民与毛驴_模型美术说明.md”，附原始三视图、预览、导出与重开统计。

首版采用简化网格花纹和基础姿态，原画手绘质感、精细表情与布料/负重物理尚未完整实现。
'''

def prepare():
    BUILD.mkdir(parents=True,exist_ok=True)
    (BUILD/'先看这里.txt').write_text(INTRO,encoding='utf-8-sig')
    shutil.copy2(BLUEPRINT/'四人同行_试玩说明.md',BUILD/'完整试玩说明.txt')
    shutil.copy2(BLUEPRINT/'三位村民与毛驴_模型美术说明.md',BUILD/'村民_模型美术说明.md')
    shutil.copy2(PROJECT/'assets/calligraphy/SOURCE.md',BUILD/'字体来源与使用范围.txt')
    for src,label in PREVIEWS.items():shutil.copy2(PROJECT/'previews'/src,BUILD/label)

def verify_protected():
    baseline=json.loads((PROJECT/'backups/three-villagers-protected-assets.json').read_text(encoding='utf8'))
    changed=[name for name,digest in baseline.items() if hashlib.sha256((PROJECT/name).read_bytes()).hexdigest()!=digest]
    assert not changed,changed
    return len(baseline)

def package():
    prepare()
    protected=verify_protected()
    reports={key:json.loads((PROJECT/'character-source'/key/'validation.json').read_text(encoding='utf8')) for key in CHARACTERS}
    for key,report in reports.items():
        reopened=json.loads((PROJECT/'character-source'/key/'reopen-validation.json').read_text(encoding='utf8'))
        assert report['vertices']==reopened['vertices'] and reopened['source_reopened']
        assert len(report['animations'])==6 and report['skins']==1
    startup=(BUILD/'startup.log').read_text(encoding='utf8')
    assert 'Godot Engine' in startup and not any(word in startup for word in ['ERROR:','SCRIPT ERROR'])
    assert (BUILD/'CuanParty.exe').stat().st_size>1000000 and (BUILD/'CuanParty.pck').stat().st_size>1000000
    evidence={'models':reports,'checks':['VILLAGE_CHARACTERS_OK (GPU)','LOCAL_COOP_OK / LOCAL_COOP_RENDER_OK (GPU)','PARTY_GAME_OK','FIELD_SATCHEL_OK','GARDEN_PREVIEW_OK','VILLAGE_SOURCE_REOPEN_OK x 4','Windows export / headless startup'],'old_assets_sha256_unchanged':protected}
    (BUILD/'验证记录.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
    game_zip=PROJECT/'builds/四人同行_村民角色美术_2026-10-17.zip'
    with zipfile.ZipFile(game_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for file in BUILD.iterdir():
            if file.is_file() and file.suffix!='.log':archive.write(file,BUILD.name+'/'+file.name)
    source_zip=PROJECT/'builds/三位村民与毛驴_模型及Blender工程_2026-10-17.zip'
    with zipfile.ZipFile(source_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        archive.writestr('先看这里.txt',SOURCE_INTRO.encode('utf-8-sig'))
        archive.writestr('cuan-game/character-source/.gdignore','')
        for key,name in CHARACTERS.items():
            for filename in [name+'_角色工程.blend','validation.json','reopen-validation.json']:
                path=PROJECT/'character-source'/key/filename;archive.write(path,'cuan-game/'+str(path.relative_to(PROJECT)).replace('\\','/'))
            path=f'assets/characters/{key}/{key}_rigged.glb';archive.write(PROJECT/path,'cuan-game/'+path)
            path=f'scenes/characters/{key}_character.tscn';archive.write(PROJECT/path,'cuan-game/'+path)
            if key!='pack_donkey':
                for path in [f'references/{name}_用户三视图.png',f'scenes/villagers/{key}_villager.tscn']:
                    archive.write(PROJECT/path,'cuan-game/'+path)
        for path in ['scripts/villager_character_controller.gd','scripts/character_animation_controller.gd','tools/build_village_character.py','tools/village_geometry.py','tools/village_rig.py','tools/character_geometry.py','tools/build_pack_donkey_blender.py','tools/pack_donkey_geometry.py','tools/pack_donkey_rig.py','tools/check_village_sources.py']:
            archive.write(PROJECT/path,'cuan-game/'+path)
        archive.write(BLUEPRINT/'三位村民与毛驴_模型美术说明.md','三位村民与毛驴_模型美术说明.md')
        archive.write(BUILD/'验证记录.json','验证记录.json')
        for src,label in PREVIEWS.items():archive.write(PROJECT/'previews'/src,'预览/'+label)
    for file in [game_zip,source_zip]:
        with zipfile.ZipFile(file) as archive:assert archive.testzip() is None
    print('VILLAGE_RELEASE_PACKAGES_OK',json.dumps({'protected_assets':protected,'files':{file.name:file.stat().st_size for file in [game_zip,source_zip]}},ensure_ascii=True))

if __name__=='__main__':
    if '--prepare' in sys.argv:prepare();print('VILLAGE_RELEASE_PREPARED')
    else:package()
