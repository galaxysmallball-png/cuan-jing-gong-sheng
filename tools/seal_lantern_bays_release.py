from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/lantern-bays-steles-2026-10-19'
previews=root/'previews'
checks={
    'lantern-bays-steles-gpu.log':'LANTERN_BAYS_STELES_OK',
    'lantern-bays-walkway-gpu.log':'WALKWAY_FIXES_OK',
    'lantern-bays-satchel-gpu.log':'FIELD_SATCHEL_OK',
    'lantern-bays-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
    'lantern-bays-single.log':'PARTY_GAME_OK',
}
environment='ERROR: Failed to read the root certificate store.'

def verify_log(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line]
    assert all(line==environment for line in errors),(path,errors)

for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
verify_log(previews/'lantern-bays-single-stdout.log','PARTY_GAME_OK')
shutil.copy2(previews/'lantern-bays-single-stdout.log',release/'lantern-bays-single-stdout.log')
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:
    verify_log(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['architectural_lantern_groups_two_stele_activity_note_and_centered_receipt_verified']
assert all(value is True for key,value in bundle.items() if key.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font_sha=hashlib.sha256((root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots={
    'coop-bays-separated-lanterns-unlit.png':'灯笼_各廊短串与留白.png',
    'coop-bays-separated-lanterns-lit.png':'灯笼_灯火共庭.png',
    'coop-refine-bays-roof-structure.png':'灯笼_依门楼廊檐分组.png',
    'coop-refine-bays-dark-footing.png':'岩岸_下方颜色加深.png',
    'coop-bays-large-stele-introduction.png':'二爨_大爨介绍.png',
    'coop-bays-small-stele-introduction.png':'二爨_小爨介绍.png',
    'coop-bays-stele-question.png':'二爨_合读三题.png',
    'coop-bays-centered-clue-receipt.png':'线索通知_去按钮居中文案.png',
    'coop-bays-comparison-note.png':'包裹_二爨对照笺.png',
}
for source,destination in shots.items(): shutil.copy2(previews/source,release/destination)
note='灯笼分组_二爨合读与精简线索通知_说明.md'
description='''# 灯笼分组、二爨合读与精简线索通知

2026-10-19。根目录两个游戏启动入口指向 `cuan-game/builds/lantern-bays-steles-2026-10-19/CuanParty.exe`；EXE与PCK需放在同一目录，无新ZIP。

四处场景下方岩层统一压深，上沿仍可见层理，越向下越沉入阴影；没有改变地面、桥栏或岩岸碰撞。

终幕取消三条横贯全院的密集灯串及屋顶上方悬空大灯。小灯按左廊、主殿左/右和右廊内/外五段短串布置，圆灯分在高门左右与两座楼檐下，共九个建筑挂灯组、13盏小灯与8盏圆灯。短绳固定在对应梁檐，圆灯有吊绳与挂钩；保留摆动、随七灯点亮的暖色变化、织物彩幔及庆典光花。中央两块牌匾、各屋顶之间留空，真实投影检查确认灯笼未遮字。

点击大爨碑可读大小爨碑各自的年代、人物、地点和书法介绍，并开始三步「二爨合读」。答错不发奖励，介绍随时可重读。完成获得「二爨对照笺」，包裹新增第五笺；小碑六字凹位显示淡色字形参照，帮助认字。四位同行的分享与六字归位仍需完成，合读不代开门。小碑界面也有「了解大小爨碑」入口，读介绍时暂停拼字长按采集，返回继续原进度。合读可重做，奖励不重复；R回位置/换场景保留，重开第一关或T重启旅程清除本次对照笺，永久民族成就保留。

二爨对照笺在包裹上方切换查看，未收集时只给获得途径，不泄露答题内容。包裹顶栏显示五笺总数。线索通知彻底移除右侧「查看包裹」按钮，按实际文字宽度自动收紧纸框、文字水平垂直居中，保留花鸟纸、B键和顶栏包裹入口。

史实按公开文博资料转述；碑体尺寸/字数/发现经过存在不同口径的部分未作答题条件。大小爨并非同一石碑，运碑过溪属于本作原创叙事。大碑当前六字图仍明确标注现代字库示意，不当作原碑拓本。

介绍及资料依据：

- [故宫博物院《爨龙颜碑》](https://www.dpm.org.cn/lemmas/241206.html)：大爨名称、458年、陆良、楷书及文献价值。
- [云南民族博物馆《爨龙颜碑拓片》](https://ynnmuseum.com/detail/4129.html)：碑主、年代、家族与生平内容。
- [云南民族博物馆《爨宝子碑拓片》](https://ynnmuseum.com/detail/4128.html)：小爨年代、碑主及隶楷过渡价值。
- [曲靖市政府《爨文化博物馆》](https://www.qj.gov.cn/html/2020/csmp_0417/83745.html)：小爨名称、405年与清代出土记录。
- [故宫《晋爨宝子碑墨拓本》](https://digitalarchive.npm.gov.tw/Collection/Detail/16062?dep=P)：小爨书体及纪年。

本轮验证：专项真实显卡/实际鼠标三题、错答、获笺、B打开/回看、淡字参照及四人六字正常开门、读介绍时长按隔离、重开清理；桥头行走与双牌无遮挡GPU、包裹暂停/按键隔离GPU、完整双人三关GPU和单人三关。独立导出PCK再次核对新合读/包裹奖励和九处挂灯，原生Windows启动退出码0。测试收藏使用独立文件，不覆盖玩家收藏。九张截图、日志与文件SHA256见“验证记录.json”。

日志仅允许既有Godot系统根证书读取环境诊断，原样保存；未忽略其他脚本或引擎错误，未改系统证书及网络。自动检查不代替同学人工试玩。保留上一版岩层/细瓦、素布显纹、支架立碑、全部爨体、21类实物图与民族交融成就。修改前普通目录备份为 backups/before-lantern-bays-2026-10-19，旧导出均保留。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新灯笼分组与二爨合读：下方岩层渐深，终幕改九处梁檐短串/圆灯组，移除跨院三排与悬空大灯，双牌无遮挡。大碑新增两碑介绍与三题合读，得第五笺及小碑淡字参照，不代做四人六字主线；小碑也可读介绍，来源按故宫/文博与市政府资料转述。线索通知去右侧按钮、文案居中、纸框随字宽，B与顶栏入口保留。专项/桥面牌匾/包裹/完整双人及单人检查、独立PCK与原生启动通过。当前 `builds/lantern-bays-steles-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    s=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新灯笼分组与二爨合读：' in s: continue
    first,rest=s.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/lantern-bays-','`../cuan-game/builds/lantern-bays-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p=release/name
    files[name]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(release/'验证记录.json').write_text(json.dumps(dict(result='LANTERN_BAYS_STELES_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,font_sha256=font_sha,files=files,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',environment_diagnostic=environment),ensure_ascii=False,indent=2),encoding='utf-8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:
    (release/name).unlink(missing_ok=True)
print('LANTERN_BAYS_STELES_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
