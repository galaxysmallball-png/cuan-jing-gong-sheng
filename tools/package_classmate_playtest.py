"""Create a small, portable classmates' playtest package from the verified release."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
WORKSPACE = PROJECT.parent.parent
SOURCE = PROJECT / 'builds/journey-polish-2026-10-17'
STAGE = PROJECT / 'builds/classmate-playtest-2026-10-17/爨境共生_同学试玩版'
OUTPUT = WORKSPACE / '爨境共生_同学试玩包_2026-10-17.zip'
VERSION = '2026-10-17 / journey-polish'

README = '''爨境·共生 — 同学试玩版
版本：2026-10-17 / 关卡指引与场景配乐版

【怎么开始】
1. 将整个ZIP解压到一个文件夹。
2. 双击 CuanParty.exe 开始游戏。
3. CuanParty.exe 和 CuanParty.pck 必须保留在同一个文件夹。

Windows 64位电脑运行，无需安装Godot、Blender或其他插件。
游戏可离线玩；文化记里的来源链接需要联网。
两位同学共用一台电脑、同一把键盘，不是两台电脑联机。

【首次试玩】
建议从封面“启程同行”开始，完整体验三关。
封面的“试玩·断溪古道 / 灯火共庭”用于直接体验后面关卡。
八张卡都会展示，只抽中四位主角；每位玩家拥有两名角色。
一名当前操作、一名跟随，只能切换自己拥有的两人。
下一步目标在右下角“此刻所往”，操作键位点左上角“提示”。

【操作】
1P：A / D行走，W / 空格跳跃，S / E任务操作。
    F交谈/察看/下一句，G切换附近目标，Tab切换自己的角色。
2P：← / →行走，↑跳跃，↓任务操作。
    /交谈/察看/下一句，.切换附近目标，右Shift切换自己的角色。

靠近村民或道具会出现小提示框，亦可点击交谈/察看。
任务操作与交谈分开：交谈不会代替修桥、护碑或送灯。
B查看行囊中的已收线索，H查看操作提示，F2查看档案。
M开关配乐；右上角“乐声”也能点击。

右上角“重新开始”重开当前关，保留此前通关与本轮角色归属。
R回起点、保留进度；T清空三关并从头重玩。
长卷用左右箭头翻页，Enter继续，末页确认返回，Esc回庭院。
目前没有退出程序后继续关卡的存档功能，请尽量一次体验完。

【反馈】
玩完可填写同文件夹“试玩反馈.txt”，发回给开发同学。
尤其欢迎记录：哪里不知道下一步、哪里卡住、界面是否遮挡、
合作操作是否清楚，以及音乐音量与结尾感受。
若遇异常，请写下所在关卡、刚才按了什么，以及截图或录屏。
'''

FEEDBACK = '''爨境·共生 — 试玩反馈
版本：2026-10-17 / 关卡指引与场景配乐版

昵称（可不填）：
试玩日期：
试玩人数：
是否完整通关：
大致用时：

1. 第一次是否看得懂怎么玩、下一步去哪？哪一处最不清楚？


2. 两人操作、切换各自角色是否清楚？有无按键冲突或误操作？


3. 哪一关或哪一步卡住了？你当时尝试了什么？


4. 提示框、右下角目标、文字大小和界面遮挡有什么问题？


5. 第二关运碑过桥是否自然？有没有人物/碑/绳索异常？


6. 各场景音乐音量是否合适？最后长卷的配乐与文字感受如何？


7. “重新开始”与行囊是否按预期工作？


8. 最喜欢的一处、最想修改的一处：


如有Bug，请尽量填写：
所在关卡与位置：
发生前的操作（包括两位玩家的角色）：
预期发生什么：
实际发生什么：
是否每次都能复现：
截图/录屏文件名：
如有卡顿/无法启动，可补充电脑系统和显卡型号：
'''

CREDITS = '''爨境·共生 — 资料与鸣谢

本包供同学进行非商业学习试玩。人物与护碑情节为原创叙事，
人物生活描写不代表某个民族所有人的习惯，长卷为艺术创作。
角色、卡片、封面及场景背景使用项目提供的美术素材。

配乐：碑院听风、断溪同行、庭前暖灯、万家共生。
由本项目程序编排与合成，未使用第三方录音或乐器采样。

字库：梁培生小爨-简，作者梁培生，来源曲靖珠江网。
https://www.zjw.cn/html/ziti/index.html
字库用于当前教育、学习的非商业原型；不是开放源码或无限制
免费商用字体。发布页限制销售产品、商业应用及字体下载镜像；
商业使用须另与权利方协商。完整范围以原发布声明为准。
游戏爨体为现代字库示意，不冒充原碑拓片。

文化资料来源：
曲靖市人民政府·爨文化博物馆
https://www.qj.gov.cn/html/2020/csmp_0417/83745.html
云南宣传网·二爨碑上的千秋笔意
https://www.ynxc.gov.cn/html/2026/whxdfocus_0831/3037025.html
国家民委·云南持续拓展各民族交往交流交融的广度和深度
https://www.neac.gov.cn/seac/xwzx/202407/1174878.shtml
国家文化记忆库·晋建宁太守爨宝子碑拓本
https://tcmb.culture.tw/zh-tw/detail?id=14000102749&indexCode=MOCCOLLECTIONS

引擎：Godot Engine。引擎及所含第三方组件的版权与许可全文
见同目录“Godot引擎与第三方许可.txt”。
'''


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare():
    evidence = json.loads((SOURCE / '验证记录.json').read_text(encoding='utf8'))
    assert evidence['exported_headless_startup']
    STAGE.mkdir(parents=True, exist_ok=True)
    for filename in ['CuanParty.exe', 'CuanParty.pck']:
        assert (SOURCE / filename).stat().st_size > 1_000_000
        shutil.copy2(SOURCE / filename, STAGE / filename)
        assert digest(SOURCE / filename) == digest(STAGE / filename)
    for filename, text in [('先看这里_启动与操作.txt', README), ('试玩反馈.txt', FEEDBACK), ('资料与鸣谢.txt', CREDITS)]:
        (STAGE / filename).write_text(text, encoding='utf-8-sig')


def package():
    check = json.loads((STAGE / 'bundle-check.json').read_text(encoding='utf8'))
    assert check['result'] == 'PLAYTEST_BUNDLE_OK'
    log = (STAGE.parent / 'bundle-startup.log').read_text(encoding='utf8')
    assert 'PLAYTEST_BUNDLE_OK' in log and 'ERROR' not in log
    assert (STAGE / 'Godot引擎与第三方许可.txt').stat().st_size > 1000
    names = ['CuanParty.exe', 'CuanParty.pck', '先看这里_启动与操作.txt', '试玩反馈.txt', '资料与鸣谢.txt', 'Godot引擎与第三方许可.txt']
    for filename in ['CuanParty.exe', 'CuanParty.pck']:
        assert digest(SOURCE / filename) == digest(STAGE / filename)
    manifest = {'version': VERSION, 'platform': 'Windows x86_64',
                'verification': check,
                'files': {name: {'bytes': (STAGE / name).stat().st_size, 'sha256': digest(STAGE / name)} for name in names}}
    (STAGE / '文件校验.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf8')
    with zipfile.ZipFile(OUTPUT, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for name in names + ['文件校验.json']: archive.write(STAGE / name, STAGE.name + '/' + name)
    with zipfile.ZipFile(OUTPUT) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == 7
        assert not any(name.endswith(('.lnk', '.log', '.gd', '.blend')) for name in archive.namelist())
        for name in ['CuanParty.exe', 'CuanParty.pck']:
            assert hashlib.sha256(archive.read(STAGE.name + '/' + name)).hexdigest() == manifest['files'][name]['sha256']
    print('CLASSMATE_PLAYTEST_PACKAGE_OK', OUTPUT.stat().st_size, str(OUTPUT).encode('unicode_escape').decode())


if __name__ == '__main__':
    if '--prepare' in sys.argv: prepare()
    else: package()
