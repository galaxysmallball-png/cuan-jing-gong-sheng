from pathlib import Path
import json,hashlib,shutil,sys

root=Path(__file__).resolve().parents[1]
previous='builds/twin-steles-art-2026-10-20'
current='builds/art-audit-2026-10-20'
release=root/current
backup=root/'backups/before-art-audit-2026-10-20'
allowed='ERROR: Failed to read the root certificate store.'
if '--prepare' in sys.argv:
    release.mkdir(parents=True,exist_ok=True)
    (release/'.gdignore').touch()
    for name in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
        shutil.copy2(root/previous/name,release/name)
    for name in ['开始游戏（最新版）.lnk','开始游戏（八牌入场版）.lnk']:
        path=root.parent.parent/name
        if path.exists() and not (backup/name).exists():shutil.copy2(path,backup/name)
    text=(root/'tools/export_twin_steles_release.ps1').read_text(encoding='utf-8-sig')
    (root/'tools/export_art_audit_release.ps1').write_text(text.replace(previous,current),encoding='utf-8-sig')
    config=root/'export_presets.cfg'
    config.write_text(config.read_text(encoding='utf8').replace(previous,current),encoding='utf8')
    print('ART_AUDIT_RELEASE_PREPARED')
    sys.exit(0)

assert '--seal' in sys.argv
checks={'art-audit-audio-mix.log':'DRAW_AUDIO_MIX_OK after','art-audit-clarity-gpu.log':'ART_AUDIT_OK',
        'art-audit-after-gpu.log':'SCENE_ART_INSPECTION_OK after-audit','art-audit-steles-gpu.log':'TWIN_STELES_ART_OK',
        'art-audit-native-crafts-gpu.log':'NATIVE_CRAFTS_OK','art-audit-coop-gpu.log':'LOCAL_COOP_RENDER_OK','art-audit-single.log':'PARTY_GAME_OK'}
def verify(path,marker):
    content=path.read_text(encoding='utf-8-sig')
    assert marker in content,(path,marker)
    bad=[line for line in content.splitlines() if ('ERROR:' in line or 'WARNING:' in line) and line!=allowed]
    assert not bad,(path,bad)
for name,marker in checks.items():
    verify(root/'previews'/name,marker)
    shutil.copy2(root/'previews'/name,release/name)
for name,marker in [('export-console.log','Godot Engine'),('export-stdout.log','Godot Engine'),('pck-check.log','PLAYTEST_BUNDLE_OK'),('pck-stdout.log','PLAYTEST_BUNDLE_OK'),('startup.log','Godot Engine')]:verify(release/name,marker)
bundle=json.loads((release/'bundle-check.json').read_text(encoding='utf8'))
assert all(v is True for k,v in bundle.items() if k.endswith('_verified'))
startup=json.loads((release/'startup-check.json').read_text(encoding='utf-8-sig'))
assert startup['exit_code']==0
before=json.loads((root/'previews/draw-mix-before.json').read_text(encoding='utf8'))
after=json.loads((root/'previews/draw-mix-after.json').read_text(encoding='utf8'))
assert after['samples']>2000 and after['rms_dbfs']>-32 and after['loop_frames']==after['expected_loop_frames']
assert after['rms_dbfs']-before['rms_dbfs']>10
for name in ['draw-mix-before.json','draw-mix-after.json']:shutil.copy2(root/'previews'/name,release/name)
audio=json.loads((root/'assets/audio/card_rotation_audit_20261020/SOURCE.json').read_text(encoding='utf8'))
for item in audio['effects']:
    file=root/'assets/audio/card_rotation_audit_20261020'/item['file']
    assert hashlib.sha256(file.read_bytes()).hexdigest()==item['sha256'] and item['peak_dbfs']<-3
(release/'选牌音效_来源与输出校验.json').write_text(json.dumps(audio,ensure_ascii=False,indent=2),encoding='utf8')
shots=['coop-audit-clear-type-1280.png','coop-audit-clear-type-1920.png']
for tag in ['before','after']:
    for shot in ['court','court-left-rocks','creek','creek-cliffs','worksite','garden','garden-tea']:
        shots.append(f'coop-refine-{tag}-audit-{shot}.png')
for name in shots:shutil.copy2(root/'previews'/name,release/name)
panels=[]
for key,title in [('creek-cliffs','溪谷山体与断裂岩台'),('court-left-rocks','树叶、竹节与残廊曲瓦'),('garden-tea','陶罐、茶碗与花盆'),('creek','第二幕全景'),('court','第一幕全景'),('garden','第三幕全景'),('worksite','备木与旧桥基近景')]:
    panels.append(f'''<section><h2>{title}</h2><div class="compare"><img src="coop-refine-before-audit-{key}.png" alt="修改前"><img class="after" src="coop-refine-after-audit-{key}.png" alt="修改后"><i></i></div><label>左侧新版 · 右侧旧版 <input type="range" min="0" max="100" value="50" aria-label="拖动比较{title}" oninput="let c=this.closest('section').querySelector('.compare');c.querySelector('.after').style.clipPath='inset(0 '+(100-this.value)+'% 0 0)';c.querySelector('i').style.left=this.value+'%'">拖动比较</label></section>''')
gallery='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>爨境·共生 · 三幕美术前后对照</title><style>body{margin:0;background:#ede0c4;color:#302e27;font:16px/1.6 "Microsoft YaHei",sans-serif}main{max-width:1280px;margin:auto;padding:32px 20px}h1{color:#843c2b;font-size:28px}h2{font-size:21px;color:#75402b}section{margin:34px 0 52px}.compare{position:relative;overflow:hidden;border:1px solid #ae8d57;background:#17272c;aspect-ratio:16/9}.compare img{width:100%;height:100%;object-fit:contain;display:block}.compare .after{position:absolute;inset:0;clip-path:inset(0 50% 0 0)}.compare i{position:absolute;left:50%;top:0;bottom:0;width:2px;background:#f3d796;pointer-events:none}label{display:flex;align-items:center;gap:15px;padding:12px 0;color:#774a2f}input{flex:1;accent-color:#9c4a35}a{color:#7b3c2b}.type{width:100%;height:auto;border:1px solid #aa8b5d}p{max-width:1000px}</style><main><h1>《爨境·共生》三幕美术前后对照</h1><p>相同镜头的游戏实机画面。拖动分隔线，左侧为本轮细化，右侧为改前画面；也可直接打开同目录PNG查看原尺寸。</p>'''+''.join(panels)+'''<h2>解碑文字 · 1080p实机</h2><img class="type" src="coop-audit-clear-type-1920.png" alt="原生文字与双倍渲染字卡"><p>状态与说明由界面直接绘制；已检查720p、1080p排版和实际鼠标归位。</p><h2>选牌声音检查</h2><p>已修正压缩字节误当采样帧造成的循环截断。真实选牌状态录得的混音输出从约−39.4提升到−21.7dBFS RMS，循环恢复完整44100帧，保留减速、落定、静音和音量设置。</p><p><a href="本轮改动与验证.md">本轮改动与验证说明</a> · <a href="验证记录.json">完整验证记录</a></p></main></html>'''
(release/'美术前后对照.html').write_text(gallery,encoding='utf8')
note='三幕美术自查细化_清晰爨字与选牌声音修复_说明.md'
description='''# 三幕美术自查、清晰爨字与选牌声音 · 2026-10-20

启动：builds/art-audit-2026-10-20/CuanParty.exe，保留同目录PCK；根目录两个“开始游戏”入口同步。旧版保留，本轮不新增ZIP。原脚本/着色器和入口备份位于backups/before-art-audit-2026-10-20。

## 声音与文字

选牌音效丢失感有两个实际问题：此前用导入后压缩字节数除以4估算循环长度，QOA数据35648字节被误判成8912帧，而1秒音源应为44100帧；同时实际混音仅约-39.4dBFS RMS，容易被背景音乐盖住。本轮以音源时长×采样率设定循环帧数（其他长按循环也同步修正），旋转与落定音改专用16位PCM导入、增加纸风与木片掠过的可听力度。选牌期间音乐降低4.5dB，按实际角速度减速与收束，保持音效/音乐独立音量、静音、退出、跳过和重抽。真实暂停选牌状态下通过AudioEffectCapture录得122880个声道样本，约-21.7dBFS RMS、峰值-13.3dBFS，完整44100帧循环；这次检查的是实际混音样本，不只检查playing标记。原型音色无外部采样，清单附SHA256。

模糊的“线索4/4、归位、两行间隔字”和字库说明从3D拼字画面移到原生2D爨体文字，保留现有字库与标题轻微增重。拼字画面从810×438提高至1620×876后按半倍显示，字卡、编号与箭头也更清楚；点击/拖放/Q转向及缩放坐标保持。720p与1080p都检查排版和真实鼠标归位，说明与状态错开，获得线索通知移到空处避让介绍按钮。用户指定花卉纸底不变。

## 三幕美术细化

先用同一镜头检查三幕及岩壁、茶席等近景，再逐项改模并输出前后对照。[打开可拖动的同镜头对照](美术前后对照.html)。

- 溪谷尖柱状山体改连续有厚度的岩体，正面增加12块错缝断裂岩台、断角和凹缝，分为三种相近石色并合批；保留远山与雾层，岩石表面使用轻微沉积条带、矿物斑驳、潮湿暗部和朝上面的少量苔色。河道中突出水面的几块长棱柱也改成受水冲蚀的不规则轮廓，仍全部在行走范围外。
- 七株树冠改为成簇叶片与中央折脊，不再由扁球堆成。竹子补竹节、侧枝和细长叶；垂藤的方块状叶片替换为有弯折的叶片。沿用各幕原来的暖夕照、冷月夜与庭院暖光配色。
- 第一幕残廊原大平板残瓦改53块弧面叠瓦与滴水端，保留缺口和露出的椽木；第三幕现有屋檐、梁柱、格栅细节保留。木材纹理改为较细木纹与节疤，弱化粗黑波纹，石面去过强的像素噪点和方块苔斑。
- 共庭茶罐改旋转成型曲面，有足、腹、肩、颈、厚唇、盖钮与两耳；三只茶碗有碗足、薄沿、内壁和茶汤。黑陶与釉面各用细轮纹和不同粗糙度。对应器物预览、实物照片、小游戏和收录不变。
- 马铃改为空心铃腔、卷口、刻线、吊环与内部铃舌，拾取物和共庭挂件共用造型。花盆改桶形沿口与金属箍，花朵改有弧度的花瓣、花心、枝叶，移离茶席和村民前方。
- 旧路岩面删除大块弯曲网纹，改少量细裂与颗粒，不遮蔽可辨的旧路线刻痕。大小爨碑主线、搬运动画、人物源工程与GLB、原图和字库都保留。

## 参考与制作方式

检索时参考[Keeper官方画面](https://www.doublefine.com/games/keeper)中前后景、岩壁体积和空气层次，以及[Line+斗拱展陈细节](https://www.lineplus.studio/news_cont_1852.html?ctid=44)的构件叠接。它们仅作构图/结构观察；没有下载或使用其中的模型、纹理和录音，也不把游戏场景称作某一历史建筑的复原。本轮模型、叶片、器形、材质和音效均在项目内制作，游戏运行无需联网。

## 验证

实际混音采样；两种分辨率原生文字和鼠标坐标；两碑真实解谜与防跳过；21件小艺与随身器物点选、照片和重试；完整双人和单人三关；同镜头三幕及近景截图；独立导出PCK资源、字体、循环帧数与新模型检查；Windows EXE启动。新景物不添加碰撞。各项完成日志随包保留，仅放行本机既有根证书读取诊断。测试与截图可复现，不代表所有设备的人工听感和画面验收。
'''
(release/'本轮改动与验证.md').write_text(description,encoding='utf8')
blueprint=root.parent/'cuan-game-blueprint'
(blueprint/note).write_text(description.replace('(美术前后对照.html)','(../cuan-game/'+current+'/美术前后对照.html)'),encoding='utf8')
guide=(root/previous/'先看这里_启动与操作.txt').read_text(encoding='utf8').replace('二爨合验与美术版','三幕细节与清晰文字修复版')
(release/'先看这里_启动与操作.txt').write_text(guide,encoding='utf8')
entry='2026-10-20 最新三幕美术细化与音字修复：修正QOA字节误当采样帧导致的截断循环，选牌换专用PCM纸风木片、随速减缓，实际混音采样通过，选牌音乐适度让位。解碑状态/说明改原生2D爨字，拼字双倍渲染，720p/1080p真实点选通过。溪谷连续岩体与断裂岩台、河道水蚀石、七株叶片树冠、竹节细叶、垂藤、残廊曲瓦、细木纹石面、曲面茶罐釉碗、空心马铃与花瓣盆栽逐处细化，茶席和村民前方让开。三幕同镜头对照、21件器物、两碑、单双人完整流程、独立PCK与原生启动通过。当前 `'+current+'/CuanParty.exe`，根入口同步，无新ZIP。见 [本轮说明](../cuan-game-blueprint/'+note+')。下方为历史记录。'
for path in [root/'README.md',root/'制作记录.md',root/'AGENTS.md',root.parent/'AGENTS.md',blueprint/'README.md',blueprint/'四人同行_试玩说明.md']:
    text=path.read_text(encoding='utf-8-sig')
    if '2026-10-20 最新三幕美术细化与音字修复：' in text:continue
    target=backup/'docs'/(path.parent.name+'-'+path.name)
    target.parent.mkdir(parents=True,exist_ok=True)
    if not target.exists():shutil.copy2(path,target)
    first,rest=text.split('\n',1)
    paragraph=('- ' if path.name=='AGENTS.md' else '')+entry
    if path.parent==blueprint:paragraph=paragraph.replace('`builds/','`../cuan-game/builds/').replace('../cuan-game-blueprint/'+note,'./'+note)
    elif path==root.parent/'AGENTS.md':paragraph=paragraph.replace('../cuan-game-blueprint/'+note,'cuan-game-blueprint/'+note)
    path.write_text(first+'\n\n'+paragraph+'\n'+rest,encoding='utf8')
font_sha=hashlib.sha256((root/'assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf').read_bytes()).hexdigest()
assert font_sha=='6a8f3a0e4142afbd4729a0825875d833e28def3ffd51f95a0cd379a2ffaf511b'
files={}
for name in ['CuanParty.exe','CuanParty.pck','美术前后对照.html',*shots]:
    p=release/name
    files[name]=dict(bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest())
(release/'验证记录.json').write_text(json.dumps(dict(result='ART_AUDIT_RELEASE_VERIFIED',checks=checks,bundle=bundle,startup=startup,audio_before=before,audio_after=after,files=files,font_sha256=font_sha,environment_diagnostic=allowed),ensure_ascii=False,indent=2),encoding='utf8')
for name in ['bundle-achievements-profile.json','startup-test-profile.json']:(release/name).unlink(missing_ok=True)
print('ART_AUDIT_RELEASE_VERIFIED',len(checks),'checks')
