from pathlib import Path
import hashlib
import json
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/folk-stories-cuan-2026-10-19'
previews=root/'previews'
checks={
    'folk-stories-cuan-gpu.log':'FOLK_STORIES_CUAN_OK',
    'folk-stories-capture_local_coop.log':'LOCAL_COOP_RENDER_OK',
    'folk-stories-capture_garden.log':'GARDEN_PREVIEW_OK',
    'folk-stories-verify_party_game.log':'PARTY_GAME_OK',
    'folk-stories-verify_folk_play.log':'FOLK_PLAY_OK',
    'folk-stories-verify_field_satchel.log':'FIELD_SATCHEL_OK',
    'folk-stories-verify_interface_pairs.log':'INTERFACE_PAIRS_OK',
    'folk-stories-verify_achievement_book.log':'ACHIEVEMENT_BOOK_OK',
    'folk-stories-verify_photo_guide.log':'PHOTO_GUIDE_OK',
}
environment_diagnostic='ERROR: Failed to read the root certificate store.'
environment_logs=[]


def verify_log(path,marker):
    text=path.read_text(encoding='utf-8')
    assert marker in text,path
    errors=[line for line in text.splitlines() if 'ERROR:' in line]
    assert not [line for line in errors if line!=environment_diagnostic],(path,errors)
    if environment_diagnostic in errors: environment_logs.append(path.name)


for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
for name in ['export-console.log','pck-check.log','startup.log']:
    verify_log(release/name,'Godot Engine')
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['per_object_stories_unique_activities_cuan_titles_and_parcel_paper_verified']
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
shots={
    'coop-folk-stories-cuan-title.png':'标题与入口_爨体.png',
    'coop-folk-stories-visible-clue-receipt.png':'看碑即提醒_线索已放入包裹.png',
    'coop-folk-stories-flower-parcel.png':'包裹_花卉纸底与线索.png',
    'coop-folk-stories-prologue-scholar_tools.png':'邓书年_拓包故事.png',
    'coop-folk-stories-prologue-miao_batik.png':'阿彩_花布相遇故事.png',
    'coop-folk-stories-weight-caravan_pack.png':'老箐驮架_十八份.png',
    'coop-folk-stories-weight-donkey.png':'玉喃驮布_二十八份.png',
    'coop-folk-stories-finished-scholar_tools.png':'拓包归整_四步小艺.png',
}
for source,destination in shots.items(): shutil.copy2(previews/source,release/destination)
description='''# 爨体、器物故事与逐物小艺

2026-10-19。项目根“开始游戏（最新版）”或 `cuan-game/builds/folk-stories-cuan-2026-10-19/CuanParty.exe` 启动。保留同目录 PCK。本轮更新可运行版本，之前10月18日的压缩包保留旧内容。

标题、关卡名、指示牌、此刻所往、操作提示、人物名、包裹/成就册标题和按钮统一接入现有梁培生小爨现代字库。字库通过界面主题函数共用，缺字有系统字体后备；长篇故事、实物说明和资料署名保留正文排版。字库源文件、原图与人物建模源未改，仍按已有来源及教育学习用途说明使用，不宣称原碑字体复原。

之前小艺仅以关卡选择同一题，现改为21个器物配置，题目、人物故事和难度逐物对应。点击器物仍可看三维/实物图，右侧先显示人物半身像和器物故事，点“开始小艺”或Enter才进入；数字键在故事页不代做。重试回到相应故事，不设强制等待。故事描述书生向石匠学护石、货郎联络不同乡音、阿彩与阿朵交流花布、老箐与木工互补、围火待客与锦带递灯等原创相助情境。

四类小艺：

- 六组配重：货担[1,2,3,4,6]合16份；驮架[1,2,3,5,7]合18份；锄头[1,3,4,6,8]合22份；竹篓[2,3,4,5,8]合22份；木梁[2,3,4,6,9]合24份；驮布[3,4,5,7,9]合28份。全部存在等重解，货包与目标同屏显示。
- 五组纹样记忆：扎染3步、花布4步、背布5步、织锦6步、织架7步，图样和次序可辨，错序后可重来。
- 五组迎灯应声：茶席4声、茶罐5声、火盆/锦带各6声且乐句不同、檐下马铃7声。开始时先示范；可重听，成就册覆盖小艺时示范暂停。
- 五组器物准备：拓包、柴刀、火具、錾子4步，红线5步。按人物故事中的不同次序理物、护角、留记，属于游戏练习，不冒充完整传统技艺教学。

完成情况以物品ID记录21份，当前旅程界面显示数量；原三关小艺标记仍兼容。关卡重开只清当前关与后续的小艺，长期成就收藏保留；可重复体验，不代做四人线索、修桥或七灯。

获得线索时，碑面标题旁当场显示“新线索已放入包裹·按B查看”，提示保持8秒，退出碑面也能继续看。包裹按钮、标题与控制提示统一用“包裹”称呼；原B、暂停、角色归属和线索内容保留。包裹卡与收起按钮用本轮图一原始PNG，SHA256见assets/interface/SOURCE.json；卡内加浅色衬底，保护正文对比度。提醒消失后，线索仍可在包裹中反复查看。

已逐物用真实鼠标验证21道题：每题配置唯一、有对应人物故事/半身像、开始门槛、文本不裁切、错误处理和重试；六组配重均求得解。核对小艺不改主线、关卡重开不丢永久收藏、取得线索时看碑内提示可见及B回看。真实显卡专项、完整双人三关和庭院检查通过；单人、器物音效/小艺、包裹、12种出牌归属界面、成就、照片/第一关/长卷回归通过。完整导出PCK检查新故事、小艺配置、爨体/花卉纸与旧资源；原生程序启动正常。截图、日志与文件哈希见验证记录。自动输入检查不等于人工试玩完成。

本次运行日志有一条Godot“Failed to read the root certificate store”环境诊断，原样保留；它不属于脚本/关卡断言失败。此轮场景、素材、音效、收藏均离线运行，资料外链由系统浏览器打开。本轮未修改证书或网络设置，也未把该诊断写成“无错误”。

保留当前场景建模优化，包括第三幕碑座中轴世界X50、石碑材质分离与模型合批；测试按当前安放点取值。新脚本folk_activity_profiles.gd和folk_activity_board.gd，原folk_playboard.gd作为兼容入口。其他主要改动为界面字体、folk_collection故事门、party_ui提醒和field_satchel纸底。修改前备份backups/before-folk-stories-cuan-2026-10-19。
'''
blueprint=root.parent/'cuan-game-blueprint'
note='爨体界面_器物故事与差异化小艺_说明.md'
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新爨体与逐物故事：标题/指示/入口/按钮接现有小爨字库；21件物品各配人物故事与半身像、Enter/点击开始门，21题配置唯一（6组配重、5纹样、5应声、5整理），小艺按物记录和分关重置，永久成就保留。线索在碑面当场提示已放入包裹/B查看，包裹卡与按钮用用户花卉原图并加正文衬底。新专项及双人/庭院GPU、六项回归、独立PCK和原生启动通过；日志原样记录本次系统根证书读取环境诊断，未改证书/网络。保留今日场景建模优化与碑轴X50。当前 `builds/folk-stories-cuan-2026-10-19/CuanParty.exe`，根最新版入口同步。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    text=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新爨体与逐物故事：' in text: continue
    first,rest=text.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint: paragraph=paragraph.replace('`builds/folk-stories-', '`../cuan-game/builds/folk-stories-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    path=release/name
    files[name]=dict(bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
record=dict(result='FOLK_STORIES_CUAN_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,
            native_startup=startup,files=files,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',
            environment_diagnostic=environment_diagnostic,environment_diagnostic_logs=environment_logs,
            coverage='逐物真实输入、题目唯一性与可解性、故事门槛、字体/提醒/纸底、三关回归；离线运行检查，保留原始环境诊断。')
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('FOLK_STORIES_CUAN_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'GPU screenshots')
