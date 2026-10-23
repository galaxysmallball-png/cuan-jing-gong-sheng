extends Control

const UiSkin = preload("res://scripts/interface_skin.gd")
const FACTS: Array[Dictionary] = [
	{"title":"小爨 · 爨宝子碑", "body":"立于东晋公元405年，记述爨宝子的生平。清乾隆四十三年（1778）在曲靖城南出土。\n\n书写介于隶、楷之间，方笔凝重、古拙有趣。读碑，也能认识当时的人物与地方生活。", "source":"资料：曲靖市政府《爨文化博物馆》；故宫《晋爨宝子碑墨拓本》", "url":"https://ynnmuseum.com/detail/4128.html"},
	{"title":"大爨 · 爨龙颜碑", "body":"立于南朝刘宋大明二年（458），位于云南陆良。碑文追述爨氏家族渊源与爨龙颜的生平事迹。\n\n书体以楷书为主，保留隶意。因碑体较大，俗称“大爨”，与小爨合称“二爨”。两碑相隔53年。", "source":"资料：故宫博物院《爨龙颜碑》；云南民族博物馆《爨龙颜碑拓片》", "url":"https://www.dpm.org.cn/lemmas/241206.html"}
]
const QUESTIONS: Array[Dictionary] = [
	{"prompt":"先后有序 · 哪一组年代对应正确？", "choices":["小爨 458 年 → 大爨 405 年","小爨 405 年 → 大爨 458 年","两碑都立于 405 年"], "answer":1, "why":"小爨405年，大爨458年，两碑相隔53年。"},
	{"prompt":"各有来处 · 大爨是哪位人物的碑？", "choices":["爨龙颜 · 云南陆良","爨宝子 · 曲靖城南","邓书年 · 游戏中的护碑人"], "answer":0, "why":"大爨是爨龙颜碑；邓书年是本作原创角色。"},
	{"prompt":"合看二爨 · 怎样理解两碑的联系？", "choices":["只是大小不同，内容和书体完全相同","属于同一位人物，文字也一模一样","共同的汉字传统，留下不同人物与地方记忆"], "answer":2, "why":"二爨既有共同文字传统，也有各自的时代、人物和书写面貌。"}
]
const NOTE: String = "小爨《爨宝子碑》：405年，隶楷之间；1778年在曲靖城南出土。\n大爨《爨龙颜碑》：458年，云南陆良；楷书为主而有隶意。两碑相隔53年。\n\n共同的汉字传统，记录不同人物与地方历史。古代爨氏不能直接等同于某一个现代民族。\n\n合读所得：核定大小爨碑的年代、碑主与书体，取得第一关必需的大爨对照印记；配合小爨传拓六字才能开门，并解锁共庭长卷的「二爨一脉 · 405—458」纪年题签。"
var chapter: Node3D
var tabs: Array[Button] = []
var title: Label
var body: Label
var source: Label
var start: Button
var choices: Array[Button] = []
var response: Label
var page: int = 1
var question: int = 0
var active: bool = false


func setup(owner_chapter: Node3D) -> void:
	chapter=owner_chapter
	size=Vector2(810,438)
	for index in range(3):
		var tab: Button = _button(Vector2(index*266,0),Vector2(254,40),["小爨介绍","大爨介绍","二爨合读"][index])
		tab.pressed.connect(func(): show_page(index))
		tabs.append(tab)
	title=_label(Vector2(8,58),Vector2(780,38),23,true)
	body=_label(Vector2(8,109),Vector2(770,216),19)
	source=_label(Vector2(8,333),Vector2(770,35),12)
	source.modulate=Color(.85,.85,.85)
	response=_label(Vector2(8,338),Vector2(770,58),16)
	for index in range(3):
		var choice: Button = _button(Vector2(8,117+index*68),Vector2(770,54),"")
		choice.pressed.connect(func(): answer(index))
		choices.append(choice)
	start=_button(Vector2(460,385),Vector2(318,43),"开始二爨合读")
	start.pressed.connect(_start)
	show_page(1)


func _label(at: Vector2, dimensions: Vector2, font_size: int, heading: bool=false) -> Label:
	var label := Label.new()
	label.position=at
	label.size=dimensions
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",UiSkin.heading_font() if heading else UiSkin.body_font())
	label.add_theme_font_size_override("font_size",UiSkin.text_size(font_size))
	label.add_theme_color_override("font_color",UiSkin.VERMILION if heading else UiSkin.INK)
	add_child(label)
	return label


func _button(at: Vector2, dimensions: Vector2, words: String) -> Button:
	var button := Button.new()
	button.position=at
	button.size=dimensions
	button.text=words
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",UiSkin.text_size(17))
	UiSkin.button(button)
	add_child(button)
	return button


func show_page(index: int) -> void:
	page=index
	active=false
	for id in range(tabs.size()): tabs[id].disabled=id==page
	for choice in choices: choice.visible=false
	body.visible=true
	source.visible=page<2
	response.text=""
	start.visible=true
	start.text="重做合读 · 印记保留" if chapter.comparison_complete else "开始对照校验" if chapter.inspected_id==1 else "请到右侧大爨碑核对"
	if page<2:
		title.text=FACTS[page].title
		body.text=FACTS[page].body
		source.text=FACTS[page].source
	else:
		title.text="二爨合读 · 邓书年的邀约"
		body.text="邓书年：小爨碑上的字，须靠诸位的见闻合读。大爨碑则记着另一位人物与另一段时代，咱们辨辨两碑的异同。\n\n读过介绍，再辨三处异同，取得「大爨对照印记」，与小爨六字共同完成第一关，并解锁终幕纪年题签。\n\n两碑不是同一块石头；护碑过溪是本作的虚构故事。"
		if chapter.comparison_complete: response.text="大爨对照印记已取得；与小爨六字合验，共庭纪年题签已解锁。"


func _start() -> void:
	if chapter.inspected_id!=1:
		response.text="收起查看，到场景右侧点击大爨碑；这里可以先读两碑介绍。"
		return
	question=0
	active=true
	body.visible=false
	source.visible=false
	start.visible=false
	response.text="可随时点上方介绍核对；答错可再试。"
	_show_question()


func _show_question() -> void:
	title.text="合读 %d / 3 · %s"%[question+1,QUESTIONS[question].prompt]
	for index in range(choices.size()):
		choices[index].text=QUESTIONS[question].choices[index]
		choices[index].visible=true


func answer(index: int) -> void:
	if not active: return
	if index!=QUESTIONS[question].answer:
		response.text="再对照两碑介绍看看。"+QUESTIONS[question].why
		chapter.get_node("../../..").sfx.play("paper")
		return
	response.text=QUESTIONS[question].why
	question+=1
	if question<QUESTIONS.size():
		_show_question()
		return
	active=false
	chapter.record_comparison()
	show_page(2)
	title.text="二爨合读完成 · 一脉文字，各有来处"
	response.text="大爨对照印记已收入包裹 · 回小爨碑合读六字，确认所护之碑。"


func reset_lore() -> void:
	question=0
	show_page(1)
