extends Control

const Art = preload("res://scripts/folk_activity_art.gd")
var kind: int = -1
var chapter: Node3D


func _draw() -> void:
	if kind>=0:
		Art.panel(self,Rect2(2,0,140,77),Art.RED if kind==0 else Art.INDIGO)
		Art.motif(self,Vector2(72,38),kind,Art.CREAM)
	else:
		draw_rect(Rect2(0,0,size.x,size.y),Color(.21,.26,.24))
		draw_rect(Rect2(size.x*.35,0,size.x*.37,size.y),Color(.37,.61,.40))
		var x: float = clampf(chapter.rope_tension,0,1)*(size.x-8)
		draw_rect(Rect2(x,0,8,size.y),Color(1,.80,.40))
