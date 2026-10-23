extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	var world: Node3D=load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	for frame in range(10): await process_frame
	var bus: int=AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus,"DrawMixProbe")
	var recorder:=AudioEffectCapture.new()
	recorder.buffer_length=1.0
	AudioServer.add_bus_effect(bus,recorder)
	world.sfx.draw_spin.bus="DrawMixProbe"
	world.get_node("PartyUI")._begin_draw()
	var sum: float=0
	var peak: float=0
	var count: int=0
	for step in range(45):
		await process_frame
		OS.delay_msec(20)
		var audio: PackedVector2Array=recorder.get_buffer(recorder.get_frames_available())
		for sample in audio:
			sum+=sample.length_squared()
			peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
			count+=2
	var rms: float=linear_to_db(sqrt(sum/maxi(count,1)))
	var stream: AudioStreamWAV=world.sfx.draw_spin.stream
	var report: Dictionary={"samples":count,"rms_dbfs":rms,"peak_dbfs":linear_to_db(peak),"format":stream.format,"bytes":stream.data.size(),"seconds":stream.get_length(),"loop_frames":stream.loop_end,"expected_loop_frames":roundi(stream.get_length()*stream.mix_rate),"volume_db":world.sfx.draw_spin.volume_db,"paused_scene":paused,"stream_paused":world.sfx.draw_spin.stream_paused}
	var before: bool="--before" in OS.get_cmdline_user_args()
	var out:=FileAccess.open("res://previews/draw-mix-"+("before" if before else "after")+".json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	out.close()
	print(JSON.stringify(report))
	world.get_node("PartyUI")._cancel_draw()
	var bad: bool=not before and (count<2000 or rms < -32 or peak>.95 or stream.loop_end!=roundi(stream.get_length()*stream.mix_rate))
	for node in world.find_children("*","AudioStreamPlayer",true,false): node.stop()
	world.queue_free()
	await process_frame
	await process_frame
	AudioServer.remove_bus(bus)
	if bad: push_error("Rotation has no sufficiently audible mixed PCM output / full loop"); quit(1); return
	print("DRAW_AUDIO_MIX_OK "+("before" if before else "after"))
	quit(0)
