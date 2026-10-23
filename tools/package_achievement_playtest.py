"""Package the verified achievement build without development/test user data."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

PROJECT=Path(__file__).resolve().parents[1]
WORKSPACE=PROJECT.parent.parent
SOURCE=PROJECT/'builds/achievement-book-2026-10-18'
EVIDENCE=PROJECT/'builds/classmate-achievements-2026-10-18'
STAGE=EVIDENCE/'爨境共生_成就版'
EXTRACTED=EVIDENCE/'解压验证'
OUTPUT=WORKSPACE/'爨境共生_成就版试玩包_2026-10-18.zip'
FILES=['CuanParty.exe','CuanParty.pck','先看这里_启动与操作.txt','试玩反馈.txt',
       '资料与鸣谢.txt','Godot引擎与第三方许可.txt','实物照片_来源与授权.md']


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


def prepare():
    verification=json.loads((SOURCE/'验证记录.json').read_text(encoding='utf-8'))
    assert verification['result']=='ACHIEVEMENT_BOOK_RELEASE_VERIFIED'
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    (EVIDENCE/'.gdignore').touch()
    STAGE.mkdir(parents=True,exist_ok=True)
    for name in ['CuanParty.exe','CuanParty.pck','资料与鸣谢.txt','Godot引擎与第三方许可.txt','实物照片_来源与授权.md']:
        shutil.copy2(SOURCE/name,STAGE/name)
        assert digest(SOURCE/name)==digest(STAGE/name)
    for name in ['CuanParty.exe','CuanParty.pck']:
        assert digest(STAGE/name)==verification['files'][name]['sha256']
    instructions=(SOURCE/'先看这里_启动与操作.txt').read_text(encoding='utf-8-sig')
    instructions=instructions.replace('项目根“开始游戏（最新版）”也会启动此版本。',
        '请把整个 ZIP 完整解压后，打开文件夹双击 CuanParty.exe。不要只拿出 EXE。\n无需安装 Godot 或 Blender，可离线试玩；两人共用一台电脑和键盘。')
    instructions=instructions.replace('这是一份可运行试玩版。检查记录与截图见《验证记录.json》和《本轮改动与验证.md》。',
        '这是一份 Windows 64 位试玩版，已完成自动化三关与导出检查。欢迎填写同目录《试玩反馈.txt》。')
    instructions=instructions.replace('收藏与成就保存在本机用户数据中；退出、重开关卡、R / T 均保留。关卡见闻与小艺仍按原有规则重置。',
        '收藏与成就保存在本机用户数据中；退出、重开关卡、R / T 均保留。关卡见闻与小艺仍按原有规则重置。\n分发包不带开发测试收藏，新电脑从空册开始；当前关卡进度不跨退出续关。')
    (STAGE/'先看这里_启动与操作.txt').write_text(instructions,encoding='utf-8-sig')
    feedback='''爨境·共生 — 成就版试玩反馈（2026-10-18）

昵称（可不填）：
试玩日期：
一人/两人：
是否通关、大致用时：

1. 第一关哪里最难理解？角色分享、换人、字卡转向和归位提示清楚吗？

2. 四向移动、专属角色切换、桥头通行和第二关石碑交接是否正常？

3. 任务长按、提示、对白、声音设置是否好用？有什么遮挡或音量问题？

4. 特色物件是否好找、能点开？三维/实物图切换与来源是否清楚？

5. 共生见闻是否自动收录？按民族筛选、翻页、回看图片和保存是否正常？

6. 八项成就的条件容易理解吗？哪些收藏组合让你感受到民族交流与相助？

7. 最后庭院、配乐和共生长卷的感受：

8. 最喜欢、最希望修改的地方：

如遇问题，请补充：关卡/位置、两位角色、发生前的操作、实际结果、能否重复，以及截图或录屏文件名。
'''
    (STAGE/'试玩反馈.txt').write_text(feedback,encoding='utf-8-sig')
    print('ACHIEVEMENT_PACKAGE_PREPARED',len(FILES),'portable files')


def package():
    bundle=json.loads((EVIDENCE/'bundle-check.json').read_text(encoding='utf-8'))
    assert bundle['achievement_book_21_items_seven_ethnic_associations_shared_objects_eight_badges_and_save_verified']
    log=(EVIDENCE/'bundle-check.log').read_text(encoding='utf-8')
    assert 'PLAYTEST_BUNDLE_OK' in log and 'ERROR:' not in log
    for name in ['CuanParty.exe','CuanParty.pck']:
        assert digest(STAGE/name)==digest(SOURCE/name)
    manifest={'version':'2026-10-18 / achievement-book','platform':'Windows x86_64',
              'verification':bundle,'files':{name:{'bytes':(STAGE/name).stat().st_size,
              'sha256':digest(STAGE/name)} for name in FILES}}
    (STAGE/'文件校验.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUTPUT,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for name in FILES+['文件校验.json']:
            archive.write(STAGE/name,STAGE.name+'/'+name)
    expected={STAGE.name+'/'+name for name in FILES+['文件校验.json']}
    with zipfile.ZipFile(OUTPUT) as archive:
        assert set(archive.namelist())==expected
        assert archive.testzip() is None
        for name in FILES:
            with archive.open(STAGE.name+'/'+name) as stream:
                assert hashlib.file_digest(stream,'sha256').hexdigest()==manifest['files'][name]['sha256']
        assert EXTRACTED.resolve().is_relative_to(EVIDENCE.resolve())
        EXTRACTED.mkdir(parents=True,exist_ok=True)
        archive.extractall(EXTRACTED)
    for name in FILES:
        assert digest(EXTRACTED/STAGE.name/name)==manifest['files'][name]['sha256']
    record={'result':'ACHIEVEMENT_PORTABLE_ZIP_VERIFIED','archive':OUTPUT.name,
            'bytes':OUTPUT.stat().st_size,'sha256':digest(OUTPUT),'files':len(expected),
            'zip_crc_verified':True,'all_extracted_hashes_verified':True,
            'no_test_profiles_or_developer_shortcuts_in_zip':True,'bundle':bundle}
    (EVIDENCE/'打包验证.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
    print('ACHIEVEMENT_PORTABLE_ZIP_VERIFIED',record['bytes'],'bytes;',record['files'],'files')


if __name__=='__main__':
    prepare() if '--prepare' in sys.argv else package()
