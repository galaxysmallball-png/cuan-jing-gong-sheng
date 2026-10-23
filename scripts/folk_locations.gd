extends RefCounted

const PLACES: Dictionary={
	"bai_tiedye":"第一关左侧：碑院入口旁的蓝白扎染架。",
	"yang_trade_goods":"第一关右侧：杨旗田路牌旁的货担与布卷。",
	"scholar_tools":"第一关左侧：小爨碑左边的拓印案与纸卷。",
	"caravan_pack":"第二关入口：杨旗田路牌右侧、旧桥基左侧的木驮架与披毡。",
	"miao_batik":"第二关桥头：石墩左边的蓝白花布架。",
	"a_cai_hoe":"阿彩肩上的横柄农具；抬碑时立在她身侧。点锄刃或长柄。",
	"a_cai_basket":"阿彩腰侧的小竹篓。点腰边圆篓，不是花布架下的筐。",
	"baby_carrier":"阿彩背后托着孩子的方形花布。点她背部的背布。",
	"a_qiang_beam":"阿强肩上的榫卯木梁。点击梁端，点脸只会交谈。",
	"a_qiang_knife":"阿强腰间收入木鞘的柴刀。点击腰侧刀鞘。",
	"dai_brocade":"第三关院门左侧：暖红色锦纹布架。",
	"shared_tea":"第三关右廊：茶席与坐凳旁的茶具。",
	"cloth_loom":"第三关右侧：圆窗前有经线的木制织架。",
	"tea_jar":"第三关右廊：保护架右侧、茶席左边独立小木几上的黑陶茶罐。",
	"fire_basin":"第三关左廊：拓片墙前、灯桌右边石垫上的三足铜火盆。",
	"flint_pouch":"第三关右侧：圆窗下、织架前方小木几上的火石布袋。",
	"yu_nan_brocade":"第三关：玉喃身侧的锦带，驮布毛驴在她旁边。",
	"donkey":"第三关右廊：玉喃旁的毛驴与驮布筐。",
	"garden_item_1":"第三关碑前左侧工具架：先由石阿朵拾回第一关的錾子并归架，再点击。",
	"garden_item_2":"第三关碑亭檐下：先由老箐拾回第二关的马铃并挂好，再点击。",
	"garden_item_3":"第三关碑亭右侧保护架：先由杨三娘拾回第二关的红线并系好，再点击。"
}


static func text(id: String, world: Node3D) -> String:
	var line: String=PLACES.get(id,"在对应场景中点击器物。")
	if id in ["a_cai_hoe","a_cai_basket","baby_carrier","a_qiang_beam","a_qiang_knife"]:
		if world.festival!=null and world.current_space==2 and world.festival.guests[0].is_visible_in_tree():
			return "第三关可补访：阿彩在左廊灯桌旁，阿强在右廊茶席旁。\n"+line
		if not world.bridge.helpers_called: return "第二关先由杨三娘在旧桥基联络帮手。\n阿彩、阿强到场后："+line
		if world.bridge.tablet_delivered: return "已送碑入院：两人仍在第二关桥右岸、城门外。\n"+line
		return "第二关：阿彩、阿强随护碑队在桥头或桥面。\n"+line
	return line
