"""Side-by-side contact sheets: concept board panorama vs in-game capture.

Read-only on the concept art; writes comparison images next to this script's
output folder so the modelling pass can cite concrete framing differences.
"""
import os
from PIL import Image

ROOT = r"C:\Users\26845\Documents\ChatGPT\“爨境，共生”游戏开发，民族交融\数媒\cuan-game"
CONCEPTS = os.path.join(ROOT, "references", "scene-concepts-2026-10-18")
SHOTS = os.path.join(ROOT, "builds", "scene-atmosphere-2026-10-18")
OUT = os.path.join(ROOT, "previews", "scene-compare-2026-10-18")
os.makedirs(OUT, exist_ok=True)

# Panorama crop of each concept board (the upper illustration block).
PANORAMA = (24, 62, 1024, 350)

PAIRS = [
    ("雾廊碑院", "雾廊碑院：古寺遗迹概念设定.png", "第一关_雾廊碑院.png"),
    ("断溪古道", "月下断溪古道概念设定图.png", "第二关_月下古道.png"),
    ("灯火共庭", "第三幕：灯火共庭概念设定板.png", "第三关_灯火共庭.png"),
]

for name, concept_file, shot_file in PAIRS:
    board = Image.open(os.path.join(CONCEPTS, concept_file)).convert("RGB")
    pano = board.crop(PANORAMA)
    shot = Image.open(os.path.join(SHOTS, shot_file)).convert("RGB")
    width = 1280
    pano = pano.resize((width, int(pano.height * width / pano.width)), Image.LANCZOS)
    shot = shot.resize((width, int(shot.height * width / shot.width)), Image.LANCZOS)
    canvas = Image.new("RGB", (width, pano.height + shot.height + 12), (245, 242, 235))
    canvas.paste(pano, (0, 0))
    canvas.paste(shot, (0, pano.height + 12))
    path = os.path.join(OUT, f"{name}_对照.png")
    canvas.save(path)
    print("saved", path, canvas.size)
