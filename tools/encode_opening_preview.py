"""Encode the native Godot MovieWriter recording with Blender's bundled FFmpeg."""
from pathlib import Path
import bpy
import json

project=Path(__file__).resolve().parents[1]
source=project/'previews/opening-card-draw.avi'
output=project/'previews/入场抽牌演示.mp4'
scene=bpy.context.scene
scene.render.fps=30
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.use_sequencer=True
editor=scene.sequence_editor_create()
movie=editor.strips.new_movie('Godot八牌入场实录',str(source),channel=1,frame_start=1)
scene.frame_start=1
scene.frame_end=movie.frame_final_end-1
scene.render.image_settings.media_type='VIDEO'
scene.render.image_settings.file_format='FFMPEG'
scene.render.ffmpeg.format='MPEG4'
scene.render.ffmpeg.codec='H264'
scene.render.ffmpeg.audio_codec='NONE'
scene.render.ffmpeg.constant_rate_factor='MEDIUM'
scene.render.ffmpeg.ffmpeg_preset='GOOD'
scene.render.filepath=str(output)
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'
scene.view_settings.exposure=0
scene.view_settings.gamma=1
bpy.ops.render.render(animation=True)
assert output.exists() and output.stat().st_size>100000
report={'source':'Godot native MovieWriter, actual game UI','format':'H.264 / MP4','width':1280,'height':720,'fps':30,'frames':scene.frame_end,'seconds':scene.frame_end/30,'bytes':output.stat().st_size}
(project/'previews/opening-draw-movie-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('OPENING_DRAW_MP4_OK',json.dumps(report))
