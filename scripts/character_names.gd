extends RefCounted

# Source: references/爨境共生_人物服饰设定_民族标注依据.docx,
# character headings and the four-character comparison table.
const DISPLAY_NAMES: Array[String] = [
	"邓书年（汉族）",
	"石阿朵（白族）",
	"老箐（彝族）",
	"杨三娘（回族）"
]

# Supporting villagers are not selectable party members.
const VILLAGER_NAMES: Array[String] = [
	"阿彩（苗族）", "阿强（壮族）", "普嫫（彝族）", "玉喃（傣族）"
]


static func annotate(text: String) -> String:
	for display_name in DISPLAY_NAMES + VILLAGER_NAMES:
		var bare_name: String = display_name.get_slice("（", 0)
		# Already formatted names may arrive through Party.NAMES.
		text = text.replace(display_name, bare_name).replace(bare_name, display_name)
	return text
