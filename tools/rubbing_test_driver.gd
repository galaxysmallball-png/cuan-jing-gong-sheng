extends RefCounted


static func key(tree: SceneTree, code: int, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	# The minimized GPU harness renders inside its own SubViewport. Parsing
	# updates polled physical actions; forward the same event to that UI once.
	for child in tree.root.get_children():
		if child is SubViewport:
			child.push_input(event.duplicate(),true)
			break
	for frame in range(2): await tree.physics_frame


static func tap(tree: SceneTree, code: int) -> void:
	await key(tree,code,true)
	await key(tree,code,false)


static func complete(tree: SceneTree, board: Control, stop_phase: int=4, capture_phase: Callable=Callable()) -> bool:
	if board.completed: return true
	var coop: bool=board.chapter.party.local_coop
	if board.phase==0:
		for slot in range(2):
			if board.fixed[slot]: continue
			var motion: int=(KEY_D if board.offsets[slot]<0 else KEY_A) if slot==0 or not coop else (KEY_RIGHT if board.offsets[slot]<0 else KEY_LEFT)
			await key(tree,motion,true)
			for frame in range(85):
				if absf(board.offsets[slot])<2.6: break
				await tree.physics_frame
			await key(tree,motion,false)
			await tap(tree,KEY_E if slot==0 or not coop else KEY_P)
		if board.phase!=1: return false
		if capture_phase.is_valid(): capture_phase.call(1)
	if stop_phase==1: return true
	if board.phase==1:
		for slot in range(2):
			if not coop: await tap(tree,KEY_A if slot==0 else KEY_D)
			for row in range(3):
				while board.cursors[slot]!=row:
					await tap(tree,KEY_S if slot==0 or not coop else KEY_DOWN)
				for dab in range(2-board.ink[row*2+slot]):
					var safe: bool=false
					for frame in range(180):
						if board.pressure(slot)>.39 and board.pressure(slot)<.61 and board.cooldown[slot]<=0:
							safe=true
							break
						await tree.physics_frame
					if not safe: return false
					await tap(tree,KEY_E if slot==0 or not coop else KEY_P)
		if board.phase!=2: return false
		if capture_phase.is_valid(): capture_phase.call(2)
	if stop_phase==2: return true
	if board.phase==2:
		await key(tree,KEY_E,true)
		if coop: await key(tree,KEY_P,true)
		for frame in range(65): await tree.physics_frame
		await key(tree,KEY_E,false)
		if coop: await key(tree,KEY_P,false)
		if board.phase!=3: return false
		if capture_phase.is_valid(): capture_phase.call(3)
	if stop_phase==3: return true
	await tap(tree,KEY_ENTER)
	return board.completed
