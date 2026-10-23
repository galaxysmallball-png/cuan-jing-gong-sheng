from pathlib import Path
root=Path('数媒/cuan-game/tools')
p=root/'verify_local_coop.gd';s=p.read_text(encoding='utf-8').replace('\tawait _dual_hold()\n\tif not court.tablet_placed:', '\tawait _dual_hold()\n\tif court.get("tablet_raising")==true: await _frames(ceili(court.RAISE_SECONDS*60)+5)\n\tif not court.tablet_placed:');p.write_text(s,encoding='utf-8')
p=root/'verify_party_game.gd';s=p.read_text(encoding='utf-8').replace('\tawait _hold()\n\tif not court.tablet_placed:', '\tawait _hold()\n\tif court.get("tablet_raising")==true: await _frames(ceili(court.RAISE_SECONDS*60)+5)\n\tif not court.tablet_placed:');p.write_text(s,encoding='utf-8')
