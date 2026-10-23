"""Package the exported clue-satchel game and its current player instructions."""
from pathlib import Path
import json
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/field-satchel-2026-10-17'
assert all((BUILD / name).is_file() for name in ['CuanParty.exe', 'CuanParty.pck', 'CuanParty.console.exe'])

instructions = '''爨境·共生 — 行囊拾闻版（2026-10-17）

运行本目录 CuanParty.exe，保留同目录 CuanParty.pck。
点“开始同行”，可看完角色介绍或按 Esc 跳过。

新增 行囊 · 拾闻笺
按 B 或点击上方“行囊”打开，B / Esc 或“收起行囊”返回。
拼字时也能打开，翻看会暂停游戏；收起后继续原来的字卡操作。

邓书年（汉族）：辨字笺
石阿朵（白族）：寻首笺
老箐（彝族）：辨向笺
杨三娘（回族）：合读笺

在小爨碑窗口里，请每位角色分享见闻，收过的线索便留在对应纸笺中。
未收的纸笺显示“待拾”，不提前展示内容；两位玩家共用已收见闻。
即使下方提示已经消失，也可反复打开行囊查看。
本次旅程中换人、离开碑面、进入下一幕或按 R 返回都会保留；T 重开才清空。
这是本次运行的线索记录，尚未增加关闭程序后的存档功能。

1P：A/D 行走，W/空格跳，S/E 分享见闻或操作，Tab 或数字 1—4 换人。
2P：左右箭头行走，上箭头跳，下箭头分享见闻或操作，右 Shift 换人。
鼠标拿放字卡，Q / 右键旋转。四人的见闻与六张字卡均正确后开门。
F2 档案，R 返回并保留进度，T 清空三幕重玩。

已通过行囊实际显卡专项、原双人三幕和单人兼容流程检查，独立程序已做有限启动检查。
四人模型、姓名民族标注及三幕内容保留。真实键盘手感和首次通关时长仍待玩家实测。
'''
(BUILD / '先看这里.txt').write_text(instructions, encoding='utf-8-sig')
(BUILD / '完整试玩说明.txt').write_text((PROJECT.parent / 'cuan-game-blueprint/四人同行_试玩说明.md').read_text(encoding='utf8'), encoding='utf-8-sig')
shutil.copy2(PROJECT / 'builds/ethnic-labels-2026-10-17/字体来源与使用范围.txt', BUILD)
pictures = {
    'coop-satchel-empty.png': '行囊_待拾.png',
    'coop-satchel-one-note.png': '行囊_辨字笺.png',
    'coop-satchel-all-notes.png': '行囊_四笺齐备.png',
    'coop-satchel-resume-puzzle.png': '收起行囊继续拼字.png',
}
for source, destination in pictures.items():
    shutil.copy2(PROJECT / 'previews' / source, BUILD / destination)

path = PROJECT / 'builds/四人同行_行囊拾闻_2026-10-17.zip'
with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for child in sorted(BUILD.iterdir()):
        if child.is_file() and child.suffix != '.log':
            archive.write(child, Path(BUILD.name) / child.name)
with zipfile.ZipFile(path) as archive:
    assert archive.testzip() is None
print('FIELD_SATCHEL_PACKAGED_OK', json.dumps({'bytes': path.stat().st_size, 'pictures': len(pictures)}))
