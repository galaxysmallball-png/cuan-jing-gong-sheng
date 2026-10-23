from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/journey-keepsakes-2026-10-19'
previews=root/'previews'
environment='ERROR: Failed to read the root certificate store.'
checks={
    'keepsakes-gpu.log':'JOURNEY_KEEPSAKES_OK',
    'keepsakes-achievements-gpu.log':'ACHIEVEMENT_BOOK_OK',
    'keepsakes-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
    'keepsakes-single.log':'PARTY_GAME_OK',
}

def verify_log(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line==environment for line in errors),(path,errors)

for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
verify_log(previews/'keepsakes-single-stdout.log','PARTY_GAME_OK')
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:
    verify_log(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['scattered_keepsakes_shared_pickup_bag_and_courtyard_inventory_verified']
assert bundle['achievement_book_21_items_seven_ethnic_associations_eight_badges_and_session_reset_verified']
assert all(value is True for key,value in bundle.items() if key.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font_sha=hashlib.sha256((root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots={
    'coop-keepsakes-act-one-dropped.png':'第一关_散落的随身物件.png',
    'coop-keepsakes-bag-one-found.png':'包裹_拾取与位置.png',
    'coop-keepsakes-act-two-found.png':'第二关_拾取入包裹.png',
    'coop-keepsakes-bag-missing-location.png':'漏拾_返回来路找物件.png',
    'coop-keepsakes-four-placed.png':'共庭_沿途物件归位.png',
    'coop-keepsakes-new-launch-empty-book.png':'重新进入_成就清零.png',
}
for source,dest in shots.items(): shutil.copy2(previews/source,release/dest)
note='沿途拾物_包裹归位与每轮成就重置_说明.md'
description='''# 沿途拾物、包裹归位与每轮成就重置 · 2026-10-19

当前导出 builds/journey-keepsakes-2026-10-19，根目录两个“开始游戏”入口同步。EXE和PCK保留同目录；本轮不新增ZIP。

成就从长期收藏改为本轮旅程记录。每次启动游戏、从封面启程或T重启旅程，都清空器物收录、成就、分组页与旧弹窗。旧的收藏文件不会读取，也不再写入新的长期收藏。R回到位置和重开当前关卡保留本轮成就。仍为21类特色物件、七族关联与共用器物、8项交融成就，规则与实物图不变，每轮可以重新获得。

第三关原有四件随身物件改为实际沿途拾取：第一关残廊拓印桌旁的邓书年练习拓片、大碑右侧古道口的石阿朵錾子；第二关左岸行囊旁的老箐马铃、花布架前石路的杨三娘红线。拾取点避开木料推运阻挡；物件复用归位后的同款模型，拓片平放。任一玩家均可帮忙收纳：走近落地站稳，按一次自己的E/P或点击物件。远处点击、空中和重复点击不能收取，藏入包裹后地面物件消失。

拾取后用既有花鸟纸通知提示已放入包裹，按B直接翻随身物件页。包裹新增四物页，列出原来位置、待拾/已拾/归位和用途，可切回四人见闻和二爨对照笺。字与按钮保留当前爨体、用户纸底，检查四卡排版。

第三关保留送碑、木架抬碑和七灯逻辑。石碑扶正后，每位角色只能安放已经拾到的对应物件；漏拾时不显示可安放标记，任务和包裹提示第一/二关位置，可沿修好的桥原路返回补找，不会重新生成已交接的碑。四物归位后仍需双人各选彩幔、分别确认，再送三盏油灯；单人仍可依次完成。

回位置保留物件；重开第一关重新散落四件，重开第二关保留第一关两件并重新散落第二关两件，重开第三关保留已拾取物件并重新归位。T清空全部本轮物件。直达第二关试玩只预置第一关物件，直达第三关试玩预置四件；此为显式跳关入口，不会在完整流程自动补齐。第三关试玩同时将已交付木料移到卸料位并关闭木料阻挡，让返回来路的状态与正常完成第二关一致。

验证：新GPU专项真实鼠标、E和P，代拾/距离与重复校验、包裹待拾与位置、缺物不能安放、实际走回第一关取漏掉的錾子并再过桥归位、原有角色归属/双人布置、R/分关重开/T、新实例清零和重新获得首项成就；旧收藏文件保持原样。成就册专项逐个交互21件与8成就、实物图/来源及分页/暂停/版面，当前关卡保留与新轮清零。完整双人、单人三关增加实际走到四个拾取点并按键收纳后才完成终幕。独立导出PCK与原生EXE启动验证通过，六张截图及原始日志见验证记录.json。

保留上一轮三幕场景美工、桥栏安全、字体、用户原图、角色与实物资产。新增脚本journey_keepsakes.gd；重置规则覆盖此前文档中“民族收藏长期保存”的历史说明。自动验证不代替陌生玩家试玩。日志保留既有系统根证书读取诊断，未忽略其他引擎错误/脚本错误/资源泄漏，也未修改系统证书。备份 backups/before-journey-keepsakes-2026-10-19。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新沿途拾物与每轮成就：成就不再跨次保存，启动/启程/T清零，R和本关重开保留；拓片、錾子散落第一关，马铃、红线散落第二关，任一玩家走近E/P或点击收纳。B包裹四物页显示待拾/已拾/归位与位置，未拾不能在第三关安放，允许过桥返回补找；分关重开和直达试玩按已过关范围处理物件。新专项/21成就器物册/完整双人单人与独立PCK、原生启动通过。当前 `builds/journey-keepsakes-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录，旧长期收藏要求已被本轮取代。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    text=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新沿途拾物与每轮成就：' in text: continue
    backup=root/'backups/before-journey-keepsakes-2026-10-19/docs'/(path.parent.name+'-'+path.name)
    backup.parent.mkdir(parents=True,exist_ok=True)
    if not backup.exists(): shutil.copy2(path,backup)
    first,rest=text.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/journey-keepsakes-','`../cuan-game/builds/journey-keepsakes-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    path=release/name
    files[name]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
(release/'验证记录.json').write_text(json.dumps(dict(result='JOURNEY_KEEPSAKES_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,font_sha256=font_sha,files=files,environment_diagnostic=environment),ensure_ascii=False,indent=2),encoding='utf-8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']: (release/name).unlink(missing_ok=True)
print('JOURNEY_KEEPSAKES_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
