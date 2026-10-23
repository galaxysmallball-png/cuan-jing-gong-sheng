"""A short original reed tone for the court's call-and-response activity."""
import json
from compose_festival_audio import reed, save, SFX

if __name__ == '__main__':
    result = save(SFX / 'folk_reed.wav', reed(74, .62))
    result['method'] = 'Original additive reed synthesis; no traditional recording or sample'
    (SFX / 'FOLK_NOTE_SOURCE.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf8')
    print('FOLK_NOTE_OK')
