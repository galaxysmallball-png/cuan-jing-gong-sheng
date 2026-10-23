extends SceneTree

func _initialize() -> void:
	var folder: String=OS.get_cmdline_user_args()[0]
	var original:=Image.load_from_file(folder.path_join("../手机图标.png").simplify_path())
	var mono: Texture2D=load("res://assets/interface/user_launcher_monochrome_20261021.png")
	var records: Array=[]
	for variant in ["icon","icon_foreground","icon_background","icon_monochrome"]:
		var actual:=Image.load_from_file(folder.path_join("launcher-"+variant+".webp"))
		var expected: Image=mono.get_image() if variant=="icon_monochrome" else original.duplicate()
		expected.resize(actual.get_width(),actual.get_height(),Image.INTERPOLATE_LANCZOS)
		actual.convert(Image.FORMAT_RGBA8)
		expected.convert(Image.FORMAT_RGBA8)
		var a: PackedByteArray=actual.get_data()
		var b: PackedByteArray=expected.get_data()
		var difference: float=0
		for index in range(a.size()): difference+=absf(float(a[index])-float(b[index]))
		difference/=float(a.size())*255.0
		if difference>.035: push_error("Packaged launcher differs from supplied artwork: "+variant+" "+str(difference)); quit(1); return
		records.append({"variant":variant,"size":actual.get_width(),"mean_channel_difference":difference})
		if variant=="icon": actual.save_png(folder.path_join("launcher-preview.png"))
	var proof:=FileAccess.open(folder.path_join("launcher-pixel-check.json"),FileAccess.WRITE)
	proof.store_string(JSON.stringify(records,"  "))
	print("PACKAGED_USER_LAUNCHER_ALL_VARIANTS_OK: ",JSON.stringify(records))
	quit(0)
