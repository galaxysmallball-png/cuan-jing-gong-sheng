from pathlib import Path
import hashlib,json,shutil

root=Path(__file__).resolve().parents[1]
base=root/'builds/scroll-guidance-correction-2026-10-22'
prior=root/'builds/pickup-only-small-text-2026-10-21'
for platform in ['Windows','Android']:
    folder=base/platform
    folder.mkdir(parents=True,exist_ok=True)
    (base/'.gdignore').touch()
    for file in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json','Godot引擎与第三方许可.txt']:
        shutil.copy2(prior/file,folder/file)
source=root/'assets/interface/user_launcher_20261021.png'
original=root/'references/app-icon/用户应用图标_20261021.png'
assert source.read_bytes()==original.read_bytes()
shutil.copy2(source,base/'手机图标.png')
(base/'图标来源.json').write_text(json.dumps({'provided_by':'user','source_file':'ChatGPT 图像 2026年10月21日 13_09_24-1.png','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'content_modified':False,'export':'Godot generates launcher density sizes from the unchanged supplied artwork'},ensure_ascii=False,indent=2),encoding='utf-8')
windows=(root/'tools/export_pickup_only_small_text_release.ps1').read_text(encoding='utf-8-sig').replace('builds/pickup-only-small-text-2026-10-21','builds/scroll-guidance-correction-2026-10-22/Windows')
(root/'tools/export_final_windows.ps1').write_text(windows,encoding='utf-8-sig')
android=(root/'tools/export_android_release.ps1').read_text(encoding='utf-8-sig').replace('builds/android-2026-10-21','builds/scroll-guidance-correction-2026-10-22/Android')
(root/'tools/export_final_android.ps1').write_text(android,encoding='utf-8-sig')
helpers=(root/'tools/verify_shipped_celebration_rewards.gd').read_text(encoding='utf-8-sig')
fields=helpers[:helpers.index('var check_done')]
utilities=helpers[helpers.index('func _frames'):]
focus=(root/'tools/verify_celebration_rewards.gd').read_text(encoding='utf-8-sig')
(root/'tools/verify_shipped_final_rewards.gd').write_text(fields+focus[focus.index('var check_done'):]+ '\n'+utilities,encoding='utf-8')
touch=(root/'tools/verify_android_touch.gd').read_text(encoding='utf-8-sig')
(root/'tools/verify_shipped_final_touch.gd').write_text(fields+touch[touch.index('const MobilePlatform'):]+ '\n'+utilities,encoding='utf-8')
print('FINAL_WINDOWS_ANDROID_RELEASE_PREPARED')
