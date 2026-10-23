$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$projectPath=Join-Path $workspace '数媒/cuan-game'
$base=Join-Path $projectPath 'builds/scroll-guidance-correction-2026-10-22'
$android=Join-Path $base 'Android'
$windows=Join-Path $base 'Windows'
$engine=Join-Path $workspace '数媒/.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$python='C:/Program Files (x86)/Steam/steamapps/common/Blender/5.2/python/bin/python.exe'
$env:APPDATA=Join-Path $workspace '数媒/.tools/godot/runtime-data'
& $python (Join-Path $projectPath 'tools/extract_final_apk.py')
if($LASTEXITCODE -ne 0){throw 'APK resource extraction failed'}
& $engine --headless --path $projectPath --log-file (Join-Path $android 'launcher-check.log') --script res://tools/verify_packaged_launcher.gd -- $android
if($LASTEXITCODE -ne 0){throw 'Packaged icon check failed'}
$env:CUAN_ACHIEVEMENT_PROFILE=Join-Path $android 'touch-test-profile.json'
$testArgs=@('--path',('"'+(Join-Path $projectPath 'previews/scroll-guidance-android-assets-20261022')+'"'),'--fixed-fps','60','--audio-driver','Dummy','--log-file',('"'+(Join-Path $android 'apk-assets-touch-gpu.log')+'"'),'--script',('"'+(Join-Path $projectPath 'tools/verify_shipped_final_touch.gd')+'"'),'--',('"'+$android+'"'),'--touch-preview')
$process=Start-Process -FilePath $engine -ArgumentList $testArgs -WindowStyle Hidden -PassThru -Wait
if($process.ExitCode -ne 0){Get-Content (Join-Path $android 'apk-assets-touch-gpu.log') -Tail 14; throw 'APK resource touch checks failed'}
Get-Content (Join-Path $android 'apk-assets-touch-gpu.log') -Tail 3
$env:CUAN_ACHIEVEMENT_PROFILE=Join-Path $windows 'shipped-test-profile.json'
$testArgs=@('--main-pack',('"'+(Join-Path $windows 'CuanParty.pck')+'"'),'--fixed-fps','60','--audio-driver','Dummy','--log-file',('"'+(Join-Path $windows 'shipped-final-rewards-gpu.log')+'"'),'--script',('"'+(Join-Path $projectPath 'tools/verify_shipped_final_rewards.gd')+'"'),'--',('"'+$windows+'"'))
$process=Start-Process -FilePath $engine -ArgumentList $testArgs -WindowStyle Hidden -PassThru -Wait
if($process.ExitCode -ne 0){Get-Content (Join-Path $windows 'shipped-final-rewards-gpu.log') -Tail 14; throw 'Windows reward checks failed'}
Get-Content (Join-Path $windows 'shipped-final-rewards-gpu.log') -Tail 3
& $python (Join-Path $projectPath 'tools/seal_final_dual_release.py')
if($LASTEXITCODE -ne 0){throw 'Final package sealing failed'}
