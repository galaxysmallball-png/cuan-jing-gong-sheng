"""Package the light classical-language dialogue update."""
from pathlib import Path
import shutil
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
BUILD = PROJECT / 'builds/classical-dialogue-2026-10-17'
PREVIOUS = PROJECT / 'builds/field-satchel-2026-10-17'
assert all((BUILD / name).is_file() for name in ['CuanParty.exe', 'CuanParty.pck', 'CuanParty.console.exe'])
instructions = (PREVIOUS / '先看这里.txt').read_text(encoding='utf-8-sig').replace('行囊拾闻版', '轻古风台词版', 1)
instructions = instructions.replace('新增 行囊 · 拾闻笺', '本版对白稍添古意，保持日常说话的口吻与易懂的操作提示。\n例：“余下两字，还请诸位相助”“碑已立稳”。\n四条解谜见闻与行囊同步更新，线索含义、字卡次序及操作不变。\n\n行囊 · 拾闻笺', 1)
(BUILD / '先看这里.txt').write_text(instructions, encoding='utf-8-sig')
(BUILD / '完整试玩说明.txt').write_text((PROJECT.parent / 'cuan-game-blueprint/四人同行_试玩说明.md').read_text(encoding='utf8'), encoding='utf-8-sig')
shutil.copy2(PREVIOUS / '字体来源与使用范围.txt', BUILD)
for source, name in {
    'coop-satchel-all-notes.png': '行囊见闻_轻古风台词.png',
    'coop-ethnic-creek.png': '断溪古道_对白.png',
    'coop-ethnic-garden.png': '灯火共庭_对白.png',
}.items():
    shutil.copy2(PROJECT / 'previews' / source, BUILD / name)
path = PROJECT / 'builds/四人同行_轻古风台词_2026-10-17.zip'
with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for child in sorted(BUILD.iterdir()):
        if child.is_file() and child.suffix != '.log':
            archive.write(child, Path(BUILD.name) / child.name)
with zipfile.ZipFile(path) as archive:
    assert archive.testzip() is None
print('CLASSICAL_DIALOGUE_PACKAGED_OK', path.stat().st_size)
