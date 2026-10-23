extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	var world: Node3D=load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	for frame in range(8): await process_frame
	var bus: int=AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus,"OriginalOpeningProbe")
	var recorder:=AudioEffectCapture.new()
	recorder.buffer_length=1
	AudioServer.add_bus_effect(bus,recorder)
	for voice in world.sfx.players: voice.bus="OriginalOpeningProbe"
	world.get_node("PartyUI")._begin_draw()
	var sum: float=0
	var peak: float=0
	var count: int=0
	for step in range(130):
		await process_frame
		OS.delay_msec(20)
		if step==85: world.get_node("PartyUI").opening_draw.reveal_now()
		for sample in recorder.get_buffer(recorder.get_frames_available()):
			sum+=sample.length_squared()
			peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
			count+=2
	var rms: float=linear_to_db(sqrt(sum/maxi(count,1)))
	var flips: int=world.sfx.events.count("opening_card_flip")
	var picks: int=world.sfx.events.count("opening_card_pick")
	var original: bool=world.sfx.SOUNDS.opening_card_flip.resource_path=="res://assets/audio/interactions/card_flip.wav" and world.sfx.SOUNDS.opening_card_pick.resource_path=="res://assets/audio/interactions/card_pick.wav"
	var report: Dictionary={"samples":count,"rms_dbfs":rms,"peak_dbfs":linear_to_db(peak),"flip_events":flips,"pick_events":picks,"original_assets":original,"continuous_rotation_playing":world.sfx.draw_spin.playing}
	var file:=FileAccess.open("res://previews/original-opening-audio.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	var bad: bool=count<20000 or rms< -48 or peak>=1 or flips<3 or picks<1 or not original or world.sfx.draw_spin.playing
	world.get_node("PartyUI")._cancel_draw()
	for node in world.find_children("*","AudioStreamPlayer",true,false): node.stop()
	world.queue_free()
	await process_frame
	await process_frame
	AudioServer.remove_bus(bus)
	if bad: push_error("Original opening sounds failed output / asset / playback verification"); quit(1); return
	print("ORIGINAL_OPENING_AUDIO_OK")
	quit(0)
