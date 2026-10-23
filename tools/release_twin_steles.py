from pathlib import Path
import hashlib,json,shutil,sys

root=Path(__file__).resolve().parents[1]
previous=root/'builds/craft-performance-2026-10-20'
relative='builds/twin-steles-art-2026-10-20'
release=root/relative
backup=root/'backups/before-creek-twin-steles-2026-10-20'
environment='ERROR: Failed to read the root certificate store.'

if '--prepare' in sys.argv:
    release.mkdir(parents=True,exist_ok=True)
    (release/'.gdignore').touch()
    for name in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
        shutil.copy2(previous/name,release/name)
    for name in ['开始游戏（最新版）.lnk','开始游戏（八牌入场版）.lnk']:
        source=root.parent.parent/name
        if source.exists() and not (backup/name).exists():shutil.copy2(source,backup/name)
    export=(root/'tools/export_craft_performance_release.ps1').read_text(encoding='utf-8-sig')
    (root/'tools/export_twin_steles_release.ps1').write_text(export.replace('builds/craft-performance-2026-10-20',relative),encoding='utf-8-sig')
    config=root/'export_presets.cfg'
    config.write_text(config.read_text(encoding='utf8').replace('builds/craft-performance-2026-10-20',relative),encoding='utf8')
    print('TWIN_STELES_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
checks={
    'twin-steles-art-gpu.log':'TWIN_STELES_ART_OK',
    'twin-native-crafts-gpu.log':'NATIVE_CRAFTS_OK',
    'twin-carried-gpu.log':'CARRIED_ARRIVAL_OK',
    'twin-court-performance-gpu.log':'COURT_PERFORMANCE_OK',
    'twin-local-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
    'twin-single-player-gpu.log':'PARTY_GAME_OK',
}
def verify(path,marker):
    text=path.read_text(encoding='utf-8-sig')
    assert marker in text,(path,marker)
    bad=[line for line in text.splitlines() if ('ERROR:' in line or 'WARNING:' in line) and line!=environment]
    assert not bad,(path,bad)
for name,marker in checks.items():
    verify(root/'previews'/name,marker)
    shutil.copy2(root/'previews'/name,release/name)
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:verify(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf8'))
assert all(v is True for k,v in bundle.items() if k.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
shots=['coop-twin-paper-rubbing.png','coop-twin-paper-small-waits-for-large.png','coop-twin-paper-large-introduction.png','coop-twin-glazed-tea-cups.png','coop-refine-twin-old-bridge-stonework.png','coop-refine-twin-bound-log-sled.png','coop-refine-twin-carved-rock-route.png','coop-refine-twin-natural-waterfall.png','coop-refine-twin-flat-stele-clearance.png']
for name in shots:shutil.copy2(root/'previews'/name,release/name)
audio=json.loads((root/'assets/audio/card_rotation_20261020/SOURCE.json').read_text(encoding='utf8'))
for item in audio['effects']:
    path=root/'assets/audio/card_rotation_20261020'/item['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256'] and item['peak_dbfs']<-3
(release/'旋转音效_来源与校验.json').write_text(json.dumps(audio,ensure_ascii=False,indent=2),encoding='utf8')
paper=root/'assets/interface/parcel_paper.png'
paper_sha=hashlib.sha256(paper.read_bytes()).hexdigest()
assert paper_sha=='352d56a350dc0fa9802e7e962f1eeb376a2438be8bc988b2ed316f990d9cafa4'
font_sha=hashlib.sha256((root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha=='6a8f3a0e4142afbd4729a0825875d833e28def3ffd51f95a0cd379a2ffaf511b'
note='二爨必经合验_花卉纸底与溪谷小艺美术_说明.md'
description='''# 二爨必经合验、花卉纸底与溪谷小艺美术 · 2026-10-20

启动：builds/twin-steles-art-2026-10-20/CuanParty.exe。保留同目录PCK；根目录两个“开始游戏”入口同步到本轮。旧版保留，不新增ZIP。修改前备份位于backups/before-creek-twin-steles-2026-10-20；上轮完整EXE/PCK仍可回退。

解碑界面用用户指定aa155e22花卉纸底（项目原有parcel_paper.png，SHA256与用户原图一致）。背景铺满，小爨传拓区使用半透明纸面，拼字区去掉原深色整板，改暖纸字卡、墨字和朱红标题；大爨介绍和三道合读题也使用同一背景。点击、拖放、Q/右键转字、二次点击空白放回、缩放坐标不变。

第一关必须完成两碑：小爨传拓、四人见闻与六字归位保留；到场景右侧实体大爨碑完成年代、碑主、共同文字传统的三次对照，才能取得大爨对照印记。只有小爨即使六字完全正确也不会开门；小爨介绍页不能代领印记。大爨不重复提供六字答案、不代做四人分享或传拓。两边先后顺序不限，小爨字卡会保留，最后一项完成时合验开门。R保留，T/重走第一关清除。历史介绍沿用已核实资料，护碑故事仍明确为虚构。

开场八牌旋转换成原创纸风与木片掠过的连续音，按实际旋转角速度改变音高、音量，减速落定另用短木片收束；不再逐张重复原有乐音。跳过、重抽、退出、静音和音量兼容。波形由程序原创合成，无外部采样，来源清单附时长、音量及SHA256。自动检查使用Dummy音频，只验证播放状态和对应关系，不代替人工听感。

溪谷旧桥基改为错缝倒角石、缺角压顶、散落碎石与分段水痕；小木橇新增五根错落杉段、可见端面年轮、树皮细缝、底托与绕束绳结；原运输碰撞和速度保留。旧路岩壁改不规则有厚度的岩体和贴合岩面的凹槽，删除凸起管状路线、C形挂钩和整齐划痕。瀑布两侧改不对称连续岩面与自然裂隙，去三块拼成方洞的石柱/横梁，仍上窄下宽向左弯。均为运行时原生模型，未改用户源GLB或Blender工程。

第三关平放碑和承架高度按阶台抬高，配低支架承托；扶起时按带碑首/碑座的完整模型最低角动态保留间隙，最后碑脚准确落座。仍是四名真实角色合抬6.4秒、合力扶起4.8秒，暂停、回出生点和新旅程可安全恢复。

新小游戏美术保留各自机制，改立体泥陶茶壶、釉杯/杯脚/椭圆杯口与茶汤、注水/蒸汽；扎染布纤维与扎结、蜡染留白、木框织机经纬与梭子、背布系带与试背、榫卯木纹与销、红绳绕柱、火石与铜火盆等也补齐器形和材质。21件物品与12种机制不变，仍逐件有故事、实物照片、重试及完成记录。所有器物是艺术化短体验，按剧中人物归档，不把共用器物说成某民族独有。

验证：专门检查真实鼠标操作小爨全部正确仍被拦、大爨错误答案/实体入口/两个先后顺序、R/T；供应纸底和文字布局；旋转音随速/静音/跳过/重抽；平放最低点和扶碑每帧净空。另有21件小艺实际鼠标完成、四人搬运中断与恢复、扶碑动作与长卷音乐、完整双人与单人三关、独立导出PCK与Windows EXE启动。日志只放行本机既有根证书读取诊断，其余错误/警告均阻止封包。图片、字体原字节保持。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf8')
guide=(previous/'先看这里_启动与操作.txt').read_text(encoding='utf8')
guide=guide.replace('器物小艺与抬碑音画版','二爨合验与美术版').replace('第一关先点击小爨碑传拓，再四人合读和六字归位；','第一关必须完成小爨传拓、四人合读、六字归位，以及右侧实体大爨碑的三次对照，才可开门；两碑顺序不限，已放字卡保留；')
(release/'先看这里_启动与操作.txt').write_text(guide,encoding='utf8')
entry='2026-10-20 最新二爨合验与美术：第一关须小爨传拓/四人见闻/六字归位＋实体大爨三题对照印记，缺项不开门，先后不限，R保留T重置。解碑使用用户aa155e22原花卉纸底与墨字暖纸字卡。开场原创旋转纸风随实际速度减缓、收束，静音/重抽/跳过安全。溪谷旧桥基/杉段木橇/刻路岩壁/瀑布裂隙重塑；平放碑高于阶台，扶起每帧校验最低角净空。新小游戏补茶壶釉杯/茶汤、经纬、布纤维、系带、木纹、绳结与护火细节，12机制21物保留。专项、21物小艺、搬运/扶碑、完整单双人、独立PCK与原生启动通过。当前 `'+relative+'/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。'
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    contents=path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新二爨合验与美术：' in contents:continue
    target=backup/'docs'/(path.parent.name+'-'+path.name)
    target.parent.mkdir(parents=True,exist_ok=True)
    if not target.exists():shutil.copy2(path,target)
    first,rest=contents.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:paragraph=paragraph.replace('`builds/','`../cuan-game/builds/').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md':paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots]:
    path=release/name
    files[name]=dict(bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
(release/'验证记录.json').write_text(json.dumps(dict(result='TWIN_STELES_RELEASE_VERIFIED',checks=checks,bundle=bundle,startup=startup,files=files,paper_sha256=paper_sha,font_sha256=font_sha,environment_diagnostic=environment),ensure_ascii=False,indent=2),encoding='utf8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:(release/name).unlink(missing_ok=True)
print('TWIN_STELES_RELEASE_VERIFIED',len(checks),'checks')
