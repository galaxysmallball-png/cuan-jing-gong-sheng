from pathlib import Path
import hashlib
import json
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/achievement-book-2026-10-18'
checks={
    'achievement-gpu-main.log':'ACHIEVEMENT_BOOK_OK',
    'achievement-gpu-capture_local_coop.log':'LOCAL_COOP_RENDER_OK',
    'achievement-gpu-capture_garden.log':'GARDEN_PREVIEW_OK',
    'achievement-headless-verify_party_game.log':'PARTY_GAME_OK',
    'achievement-headless-verify_folk_play.log':'FOLK_PLAY_OK',
    'achievement-headless-verify_field_satchel.log':'FIELD_SATCHEL_OK',
    'achievement-headless-verify_interface_pairs.log':'INTERFACE_PAIRS_OK',
    'achievement-headless-verify_photo_guide.log':'PHOTO_GUIDE_OK',
}
for name,marker in checks.items():
    log=(root/'previews'/name).read_text(encoding='utf-8')
    assert marker in log and 'ERROR:' not in log,name
    shutil.copy2(root/'previews'/name,release/name)
for name in ['export-console.log','pck-check.log','startup.log']:
    log=(release/name).read_text(encoding='utf-8')
    assert 'Godot Engine' in log and 'ERROR:' not in log,name
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['achievement_book_21_items_seven_ethnic_associations_shared_objects_eight_badges_and_save_verified']
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
shots={
    'coop-achievements-empty-book.png':'成就册_首次打开.png',
    'coop-achievements-object-auto-collected.png':'物件交互_自动收录.png',
    'coop-achievements-bai-collected-photo.png':'民族收藏页_已收录实物图.png',
    'coop-achievements-seven-cultures-connected.png':'七族共生_连结图谱.png',
    'coop-achievements-woven-encounters.png':'布上相逢_跨民族成就.png',
    'coop-achievements-seven-together.png':'七族同庭_解锁条件.png',
}
for source,destination in shots.items(): shutil.copy2(root/'previews'/source,release/destination)

description='''# 共生见闻成就册

2026-10-18。运行项目根“开始游戏（最新版）”，或 `cuan-game/builds/achievement-book-2026-10-18/CuanParty.exe`，保留同目录 PCK。

点击封面或游戏顶栏“共生见闻”，或按 C 打开成就册；Esc/C 收起。物件浮窗下方也增加入口。册内暂停同行和任务，收起后精确回到之前的封面、游戏、碑面、行囊或物件浮窗，不把下层仍打开的物件窗口解除暂停。

21 类特色物件在实际交互打开介绍后自动收录，重复交互只记一次，两位玩家共享收藏。按剧中人物与使用情境分为汉族 1、白族 2、彝族 5、回族 2、苗族 4、壮族 2、傣族 3，以及共用器物 2。通用器物的关联不代表民族独占；照片继续显示它自身的馆藏、地区、作者和授权。册内可以重看全部已收录实物图，多图可以切换；离开原场景或重开关卡仍能翻看。未收录项保留名称、所属关卡与相遇提示，照片待互动后解锁。

右侧七族连结图谱随收藏点亮，八项成就把收藏串成共同见闻：

|成就|条件与联系|
|---|---|
|初见一物|与任意一物相遇|
|笔墨石声|邓书年纸笔、石阿朵錾子：汉族/白族，识读与石作互补|
|布上相逢|扎染、蜡染、傣锦：白族/苗族/傣族，不同布艺相遇|
|众手成桥|老箐驮架、阿彩锄头、阿强木梁：彝族/苗族/壮族，日常经验相助|
|茶暖往来|杨三娘货担、普嫫茶罐、玉喃锦带：回族/彝族/傣族，行商与待客相接|
|共用成家|收录两件共用器物，并认识至少四族相关器物|
|七族同庭|七族各至少一物，加两件共用器物|
|万物成卷|全部21类物件|

成就卡显示解锁状态、条件百分比条与计数；点条件中的器物名跳转对应收藏页。物件页补充人与人如何交流、互助的短文，归档保留来处，成就强调本领相接和共同生活。

收藏保存为 Godot 本机用户目录下 `共生见闻_v1.json`，包含已收录ID/时间及成就时间。场景重开、R、T、退出游戏都保留长期收藏；当前关卡见闻与小艺的原重置规则继续有效。加载只接受当前目录内有效ID，并按已收录项重新核对成就条件。自动检查通过 CUAN_ACHIEVEMENT_PROFILE 指向独立测试文件，不改玩家收藏。

验证：新专项真实显卡渲染与输入注入，涵盖封面/顶栏/物件入口、首次真实场景点击收录、重复与未知项过滤、21物逐一交互、七族筛选、八成就门槛、未遇到傣族前交融成就不提前完成、全部离线实物图在离场后重看、署名和文案不裁切、多图切换、成就条件跳转、进度条不压字、暂停时人物不移动、嵌套窗口返回、R/T长期保留以及新实例从文件恢复。另通过双人三关/共庭 GPU 和单人、器物小艺/音效、行囊、专属角色与界面、上一轮照片/第一关/长卷检查。独立导出 PCK 中检查成就目录、21物/七族/共用分类、全部八成就、照片回看及保存重载；Windows原生程序启动正常。日志与截图见本轮《验证记录.json》。这些自动输入与启动检查不代表其他同学已完成完整人工试玩。

新增 achievement_content.gd、achievement_book.gd、achievement_threads.gd；接入 folk_collection.gd、party_ui.gd、world.gd 与提示。Screen 枚举在末尾追加 ACHIEVEMENTS=11，旧枚举编号保留；成就册 CanvasLayer16，物件14，游戏UI12。新增检查 tools/verify_achievement_book.gd，导出检查继续覆盖旧资源。改前备份 backups/before-achievement-book-2026-10-18；用户原图与人物源文件未改。
'''
blueprint=root.parent/'cuan-game-blueprint'
note='共生见闻_民族收藏与交融成就_说明.md'
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-18 最新共生见闻成就册：21类特色物件交互自动收录，七个民族关联页与共用器物，七族连结图谱、实物图离场回看，八项成就以笔墨/石作、三种布艺、众手修桥与行商待客体现交融。封面/顶栏/物件浮窗及C入口，支持分页、条件跳转和准确恢复下层暂停；本机长期保存，R/T/关卡重开保留收藏，测试使用独立文件。新专项及完整双人/共庭GPU、单人/器物音效/行囊/归属界面/照片指引回归、独立PCK和原生启动通过。当前 `builds/achievement-book-2026-10-18/CuanParty.exe`，根最新版快捷方式同步。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    content=path.read_text(encoding='utf-8-sig')
    if '2026-10-18 最新共生见闻成就册：' in content: continue
    first,rest=content.split('\n',1)
    text=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint: text=text.replace('`builds/achievement-', '`../cuan-game/builds/achievement-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': text=text.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+text+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    file=release/name
    files[name]=dict(bytes=file.stat().st_size,sha256=hashlib.sha256(file.read_bytes()).hexdigest())
record=dict(result='ACHIEVEMENT_BOOK_RELEASE_VERIFIED',date='2026-10-18',checks=checks,bundle=bundle,
            native_startup=startup,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',files=files,
            screenshot_note='收藏满册为自动化交互测试结果；新玩家本机收藏从空册开始。')
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('ACHIEVEMENT_BOOK_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'GPU screenshots')
