from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]/'scripts'
for name in ['glyph_puzzle.gd','creek_art.gd','courtyard_art.gd','festival_court.gd']:
    p=root/name
    s=p.read_text(encoding='utf-8')
    s=re.sub(r'(\.font_size = )(\d+)',r'\1preload("res://scripts/interface_skin.gd").text_size(\2)',s)
    p.write_text(s,encoding='utf-8')
p=root/'garden_art.gd'
s=p.read_text(encoding='utf-8').replace('label.font_size = font_size','label.font_size = UiStyle.text_size(font_size)')
p.write_text(s,encoding='utf-8')
p=root/'achievement_threads.gd'
s=p.read_text(encoding='utf-8')
for n in [14,11,18]:
    s=s.replace(',-1,'+str(n)+',',',-1,preload("res://scripts/interface_skin.gd").text_size('+str(n)+'),')
s=s.replace('point+Vector2(-14,5)','point+Vector2(-16,6)').replace('center+Vector2(-18,6)','center+Vector2(-21,7)')
p.write_text(s,encoding='utf-8')
