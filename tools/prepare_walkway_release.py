from pathlib import Path
import json
import hashlib
import shutil

root = Path(__file__).resolve().parents[1]
release = root/'builds/walkway-fixes-2026-10-18'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
previous = root/'builds/scene-atmosphere-2026-10-18'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt']:
    shutil.copy2(previous/name,release/name)
p = release/'先看这里_启动与操作.txt'
text = p.read_text(encoding='utf-8')
p.write_text('爨境·共生 / 牌匾与桥头通行修正版\n\n封面和游戏内的声音入口均在最右上角。\n两块终幕牌匾已放大，灯笼与檐口已错开。\n跟随者绕开木料，搭好桥后的两端斜向通行和跳跃已加边界。\n\n'+text,encoding='utf-8')
doc = root.parent/'cuan-game-blueprint/牌匾遮挡_封面声音入口与桥头通行_说明.md'
shutil.copy2(doc,release/'本轮改动与验证.md')

note = '2026-10-18 最新牌匾与桥头通行修正：封面/游戏的声音入口按钮本身移至最右上角X1164，行囊与重开左移错开。终幕两牌放大并前移檐口外，大灯中央上提、三排小灯抬高，字面避让。建桥后两岸提前收窄连续安全纵深，补桥头斜拉护绳，防四角斜走/跳跃绕出桥面。跟随者取消自动跳障，AStarGrid地面路线绕木料/布架，阻塞目标投影到空地，随木料/开门/架桥更新；道具和推料阻挡覆盖上方，保留原推运与任务参数。新专项GPU、完整双人GPU、声音/对话GPU及单人/四向石碑/附近交互回归通过；独立PCK和原生启动见构建日志。当前 `builds/walkway-fixes-2026-10-18/CuanParty.exe`，根最新快捷方式同步，未做新ZIP。见 [本轮说明](../cuan-game-blueprint/牌匾遮挡_封面声音入口与桥头通行_说明.md)。下方为历史记录。'
for folder,names in [(root,['README.md','制作记录.md','AGENTS.md']),(root.parent/'cuan-game-blueprint',['README.md','四人同行_试玩说明.md']),(root.parent,['AGENTS.md'])]:
    for name in names:
        p = folder/name
        text = p.read_text(encoding='utf-8')
        n = note
        if folder.name=='cuan-game-blueprint': n = n.replace('`builds/','`../cuan-game/builds/').replace('../cuan-game-blueprint/','./')
        if folder == root.parent: n = n.replace('../cuan-game-blueprint/','cuan-game-blueprint/')
        if n in text: continue
        title,rest = text.split('\n',1)
        p.write_text(title+'\n\n'+('- ' if name=='AGENTS.md' else '')+n+'\n'+rest,encoding='utf-8',newline='\n')
print('WALKWAY_RELEASE_PREPARED')
