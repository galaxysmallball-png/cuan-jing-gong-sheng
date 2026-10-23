from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/cooperative-experience-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
old=root/'builds/lantern-bays-steles-2026-10-19'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(old/name,release/name)
p=release/'先看这里_启动与操作.txt'
s=p.read_text(encoding='utf-8-sig').replace('lantern-bays-steles-2026-10-19','cooperative-experience-2026-10-19')
p.write_text('''爨境，共生｜合作玩法与同行引导版 · 2026-10-19

启动：Windows 64位，双击 CuanParty.exe；同目录 CuanParty.pck 必须保留。
项目根“开始游戏（最新版）”已指向本版。封面可走完整开场，也可直接试玩第二/第三幕。

1P：WASD前后左右，空格跳跃，E任务操作，F交谈，G换附近目标，Tab换专属同行。
2P：方向键移动，右Ctrl跳跃，P或小键盘0操作，/交谈，.换附近目标，右Shift换专属同行。
B包裹，C成就，H帮助，V续话，F2本次档案，R回位置（保留任务进度），T重启旅程。
右上声音设置可分别调音乐与音效；M/N静音。教学可收起、展开，H内也可恢复。

第一关：点击小碑，按一次E/P分享当前角色见闻，换人补齐。邓书年给1/3/5位，杨三娘补2/4/6位。
鼠标拿字，Q或右键转正，点编号凹位放下；四人见闻和六字均正确才开门。大碑可读介绍、合读收对照笺。

第二关：按当前任务察看桥基、备杉木、推料、砌墩、联络与会合架桥。
桥心救碑时，石阿朵持续按住顶碑；老箐在右岸按下收绳、松开放绳，将张力保持绿色。
一直按住绳索键不能获胜；过紧/过松会缓慢回退。单人时同行帮助收放绳索，你在桥心按住E扶碑。

第三关：跟随木橇送碑入院，石阿朵与同伴合力扶正。四人物件归位后，共同试配庭院彩幔。
布置时1P A/D试配、E确认；2P左右试配、P确认；也可用鼠标。两人分别确认后再分头送三盏油灯。
单人依次A/D/E完成左右两幅。Esc可稍后再选，左上布置按钮或灯桌操作可继续。
你们的选择会出现在院中彩幔和F2档案里。七灯亮起，一同走到右廊看长卷。

点击特色器物，可读人物故事、切实物照片/三维、试作小艺；21类物件关联民族收藏与交融成就。
主线为原创护碑故事，原碑年代与资料来源在文化记和二爨介绍中；字库示意及实物图署名均有说明。
本次主线进度在运行内保留，民族收藏长期保存。请用真实陌生人试玩反馈补充自动检查。
资料、字体/照片来源与引擎许可见同目录；本轮改动、截图与验证记录另附。
''',encoding='utf-8')
p=root/'export_presets.cfg'
p.write_text(p.read_text(encoding='utf-8').replace('builds/lantern-bays-steles-2026-10-19/CuanParty.exe','builds/cooperative-experience-2026-10-19/CuanParty.exe'),encoding='utf-8')
s=(root/'tools/export_lantern_bays_release.ps1').read_text(encoding='utf-8-sig')
(root/'tools/export_cooperative_release.ps1').write_text(s.replace('lantern-bays-steles-2026-10-19','cooperative-experience-2026-10-19'),encoding='utf-8-sig')
print('COOPERATIVE_RELEASE_PREPARED')
