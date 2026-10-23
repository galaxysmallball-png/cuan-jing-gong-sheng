from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/cooperative-experience-2026-10-19'
previews=root/'previews'
checks={
    'cooperative-experience-gpu.log':'COOPERATIVE_EXPERIENCE_OK',
    'cooperative-solo-gpu.log':'COOPERATIVE_SOLO_OK',
    'cooperative-flow-gpu.log':'LOCAL_COOP_RENDER_OK',
    'cooperative-walkway-gpu.log':'WALKWAY_FIXES_OK',
    'cooperative-single.log':'PARTY_GAME_OK',
}
environment='ERROR: Failed to read the root certificate store.'

def verify_log(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
    assert all(line==environment for line in errors),(path,errors)

for name,marker in checks.items():
    verify_log(previews/name,marker)
    shutil.copy2(previews/name,release/name)
verify_log(previews/'cooperative-single-stdout.log','PARTY_GAME_OK')
shutil.copy2(previews/'cooperative-single-stdout.log',release/'cooperative-single-stdout.log')
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:
    verify_log(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['cooperative_teaching_alternating_clues_tension_control_and_joint_courtyard_design_verified']
assert all(value is True for key,value in bundle.items() if key.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font_sha=hashlib.sha256((root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots={
    'coop-cooperation-first-move-guide.png':'同行引导_移动与找到小碑.png',
    'coop-cooperation-alternating-clues.png':'合读_两份间隔字.png',
    'coop-cooperation-rope-too-tight.png':'护碑_绳索过紧.png',
    'coop-cooperation-rope-green-band.png':'护碑_保持绿色张力.png',
    'coop-cooperation-design-two-voices.png':'合织_两位玩家各选一幅.png',
    'coop-cooperation-design-first-confirmed.png':'合织_等待另一位玩家确认.png',
    'coop-refine-cooperation-shared-cloth.png':'合织_选择进入真实场景.png',
    'coop-cooperation-solo-guide.png':'单人_同行引导.png',
    'coop-cooperation-solo-design.png':'单人_依次完成左右两幅.png',
}
for source,destination in shots.items(): shutil.copy2(previews/source,release/destination)
note='合作玩法_互补合读张力护碑与共同布置_说明.md'
description='''# 合作玩法与同行引导

2026-10-19。本轮落实“合作玩法＋新手引导”，覆盖现有三关。根目录两处启动入口更新到 `cuan-game/builds/cooperative-experience-2026-10-19/CuanParty.exe`，保留同目录PCK；旧版本和普通目录备份均保留，无新ZIP。

第一关保留四人线索和六字拿放/旋转，取消每位角色重复等待1.6秒。现在按一下E/P或点击同行卡即分享，持续按住再换人不会自动取得下一位的线索。邓书年提供1/3/5位「晋、振、建」，杨三娘提供2/4/6位「故、威、宁」，另两人补充位置和辨向；现有专属角色配对让两份间隔字分属不同控制者。界面不再提前给整串答案，四条线索仍可B回看；大爨合读获得的字形参照保留，错误次序和方向仍不能开门。四人见闻/正确归位改用即时进度展示。

第二关仍按原路线备木、推料、砌墩、联络、会合架桥。桥心护碑改为实际收放绳：石阿朵在桥心持续顶碑，老箐在右岸按下操作键收绳、松开放绳。张力从0到1变化，绿色区0.35—0.72，四人到附近、顶碑/牵绳站位正确且张力合适时累计护稳2.4秒；过紧、过松或失去支撑会缓慢回退，安全桥面不改变，不使用失败掉落惩罚。一直按住不会自动获胜。HUD显示当前缺少的条件、双方实际键位与进度；绳索弧垂和碑身倾斜同步变化。单人时同行管理绳索，玩家在桥心按住E扶碑即可。

第三关保留第二关送碑入院、木架缓抬和四人物件归位。四件归位后进入「合织共庭」：两位玩家各试配一幅赭金菱纹、蓝白花叶或靛蓝回旋，选择实时改变高门左右六面彩幔，中幅按格交错显示双方纹样。两人分别确认后才解锁三盏油灯；一方不能替另一方确认。可Esc稍后再选，选择保留，左上布置按钮或灯桌操作可继续。单人用A/D/E依次完成左右两幅，不要求第二位玩家。确认结果写入本次旅程F2档案，场景保持选择；重开第一/第二/第三关及T会清空本次庭院布置，R回位置保留。永久民族收藏成就不改。

新增同行引导按当前关卡/任务显示，支持收起、展开及H页恢复，教学不锁住自由移动，也不把跳跃当作通关条件。绳索阶段默认只显示张力卡，需详细说明可展开引导；单人提示不出现不存在的2P。收紧左下任务文本和计数，加入阅读衬底，检查新教学/布置文案无裁切。鼠标点击教学与张力卡不会穿透触发场景物件。布置窗口暂停世界，隔离R/T/B/C/H等底层输入，Esc退出恢复。

验证：新专项真实显卡与实际鼠标/物理键，包括一键分享/长按换人隔离、交错线索正常开门、一直拉绳不能获胜、收放通过/暂停冻结、两位玩家独立选择/单方不能确认、取消返回/输入隔离、七面真实布变化/中幅双纹、档案记录及重开清理。单人GPU检查真实扶碑/四物归位和A/D/E依次布置；完整双人三关与完整单人三关通过；桥头四角/跟随绕行/双牌无遮挡回归通过。导出PCK独立检查新脚本、线索、布置、共同确认及材质参数，Windows原生启动退出码0。九张截图、日志和SHA256见验证记录.json。

保留全界面爨体与放大字号、原始用户图片/角色模型、21类实物照片与文化成就、二爨介绍和对照笺、九组梁檐挂灯、加深岩层、素布显纹、连续工作音效、四向移动与桥头边界。新增内容为原生GDScript/三维材质交互，纹样合用是本作的布置创作，不声称复原具体历史织造工艺。

测试使用独立收藏文件；没有替代同学的陌生人试玩。日志仅保留既有Godot系统根证书读取环境诊断，未忽略其他脚本/引擎错误或资源泄漏，未改系统证书/网络。补充GPU测试销毁场景前停止测试音频并等待混音线程，完成功能检查后断开其虚拟时钟超时监听，避免空场高速清理误报；游戏逻辑不因此放宽。修改前备份为backups/before-cooperative-experience-2026-10-19。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新合作玩法与同行引导：第一关一键分享1/3/5与2/4/6间隔线索，持键换人不代收；第二关顶碑＋收放绳张力绿色区，持续按住不自动过关，单人同行协助；第三关四物归位后两人各选纹样，七面彩幔与中幅双纹真实变化、双方确认解锁油灯，结果进档案。情境引导可收起/恢复，任务文案收紧、模式隔离和重开清理。专项/单人布置GPU、完整双人/单人及桥面回归、独立PCK与原生启动通过。当前 `builds/cooperative-experience-2026-10-19/CuanParty.exe`，根最新版入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    s=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新合作玩法与同行引导：' in s: continue
    first,rest=s.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/cooperative-','`../cuan-game/builds/cooperative-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p=release/name
    files[name]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(release/'验证记录.json').write_text(json.dumps(dict(result='COOPERATIVE_EXPERIENCE_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,font_sha256=font_sha,files=files,renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',environment_diagnostic=environment),ensure_ascii=False,indent=2),encoding='utf-8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:
    (release/name).unlink(missing_ok=True)
print('COOPERATIVE_EXPERIENCE_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
