from pathlib import Path
import shutil
root=Path('数媒/cuan-game')
release=root/'builds/all-cuan-2026-10-19'
release.mkdir(parents=True,exist_ok=True)
(release/'.gdignore').touch()
old=root/'builds/folk-stories-cuan-2026-10-19'
for name in ['先看这里_启动与操作.txt','资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
    shutil.copy2(old/name,release/name)
p=release/'先看这里_启动与操作.txt'
s=p.read_text(encoding='utf-8-sig').replace('folk-stories-cuan-2026-10-19','all-cuan-2026-10-19')
p.write_text('2026-10-19 全界面爨体版：正文、对白、提示、包裹、成就与小艺文字统一爨体；标题轻微加粗。\n\n'+s,encoding='utf-8')
p=root/'export_presets.cfg'
s=p.read_text(encoding='utf-8').replace('builds/folk-stories-cuan-2026-10-19/CuanParty.exe','builds/all-cuan-2026-10-19/CuanParty.exe')
p.write_text(s,encoding='utf-8')
p=root/'assets/calligraphy/SOURCE.md'
s=p.read_text(encoding='utf-8-sig')
s+='\n\n2026-10-19 全界面排版更新：同一现有字库用于运行时正文、对白、物品说明、包裹线索、成就、字幕、按钮和指示牌；标题通过 Godot FontVariation 的 0.3 轻微增重呈现，字库文件字节未改。保留缺字后备，原始拓片与用户图片中的字仍为原图内容。字库来源、现代示意性质与原有使用范围不变。\n'
p.write_text(s,encoding='utf-8')
# These one-off edit scripts are complete; the maintained bundle verifier remains.
for name in ['apply_all_cuan.py','add_all_cuan_bundle_check.py']:
    p=root/'tools'/name
    p.unlink()
print(release.resolve())
