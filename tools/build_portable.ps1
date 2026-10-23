param([Parameter(Mandatory=$true)][string]$GodotExe,[ValidateSet('Android','Windows')][string]$Platform='Android',[switch]$DebugBuild)
$ErrorActionPreference='Stop'
$project=Split-Path -Parent $PSScriptRoot
$folder=Join-Path $project ('builds/'+$Platform)
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$preset=if($Platform -eq 'Android'){'Android'}else{'Windows Desktop'}
$output=Join-Path $folder $(if($Platform -eq 'Android'){'CuanJingGongSheng.apk'}else{'CuanParty.exe'})
$mode=if($DebugBuild){'--export-debug'}else{'--export-release'}
& $GodotExe --headless --path $project $mode $preset $output
if($LASTEXITCODE -ne 0){throw 'Godot export failed; check engine templates, SDK paths and signing configuration'}
Write-Output $output
