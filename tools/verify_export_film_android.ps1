$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$projectPath=Join-Path $workspace '数媒/cuan-game'
$env:APPDATA=Join-Path $workspace '数媒/.tools/godot/runtime-data'
function Assert-GameLog([string]$Path,[string]$Marker){
    $log=Get-Content -LiteralPath $Path -Raw
    if(-not $log.Contains($Marker)){throw ('Missing check marker: '+$Marker)}
    if($log.Contains('SCRIPT ERROR') -or $log.Contains('WARNING:')){throw ('Script error or warning in '+$Path)}
    foreach($line in ($log -split "`n")){
        if($line.Contains('ERROR:') -and -not $line.Contains('ERROR: Failed to read the root certificate store.')){throw ('Engine error in '+$Path+': '+$line)}
    }
}
Assert-GameLog (Join-Path $projectPath 'previews/chapter-films-gpu.log') 'CHAPTER_FILMS_OK'
& './数媒/cuan-game/tools/run_craft_gpu.ps1' -Script 'verify_android_touch.gd' -Log 'android-touch-gpu' -Capture '--touch-preview'
Assert-GameLog (Join-Path $projectPath 'previews/android-touch-gpu.log') 'ANDROID_TOUCH_OK'
& './数媒/cuan-game/tools/run_craft_gpu.ps1' -Script 'verify_local_coop.gd' -Log 'opening-film-coop' -Capture '--capture-coop'
Assert-GameLog (Join-Path $projectPath 'previews/opening-film-coop.log') 'LOCAL_COOP_RENDER_OK'
$env:CUAN_ACHIEVEMENT_PROFILE=Join-Path $projectPath 'previews/opening-film-single-profile.json'
& './数媒/.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path $projectPath --fixed-fps 60 --audio-driver Dummy --log-file (Join-Path $projectPath 'previews/opening-film-single.log') --script res://tools/verify_party_game.gd
if($LASTEXITCODE -ne 0){throw 'Single-player regression failed'}
Assert-GameLog (Join-Path $projectPath 'previews/opening-film-single.log') 'PARTY_GAME_OK'
& './数媒/cuan-game/tools/run_craft_gpu.ps1' -Script 'verify_opening_film.gd' -Log 'opening-film-gpu'
Assert-GameLog (Join-Path $projectPath 'previews/opening-film-gpu.log') 'OPENING_FILM_OK'
& './数媒/cuan-game/tools/export_android_release.ps1'
& './数媒/cuan-game/tools/export_opening_film_release.ps1'
Assert-GameLog (Join-Path $projectPath 'builds/opening-film-2026-10-21/pck-check.log') 'PLAYTEST_BUNDLE_OK'
Write-Output 'STORY_AND_ANDROID_EXPORT_CHECKS_OK'
