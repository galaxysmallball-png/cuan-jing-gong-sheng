param([string]$Script,[string]$Log,[string]$Capture='')
$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$env:APPDATA=Join-Path $workspace '数媒/.tools/godot/runtime-data'
$projectPath=Join-Path $workspace '数媒/cuan-game'
$env:CUAN_ACHIEVEMENT_PROFILE=Join-Path $projectPath ('previews/'+$Log+'-profile.json')
$testLog=Join-Path $projectPath ('previews/'+$Log+'.log')
$testArgs=@('--path',('"'+$projectPath+'"'),'--fixed-fps','60','--audio-driver','Dummy','--log-file',('"'+$testLog+'"'),'--script',('res://tools/'+$Script))
if($Capture){$testArgs+=@('--',$Capture)}
$process=Start-Process -FilePath (Join-Path $workspace '数媒/.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe') -ArgumentList $testArgs -WindowStyle Hidden -PassThru -Wait
Get-Content $testLog -Tail 12
if($process.ExitCode -ne 0){throw "$Script failed: $($process.ExitCode)"}
