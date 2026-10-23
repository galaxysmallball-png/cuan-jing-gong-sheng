"""Decode the delivered MP4 and render sample frames for visual QA."""
import bpy
import json
from pathlib import Path

project=Path(__file__).resolve().parents[1]
scene=bpy.context.scene
scene.render.fps=30
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
editor=scene.sequence_editor_create()
movie=editor.strips.new_movie('DeliveredMP4',str(project/'previews/入场抽牌演示.mp4'),channel=1,frame_start=1)
assert movie.frame_final_duration>=240
scene.render.use_sequencer=True
scene.render.image_settings.media_type='IMAGE'
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'
samples=[70,180,int(movie.frame_final_duration)-35]
for frame in samples:
    scene.frame_set(frame)
    scene.render.filepath=str(project/f'previews/opening-draw-video-{frame:03d}.png')
    bpy.ops.render.render(write_still=True)
report={'decoded':True,'frames':movie.frame_final_duration,'fps':movie.fps,'samples':samples,'width':1280,'height':720}
(project/'previews/opening-draw-video-qa.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('OPENING_DRAW_VIDEO_DECODE_OK',json.dumps(report))
