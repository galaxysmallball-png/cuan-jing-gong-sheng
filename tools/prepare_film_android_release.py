from pathlib import Path
import hashlib,json,os,secrets,subprocess

root=Path(__file__).resolve().parents[1]
workspace=root.parent.parent
tools=root.parent/'.tools'
previous='builds/courtyard-edge-original-draw-2026-10-20'
windows='builds/opening-film-2026-10-21'
android='builds/android-2026-10-21'
for folder in [windows,android]:
    (root/folder).mkdir(parents=True,exist_ok=True)
    (root/folder/'.gdignore').touch()
preset=root/'export_presets.cfg'
text=preset.read_text(encoding='utf-8')
text=text.replace(previous,windows)
if '[preset.1]' not in text:
    text+='''
[preset.1]
name="Android"
platform="Android"
runnable=true
advanced_options=false
custom_features=""
export_filter="all_resources"
include_filter="assets/references/folk/*.json,assets/references/folk/*.md"
exclude_filter="tools/*,previews/*,backups/*,references/*,builds/*,character-source/*"
export_path="builds/android-2026-10-21/CuanJingGongSheng.apk"
script_export_mode=2

[preset.1.options]
custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
gradle_build/export_format=0
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=1
version/name="0.1.0"
package/unique_name="org.cuanjing.gongsheng"
package/name="爨境·共生"
package/signed=true
screen/immersive_mode=true
screen/edge_to_edge=false
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
launcher_icons/main_192x192="res://assets/interface/android_launcher.png"
permissions/internet=false
permissions/access_network_state=false
permissions/read_external_storage=false
permissions/write_external_storage=false
'''
preset.write_text(text,encoding='utf-8')
config=root/'project.godot'
project=config.read_text(encoding='utf-8')
if 'window/handheld/orientation' not in project:
    project=project.replace('window/stretch/mode="canvas_items"','window/stretch/mode="canvas_items"\nwindow/stretch/aspect="keep"\nwindow/handheld/orientation=0\nwindow/energy_saving/keep_screen_on=true')
if 'textures/vram_compression/import_etc2_astc' not in project:
    project=project.replace('renderer/rendering_method.mobile="gl_compatibility"','renderer/rendering_method.mobile="gl_compatibility"\ntextures/vram_compression/import_etc2_astc=true')
config.write_text(project,encoding='utf-8')

settings=tools/'godot/4.7.2/editor_data/editor_settings-4.7.tres'
content=settings.read_text(encoding='utf-8')
import re
for key,value in [('export/android/java_sdk_path','C:/Program Files/Microsoft/jdk-17.0.16.8-hotspot'),('export/android/android_sdk_path','C:/Users/26845/AppData/Local/Temp/cuan-android-build-20261021/sdk')]:
    line=key+' = '+json.dumps(value,ensure_ascii=False)
    if re.search('^'+re.escape(key)+' = .*$',content,re.M):
        content=re.sub('^'+re.escape(key)+' = .*$',lambda m:line,content,flags=re.M)
    else: content+='\n'+line+'\n'
settings.write_text(content,encoding='utf-8')

signing=tools/'android/signing'
signing.mkdir(parents=True,exist_ok=True)
creds=signing/'credentials.json'
if not creds.exists():
    password=secrets.token_hex(24)
    creds.write_text(json.dumps({'alias':'cuan-release','password':password}),encoding='utf-8')
credentials=json.loads(creds.read_text(encoding='utf-8'))
key=signing/'cuan-release.jks'
if not key.exists():
    environment=os.environ.copy()
    environment['CUAN_ANDROID_BUILD_KEY_PASS']=credentials['password']
    result=subprocess.run(['C:/Program Files/Microsoft/jdk-17.0.16.8-hotspot/bin/keytool.exe','-genkeypair','-keystore',str(key),'-alias',credentials['alias'],'-keyalg','RSA','-keysize','3072','-validity','10000','-storepass:env','CUAN_ANDROID_BUILD_KEY_PASS','-keypass:env','CUAN_ANDROID_BUILD_KEY_PASS','-dname','CN=Cuan Jing Gong Sheng, OU=Game Project, O=Independent, C=CN'],env=environment,capture_output=True)
    assert result.returncode==0,'Cannot create local Android signing key'

for folder in [windows,android]:
    for name in ['资料与鸣谢.txt','实物照片_来源与授权.md','实物照片目录.json']:
        import shutil
        shutil.copy2(root/previous/name,root/folder/name)
source=(root/'tools/export_courtyard_edge_release.ps1').read_text(encoding='utf-8-sig')
(root/'tools/export_opening_film_release.ps1').write_text(source.replace(previous,windows).replace("date='2026-10-20'","date='2026-10-21'"),encoding='utf-8-sig')
original=root/'references/opening-film/用户剧情原片_2026-10-21.mp4'
film=root/'assets/video/opening_story.ogv'
manifest={'source':'D:/10月21日 (1).mp4','provided_by':'user','source_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'source_seconds':36.99,'source_resolution':[2592,1440],'runtime_resolution':[1296,720],'runtime_fps':30,'runtime_codec':'Theora + Vorbis','runtime_sha256':hashlib.sha256(film.read_bytes()).hexdigest(),'runtime_bytes':film.stat().st_size,'playback':'title start -> story -> original card draw -> game; skippable; original dialogue/audio preserved'}
manifest_path=root/'assets/video/SOURCE.json'
# Keep the full five-film manifest when preparing an existing chapter release.
existing=json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
if not existing.get('films'):
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('FILM_AND_ANDROID_RELEASE_PREPARED; signing credentials remain outside exported project')
