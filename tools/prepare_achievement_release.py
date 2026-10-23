from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/achievement-book-2026-10-18'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
prior=root/'builds/photo-guide-2026-10-18'
for name in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(prior/name,release/name)
instructions=(prior/'先看这里_启动与操作.txt').read_text(encoding='utf-8-sig')
instructions=instructions.replace('实物图与关卡指引版','共生见闻成就册版')
instructions=instructions.replace('B 行囊；V 续话；F2 档案；R 回本关起点；T 清空重玩。','B 行囊；C 成就册；V 续话；F2 档案；R 回本关起点；T 重启旅程（保留长期收藏）。')
instructions+='''

共生见闻 · 成就册：
封面与游戏顶栏的“共生见闻”或 C 打开，Esc / C 收起。
物件浮窗里也能点“共生见闻·成就”；收起成就册会回到刚才的物件窗口。
与特色物件交互打开介绍后，自动加入收藏。两位玩家共享这本册子，重复查看只收录一次。
七个民族分别有收藏页，按剧中人物与使用情境归档；茶席、织机列为共用器物。
已收录的物件可以在册中重看实物图、来源与交融见闻，离开原场景后仍可查看。
八项成就：初见一物、笔墨石声、布上相逢、众手成桥、茶暖往来、共用成家、七族同庭、万物成卷。
点“交融成就”可看条件、当前进度，以及不同人物的手艺和生活经验如何相接。
点成就条件中的器物名，可跳到对应收藏页；未收录的物件会提示所在关卡。
左右箭头或“上一页/下一页”翻页；不同民族的收录会点亮右侧连结图谱。
收藏与成就保存在本机用户数据中；退出、重开关卡、R / T 均保留。关卡见闻与小艺仍按原有规则重置。
'''
(release/'先看这里_启动与操作.txt').write_text(instructions,encoding='utf-8-sig')
print('ACHIEVEMENT_RELEASE_PREPARED')
