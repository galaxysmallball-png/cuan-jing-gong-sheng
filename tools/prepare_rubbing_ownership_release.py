from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
old = 'builds/feedback-polish-2026-10-19'
new = 'builds/rubbing-ownership-2026-10-19'
release = root / new
release.mkdir(parents=True, exist_ok=True)
(release / '.gdignore').touch()
for name in ['资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
    shutil.copy2(root / old / name, release / name)
(release / '先看这里_启动与操作.txt').write_text('''爨境·共生｜合作传拓与物归其主版 · 2026-10-19

Windows 64位，双击 CuanParty.exe；保留同目录 CuanParty.pck。项目根“开始游戏（最新版）”已同步。
封面可完整启程，或直接试玩第二／第三幕。同键盘双人；每人拥有两位专属角色，另一位跟随。

1P：WASD前后左右，空格跳，E任务，F交谈／察看，G换目标，Tab换专属同行。
2P：方向键移动，小键盘Enter跳，P／小键盘0任务，/交谈／察看，.换目标，右Shift换专属同行。
B包裹，C成就册，H帮助，V续话，F2档案，R回位置保留进度，T从第一关重新开始。
右上声音设置分别调整音乐与音效；M／N静音。H可恢复已收起的引导。

第一关：点击小爨碑，先合作传拓，再合读六字。
1. 覆纸：1P用A/D调上边，2P用左右键调下边；纸边到金线后，分别按E／P压稳。可点左右箭头与压纸按钮。
2. 扑墨：1P用W/S选左列的格，2P用上下键选右列的格。指针进绿色区时按E／P，每格轻扑两次。
   按住不会连续扑墨，错过时机可重试；也可直接点格子扑墨。六格墨色均匀才进入揭纸。
3. 揭纸：双人同时按住E／P，托住两边缓缓揭纸，松开会回落；鼠标可配合按住侧边按钮。
4. 点击“取下练习拓片”，再由四位角色各分享一次见闻。Tab／右Shift切换各自的同行。
5. 鼠标拿拓字卡，Q／右键转正，点编号凹位放下；IJKL也可选字／选位，Enter放置。
   四人线索与六字排列、方向均正确才开门。单张放下不再用颜色直接判定对错。
传拓采用练习刻板上的现代小爨字库节选，不直接对古碑上墨；拓字显影为乱序，不代替四人合读。
单人模式：A/D先调上边，E压稳后再调下边；扑墨时A/D换列、W/S选格、E轻扑；按住E揭纸。
Esc中途离开可继续，H暂停会冻结节拍。R保留本轮传拓与字卡进度，重开第一关／T重新制作。
大爨仍可完成二爨合读，获得独立对照笺和终幕“二爨一脉 · 405—458”纪年题签，不提供小爨排列答案。

随身物件只能由物主本人拾取：
邓书年——第一关残廊拓印桌旁的练习拓片；石阿朵——第一关大碑右侧古道口的錾子。
老箐——第二关左岸行囊旁的马铃；杨三娘——第二关花布架前石路上的红线。
请由拥有该角色的玩家按Tab／右Shift换到本人，走近站稳，再按自己的E／P或点击物件。
其他角色的按键、附近交互和鼠标均不能代拾；提示会说明由谁、哪位玩家来拾。拾后按B可查位置与状态。

第二关：察看旧桥基、备杉木、辨路推料。送达后由石阿朵修筑桥头的方石墩，再由杨三娘联络帮手。
石墩有双层基座、错缝砌石、厚压顶与木梁承托；修筑中松动石块逐渐归正，不新增行走障碍。
会合架桥后，石阿朵在桥心按住顶碑，老箐在右岸按下收绳／松开放绳，让张力保持绿色。
一直按住绳索键不能获胜。单人由同行辅助收放绳索，玩家在桥心按住E扶碑。

第三关：随碑入院，合力立碑；由四位角色安放前两关亲自拾得的对应物件。
四物归位后共同选择彩幔，两位玩家分别确认，再分头领取并安放三盏油灯。七灯亮起，走到右廊共看长卷。
漏拾可沿已修桥返回；直达第三关试玩会预置此前四件。重开当前关保留前关收获。

特色器物介绍／实物图／小艺、21件器物与8项交融成就仍保留。成就只在本轮，启动／启程／T清零。
阿强木梁与柴刀属于特色器物收录：杨三娘联络后，点击阿强肩上木梁／腰间柴刀；与四人物件拾取分开。
听音小艺不显示答案，支持重听。终幕保留指定牡丹卷轴底图、六色烟花、九组建筑挂灯和二爨题签。
原碑史实／字体与照片来源、引擎许可见随附文件；自动验证与截图不代替陌生玩家试玩。
''', encoding='utf-8')
export = (root / 'tools/export_feedback_polish_release.ps1').read_text(encoding='utf-8-sig')
(root / 'tools/export_rubbing_ownership_release.ps1').write_text(export.replace(old, new), encoding='utf-8-sig')
preset = root / 'export_presets.cfg'
preset.write_text(preset.read_text(encoding='utf-8').replace(old, new), encoding='utf-8')
backup = root / 'backups/before-rubbing-ownership-2026-10-19'
for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
    source = root.parent.parent / name
    if source.exists() and not (backup / name).exists(): shutil.copy2(source, backup / name)
print('RUBBING_OWNERSHIP_RELEASE_PREPARED')
