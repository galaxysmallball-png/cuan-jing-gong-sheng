extends RefCounted

# These are associations in the authored story, not exclusive ethnic ownership
# of a craft or utensil. The reference-photo captions retain their own origin.
const GROUPS: Array[String] = ["汉族","白族","彝族","回族","苗族","壮族","傣族","共用器物"]
const ITEMS: Dictionary = {
	"scholar_tools":{"group":"汉族","note":"邓书年的纸笔记录古字，也记录石匠、赶马人与货郎的经验。认字的人同样要向同行请教。"},
	"bai_tiedye":{"group":"白族","note":"把蓝白扎染与阿彩的蜡染、玉喃的织锦放在一起看：留白与纹样各有做法，布匹随人的往来相遇。"},
	"garden_item_1":{"group":"白族","note":"石阿朵的錾子留下匠人的手感。它与邓书年的纸笔相接，让认读碑文与护住石角成为同一件事。"},
	"caravan_pack":{"group":"彝族","note":"老箐熟悉驮架、配重与山路。过溪时，这份行路经验要接上阿彩的绳索和阿强的木梁。"},
	"tea_jar":{"group":"彝族","note":"普嫫的热茶留给每位归来的同行。茶罐跟着主人来到院中，也在一张共用茶席上迎接各方来客。"},
	"fire_basin":{"group":"彝族","note":"普嫫留住炭火，诸位一同点灯。火盆带着主人的生活记忆，暖意却向院中每一个人敞开。"},
	"flint_pouch":{"group":"彝族","note":"火石与干茶随普嫫而来。取火、暖茶、给灯续火，把赶路者的日常接进众人共享的庭院。"},
	"garden_item_2":{"group":"彝族","note":"老箐把马铃挂上共同的屋檐。山路上的声响留在院中，记着修桥、护碑时彼此照应的人。"},
	"yang_trade_goods":{"group":"回族","note":"杨三娘的货担把针线、布匹和乡音带过村镇。她的家庭与行商经历，让互不相识的人先听懂彼此。"},
	"garden_item_3":{"group":"回族","note":"杨三娘系下红线，给后来人留下护碑的记号。此处按她在故事中的使用情境归档，红绳编结并非某一民族独有。"},
	"miao_batik":{"group":"苗族","note":"阿彩的蓝白花布与竹筐一道来到桥边。花纹保留生活的颜色，递绳与搭手则把她和同行连接起来。"},
	"a_cai_hoe":{"group":"苗族","note":"阿彩放下田里的活来帮忙。她不必先懂碑上的字，也能凭日常劳作积累的经验，与书生、石匠和木工并肩。"},
	"a_cai_basket":{"group":"苗族","note":"阿彩的竹篓装着随身零物；杨三娘的竹筐装着货物。同样的编织器具，进入不同人的生活与共同的路途。"},
	"baby_carrier":{"group":"苗族","note":"背婴布护着孩子，同行人便放轻声响、互相照看。照料孩子与护稳碑石，在这一夜都需要彼此体谅。"},
	"a_qiang_beam":{"group":"壮族","note":"阿强带来的榫卯木梁，要接上石阿朵判断的墩脚与老箐选定的过溪路线。桥由众手搭成。"},
	"a_qiang_knife":{"group":"壮族","note":"柴刀是阿强整理木料的工具。按剧中木工的使用情境收录，与各族共享的木作经验相通，并非族属专用品。"},
	"dai_brocade":{"group":"傣族","note":"玉喃带来的织锦与扎染、蜡染在共庭相遇。各有纹样与做法，也都能成为提灯、迎客和往来的媒介。"},
	"yu_nan_brocade":{"group":"傣族","note":"玉喃把锦带系在灯柄，让诸位提握方便。布商的手艺转成共同点灯时的一份照应。"},
	"donkey":{"group":"傣族","note":"玉喃的毛驴驮来布卷与锦带。沿途的生意也带来人情，与杨三娘的货担一起连起不同村镇。"},
	"shared_tea":{"group":"共用器物","note":"这张茶席属于共同抵达的时刻。普嫫温茶，护碑的人围坐，交换乡音、手艺与沿途见闻。"},
	"cloth_loom":{"group":"共用器物","note":"织机是多地生活中的工具，照片注明其自身馆藏来处。织染经验随学习、交易和互助流动，在此与不同布艺相对照。"}
}
const BADGES: Array[Dictionary] = [
	{"id":"first_meeting","title":"初见一物","subtitle":"一次相识，留下一闻","items":[],"minimum":1,"note":"与任意一件特色物件交互。器物背后有具体的人，收藏从认真看见一件日常之物开始。"},
	{"id":"ink_and_stone","title":"笔墨石声","subtitle":"汉族 · 白族","items":["scholar_tools","garden_item_1"],"note":"纸笔辨字，錾子护石。邓书年与石阿朵的本领相接，共同留住碑上的记忆。"},
	{"id":"woven_encounters","title":"布上相逢","subtitle":"白族 · 苗族 · 傣族","items":["bai_tiedye","miao_batik","dai_brocade"],"note":"扎染、蜡染、织锦各有纹样和做法。把三种布艺一起收入册中，看见差异，也看见布匹与手艺随人往来。"},
	{"id":"many_hands_bridge","title":"众手成桥","subtitle":"彝族 · 苗族 · 壮族","items":["caravan_pack","a_cai_hoe","a_qiang_beam"],"note":"赶马人的行路经验、阿彩的劳作与搭手、阿强的木工，连成同一条过溪的路。每个人都有别人需要的经验。"},
	{"id":"tea_and_travel","title":"茶暖往来","subtitle":"回族 · 彝族 · 傣族","items":["yang_trade_goods","tea_jar","yu_nan_brocade"],"note":"货担带来消息，茶罐留住热意，锦带方便提灯。行商与待客让不同来处的人，有机会坐下来、听彼此讲述。"},
	{"id":"shared_home","title":"共用成家","subtitle":"四族相识 · 共坐一席","items":["shared_tea","cloth_loom"],"groups":4,"note":"收录茶席与织机，并认识至少四个民族相关的器物。归档保留人物的来处，共用的工具与生活空间则让经验相互流通。"},
	{"id":"seven_together","title":"七族同庭","subtitle":"七族各留一闻 · 共用两物","items":["shared_tea","cloth_loom"],"groups":7,"note":"七个民族相关的收藏页都至少收录一件，再收齐两件共用器物。各自留着来处的颜色，也共同照亮一方庭院。"},
	{"id":"complete_scroll","title":"万物成卷","subtitle":"二十一物 · 一路共生","items":[],"minimum":21,"note":"与全部二十一类特色物件交互。把不同人的生活经验留在同一卷中，记住各自的颜色，也记住彼此需要、共同创造的这一程。"}
]
