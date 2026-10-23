from pathlib import Path
p=Path('数媒/cuan-game/scripts/lantern_garden.gd');s=p.read_text(encoding='utf-8')
s=s.replace('var tablet_arriving: bool = false','''var tablet_arriving: bool = false
var tablet_raising: bool = false
var raise_progress: float = 0
var raise_rig: Node3D
const RAISE_SECONDS: float = 2.8''',1)
s=s.replace('Vector3(PLACEMENT_X,.70,-1.8)','Vector3(PLACEMENT_X,1.0,-1.8)').replace('Vector3(PLACEMENT_X, 0.70, -1.8)','Vector3(PLACEMENT_X, 1.0, -1.8)').replace('arrival_from.y=.85','arrival_from.y=1.0')
s=s.replace('\t_arrival_sled.visible=bridge.tablet_delivered and not tablet_placed\n\t_arrival_sled.position=Vector3(_tablet.position.x,.11,_tablet.position.z)','''	if not tablet_raising:
		_arrival_sled.visible=bridge.tablet_delivered and not tablet_placed
		_arrival_sled.position=Vector3(_tablet.position.x,.11,_tablet.position.z)''')
s=s.replace('\tif not tablet_placed:\n\t\tif not tablet_arriving', '\tif tablet_raising: return\n\tif not tablet_placed:\n\t\tif not tablet_arriving',1)
a=s.index('func _raise_tablet() -> void:');b=s.index('\n\nfunc personal_items_done()',a)
s=s[:a]+'''func _raise_tablet() -> void:
	if tablet_raising or tablet_placed: return
	tablet_arriving=false
	tablet_raising=true
	raise_progress=0
	action_progress=0
	raise_rig=preload("res://scripts/stele_raise_rig.gd").new()
	add_child(raise_rig)
	raise_rig.setup(self)
	party.set_interaction_lock(true)
	get_node("../../..").sfx.play("wood")
	landscape.say("石阿朵","先垫稳碑脚，绳子慢慢收。大家顺着我的号子，一点点扶起来。",5)
	_raise_tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_raise_tween.tween_method(_apply_raise,0.0,1.0,RAISE_SECONDS)
	_raise_tween.tween_callback(_finish_raising)
	landscape.sync_state()


func _apply_raise(progress: float) -> void:
	raise_progress=progress
	if is_instance_valid(raise_rig): raise_rig.apply_pose(progress)


func _finish_raising() -> void:
	tablet_raising=false
	tablet_placed=true
	raise_progress=1
	_arrival_sled.visible=false
	party.set_interaction_lock(false)
	if is_instance_valid(raise_rig): raise_rig.dismantle()
	get_node("../../..").sfx.play("stone")
	landscape.say("杨三娘","碑脚落座了，稳稳当当。各人带来的物件，也有了共同的归处。",5)
	landscape.sync_state()
'''+s[b:]
s=s.replace('if tablet_arriving: return "溪桥送来的碑正在入院', 'if tablet_raising: return "绳索收紧，众人正将碑缓缓立起 %d%%。\\n等碑脚落座，再安放随身物件。"%int(raise_progress*100)\n\tif tablet_arriving: return "溪桥送来的碑正在入院')
s=s.replace('if tablet_arriving: return _task("随碑入院', 'if tablet_raising: return _task("合力立碑 %d%% · 等碑脚落座"%int(raise_progress*100),raise_progress*lighting_hold_seconds)\n\tif tablet_arriving: return _task("随碑入院')
s=s.replace('\tclose_record()\n\ttablet_placed = false','''	close_record()
	if tablet_raising: party.set_interaction_lock(false)
	if is_instance_valid(raise_rig): raise_rig.free()
	tablet_raising=false
	raise_progress=0
	tablet_placed = false''')
p.write_text(s,encoding='utf-8')
p=Path('数媒/cuan-game/scripts/garden_art.gd');s=p.read_text(encoding='utf-8').replace('and not chapter.tablet_arriving and not chapter.tablet_placed','and not chapter.tablet_arriving and not chapter.tablet_raising and not chapter.tablet_placed');p.write_text(s,encoding='utf-8')
p=Path('数媒/cuan-game/scripts/world.gd');s=p.read_text(encoding='utf-8').replace('if courtyard.tablet_arriving:\n\t\t\ttext', 'if courtyard.tablet_raising:\n\t\t\ttext="众人正在收绳扶碑。\\n等碑脚稳稳落座，再安放各自的物件。"\n\t\t\tprogress="立碑 %d%%"%int(courtyard.raise_progress*100)\n\t\telif courtyard.tablet_arriving:\n\t\t\ttext',1)
s=s.replace('\tif courtyard.tablet_arriving:\n\t\tvar arrival_ratio', '\tif courtyard.tablet_raising:\n\t\tlabels.append("合力立碑 %d%%"%int(courtyard.raise_progress*100))\n\t\tratio=maxf(ratio,courtyard.raise_progress)\n\tif courtyard.tablet_arriving:\n\t\tvar arrival_ratio',1)
p.write_text(s,encoding='utf-8')
print('SUPPORTED_STELE_RAISE_INTEGRATED')
