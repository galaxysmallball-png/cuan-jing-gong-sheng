from pathlib import Path
root=Path('数媒/cuan-game/scripts')
p=root/'creek_art.gd';s=p.read_text(encoding='utf-8')
s=s.replace('\t\t\t_rock(self, Vector3(x, -1.4, 2.2), Vector3(1.9, rng.randf_range(2.9, 3.5), 1.5), stone)\n','')
s=s.replace('\tfor x in [11.2, 18.6]:\n\t\t_rock(self, Vector3(x, -1.7, -0.15), Vector3(1.6, 3.6, 4.7), stone)','''	for section in [[-.5,12.0,1],[18.0,21.0,-1]]:
		var bank := preload("res://scripts/layered_bank.gd").new()
		add_child(bank)
		bank.setup(section[0],section[1],-.10,-3.85,2.66,Color(.26,.32,.33),section[2])''')
p.write_text(s,encoding='utf-8')
p=root/'courtyard_art.gd';s=p.read_text(encoding='utf-8')
needle='\t_box(self, Vector3(10, -1.13, 3.4), Vector3(21.2, 0.8, 2.0), _surface(Color(0.10, 0.15, 0.12), 0))'
s=s.replace(needle,needle+'''
	var bank := preload("res://scripts/layered_bank.gd").new()
	add_child(bank)
	bank.setup(-.5,20.5,-.76,-3.65,4.46,Color(.24,.30,.29))''')
p.write_text(s,encoding='utf-8')
p=root/'garden_art.gd';s=p.read_text(encoding='utf-8')
s=s.replace('var placement_marker: MeshInstance3D','var stele_plinth: MeshInstance3D\nvar placement_marker: MeshInstance3D')
s=s.replace('func _build_ground() -> void:\n','''func _build_ground() -> void:
	var bank := preload("res://scripts/layered_bank.gd").new()
	add_child(bank)
	bank.setup(-.25,20.3,-.73,-3.65,3.69,Color(.27,.31,.27))
''')
a=s.index('\t# Hundreds of ridge tiles',s.index('func _tiled_roof'))
b=s.index('\n\nfunc _build_architecture()',a)
s=s[:a]+'''	var tiled := preload("res://scripts/curved_tile_roof.gd").new()
	add_child(tiled)
	tiled.position=Vector3(center,y,z)
	tiled.setup(width,depth)
'''+s[b:]
s=s.replace('\t_box(self, Vector3(SHRINE_AXIS_X, 0.42, -2.35), Vector3(1.75, 0.46, 0.95), stone)','''	stele_plinth=_box(self, Vector3(SHRINE_AXIS_X, 0.42, -2.35), Vector3(1.75, 0.46, 0.95), stone)
	stele_plinth.name="SteleSocketPlinth"''')
s=s.replace('Vector3(x, 2.94, -2.1)','Vector3(x, 3.45, -2.1)').replace('0.95, 2.94, -2.1)','0.95, 3.45, -2.1)')
p.write_text(s,encoding='utf-8')
p=root/'grand_court.gd';s=p.read_text(encoding='utf-8')
a=s.index('func _roof(');b=s.index('\n\nfunc _build_celebration',a)
s=s[:a]+'''func _roof(at: Vector3, width: float, depth: float, _roof: Material, _gold: Material) -> void:
	var tiled := preload("res://scripts/curved_tile_roof.gd").new()
	add_child(tiled)
	tiled.position=at
	tiled.setup(width,depth,Color(.16,.24,.26))
'''+s[b:]
p.write_text(s,encoding='utf-8')
p=root/'scene_atmosphere.gd';s=p.read_text(encoding='utf-8')
for call in ['_roof_detail(parent,10,7,4.65,-2.65,3.1)','_roof_detail(parent,10,13.6,6.72,-6,2.7)','_roof_detail(parent,17.2,5,3.77,-3,2.4)','_roof_detail(parent,5.7,2.8,3.67,-3.1,2.2)']:
    s=s.replace('\t'+call+'\n','')
p.write_text(s,encoding='utf-8')
p=Path('数媒/cuan-game/shaders/layered_bank.gdshader');s=p.read_text(encoding='utf-8').replace('shader_type spatial;','shader_type spatial;\nrender_mode cull_disabled;');p.write_text(s,encoding='utf-8')
p=root/'layered_bank.gd';s=p.read_text(encoding='utf-8').replace('\t# End faces have their own orientation; draw both sides of this thin rock skin.\n\tbedrock.set_shader_parameter("base_color",bedrock.get_shader_parameter("base_color"))\n','');p.write_text(s,encoding='utf-8')
print('ROCK_AND_ROOF_INTEGRATED')
