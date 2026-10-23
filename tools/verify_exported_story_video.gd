extends SceneTree

var world: Node3D
var viewport: SubViewport
var output: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()!=1: push_error("Missing exported-video preview directory"); quit(1); return
	output=args[0]
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",output.path_join("exported-film-profile.json"))
	root.mode=Window.MODE_MINIMIZED
	viewport=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world=load("res://scenes/world.tscn").instantiate()
	viewport.add_child(world)
	for frame in range(10): await process_frame
	var ui: CanvasLayer=world.get_node("PartyUI")
	ui._begin_film()
	if not await _check_movie("opening"): return
	ui.opening_draw.reveal_now()
	ui._finish_draw()
	if not await _check_movie("chapter-1"): return
	world.chapter_films.played.fill(true)
	for index in range(1,4):
		ui.play_story_film(world.chapter_films.PATHS[index],1.75)
		if not await _check_movie("chapter-"+str(index+1)): return
	for node in world.find_children("*","AudioStreamPlayer",true,false): node.stop()
	world.queue_free()
	await process_frame
	await process_frame
	print("EXPORTED_STORY_VIDEO_OK: five actual shipped video streams decoded and rendered, nonblank frames, film pauses 3D, skip restores renderer")
	quit(0)

func _check_movie(title: String) -> bool:
	var ui: CanvasLayer=world.get_node("PartyUI")
	if ui.screen!=ui.Screen.FILM or not viewport.disable_3d:
		push_error("Exported video does not start / suspend hidden 3D: "+title); quit(1); return false
	for frame in range(120):
		await process_frame
		OS.delay_msec(10)
	var texture: Texture2D=ui.opening_film.player.get_video_texture()
	if texture==null or texture.get_width()<1200:
		push_error("Exported video stream is not decoding: "+title); quit(1); return false
	RenderingServer.force_draw(false)
	var pixels: Image=viewport.get_texture().get_image()
	var light: float=0
	for y in range(100,600,100):
		for x in range(100,1200,100): light+=pixels.get_pixel(x,y).get_luminance()
	if light<1:
		push_error("Exported film is blank: "+title); quit(1); return false
	pixels.save_png(output.path_join("exported-film-"+title+".png"))
	ui.opening_film.finish()
	for frame in range(3): await process_frame
	if viewport.disable_3d:
		push_error("Exported film leaves 3D renderer disabled"); quit(1); return false
	print("EXPORTED_FILM_FRAME_OK ",title)
	return true
