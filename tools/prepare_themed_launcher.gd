extends SceneTree

func _initialize() -> void:
	# Android's themed launcher consumes an alpha mask. Derive it from the
	# supplied ink image; the full-colour source stays byte-for-byte intact.
	var texture: Texture2D=load("res://assets/interface/user_launcher_20261021.png")
	var image: Image=texture.get_image() if texture!=null else null
	if image==null: push_error("Missing supplied launcher image"); quit(1); return
	image.resize(432,432,Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGBA8)
	for y in range(432):
		for x in range(432):
			var color: Color=image.get_pixel(x,y)
			var luminance: float=color.r*.2126+color.g*.7152+color.b*.0722
			image.set_pixel(x,y,Color(1,1,1,1-smoothstep(.28,.75,luminance)))
	var result: Error=image.save_png("res://assets/interface/user_launcher_monochrome_20261021.png")
	if result!=OK: push_error("Cannot save Android themed icon"); quit(1); return
	print("USER_THEMED_LAUNCHER_MASK_PREPARED")
	quit(0)
