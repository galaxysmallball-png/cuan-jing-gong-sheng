extends Control

var counts: Array[int] = [0,0,0,0,0,0,0]
var totals: Array[int] = [1,2,5,2,4,2,3]
var groups: Array[String] = ["汉族","白族","彝族","回族","苗族","壮族","傣族"]
var font: Font


func _draw() -> void:
	if font==null: return
	var center := size*.5
	var points: Array[Vector2] = []
	for index in range(7):
		var angle: float = -PI/2+TAU*index/7
		points.append(center+Vector2(cos(angle)*123,sin(angle)*86))
	for index in range(7):
		var active: bool = counts[index]>0
		var ink := Color(.57,.38,.16) if active else Color(.62,.61,.53,.5)
		draw_line(center,points[index],ink,2 if active else 1,true)
		if active and counts[(index+1)%7]>0: draw_line(points[index],points[(index+1)%7],Color(.65,.34,.19,.6),2,true)
	for index in range(7):
		var point: Vector2 = points[index]
		var active: bool = counts[index]>0
		draw_circle(point,21,Color(.26,.35,.32) if active else Color(.73,.71,.62))
		draw_arc(point,23,0,TAU,36,Color(.64,.46,.23),1.2,true)
		draw_string(font,point+Vector2(-16,6),groups[index],HORIZONTAL_ALIGNMENT_LEFT,-1,preload("res://scripts/interface_skin.gd").text_size(14),Color(.98,.92,.76) if active else Color(.35,.36,.32))
		draw_string(font,point+Vector2(-10,38),"%d/%d"%[counts[index],totals[index]],HORIZONTAL_ALIGNMENT_LEFT,-1,preload("res://scripts/interface_skin.gd").text_size(11),Color(.32,.32,.26))
	draw_circle(center,29,Color(.54,.27,.17))
	draw_arc(center,33,0,TAU,48,Color(.66,.48,.23),1.5,true)
	draw_string(font,center+Vector2(-21,7),"共生",HORIZONTAL_ALIGNMENT_LEFT,-1,preload("res://scripts/interface_skin.gd").text_size(18),Color(1,.9,.65))
