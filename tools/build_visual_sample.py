"""Source authoring helper. Writes editable Godot scenes, never edits raster images.
Run only when intentionally regenerating the initial sample; subsequent editor edits
to these scenes should be preserved rather than overwritten by this helper.
"""
from pathlib import Path
from math import sin, cos, pi

ROOT = Path(__file__).resolve().parents[1]


def vec(v):
    return 'Vector3(' + ', '.join(f'{x:.6g}' for x in v) + ')'


class Scene:
    def __init__(self, script):
        self.resources = ['[gd_scene format=3]', f'[ext_resource type="Script" path="res://scripts/{script}" id="script"]']
        self.nodes = []

    def resource(self, kind, name, properties):
        self.resources.append(f'[sub_resource type="{kind}" id="{name}"]\n' + '\n'.join(f'{k} = {v}' for k, v in properties.items()))
        return f'SubResource("{name}")'

    def node(self, name, kind, parent=None, position=None, properties=None):
        header = f'[node name="{name}" type="{kind}"'
        if parent is not None:
            header += f' parent="{parent}"'
        header += ']'
        lines = [header]
        if position is not None:
            lines.append('position = ' + vec(position))
        lines.extend(f'{k} = {v}' for k, v in (properties or {}).items())
        self.nodes.append('\n'.join(lines))

    def mesh(self, name, parent, position, size, material, rotation=None, shape='box'):
        props = {'mesh': f'SubResource("{shape}")', 'material_override': material, 'scale': vec(size)}
        if rotation:
            props['rotation_degrees'] = vec(rotation)
        self.node(name, 'MeshInstance3D', parent, position, props)

    def save(self, name):
        (ROOT / 'scenes' / name).write_text('\n\n'.join(self.resources + self.nodes) + '\n', encoding='utf-8')


s = Scene('space01_visual.gd')
s.resources += ['[ext_resource type="Shader" path="res://shaders/weathered_surface.gdshader" id="surface"]', '[ext_resource type="Shader" path="res://shaders/mist_ribbon.gdshader" id="mist"]']
s.resource('BoxMesh', 'box', {'size': vec((1, 1, 1))})
s.resource('QuadMesh', 'quad', {'size': 'Vector2(1, 1)'})


def surface(name, color, pattern=0):
    return s.resource('ShaderMaterial', name, {'shader': 'ExtResource("surface")', 'shader_parameter/base_color': color, 'shader_parameter/pattern': f'{pattern}.0'})


stone = surface('stone', 'Color(0.22, 0.27, 0.27, 1)')
wall = surface('wall', 'Color(0.19, 0.24, 0.25, 1)', 1)
wood = surface('wood', 'Color(0.14, 0.105, 0.075, 1)', 2)
slate = surface('slate', 'Color(0.13, 0.18, 0.20, 1)')
dark = s.resource('StandardMaterial3D', 'dark', {'albedo_color': 'Color(0.025, 0.045, 0.055, 1)', 'roughness': '1.0'})
leaf = s.resource('StandardMaterial3D', 'leaf', {'albedo_color': 'Color(0.12, 0.19, 0.15, 1)', 'roughness': '1.0'})
mist = s.resource('ShaderMaterial', 'fog', {'shader': 'ExtResource("mist")', 'shader_parameter/strength': '0.1'})
s.node('VisualSample', 'Node3D', properties={'script': 'ExtResource("script")'})
for group in ['Paving', 'Masonry', 'Timber', 'DisplayFrames', 'Foreground', 'Growth', 'Mist']:
    s.node(group, 'Node3D', '.')

# Level walking surface: visual paving replaces only the old mesh, not collisions.
for row in range(6):
    for col in range(16):
        x = (col + 0.5) * 1.25
        z = (row + 0.5) * 0.95 - 2.85
        s.mesh(f'Slab{row}_{col}', 'Paving', (x, -0.04, z), (1.22, 0.08, 0.92), stone)
s.mesh('Foundation', 'Paving', (10, -0.5, 0), (20, 0.9, 6), slate)
for i in range(3):
    s.mesh(f'FrontStep{i}', 'Foreground', (10, -0.18 - i * 0.16, 2.9 + i * 0.25), (20.4, 0.2, 0.45), stone)

s.mesh('RearStoneWall', 'Masonry', (10, 2.75, -3.65), (20.4, 5.5, 0.65), wall)
s.mesh('DisplayRecess', 'Masonry', (13.5, 2.1, -3.27), (6.15, 4.15, 0.08), dark)
for i in range(20):
    a = (i + 0.5) * pi / 20
    s.mesh(f'ArchStone{i}', 'Masonry', (13.5 + 3.13 * cos(a), 1.15 + 3.13 * sin(a), -3.15), (0.48, 0.36, 0.42), stone, (0, 0, a * 180 / pi + 90))
for side in [10.37, 16.63]:
    s.mesh(f'ArchFoot{side}', 'Masonry', (side, 0.55, -3.15), (0.38, 1.1, 0.45), stone)

for i, x in enumerate([0.7, 5.8, 10.5, 17.0, 19.7]):
    s.mesh(f'Plinth{i}', 'Timber', (x, 0.18, -2.8), (0.75, 0.36, 0.8), stone)
    s.mesh(f'Post{i}', 'Timber', (x, 2.65, -2.8), (0.36, 4.7, 0.4), wood)
    s.mesh(f'Capital{i}', 'Timber', (x, 4.83, -2.8), (0.9, 0.25, 0.75), wood)
    s.mesh(f'Brace{i}', 'Timber', (x + 0.35, 4.47, -2.8), (0.9, 0.18, 0.2), wood, (0, 0, 45))
s.mesh('MainBeam', 'Timber', (10, 5.0, -2.8), (20.5, 0.35, 0.6), wood)
s.mesh('FrontBeam', 'Foreground', (10, 5.35, 2.7), (20.5, 0.5, 0.55), wood)
s.mesh('LeftForegroundPost', 'Foreground', (0.15, 2.6, 2.65), (0.46, 5.5, 0.6), wood)
for i in range(12):
    s.mesh(f'RoofRib{i}', 'Timber', (i * 1.7, 5.15, -0.05), (0.13, 0.19, 6), wood)
s.mesh('RoofShadow', 'Timber', (10, 5.65, -0.1), (20.5, 0.15, 6.1), slate)

# Window tracery is fictional set dressing, not reconstructed historical architecture.
s.mesh('WindowShadow', 'Masonry', (3.1, 2.85, -3.25), (3.1, 2.6, 0.08), dark)
for i in range(8):
    s.mesh(f'WindowBar{i}', 'Timber', (1.75 + i * 0.38, 2.85, -3.1), (0.055, 2.55, 0.08), wood)
for i in range(4):
    s.mesh(f'WindowRail{i}', 'Timber', (3.1, 1.7 + i * 0.76, -3.05), (3.2, 0.055, 0.1), wood)

for index, (x, height) in enumerate([(12.25, 1.9), (14.75, 2.5)]):
    y = 1.2 if index == 0 else 1.5
    width = 1.1 if index == 0 else 1.35
    s.mesh(f'DisplayBase{index}', 'DisplayFrames', (x, 0.10, -2.35), (width + 0.55, 0.2, 0.85), stone)
    for side in [-1, 1]:
        s.mesh(f'DisplaySide{index}_{side}', 'DisplayFrames', (x + side * (width / 2 + 0.09), y, -2.35), (0.12, height + 0.24, 0.32), wood)
    for side in [-1, 1]:
        s.mesh(f'DisplayRail{index}_{side}', 'DisplayFrames', (x, y + side * (height / 2 + 0.09), -2.35), (width + 0.3, 0.12, 0.32), wood)

for i in range(18):
    x = 7.3 + sin(i * 0.7) * 0.15
    y = 3.0 - i * 0.12
    s.mesh(f'VineStem{i}', 'Growth', (x, y, -3.0), (0.035, 0.18, 0.045), leaf, (0, 0, sin(i) * 25))
    s.mesh(f'VineLeaf{i}', 'Growth', (x + (0.13 if i % 2 else -0.13), y, -2.99), (0.22, 0.1, 0.05), leaf, (0, 0, 35 if i % 2 else -35))
for i in range(14):
    x = 1.0 + i * 1.36
    s.mesh(f'EdgeMoss{i}', 'Growth', (x, 0.02, -2.5), (0.45, 0.055, 0.18), leaf)
for i, (x, y, z, width) in enumerate([(6, 0.3, 1.8, 12), (15, 0.45, 1.4, 10), (10, 0.65, -1.8, 16)]):
    s.mesh(f'Ribbon{i}', 'Mist', (x, y, z), (width, 0.7, 1), mist, shape='quad')
s.node('Moonlight', 'OmniLight3D', '.', (4.8, 3.7, -0.5), {'light_color': 'Color(0.37, 0.57, 0.72, 1)', 'light_energy': '1.5', 'omni_range': '9.0'})
s.save('space01_visual.tscn')

# Original traveler: short mantle, scarf, satchel and wrapped boots; no copied hero.
t = Scene('traveler_visual.gd')
t.resource('BoxMesh', 'box', {'size': vec((1, 1, 1))})
t.resource('CylinderMesh', 'cone', {'top_radius': '0.16', 'bottom_radius': '0.27', 'height': '0.58', 'radial_segments': '10'})
t.resource('CylinderMesh', 'mantle', {'top_radius': '0.16', 'bottom_radius': '0.32', 'height': '0.22', 'radial_segments': '10'})
t.resource('SphereMesh', 'head', {'radius': '0.145', 'height': '0.3', 'radial_segments': '12', 'rings': '6'})
t.resource('SphereMesh', 'hair', {'radius': '0.15', 'height': '0.19', 'radial_segments': '12', 'rings': '6'})
colors = {'coat': 'Color(0.24, 0.36, 0.36, 1)', 'mantle_mat': 'Color(0.52, 0.46, 0.32, 1)', 'skin': 'Color(0.65, 0.49, 0.36, 1)', 'dark': 'Color(0.075, 0.10, 0.11, 1)', 'bag': 'Color(0.31, 0.21, 0.12, 1)', 'scarf_mat': 'Color(0.71, 0.65, 0.48, 1)'}
m = {name: t.resource('StandardMaterial3D', name, {'albedo_color': color, 'roughness': '0.95'}) for name, color in colors.items()}
t.node('TravelerVisual', 'Node3D', position=(0, -0.7, 0), properties={'script': 'ExtResource("script")'})
t.node('Torso', 'MeshInstance3D', '.', (0, 0.68, 0), {'mesh': 'SubResource("cone")', 'material_override': m['coat']})
t.node('Mantle', 'MeshInstance3D', '.', (0, 0.98, 0), {'mesh': 'SubResource("mantle")', 'material_override': m['mantle_mat']})
t.node('Head', 'MeshInstance3D', '.', (0, 1.19, 0), {'mesh': 'SubResource("head")', 'material_override': m['skin']})
t.node('Hair', 'MeshInstance3D', '.', (0, 1.31, 0), {'mesh': 'SubResource("hair")', 'material_override': m['dark']})
t.mesh('Nose', '.', (0.14, 1.19, 0.025), (0.075, 0.065, 0.08), m['skin'])
t.mesh('Eye', '.', (0.065, 1.235, 0.13), (0.017, 0.023, 0.012), m['dark'])
t.node('Scarf', 'Node3D', '.', (0.12, 1.03, 0.17))
t.mesh('Tail', 'Scarf', (0, -0.17, 0), (0.11, 0.32, 0.05), m['scarf_mat'], (0, 0, -12))
t.mesh('Satchel', '.', (-0.1, 0.67, 0.24), (0.25, 0.27, 0.15), m['bag'])
t.mesh('Strap', '.', (0, 0.85, 0.20), (0.055, 0.5, 0.045), m['bag'], (0, 0, -25))
for side, x in [('Left', -0.12), ('Right', 0.12)]:
    t.node(side + 'Leg', 'Node3D', '.', (x, 0.48, 0))
    t.mesh('Leg', side + 'Leg', (0, -0.16, 0), (0.13, 0.32, 0.14), m['coat'])
    t.mesh('Wrap', side + 'Leg', (0, -0.3, 0), (0.15, 0.14, 0.16), m['scarf_mat'])
    t.mesh('Boot', side + 'Leg', (0.025, -0.415, 0), (0.21, 0.13, 0.21), m['dark'])
    t.node(side + 'Arm', 'Node3D', '.', (x * 1.7, 0.98, 0))
    t.mesh('Sleeve', side + 'Arm', (0, -0.15, 0), (0.12, 0.3, 0.13), m['coat'])
    t.mesh('Hand', side + 'Arm', (0, -0.31, 0), (0.1, 0.1, 0.11), m['skin'])
t.save('traveler_visual.tscn')
print('Visual sample source written: editable architecture and original traveler')
