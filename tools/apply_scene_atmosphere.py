from pathlib import Path

root = Path(__file__).resolve().parents[1]
def replace(file, old, new):
    p = root / file
    text = p.read_text(encoding='utf-8')
    assert old in text, (file, old[:80])
    p.write_text(text.replace(old, new, 1), encoding='utf-8', newline='\n')

p = root / 'scripts/courtyard_art.gd'
t = p.read_text(encoding='utf-8')
a = t.index('\tvar sky :=', t.index('func _build_landscape'))
b = t.index('\tfor index in range(4):', a)
p.write_text(t[:a] + t[b:], encoding='utf-8', newline='\n')

p = root / 'scripts/creek_art.gd'
t = p.read_text(encoding='utf-8')
a = t.index('\t_box(self,', t.index('func _build_horizon'))
b = t.index('\tfor index in range(3):', t.index('add_child(moon)', a))
t = t[:a] + t[b:]
t = t.replace('\tfor x in [-0.2, 5.0, 10.7, 19.8]:\n\t\t_pine(Vector3(x, 0, -3.7), rng.randf_range(4.6, 6.6))\n','')
p.write_text(t, encoding='utf-8', newline='\n')

p = root / 'scripts/garden_art.gd'
t = p.read_text(encoding='utf-8')
a = t.index('\t# Distant trees and blue sky')
b = t.index('\n\nfunc _post', a)
p.write_text(t[:a] + t[b:], encoding='utf-8', newline='\n')

replace('scripts/grand_court.gd', '\tfor layer in range(2):\n\t\tfor index in range(9):', '\tfor layer in range(0):\n\t\tfor index in range(9):')
replace('scripts/world.gd', 'var walk_space: Node3D', 'var walk_space: Node3D\nvar scene_atmosphere: Node3D')
replace('scripts/world.gd', '\twalk_space.setup(self)', '\twalk_space.setup(self)\n\tscene_atmosphere = preload("res://scripts/scene_atmosphere.gd").new()\n\tadd_child(scene_atmosphere)\n\tscene_atmosphere.setup(self)')
