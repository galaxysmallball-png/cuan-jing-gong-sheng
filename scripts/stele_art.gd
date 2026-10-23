extends RefCounted

# These are typeset educational illustrations, not scans or reconstructions.
const TEXTS: Array[String] = ["晋故振威建宁", "宋故龙骧将军"]
const NAMES: Array[String] = ["爨宝子碑", "爨龙颜碑"]


static func create_viewport(parent: Node, font: FontFile, id: int) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "SteleImage%d" % id
	viewport.size = Vector2i(512, 896)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	var paper := ColorRect.new()
	paper.size = Vector2(512, 896)
	paper.color = Color(0.18, 0.23, 0.24)
	viewport.add_child(paper)
	if id == 0:
		var rubbing := TextureRect.new()
		rubbing.name = "SuppliedHistoricalRubbing"
		rubbing.texture = preload("res://assets/historical_steles/small_stele_rubbing.jpg")
		rubbing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rubbing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rubbing.position = Vector2(8, 8)
		rubbing.size = Vector2(496, 880)
		viewport.add_child(rubbing)
		return viewport
	for index in range(14):
		var grain := ColorRect.new()
		grain.position = Vector2(30 + (index * 73) % 430, 40 + (index * 127) % 810)
		grain.size = Vector2(1 + index % 3, 13 + index * 3)
		grain.color = Color(0.22, 0.27, 0.27, 0.45)
		viewport.add_child(grain)
	for side in [0, 1]:
		var edge := ColorRect.new()
		edge.position = Vector2(24 + side * 462, 28)
		edge.size = Vector2(2, 840)
		edge.color = Color(0.45, 0.47, 0.42)
		viewport.add_child(edge)
	for index in range(6):
		var glyph := Label.new()
		glyph.position = Vector2(282 - floori(index / 3.0) * 184, 115 + (index % 3) * 218)
		glyph.size = Vector2(140, 185)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_override("font", font)
		glyph.add_theme_font_size_override("font_size", preload("res://scripts/interface_skin.gd").text_size(170))
		glyph.add_theme_color_override("font_color", Color(0.83, 0.81, 0.66))
		glyph.text = TEXTS[id].substr(index, 1)
		viewport.add_child(glyph)
	return viewport
