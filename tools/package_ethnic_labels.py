"""Package the exported ethnicity-label update without rebuilding model sources."""
from pathlib import Path
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/ethnic-labels-2026-10-17'
assert all((BUILD / name).is_file() for name in ['CuanParty.exe', 'CuanParty.pck', 'CuanParty.console.exe'])

read_first = '''爨境·共生 — 民族标注版（2026-10-17）

运行本目录 CuanParty.exe，保留同目录 CuanParty.pck。
点击“开始同行”，逐个查看角色介绍，或按 Esc 跳过介绍。

按用户提供《爨境共生_人物服饰设定.docx》统一显示：
邓书年（汉族）
石阿朵（白族）
老箐（彝族）
杨三娘（回族）

已同步头顶姓名、两排选角按钮、角色介绍、玩家状态栏、对白、任务提示和结尾长卷。
四位角色模型和三幕任务沿用杨三娘角色美术版。

1P：A/D 行走，W/空格跳，S/E 操作，Tab 或数字 1—4 换人。
2P：左右箭头行走，上箭头跳，下箭头操作，右 Shift 换人。
F2 档案暂停，R 回出生点保留进度，T 清空三幕重玩。
1P 按数字 4 即可控制杨三娘；不能占用对方正在控制的角色。

已检查四张角色介绍、实际游戏姓名和选角布局，并通过完整双人三幕显卡流程及有限启动检查。
自动检查不能代替真实双人键盘体验验收，首次通关时长仍待玩家实测。

模型编辑源继续使用已有四人 Blender 工程，本次没有重做模型。
附姓名显示、第二/三幕提示和四张角色介绍截图。
'''
(BUILD / '先看这里.txt').write_text(read_first, encoding='utf-8-sig')
for name in ['字体来源与使用范围.txt', '完整试玩说明.txt']:
    shutil.copy2(PROJECT / 'builds/yang-character-2026-10-17' / name, BUILD / name)
pictures = {
    'coop-ethnic-names.png': '四人姓名民族标注.png',
    'coop-ethnic-creek.png': '第二幕民族标注.png',
    'coop-ethnic-garden.png': '第三幕民族标注.png',
}
for index in range(1, 5):
    pictures[f'coop-ethnic-intro-{index}.png'] = f'角色介绍_{index}.png'
for source, destination in pictures.items():
    shutil.copy2(PROJECT / 'previews' / source, BUILD / destination)

path = PROJECT / 'builds/四人同行_民族标注_2026-10-17.zip'
with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for child in sorted(BUILD.iterdir()):
        if child.is_file() and child.suffix != '.log':
            archive.write(child, Path(BUILD.name) / child.name)
with zipfile.ZipFile(path) as archive:
    assert archive.testzip() is None
print('ETHNIC_LABELS_PACKAGED_OK', json.dumps({'bytes': path.stat().st_size, 'pictures': len(pictures)}))
