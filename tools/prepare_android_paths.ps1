$ErrorActionPreference='Stop'
$workspace=(Get-Location).Path
$stage='C:/Users/26845/AppData/Local/Temp/cuan-android-build-20261021'
New-Item -ItemType Directory -Force -Path $stage | Out-Null
foreach($entry in @(@('project','数媒/cuan-game'),@('engine','数媒/.tools/godot/4.7.2'),@('sdk','数媒/.tools/android/sdk'),@('signing','数媒/.tools/android/signing'))){
    $alias=Join-Path $stage $entry[0]
    $target=(Resolve-Path -LiteralPath $entry[1]).Path
    if(-not $target.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar)){throw 'Build target is outside the workspace'}
    if(Test-Path -LiteralPath $alias){
        if((Get-Item -LiteralPath $alias).Target -ne $target){throw ('Unexpected existing build alias: '+$alias)}
    } else {
        New-Item -ItemType Junction -Path $alias -Target $target | Out-Null
    }
}
