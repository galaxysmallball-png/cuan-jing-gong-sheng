from pathlib import Path
import hashlib
import json
import shutil

root=Path(__file__).resolve().parents[1]
release=root/'builds/folk-stories-cuan-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
prior=root/'builds/achievement-book-2026-10-18'
for name in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(prior/name,release/name)
instructions=(prior/'先看这里_启动与操作.txt').read_text(encoding='utf-8-sig')
instructions=instructions.replace('2026-10-18 共生见闻成就册版','2026-10-19 爨体与器物故事版').replace('行囊','包裹')
instructions+='''

本轮更新：爨体、器物故事与不同的小艺
标题、关卡名、指示牌、操作入口及按钮使用现有梁培生小爨现代字库。
交互物件后，先阅读对应人物与物品的故事，再点“开始小艺”或 Enter。
21件器物各有题目；按上方提示、故事中的次序及乐句操作，点错可重新接续。
配重共六组，分别为16、18、22、22、24、28份；两组22份的货包重量也不同。
纹样记忆3—7步、合奏回应4—7声，另有四/五步器物整理，逐渐增加长度与难度。
乐句会先示范，听完再用鼠标或1/2/3回应；“听奏示范”可重听。
其他小艺也可点击或用数字1—5选择；“再试一次”回到对应故事后重新开始。
器物小艺按物件记录本次旅程的完成数量；关卡重新开始会清理该关与后续小艺。
共生见闻的永久收藏与成就仍保留；这些小艺不会替你完成认字、修桥和七灯主线。
取得线索时，看碑界面会提示“新线索已放入包裹·按B查看”，无需先退出看碑。
包裹内的线索卡与按钮采用新花卉纸底；正文有浅色衬底，可反复翻看已收线索。
'''
(release/'先看这里_启动与操作.txt').write_text(instructions,encoding='utf-8-sig')
source=Path('C:/Users/26845/Desktop/树莓比赛美工/按钮和提示框背景/aa155e22-ee87-414b-9059-4cb4a69f90ea.png')
paper=root/'assets/interface/parcel_paper.png'
digest=hashlib.sha256(paper.read_bytes()).hexdigest()
assert digest==hashlib.sha256(source.read_bytes()).hexdigest()
manifest=root/'assets/interface/SOURCE.json'
records=json.loads(manifest.read_text(encoding='utf-8-sig'))
records=[entry for entry in records if entry['file']!=paper.name]
records.append(dict(file=paper.name,source=str(source),sha256=digest,use='包裹线索卡与包裹内按钮背景',altered=False))
manifest.write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('FOLK_STORIES_RELEASE_PREPARED',digest)
