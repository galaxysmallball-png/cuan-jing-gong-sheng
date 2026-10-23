from pathlib import Path
import hashlib, json, shutil
root=Path(__file__).resolve().parents[1]
release=root/'builds/all-cuan-2026-10-19'
previews=root/'previews'
checks={
'all-cuan-stories-gpu.log':'FOLK_STORIES_CUAN_OK',
'all-cuan-culture-gpu.log':'CULTURE_SCROLL_OK',
'all-cuan-story-gpu.log':'STORY_SOUND_OK',
'all-cuan-achievements-gpu.log':'ACHIEVEMENT_BOOK_OK',
'all-cuan-coop-gpu.log':'LOCAL_COOP_RENDER_OK',
'all-cuan-font-audit.log':'PLAYTEST_BUNDLE_OK',
}
environment='ERROR: Failed to read the root certificate store.'
def check(path,marker):
    s=path.read_text(encoding='utf-8-sig')
    assert marker in s,path
    errors=[line for line in s.splitlines() if 'ERROR:' in line]
    assert all(line==environment for line in errors),(path,errors)
for name,marker in checks.items():
    check(previews/name,marker)
    shutil.copy2(previews/name,release/name)
for name in ['export-console.log','pck-check.log','startup.log']:
    check(release/name,'Godot Engine')
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf-8'))
assert bundle['all_runtime_text_cuan_and_slightly_bolder_headings_verified']
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
font=root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf'
font_sha=hashlib.sha256(font.read_bytes()).hexdigest()
assert font_sha.upper()=='6A8F3A0E4142AFBD4729A0825875D833E28DEF3FFD51F95A0CD379A2FFAF511B'
shots={
'coop-culture-person-1.png':'人物小传_全文爨体.png',
'coop-culture-page-1.png':'文化介绍_全文爨体.png',
'coop-culture-scroll-4.png':'共生长卷_全文爨体.png',
'coop-folk-stories-flower-parcel.png':'包裹线索_全文爨体.png',
'coop-folk-stories-prologue-scholar_tools.png':'器物故事_全文爨体.png',
'coop-story-puzzle-portrait.png':'对白与提示_全文爨体.png',
'coop-achievements-seven-cultures-connected.png':'成就册_全文爨体.png',
}
for src,dst in shots.items(): shutil.copy2(previews/src,release/dst)
note='全界面爨体与标题轻微加粗_说明.md'
description='''# 全界面爨体与标题轻微加粗

2026-10-19。项目根“开始游戏（最新版）”和“开始游戏（八牌入场版）”启动本轮 `cuan-game/builds/all-cuan-2026-10-19/CuanParty.exe`；同目录PCK必须保留。

按用户“全部用爨体，标题加粗一点点”，所有运行时文字统一使用现有梁培生小爨现代字库：对白和角色名、文化介绍、八位人物小传、物品说明与实物署名、21种小艺中的故事/指令/数字、包裹线索、成就说明、声音面板、提示与长卷正文。移除各界面单独的系统字体构造，统一正文入口body_font；富文本普通、加粗、斜体及等宽格式均保持同一家族，场景预设标签与默认主题也接入爨体。

标题、栏目、牌匾与按钮用同一家族的FontVariation，variation_embolden=0.3，轻微增加笔画厚度，正文使用原重。保留缺字后备。字体文件SHA256与原始来源记录完全一致，未改字库数据。用户原图、实际拓片与参考照片中的文字保留原图内容；现代字库仍明示为现代示意，原有来源及使用范围见assets/calligraphy/SOURCE.md。

真实显卡检查文化四页、八位人物、四幅长卷、21个器物故事和逐物小艺、四个主角半身像对白及碑面紧凑对白、成就册全部21类与八项交融成就，换行/显示行数检查通过。完整双人三关流程通过，保留前后移动、桥面安全、石碑交接、七灯、音效和永久收藏。人工查看人物小传、器物故事、紧凑对白、成就册与明亮长卷截图，字形与边界显示正常。

导出后的独立PCK逐节点核对Label、Button、Label3D与富文本各字重确实来自爨体，并核对手工绘制文字与标题微增重；Windows原生程序启动退出码0。测试收藏使用独立路径，未替换玩家收藏。截图、原始日志、EXE/PCK字节数与SHA256见验证记录.json。

日志保留Godot的系统根证书读取环境诊断“Failed to read the root certificate store”；仅此既有诊断得到容许，未忽略其他脚本/断言错误，未修改系统证书或网络设置。

备份为backups/before-all-cuan-2026-10-19，保留上一版可运行导出。本轮更新可运行目录及最新版入口。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf-8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description,encoding='utf-8')
entry=('2026-10-19 最新全界面爨体：正文、对白、小传、21器物说明与小艺、包裹、成就、声音及长卷全部统一现有小爨；标题/栏目/按钮/牌匾以FontVariation 0.3轻微增重，正文原重。富文本全字重与场景预设/默认主题覆盖，原始图片和字库字节保留。文化/对白/逐物小艺/成就GPU及完整双人三关通过，独立PCK全树字体核对与原生启动通过。当前 `builds/all-cuan-2026-10-19/CuanParty.exe`，根最新版入口同步。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。')
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    s=path.read_text(encoding='utf-8-sig')
    if '2026-10-19 最新全界面爨体：' in s: continue
    first,rest=s.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:
        paragraph=paragraph.replace('`builds/all-cuan-', '`../cuan-game/builds/all-cuan-').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md': paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf-8')
p=root/'assets/calligraphy/SOURCE.md'
s=p.read_text(encoding='utf-8-sig').replace('# 六张字卡的字形来源','# 爨体字库与字形来源').replace('用途：当前个人教育、学习的非商业游戏原型中六张字卡的显示。界面提示和现代释读继续使用原有字体。','用途：当前个人教育、学习的非商业游戏原型中的字卡与全界面运行时文字。正文原重，标题轻微增重；详见文末更新。')
p.write_text(s,encoding='utf-8')
files={}
for name in ['CuanParty.exe','CuanParty.pck',*shots.values()]:
    p=release/name
    files[name]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
record=dict(result='ALL_CUAN_RELEASE_VERIFIED',date='2026-10-19',checks=checks,bundle=bundle,native_startup=startup,
            font_sha256=font_sha,heading_embolden=0.3,files=files,
            renderer='NVIDIA RTX 5060 Laptop GPU / OpenGL Compatibility',environment_diagnostic=environment)
(release/'验证记录.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print('ALL_CUAN_RELEASE_VERIFIED',len(checks),'checks,',len(shots),'screenshots')
