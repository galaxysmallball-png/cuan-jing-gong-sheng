extends RefCounted

# Build local runtime variants from the shipped rig. Original GLBs and their
# six authored actions remain untouched; every new track retains its bone path.
static func build(skeleton: Skeleton3D, player: AnimationPlayer, clips: Dictionary) -> Dictionary:
	if skeleton.find_bone("thigh.L")<0: return {}
	var library:=AnimationLibrary.new()
	var result: Dictionary={}
	for kind in ["carry_plant","carry_lift","work_wood","work_stone","work_rope","work_place","jump_fall"]:
		var base: Animation=player.get_animation(clips["jump" if kind=="jump_fall" else "carry"])
		var idle: Animation=player.get_animation(clips.idle)
		var clip:=Animation.new()
		clip.length=1.2 if kind.begins_with("work") else .6
		clip.loop_mode=Animation.LOOP_NONE if kind=="jump_fall" else Animation.LOOP_LINEAR
		for track in range(base.get_track_count()):
			var path: NodePath=base.track_get_path(track)
			var bone: String=path.get_subname(path.get_subname_count()-1)
			var type: int=base.track_get_type(track)
			if type not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]: continue
			var target: int=clip.add_track(type)
			clip.track_set_path(target,path)
			var planted: bool=bone.begins_with("thigh.") or bone.begins_with("shin.") or bone.begins_with("foot.") or bone in ["hips","root"]
			var idle_track: int=idle.find_track(path,type)
			for key in range(13):
				var t: float=key/12.0
				var source: Animation=idle if planted and idle_track>=0 else base
				var index: int=idle_track if source==idle else track
				var time: float=0 if planted else t*source.length
				if type==Animation.TYPE_ROTATION_3D:
					var q: Quaternion=source.rotation_track_interpolate(index,time)
					var pitch: float=0
					if kind=="carry_lift":
						if bone.begins_with("thigh."): pitch=-.26
						elif bone.begins_with("shin."): pitch=.52
						elif bone=="spine": pitch=.08
					elif kind=="jump_fall" and planted:
						q=base.rotation_track_interpolate(track,base.length*.5).slerp(q,.60)
					elif kind.begins_with("work"):
						var pulse: float=sin(t*TAU)
						if bone=="spine": pitch=.04+cos(t*TAU)*.018
						if kind=="work_wood" and bone=="forearm.R": pitch=pulse*.24
						elif kind=="work_rope" and bone.begins_with("upper_arm."): pitch=pulse*.17
						elif kind=="work_stone" and bone.begins_with("upper_arm."): pitch=.08+pulse*.065
						elif kind=="work_place" and bone=="forearm.R": pitch=pulse*.11
					var bone_index: int=skeleton.find_bone(bone)
					if bone_index>=0 and pitch!=0:
						var axis: Vector3=skeleton.get_bone_global_rest(bone_index).basis.inverse()*Vector3.RIGHT
						q=Quaternion(axis.normalized(),pitch)*q
					clip.rotation_track_insert_key(target,t*clip.length,q)
				elif type==Animation.TYPE_POSITION_3D:
					var p: Vector3=source.position_track_interpolate(index,time)
					if kind=="carry_lift" and bone=="hips": p.y-=.065
					clip.position_track_insert_key(target,t*clip.length,p)
				else:
					clip.scale_track_insert_key(target,t*clip.length,source.scale_track_interpolate(index,time))
		library.add_animation(kind,clip)
		result[kind]="motion/"+kind
	player.add_animation_library("motion",library)
	return result
