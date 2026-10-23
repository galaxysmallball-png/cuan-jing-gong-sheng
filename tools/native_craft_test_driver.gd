extends RefCounted


static func frames(tree: SceneTree, count: int) -> void:
	for i in range(count): await tree.physics_frame
	await tree.process_frame


static func event(board: Control, at: Vector2, down: bool) -> void:
	var e:=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.pressed=down
	e.position=board.get_global_transform_with_canvas()*at
	e.global_position=e.position
	board.get_viewport().push_input(e,true)


static func click(tree: SceneTree, board: Control, at: Vector2, held: int=1) -> void:
	event(board,at,true)
	await frames(tree,held)
	event(board,at,false)
	await frames(tree,2)


static func drag_path(tree: SceneTree, board: Control, path: Array[Vector2]) -> void:
	event(board,path[0],true)
	await frames(tree,2)
	for i in range(1,path.size()):
		for step in range(1,9):
			var e:=InputEventMouseMotion.new()
			e.position=board.get_global_transform_with_canvas()*path[i-1].lerp(path[i],step/8.0)
			e.global_position=e.position
			e.button_mask=MOUSE_BUTTON_MASK_LEFT
			board.get_viewport().push_input(e,true)
			await frames(tree,1)
	event(board,path[-1],false)
	await frames(tree,2)


static func complete(tree: SceneTree, board: Control) -> bool:
	if board.mode<4:
		if board.mode==1:
			for mask in range(1<<board.weights.size()):
				var amount: int=0
				for i in range(board.weights.size()):
					if mask&(1<<i): amount+=board.weights[i]
				if amount*2!=board.total_weight(): continue
				for i in range(board.weights.size()):
					if mask&(1<<i): await click(tree,board,board.option_position(i))
				break
		else:
			if board.mode==2: await frames(tree,ceili((board.recipe.size()+1)*.48*60)+20)
			for choice in board.recipe: await click(tree,board,board.option_position(choice))
		return board.won
	var game: RefCounted=board.native
	match board.mode:
		4:
			for point in game.KNOTS: await click(tree,board,point)
			await click(tree,board,Vector2(440,120),70)
			for point in game.KNOTS: await click(tree,board,point)
		5:
			await drag_path(tree,board,game.WAX)
			await click(tree,board,Vector2(440,120),70)
			await click(tree,board,Vector2(170,125))
		6:
			for cell in game.FURROWS:
				var count: int=(4-game.turns[cell])%4
				for i in range(count): await click(tree,board,game.cell_point(cell))
		7:
			for row in range(game.target_rows.size()):
				await click(tree,board,Vector2(420+game.target_rows[row]*60,91))
				var start: Vector2=game.shuttle_start()
				await drag_path(tree,board,[start,Vector2(338 if row%2==0 else 50,start.y)])
		8:
			for side in range(2):
				var start:=Vector2(60+side*230+130*game.tension[side],188)
				await drag_path(tree,board,[start,Vector2(60+side*230+130*.55,188)])
			await click(tree,board,Vector2(470,135),82)
		9:
			for i in range(3): await click(tree,board,Vector2(130,195))
			await drag_path(tree,board,[Vector2(115,130),Vector2(330,127)])
			await click(tree,board,Vector2(471,140),55)
		10:
			await click(tree,board,Vector2(85,130),60)
			for i in range(3): await click(tree,board,Vector2(225+i*110,140),roundi(game.target_fills[i]/.52*60))
		11:
			await drag_path(tree,board,game.rope_path())
			await drag_path(tree,board,game.rope_path())
			await click(tree,board,Vector2(471,140),50)
		12:
			for step in range(1500):
				if game.phase>0: break
				var x: float=154+92*sin(game.spark_clock*2.7)
				if x>146 and x<169: await click(tree,board,Vector2(190,130))
				else: await frames(tree,1)
			for step in range(700):
				if game.phase>1: break
				if game.ember<.51 and not game.hold: event(board,Vector2(450,140),true)
				elif game.ember>.63 and game.hold: event(board,Vector2(450,140),false)
				await frames(tree,1)
			event(board,Vector2(450,140),false)
			for i in range(3): await click(tree,board,Vector2(135+i*140,133))
	await frames(tree,3)
	return board.won
