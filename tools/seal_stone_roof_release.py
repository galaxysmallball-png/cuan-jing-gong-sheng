from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/stone-roof-2026-10-19'
previews=root/'previews'
checks={
    'stone-roof-gpu.log':'STONE_ROOF_OK',
    'stone-roof-stories-gpu.log':'FOLK_STORIES_CUAN_OK',
    'stone-roof-story-gpu.log':'STORY_SOUND_OK',
    'stone-roof-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
    'stone-roof-single.log':'PARTY_GAME_OK',
}
environment='ERROR: Failed to read the root certificate store.'

def verify_log(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR:' in line]
    assert all(line==environment for line in errors),(path,errors)

for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
verify_log(previews/'stone-roof-single-stdout.log','PARTY_GAME_OK')
shutil.copy2(previews/'stone-roof-single-stdout.log',release/'stone-roof-single-stdout.log')
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:
    verify_log(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['layered_banks_curved_roofs_blank_cloth_and_supported_stele_lift_verified']
assert all(value is True for key,value in bundle.items() if key.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font=root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf'
font_sha=hashlib.sha256(font.read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots={
    'coop-refine-bank-rock-strata.png':'岩岸_错落岩层与凸石.png',
    'coop-refine-detailed-distant-eaves.png':'瓦檐_叠瓦瓦当与木构.png',
    'coop-refine-cloth-blank.png':'印花_初始素布.png',
    'coop-refine-cloth-first-print.png':'印花_首次显纹.png',
    'coop-refine-cloth-complete.png':'印花_完成.png',
    'coop-refine-raise-cradle.png':'立碑_支撑就位.png',
    'coop-refine-raise-halfway.png':'立碑_牵绳缓抬.png',
    'coop-refine-raise-seated.png':'立碑_碑脚落座.png',
}
for source,destination in shots.items(): shutil.copy2(previews/source,release/destination)
note='岩岸瓦檐_素布显纹与合力立碑_说明.md'
description='''# 岩岸瓦檐、素布显纹与合力立碑

2026-10-19。项目根“开始游戏（最新版）”与“开始游戏（八牌入场版）”进入 `cuan-game/builds/stone-roof-2026-10-19/CuanParty.exe`。EXE与PCK需保留同目录，本轮直接提供文件夹，未制作新ZIP。

溪谷两岸、碑院及共庭的地面下方增加四组不规则岩层基座。横向断层、错落石沿、局部凸石与底部碎石替换溪岸前排重复长柱，岩石以连续细颗粒/层理/断缝材质收束。每组岩岸合成一个网格，装饰不添加碰撞，保持已有地面与桥头行走边界。

远处重檐高门、塔檐与共庭屋顶使用弧形叠瓦、脊瓦、滴水端头、瓦当刻环、檐下椽头和挑檐角。每座屋顶最多五个合批网格，保留牌匾位置、尺寸和无遮挡字面。没有改角色源模型、原始图片或行走碰撞。

印花类小艺从素布开始：鼠标悬停只描亮边框，正确交互后该块布逐渐显纹。浮窗三维练习布使用独立复制的印染材质，跟随正确进度显纹，完成后全幅印好，重试清回素布。场景中原有成品布与实物照片保留原样，其他器物题目和主线条件未改。

第三关仍由第二关单向交接送碑入院，到达后才允许合力扶正。现在长按完成后先架木撑、收紧双绳，碑从运输橇抬起，约2.8秒绕碑脚缓缓立起，最后减速校正并落入碑座；运输橇随后撤开，临时支架淡出。以真实碑体最低点和基座顶面计算落座，不再绕中心生硬旋转。过程中玩家保持协作姿态、任务栏显示百分比、安放任务等落座才开启；对白移到左上留出碑脚视线。暂停冻结动画，中途重开清理支架/补间并解除锁定，没有迟到的落座回调。

本轮验证：专项真实显卡截图和真实鼠标印花输入，21件人物故事与独特小艺逐项输入，半身像对白/音效，完整双人三关、单人三关，以及独立导出PCK内容/动画检查和Windows原生启动。专项检查覆盖素布初始、显纹/重试、双人实际长按触发、动画中暂停恢复、全过程碑脚高度、落座后任务开启及中途重开。采用独立测试收藏文件，未覆盖玩家收藏；自动检查不替代人工试玩反馈。

日志原样保留既有Godot系统根证书读取环境诊断；仅允许这条已知诊断，未忽略其他脚本/引擎错误，未改系统证书或网络。所有日志、八张截图与SHA256见本目录“验证记录.json”。

修改前备份为 backups/before-stone-roof-animation-2026-10-19，旧可运行目录均保留。全界面爨体、放大字号、花鸟通知按钮、21类实物图与民族交融成就、四向移动、桥栏保护和单向运碑生命周期均保留。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新岩岸瓦檐与合力立碑：四组地面基座改为错落岩层/凸石/碎石，远近屋檐增加弧面叠瓦、瓦当、脊瓦与椽头并合批。印花初始素布，交互逐次显纹，练习三维布独立材质、重试清空；成品和实物图保留。立碑采用木架双绳、碑脚枢转、缓抬/校正/落座2.8秒，落座才解锁安放，暂停及中途重开安全；对白左上避开碑脚。专项、21件小艺、对白/音效、完整双人和单人流程通过，独立PCK和原生启动通过。当前 `builds/stone-roof-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    s=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新岩岸瓦檐与合力立碑：' in s: continue
    first,rest=s.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/stone-roof-','`../cuan-game/builds/stone-roof-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p=release/name
    files[name]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(release/'验证记录.json').write_text(json.dumps(dict(result='STONE_ROOF_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,font_sha256=font_sha,files=files,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',environment_diagnostic=environment),ensure_ascii=False,indent=2),encoding='utf-8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:
    (release/name).unlink(missing_ok=True)
print('STONE_ROOF_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
