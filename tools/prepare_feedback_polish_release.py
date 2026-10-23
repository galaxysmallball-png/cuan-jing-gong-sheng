from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
old = 'builds/journey-keepsakes-2026-10-19'
new = 'builds/feedback-polish-2026-10-19'
release = root / new
release.mkdir(parents=True, exist_ok=True)
(release / '.gdignore').touch()
for name in ['先看这里_启动与操作.txt', '资料与鸣谢.txt', '实物照片_来源与授权.md', '实物照片目录.json']:
    shutil.copy2(root / old / name, release / name)
path = release / '先看这里_启动与操作.txt'
text = path.read_text(encoding='utf-8-sig')
text = text.replace('沿途拾物与本轮成就版', '二爨奖励与互动修正版')
text = text.replace('右Ctrl', '小键盘Enter（数字键盘右下角）').replace('小碑', '小爨碑')
text += '''
本轮修正：
大爨碑完成二爨合读，收录两碑年代、地点与书体差异，并解锁终幕卷轴“二爨一脉 · 405—458”纪年题签。
此奖励不提供小爨碑的六字答案；主线仍需四位角色在小爨碑分享互补线索。
听音小艺不显示音序、数字答案或播放亮牌；请听后回应，可反复点“再听一次”。声音设置中需开启音效。
壮族栏的木梁、柴刀为器物收录：第二关让杨三娘联络帮手，再点击阿强肩上的木梁／腰间柴刀。
阿强扛梁时也能查看木梁；点他的脸仍是交谈。已进入庭院时，可沿桥返回右岸寻找阿强。
第二关“筑牢桥头石墩”处现在有松动石墩和压顶石，石阿朵站稳按住自己的操作键，修筑中石块逐步归位。
终幕场景内卷轴采用指定牡丹彩纹纸底，烟花增加红、金、青绿、蓝、紫、粉六色。
2P跳跃改为小键盘Enter；右Ctrl不再跳跃。P／小键盘0仍为任务操作。
'''
path.write_text(text, encoding='utf-8')
export = (root / 'tools/export_journey_keepsakes_release.ps1').read_text(encoding='utf-8-sig')
(root / 'tools/export_feedback_polish_release.ps1').write_text(export.replace(old, new), encoding='utf-8-sig')
preset = root / 'export_presets.cfg'
preset.write_text(preset.read_text(encoding='utf-8').replace(old, new), encoding='utf-8')
backup = root / 'backups/before-feedback-polish-2026-10-19'
for name in ['开始游戏（最新版）.lnk', '开始游戏（八牌入场版）.lnk']:
    source = root.parent.parent / name
    if source.exists() and not (backup / name).exists():
        shutil.copy2(source, backup / name)
print('FEEDBACK_POLISH_RELEASE_PREPARED')
