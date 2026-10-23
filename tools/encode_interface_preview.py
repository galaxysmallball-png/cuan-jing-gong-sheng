"""Encode actual GPU frames captured while the Godot window stays minimized."""
from pathlib import Path
import json
import bpy

project = Path(__file__).resolve().parents[1]
report = json.loads((project / 'previews/interface-movie-frames.json').read_text(encoding='utf8'))
frames = [project / 'previews/interface-movie-frames' / f'frame-{i:04}.jpg' for i in range(report['frames'])]
assert len(frames) >= 240 and all(path.exists() for path in frames)
scene = bpy.context.scene
scene.render.fps = 30
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.use_sequencer = True
editor = scene.sequence_editor_create()
strip = editor.strips.new_image('Godot水墨抽牌实机', str(frames[0]), channel=1, frame_start=1)
for path in frames[1:]: strip.elements.append(path.name)
strip.frame_final_duration = len(frames)
scene.frame_start = 1
scene.frame_end = len(frames)
scene.render.image_settings.media_type = 'VIDEO'
scene.render.image_settings.file_format = 'FFMPEG'
scene.render.ffmpeg.format = 'MPEG4'
scene.render.ffmpeg.codec = 'H264'
scene.render.ffmpeg.audio_codec = 'NONE'
scene.render.ffmpeg.constant_rate_factor = 'MEDIUM'
scene.render.ffmpeg.ffmpeg_preset = 'GOOD'
output = project / 'previews/入场抽牌演示.mp4'
scene.render.filepath = str(output)
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1
bpy.ops.render.render(animation=True)
assert output.exists() and output.stat().st_size > 100000
report.update({'format': 'H.264 / MP4', 'seconds': report['frames'] / 30, 'bytes': output.stat().st_size})
(project / 'previews/opening-draw-movie-validation.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print('INTERFACE_MOVIE_MP4_OK', json.dumps(report))
