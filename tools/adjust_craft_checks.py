from pathlib import Path
root=Path('数媒/cuan-game')
for name in ['verify_folk_stories_cuan.gd','verify_playtest_bundle.gd']:
    p=root/'tools'/name;s=p.read_text(encoding='utf-8')
    # Popup close now follows the user's new flower-and-bird notice art.
    if name=='verify_folk_stories_cuan.gd':
        s=s.replace('ui.satchel.close_button.get_theme_stylebox("normal").texture!=UiSkin.PARCEL_PAPER','ui.satchel.close_button.get_theme_stylebox("normal").texture!=UiSkin.NOTICE_PAPER')
    else:
        s=s.replace('ui.satchel.close_button.get_theme_stylebox("normal").texture!=ui_skin.PARCEL_PAPER','ui.satchel.close_button.get_theme_stylebox("normal").texture!=(ui_skin.NOTICE_PAPER if "NOTICE_PAPER" in ui_skin.get_script_constant_map() else ui_skin.PARCEL_PAPER)')
    p.write_text(s,encoding='utf-8')
