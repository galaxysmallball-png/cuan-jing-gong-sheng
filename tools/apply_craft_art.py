from pathlib import Path
p=Path('数媒/cuan-game/scripts/folk_activity_art.gd');s=p.read_text(encoding='utf-8-sig');s=s.replace('\tb.draw_ellipse if false else b.get_class() # drawing remains native, with no raster dependency\n','');p.write_text(s,encoding='utf-8')
p=Path('数媒/cuan-game/scripts/folk_activity_board.gd');s=p.read_text(encoding='utf-8');s=s.replace('var font: Font','var font: Font\nvar hovered: int = -1\nconst Art = preload("res://scripts/folk_activity_art.gd")\nconst VISUAL_VERSION: int = 2')
s=s.replace('Vector2(62+index*101,64)','Vector2(65+index*105,96)').replace('Vector2(62+index*101,107)','Vector2(65+index*105,135)').replace('Vector2(95+index*175,112)','Vector2(100+index*175,130)')
s=s.replace('if not running: return\n\tvar at', '''if event is InputEventMouseMotion:
		hovered=-1
		for index in range(weights.size() if mode==1 else actions.size() if mode==3 else 3):
			if _option_rect(index).has_point(event.position): hovered=index; break
		tooltip_text=("点击移到另一筐" if mode==1 else "点击留下纹样" if mode==0 else "点击回应") if hovered>=0 else ""
		queue_redraw()
	if not running: return
	var at''')
s=s.replace('Rect2(option_position(index)-Vector2(44,30 if mode==1 else 38),Vector2(88,60 if mode==1 else 76)).has_point(at)','_option_rect(index).has_point(at)').replace('at.distance_to(option_position(index))<53','_option_rect(index).has_point(at)')
a=s.index('\nfunc _draw() -> void:')
s=s[:a]+'''
func _option_rect(index: int) -> Rect2:
	var half := Vector2(44,42) if mode in [1,3] else Vector2(76,60)
	return Rect2(option_position(index)-half,half*2)


func _draw() -> void:
	if font==null or profile.is_empty(): return
	Art.render(self)
'''
p.write_text(s,encoding='utf-8')
