$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$env:APPDATA=Join-Path $workspace '数媒/.tools/godot/runtime-data'
$projectPath=Join-Path $workspace '数媒/cuan-game'
$release=Join-Path $projectPath 'builds/carried-arrival-2026-10-20'
& './数媒/.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path $projectPath --log-file (Join-Path $release 'export-console.log') --export-release 'Windows Desktop' (Join-Path $release 'CuanParty.exe') *> (Join-Path $release 'export-stdout.log')
if($LASTEXITCODE -ne 0){Get-Content (Join-Path $release 'export-stdout.log') -Tail 14; throw "Export failed"}
& './数媒/.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --main-pack (Join-Path $release 'CuanParty.pck') --audio-driver Dummy --log-file (Join-Path $release 'pck-check.log') --script (Join-Path $projectPath 'tools/verify_playtest_bundle.gd') -- $release *> (Join-Path $release 'pck-stdout.log')
if($LASTEXITCODE -ne 0){Get-Content (Join-Path $release 'pck-check.log') -Tail 16; throw "PCK verification failed"}
$env:CUAN_ACHIEVEMENT_PROFILE=Join-Path $release 'startup-test-profile.json'
$startupLog=Join-Path $release 'startup.log'
$testArgs=@('--headless','--audio-driver','Dummy','--log-file',('"'+$startupLog+'"'),'--quit-after','90')
$process=Start-Process -FilePath (Join-Path $release 'CuanParty.exe') -WorkingDirectory $release -ArgumentList $testArgs -WindowStyle Hidden -PassThru -Wait
@{exit_code=$process.ExitCode;scope='Native Windows executable, offline startup, 90 frames';date='2026-10-20'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $release 'startup-check.json') -Encoding UTF8
if($process.ExitCode -ne 0){throw 'Native startup failed'}
Get-Content (Join-Path $release 'bundle-check.json')
