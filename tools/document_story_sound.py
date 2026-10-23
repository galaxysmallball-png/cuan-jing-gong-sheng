"""Record the source material and release notes; does not create an archive."""
from pathlib import Path
import hashlib
import json

PROJECT = Path(__file__).resolve().parents[1]
BLUEPRINT = PROJECT.parent / 'cuan-game-blueprint'
ART = Path('C:/Users/26845/Desktop/树莓比赛美工')
DATE = '2026-10-18'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources(folder, items, **extra):
    records = []
    for filename, original, details in items:
        target = PROJECT / 'assets' / folder / filename
        assert target.read_bytes() == original.read_bytes(), original
        records.append(dict(file=filename, source=str(original), sha256=sha(target), altered=False, **details))
    output = dict(date=DATE, images=records, **extra)
    (PROJECT / 'assets' / folder / 'SOURCE.json').write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf8')


def prepend(path, paragraph):
    text = path.read_text(encoding='utf-8-sig')
    if paragraph in text:
        return
    title, body = text.split('\n', 1)
    path.write_text(title + '\n\n' + paragraph + '\n' + body, encoding='utf8')


sources('dialogue', [
    ('deng_shunian.png', ART / '人物和场景/邓书年角色设定图 (2).png', {'runtime_atlas_rect': [125, 18, 320, 435]}),
    ('shi_aduo.png', ART / '人物和场景/石阿朵：白族女石匠设定集.png', {'runtime_atlas_rect': [111, 30, 330, 446]}),
    ('lao_qing.png', ART / '人物和场景/彝族赶马人角色设定图.png', {'runtime_atlas_rect': [125, 25, 310, 420]}),
    ('yang_sanniang.png', ART / '人物和场景/杨三娘：回族女货郎角色设定稿.png', {'runtime_atlas_rect': [115, 135, 300, 405]}),
    ('dialogue_paper.png', Path('C:/Users/26845/AppData/Local/Temp/codex-clipboard-6033993f-a219-420b-af14-dddf1542a7b7.png'), {'usage': 'dialogue panel paper background'}),
], method='Original bytes retained. Runtime Godot AtlasTexture crops show busts from the four supplied front views. NPCs reuse the original character cards.')
sources('historical_steles', [
    ('stele_shape_reference.jpg', ART / '爨碑/images (2).jpg', {'usage': 'visual reference for rounded shoulders and pierced crown; artistic mesh study'}),
    ('rubbing_reference.jpg', ART / '爨碑/images.jpg', {'usage': 'reference for dense columns, wear, engraved text and stone tonality'}),
    ('small_stele_rubbing.jpg', ART / '爨碑/images (1).jpg', {'usage': 'supplied small-stele image rendered on small stele and matching viewer'}),
], distinction='Small stele uses supplied rubbing; large-stele excerpt remains modern small-Cuan font artwork, explicitly labeled. Mesh proportions and aging are artistic studies, not measured reconstruction.')

note = '''# 半身像剧情、古碑与民乐音效

2026-10-18。当前运行：`../cuan-game/builds/story-sound-2026-10-18/CuanParty.exe`，项目最外层“开始游戏（最新版）”已指向此版本。本轮依用户最新要求不制作压缩包。

对白窗使用本次第五张花卉祥云纸底，并从前四张设定稿正面取半身像，包含帽子、包头和职业服饰。轮到谁说话便换谁的图，姓名后保留民族。四位村民使用此前原人物卡的上半身；图片原文件逐字节保留，运行时裁切，不重绘脸和衣饰。点击“续话”或按 V 可读下一句，也可让短句自然播放；移动与合作操作不中断，暂停、查看档案和长卷时对白计时停下。

根据用户《爨境共生_方案A_灯起杨旗田_完整剧本》，加入相逢、释字、辨路、请帮手、救碑后、立碑、围火与共灯八组短对话。通过识字、护石、认路、联络等实际合作体现各人互补，保留轻古风、可读懂的口吻。村民交谈仍能独立翻阅，闲谈不代替修桥和送灯。跨关清理旧对白，重新开始当前关可重播本关剧情。

“此刻所往”移到左下角；剧情窗在右下角，拼字时用更矮版本。交互小框按实际标题、正文、脚注最宽一行计算宽度，仅留必要边距，纸底不透明度降至62%；仍在人物和物件上方，用箭头指向。两人各自提示独立，并错开重叠。第三关进度卡避开左下任务与右下对白。

配乐改为四首原创合成器乐：碑院相逢（96 BPM）、踏歌过溪（112 BPM）、暖灯对歌（108 BPM）、万家同欢（116 BPM）。五声音列、拨弦分奏、簧管呼应、木击舞步和鼓点带来更活泼的节奏；终章加厚弦乐、铜管、鼓镲层次。曲目渐变循环，M/“乐声”开关继续只控制背景音乐。

编曲参考地方非遗介绍里的伴奏与群舞呼应方式：[云南非物质文化遗产保护网·彝族烟盒舞](https://www.ynich.cn/item/37.html)、[中国非物质文化遗产网·苗族的芦笙舞](https://www.ihchina.cn/news_1_details/11374.html)。这是新旋律与合成音色的创作，没有使用第三方录音或采样，也不作为原生态民族乐曲复原；某地习俗不推及整个民族或所有人物。

场景登记的64类交互目标均有声音映射，按实际对象采用纸、石、木、绳、马铃、灯火、水、布、翻卷或交谈提示；另有完成和拼字错误反馈，共12种短音效。点击、F、/均走同一交互入口；推木、架桥、拉绳、拼字、立碑、物件归位等任务另有动作反馈，连续操作适当限频。交谈音效是轻提示，不是配音；毛驴物件采用驮包布料摩擦声。

参考本次三张爨碑照片制作斑驳石色、缺角、碑肩、风化刻痕与底部苔色，大碑冠部有实际通孔。小碑采用用户提供的小爨拓影，场景碑面、放大查看和搬运中的碑一致；大碑仍保留明确标注的现代字库节选示意，不将小爨拓片冒充大爨原文。造型与旧化属于美术表现，并非实测考古复原。原碰撞、点击范围、六字谜题及双人合作条件保留。

图片原始路径、SHA256、用途与运行时裁切见 `assets/dialogue/SOURCE.json`、`assets/historical_steles/SOURCE.json`；剧本使用此前已存档同哈希版本，原Word未改。音乐与音效参数及哈希见 `assets/audio/SOURCE.json`，生成入口 `tools/compose_festival_audio.py`。用户手工修改音频后请另存，不直接重跑覆盖。

验证：新增真实显卡专项检查四人原图对白、村民卡图、拼字窗口、62%自适应双提示、旧化碑/通孔、64目标音效映射、四曲播放状态与当前关重开；完整双人三幕和共庭显卡检查通过，单人兼容、12种身份归属、行囊、八牌入场、场景交互、文化长卷及旧指引专项回归通过。截图使用 Dummy 音频驱动；音频检查为PCM信号与播放/循环状态，最终听感需实际试玩聆听。
'''
(BLUEPRINT / '半身像剧情_古碑与民乐音效_说明.md').write_text(note, encoding='utf8')
(PROJECT / 'assets/audio/配乐来源.md').write_text('''# 配乐与物件音效来源

2026-10-18 当前音频由 `tools/compose_festival_audio.py` 原创编排与程序合成；借用旧 `compose_scene_music.py` 的合成函数，旧脚本整段运行会覆盖当前曲目，请勿直接重跑。

四曲：碑院相逢96 BPM、踏歌过溪112 BPM、暖灯对歌108 BPM、万家同欢116 BPM。32000 Hz、立体声，约50—60秒循环。采用五声音列呼应、拨弦、簧管合成、木击和鼓点，终章增加弦乐铜管鼓镲。12种交互短音效在 interactions 子目录；纸、石、木、绳、铃、火、水、布、翻卷、完成、交谈提示与错误反馈均为程序合成。

配器灵感参考：[云南非物质文化遗产保护网·彝族烟盒舞](https://www.ynich.cn/item/37.html)、[中国非物质文化遗产网·苗族的芦笙舞](https://www.ihchina.cn/news_1_details/11374.html)。这是受地方舞蹈伴奏启发的原创新旋律，非某一传统曲牌复刻，也非真实民族乐器实录。没有下载或使用第三方歌曲、录音或乐器采样。

SOURCE.json记录SHA256、时长、速率、声道、RMS及峰值。已检查PCM信号、播放、循环与切换状态；显卡截图检查使用Dummy不外放，未宣称人工听审。请保留独立版本后再修改或重生成。
''', encoding='utf8')
summary = '2026-10-18 最新半身像剧情与民乐音效：此刻所往在左下角，交互框按文字实际宽度伸缩、纸底62%不透明度；四位主角用新设定图半身像与新花卉纸底，村民用原卡半身，V/续话翻句。按剧本补充八组互助交流短对白。四首配乐更轻快，融入拨弦、簧管呼应与木击舞步灵感，终章加厚配器；64目标按材质配12种原创短音效。三幕碑面增加旧石、缺角、碑肩与风化，小碑及查看窗使用用户拓影，大碑仍明示现代字库示意。当前 `builds/story-sound-2026-10-18/CuanParty.exe`，根最新快捷方式直达；按用户最新要求不制作压缩包。新增GPU专项、完整双人/共庭GPU及单人、身份归属、行囊、八牌、交互、文化长卷和指引回归通过。详见 [本轮说明](../cuan-game-blueprint/半身像剧情_古碑与民乐音效_说明.md)。下方为历史记录。'
prepend(PROJECT / 'README.md', summary)
prepend(PROJECT / '制作记录.md', summary)
prepend(BLUEPRINT / 'README.md', summary.replace('`builds/', '`../cuan-game/builds/').replace('../cuan-game-blueprint/', './'))
prepend(BLUEPRINT / '四人同行_试玩说明.md', summary.replace('详见 [本轮说明](../cuan-game-blueprint/', '详见 [本轮说明](./'))
memory = '- ' + summary.replace('[本轮说明](../cuan-game-blueprint/半身像剧情_古碑与民乐音效_说明.md)', 'cuan-game-blueprint/半身像剧情_古碑与民乐音效_说明.md') + ' 备份 before-story-sound-2026-10-18.zip；原人物Blender/GLB未改。实际音频尚待玩家听感反馈。'
prepend(PROJECT / 'AGENTS.md', memory)
prepend(PROJECT.parent / 'AGENTS.md', memory)
print('STORY_SOUND_PROVENANCE_AND_NOTES_OK')
