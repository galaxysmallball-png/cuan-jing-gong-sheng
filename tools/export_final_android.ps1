$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$projectPath=Join-Path $workspace '数媒/cuan-game'
$toolsPath=Join-Path $workspace '数媒/.tools'
$release=Join-Path $projectPath 'builds/scroll-guidance-correction-2026-10-22/Android'
$stage='C:/Users/26845/AppData/Local/Temp/cuan-android-build-20261021'
& './数媒/cuan-game/tools/prepare_android_paths.ps1'
$env:APPDATA=Join-Path $toolsPath 'godot/runtime-data'
$env:JAVA_HOME='C:/Program Files/Microsoft/jdk-17.0.16.8-hotspot'
$credentials=Get-Content -LiteralPath (Join-Path $toolsPath 'android/signing/credentials.json') -Raw | ConvertFrom-Json
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH=Join-Path $stage 'signing/cuan-release.jks'
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER=$credentials.alias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=$credentials.password
try {
    $asciiProject=Join-Path $stage 'project'
    & (Join-Path $stage 'engine/Godot_v4.7.2-stable_win64_console.exe') --headless --path $asciiProject --log-file (Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/export-console.log') --export-release 'Android' (Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/CuanJingGongSheng.apk') *> (Join-Path $release 'export-stdout.log')
    if($LASTEXITCODE -ne 0){Get-Content (Join-Path $release 'export-stdout.log') -Tail 20; throw 'Android export failed'}
    $unsigned=Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/video-storage-unsigned.apk'
    $aligned=Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/video-storage-aligned.apk'
    $apk=Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/CuanJingGongSheng.apk'
    & 'C:/Program Files (x86)/Steam/steamapps/common/Blender/5.2/python/bin/python.exe' (Join-Path $projectPath 'tools/store_apk_videos.py') $apk $unsigned *> (Join-Path $release 'video-storage-check.txt')
    if($LASTEXITCODE -ne 0){throw 'Android video storage preparation failed'}
    & (Join-Path $stage 'sdk/build-tools/36.0.0/zipalign.exe') -f -P 16 4 $unsigned $aligned *> (Join-Path $release 'zipalign-build.txt')
    if($LASTEXITCODE -ne 0){throw 'Android video ZIP alignment failed'}
    & (Join-Path $env:JAVA_HOME 'bin/java.exe') -jar (Join-Path $stage 'sdk/build-tools/36.0.0/lib/apksigner.jar') sign --ks $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH --ks-pass 'env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD' --key-pass 'env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD' --ks-key-alias $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER --v1-signing-enabled false --v4-signing-enabled false --out $apk $aligned *> (Join-Path $release 'video-signing-check.txt')
    if($LASTEXITCODE -ne 0){throw 'Android streaming-video APK signing failed'}
    Remove-Item -LiteralPath $unsigned,$aligned -Force
    if(Test-Path -LiteralPath ($apk+'.idsig')){Remove-Item -LiteralPath ($apk+'.idsig') -Force}
    & (Join-Path $env:JAVA_HOME 'bin/java.exe') -jar (Join-Path $stage 'sdk/build-tools/36.0.0/lib/apksigner.jar') verify --verbose --print-certs (Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/CuanJingGongSheng.apk') *> (Join-Path $release 'signature-check.txt')
    if($LASTEXITCODE -ne 0){throw 'Android APK signature verification failed'}
    & (Join-Path $stage 'sdk/build-tools/36.0.0/aapt.exe') dump badging (Join-Path $asciiProject 'builds/scroll-guidance-correction-2026-10-22/Android/CuanJingGongSheng.apk') *> (Join-Path $release 'apk-manifest.txt')
    if($LASTEXITCODE -ne 0){throw 'Android APK manifest verification failed'}
    & (Join-Path $stage 'sdk/build-tools/36.0.0/zipalign.exe') -c -P 16 4 $apk *> (Join-Path $release 'zipalign-check.txt')
    if($LASTEXITCODE -ne 0){throw 'Final Android APK alignment verification failed'}
    Get-Content (Join-Path $release 'apk-manifest.txt') -TotalCount 9
} finally {
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}
