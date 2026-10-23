"""Prepare notices and instructions for the locally verified photo/guide build."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
release = root / 'builds/photo-guide-2026-10-18'
release.mkdir(parents=True, exist_ok=True)
(release / '.gdignore').touch()
interface = root / 'assets/interface'
source_file = interface / 'SOURCE.json'
sources = json.loads(source_file.read_text(encoding='utf-8-sig'))
cover = interface / 'scroll_cover.png'
original = Path('C:/Users/26845/Desktop/树莓比赛美工/按钮和提示框背景/ff8a7c2a-dbf2-4846-8552-74f254197169.png')
digest = hashlib.sha256(cover.read_bytes()).hexdigest()
assert digest == hashlib.sha256(original.read_bytes()).hexdigest()
sources = [entry for entry in sources if entry['file'] != cover.name]
sources.append(dict(file=cover.name, source=str(original), sha256=digest,
                    use='共生长卷卷首封面；展卷后接原四幅画面', altered=False))
source_file.write_text(json.dumps(sources, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

catalog = json.loads((root / 'assets/references/folk/catalog.json').read_text(encoding='utf-8'))
assert len(catalog['items']) == 21 and len(catalog['photos']) == 18
credits = ['# 游戏实物照片来源与署名', '',
           '21 类特色物件均可在三维模型和实物照片之间切换。照片按下列工艺或器型作参照；地区、馆藏、作者和授权分别列出。外国器型和其他年代的器具明确标为对照，不据照片推断剧中族属。', '',
           '本地图片为来源照片的下载缩图；竹笔筒在界面取局部展示。原图与署名、授权链接均可由游戏照片下方打开。公共领域条目以来源页的权利声明为准。CC BY/CC BY-SA 照片继续遵守各自授权；软件及其他素材的权利不由照片许可覆盖。', '']
for entry in catalog['photos'].values():
    path = root / entry['file'].removeprefix('res://')
    assert path.exists(), path
    file_hash = hashlib.sha256(path.read_bytes()).hexdigest()
    if 'sha256' in entry:
        assert file_hash == entry['sha256'], path
    else:
        # The pre-existing Met brush-holder reference predates this catalog.
        assert path.name == 'bamboo_brush_holder_met.jpg', path
        entry['sha256'] = file_hash
    assert entry['author'] and entry['source'] and entry['license']
    license_url = entry.get('license_url') or entry['source']
    credits += [f"- {entry['title']} — {entry['author']} — {entry['license']}",
                f"  来源：{entry['source']}", f"  授权/权利声明：{license_url}",
                f"  本地文件：{entry['file']}", '']
credits_path = root / 'assets/references/folk/CREDITS.md'
credits_path.write_text('\n'.join(credits), encoding='utf-8')
(root / 'assets/references/folk/catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
shutil.copy2(credits_path, release / '实物照片_来源与授权.md')
shutil.copy2(root / 'assets/references/folk/catalog.json', release / '实物照片目录.json')
old = root / 'builds/walkway-fixes-2026-10-18'
notices = (old / '资料与鸣谢.txt').read_text(encoding='utf-8-sig')
notices += '\n\n本轮新增 18 张实物照片，覆盖 21 类特色物件。完整作者、来源页和授权链接见同目录《实物照片_来源与授权.md》；游戏照片下方也有来源与授权入口。\n'
(release / '资料与鸣谢.txt').write_text(notices, encoding='utf-8-sig')

instructions = '''爨境·共生 — 2026-10-18 实物图与关卡指引版

Windows 64 位。双击 CuanParty.exe，保留同目录 CuanParty.pck。
项目根“开始游戏（最新版）”也会启动此版本。

同键盘双人：
1P：WASD 前后左右；空格跳；E 任务；F 交谈/察看；G 切附近目标；Tab 换自己的角色。
2P：方向键前后左右；右 Ctrl 跳；P / 小键盘0 任务；/ 交谈/察看；. 切附近目标；右 Shift 换自己的角色。
H / 左上“提示”：查看操作。右上“声音设置”：音乐、音效各自开关与音量。
B 行囊；V 续话；F2 档案；R 回本关起点；T 清空重玩。
各场景右上“重新开始”重置当前关及后续关。

第一关：
向右找到小爨碑，点击碑面进入合看；大爨碑是可选对照。
两位玩家分别长按自己的操作键，或长按下方对应按钮，分享当前角色的线索。
每人再换到自己的另一位同行，补齐四人的分享；按钮显示状态与长按百分比。
六字从上至下为“晋、故、振、威、建、宁”。
点击拿起字卡，按 Q / 鼠标右键将角上箭头转向上方，再点击右侧编号槽放下。
放错的字卡可以取回调整；顶部会指出第几格的次序或方向需要修正。
线索与字卡齐备后开门，向右与同伴出院。Esc 可暂时离开，已有进度保留。

特色器物：
点击场景中的特色物件，打开介绍、可旋转三维模型与同行小艺。
点“实物照片·切换查看”看照片；点“回到三维”返回模型。
有多张参照的物件可点“下一张”。照片均随 PCK 离线携带。
照片下方显示实拍对象、作者、来源和授权。外国器型、其他年代的器具会标明对照。

长卷：
共同完成第三关并在右廊会合，先展示新花卉卷首封面。
点“展卷共读”或 Enter 阅读原四幅画面；A/D、左右箭头翻页，末页 Enter 返回庭院，Esc 随时收起。

本轮调整：瀑布上窄下宽并有落水雾；新长卷封面；第一关四步提示与双人按钮；21 类特色物件实物图切换。
这是一份可运行试玩版。检查记录与截图见《验证记录.json》和《本轮改动与验证.md》。
'''
(release / '先看这里_启动与操作.txt').write_text(instructions, encoding='utf-8-sig')
print('PHOTO_GUIDE_RELEASE_PREPARED', len(catalog['items']), 'items,', len(catalog['photos']), 'photos; original cover SHA256', digest)
