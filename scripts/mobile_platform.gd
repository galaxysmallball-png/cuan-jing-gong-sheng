extends RefCounted

static var cooperative: bool=false

static func active() -> bool:
	return OS.has_feature("android") or "--touch-preview" in OS.get_cmdline_user_args()
