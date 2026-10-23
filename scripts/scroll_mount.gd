extends Control

# Drawn mount and cylindrical wooden rollers; the four supplied paintings remain
# separate, unmodified textures behind this foreground decoration.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(59, 20, 1162, 660), Color(0.025, 0.025, 0.02, 0.5), false, 12)
	draw_rect(Rect2(59, 20, 1162, 660), Color(0.76, 0.60, 0.33), false, 4)
	draw_rect(Rect2(64, 25, 1152, 650), Color(0.94, 0.81, 0.50), false, 1)
	for x in [48.0, 1232.0]:
		_roller(x)
	for x in [80.0, 1200.0]:
		for y in [39.0, 661.0]:
			var sx: float = 1 if x < 640 else -1
			var sy: float = 1 if y < 360 else -1
			draw_polyline(PackedVector2Array([Vector2(x, y + sy * 22), Vector2(x, y), Vector2(x + sx * 30, y)]), Color(0.94, 0.77, 0.43), 2)
			draw_circle(Vector2(x + sx * 8, y + sy * 8), 2, Color(0.94, 0.77, 0.43))


func _roller(center: float) -> void:
	for band in range(32):
		var t: float = float(band) / 31
		var light: float = pow(maxf(0, sin(t * PI)), 0.7)
		var color: Color = Color(0.13, 0.075, 0.035).lerp(Color(0.57, 0.36, 0.16), light)
		draw_rect(Rect2(center - 16 + band, 16, 1.3, 670), color)
	for offset in [-10.0, -5.0, 4.0, 10.0]:
		draw_line(Vector2(center + offset, 46), Vector2(center + offset + 0.8, 655), Color(0.76, 0.53, 0.25, 0.20), 1)
	for y in [28.0, 674.0]:
		draw_circle(Vector2(center, y), 19, Color(0.24, 0.14, 0.07))
		draw_circle(Vector2(center, y), 15, Color(0.65, 0.44, 0.19))
		draw_circle(Vector2(center, y), 10, Color(0.33, 0.20, 0.08))
		draw_arc(Vector2(center - 1, y - 1), 12, PI, TAU, 18, Color(0.91, 0.70, 0.33), 1.5)
	for y in [52.0, 650.0]:
		draw_rect(Rect2(center - 17, y, 34, 7), Color(0.64, 0.44, 0.20))
		draw_line(Vector2(center - 17, y), Vector2(center + 17, y), Color(0.95, 0.77, 0.43), 1)
