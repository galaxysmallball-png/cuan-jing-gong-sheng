from pathlib import Path

root=Path(__file__).resolve().parents[1]
for name in ['controls_hint.gd','cooperative_experience.gd','glyph_puzzle.gd','nearby_interactions.gd','party_ui.gd','stele_inspector.gd','world.gd']:
    path=root/'scripts'/name
    text=path.read_text(encoding='utf-8-sig')
    text=text.replace('右Ctrl','小键盘Enter').replace('右 Ctrl','小键盘 Enter')
    text=text.replace('小碑','小爨碑')
    text=text.replace('大碑合读可获得字形参照。','大爨合读可解锁长卷纪年题签。')
    text=text.replace('收对照笺，为小爨碑添字形参照。','收对照笺，解锁共庭长卷纪年题签。')
    path.write_text(text,encoding='utf-8')
print('FEEDBACK_WORDING_UPDATED')
