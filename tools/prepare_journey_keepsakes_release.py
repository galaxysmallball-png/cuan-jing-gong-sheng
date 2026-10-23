from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
previous=root/'builds/scene-art-2026-10-19'
release=root/'builds/journey-keepsakes-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(previous/name,release/name)
p=release/'先看这里_启动与操作.txt'
text=p.read_text(encoding='utf-8-sig').replace('三幕场景美工版','沿途拾物与本轮成就版')
text=text.replace('本次主线进度在运行内保留，民族收藏长期保存。','主线与成就只在本轮保留，再次启动或T重启旅程从零收集。R回位置、重开本关保留本轮成就。')
text=text.replace('第一关：点击小碑，','第一关：沿路拾取邓书年的练习拓片、石阿朵的錾子。点击小碑，')
text=text.replace('第二关：按当前任务','第二关：沿路拾取老箐的马铃、杨三娘的红线。按当前任务')
text=text.replace('四人物件归位后，','把前两关拾得的四人物件归位后，')
text+='''
沿途拾物：第一关残廊拓印桌旁的练习拓片、大碑右侧古道口的錾子；第二关左岸行囊旁的马铃、花布架前的红线。
任一玩家可以代拾：走近、落地站稳，按一下自己的E/P，或点击地面物件。拾取后模型消失，提示已放入包裹。
B包裹中可切“随身物件”，查看散落位置、待拾/已拾/归位和用途。第三关由对应角色归位，未拾到的不能凭空安放。
漏拾时可沿已修好的桥返回；前往第三关的直达试玩会预置前两关物件，完整旅程需要实际拾取。
重开第一关：四件重新散落；重开第二关：保留第一关两件，第二关两件重新散落；重开第三关：保留已拾物件，重新归位。
成就系统不再读取或写入长期收藏，旧收藏不会带入本轮；每轮仍可收集21类器物、解锁8项交融成就。
'''
p.write_text(text,encoding='utf-8')
old='builds/scene-art-2026-10-19'
new='builds/journey-keepsakes-2026-10-19'
export=(root/'tools/export_scene_art_release.ps1').read_text(encoding='utf-8-sig')
(root/'tools/export_journey_keepsakes_release.ps1').write_text(export.replace(old,new),encoding='utf-8-sig')
preset=root/'export_presets.cfg'
preset.write_text(preset.read_text(encoding='utf-8').replace(old,new),encoding='utf-8')
backup=root/'backups/before-journey-keepsakes-2026-10-19'
for name in ['开始游戏（最新版）.lnk','开始游戏（八牌入场版）.lnk']:
    source=root.parent.parent/name
    if source.exists() and not (backup/name).exists(): shutil.copy2(source,backup/name)
print('JOURNEY_KEEPSAKES_RELEASE_PREPARED')
