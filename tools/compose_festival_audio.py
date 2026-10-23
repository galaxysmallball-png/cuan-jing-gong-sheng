"""Original lively folk-inspired score arrangements and material-specific Foley."""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np
from compose_scene_music import tone, percussion, RATE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'
SFX = OUT / 'interactions'
RNG = np.random.default_rng(1810405)
TAU = 2 * np.pi


def save(path, signal):
    signal = np.asarray(signal, dtype=np.float32)
    if signal.ndim == 1: signal = np.column_stack([signal, signal])
    signal -= signal.mean(axis=0)
    signal = np.tanh(signal * .85 / max(.01, float(np.max(np.abs(signal)))))
    with wave.open(str(path), 'wb') as handle:
        handle.setnchannels(2); handle.setsampwidth(2); handle.setframerate(RATE)
        handle.writeframes((signal * 32767).astype('<i2').tobytes())
    return {'file': path.name, 'duration_seconds': len(signal) / RATE, 'sample_rate': RATE, 'channels': 2,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'rms_dbfs': float(20 * np.log10(np.sqrt(np.mean(signal ** 2)))),
            'peak_dbfs': float(20 * np.log10(np.max(np.abs(signal))))}


def reed(note, duration):
    t = np.arange(int(duration * RATE)) / RATE
    f = 440 * 2 ** ((note - 69) / 12)
    phase = TAU * f * (t - .0025 * (1 - np.exp(-t / .06))) + .032 * np.sin(TAU * 5.3 * t)
    y = np.sin(phase) + .25 * np.sin(phase * 2) + .35 * np.sin(phase * 3) + .08 * np.sin(phase * 5)
    envelope = np.minimum(t / .045, 1) * np.minimum((duration - t) / .10, 1)
    return (y * np.maximum(envelope, 0) * (.95 + .05 * np.sin(TAU * 4 * t))).astype(np.float32)


def clack(duration=.14):
    t = np.arange(int(duration * RATE)) / RATE
    return ((np.sin(TAU * 1220 * t) + .42 * np.sin(TAU * 2330 * t)) * np.exp(-t * 55)
            + RNG.normal(0, .16, len(t)) * np.exp(-t * 90)).astype(np.float32)


def track(key, title, bpm, motif, energy):
    beat = 60 / bpm
    frames = round(96 * beat * RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)

    def put(sound, at, gain, pan=0):
        location = (np.arange(len(sound)) + round(at * RATE)) % frames
        np.add.at(mix[:, 0], location, sound * gain * np.sqrt((1 - pan) / 2))
        np.add.at(mix[:, 1], location, sound * gain * np.sqrt((1 + pan) / 2))

    scale = [62, 64, 66, 69, 71, 74, 76, 78, 81]
    for bar in range(24):
        root = [50, 47, 43, 45][(bar // 2) % 4]
        chord = [root, root + 7, root + 12, root + 16]
        for off, chord_id in zip([0, .75, 1.5, 2, 2.75, 3.5], [0, 2, 1, 0, 3, 2]):
            put(tone(chord[chord_id] + 12, beat * 1.1, 'pluck'), (bar * 4 + off) * beat, .135, -.40)
        for off in [.5, 1.5, 2.5, 3.5]:
            put(clack(), (bar * 4 + off) * beat, .07 + .015 * energy, .35)
        for off in [0, 2]: put(percussion(.55), (bar * 4 + off) * beat, .075 + .035 * energy, -.12)
        if energy >= 2:
            for off in [1.25, 3.25]: put(clack(.09), (bar * 4 + off) * beat, .055, -.25)
        if key in ['garden', 'finale'] and bar % 2 == 0:
            put(tone(scale[(bar // 2) % 5] + 12, 2.5, 'bell'), bar * 4 * beat, .065, .5)
        for index, note in enumerate(chord[:3]):
            put(tone(note, beat * 4.15, 'strings'), bar * 4 * beat, .025 + .012 * energy, -.4 + .4 * index)
        if key == 'finale':
            for i, note in enumerate([root + 12, root + 19]):
                put(tone(note, beat * 3.6, 'brass'), bar * 4 * beat, .055, -.35 + .7 * i)
            if bar % 4 == 0: put(percussion(2.0, False), bar * 4 * beat, .26)
    for phrase in range(12):
        for j in range(4):
            note = scale[motif[(phrase * 3 + j) % len(motif)]]
            # Two voices answer each other; short graces animate the reed line.
            at = (phrase * 8 + j * 2) * beat
            if j in [1, 3]: put(reed(note + 2, .065), at - .065, .07, .24)
            lead = reed(note, beat * (1.3 if j < 3 else 1.75)) if phrase % 2 == 0 else tone(note, beat * 1.5, 'flute')
            put(lead, at, .13, -.17 if phrase % 2 == 0 else .20)
            if key == 'finale' and phrase >= 6:
                put(tone(note + 12, beat * 1.7, 'strings'), at, .13, -.25)
    dry = mix.copy()
    for delay, gain in [(.097, .11), (.213, .09), (.371, .06), (.563, .035)]:
        mix[:, 0] += np.roll(dry[:, 1], round(delay * RATE)) * gain
        mix[:, 1] += np.roll(dry[:, 0], round((delay + .013) * RATE)) * gain
    result = save(OUT / f'{key}.wav', mix)
    result.update(title=title, bpm=bpm, arrangement='original pentatonic call-and-response, plucked strings, reed synthesis and wooden dance pulse')
    return result


def effects():
    SFX.mkdir(parents=True, exist_ok=True)
    results = []
    for kind, length in [('paper', .32), ('stone', .40), ('wood', .30), ('rope', .40), ('bell', 1.1),
                         ('fire', .50), ('water', .42), ('cloth', .28), ('page', .38), ('success', .70), ('talk', .15), ('wrong', .25)]:
        t = np.arange(int(length * RATE)) / RATE
        noise = RNG.normal(0, 1, len(t))
        soft = np.convolve(noise, np.ones(17) / 17, mode='same')
        if kind in ['paper', 'cloth', 'page']:
            y = (noise - .82 * np.roll(noise, 1)) * (.15 + .85 * np.sin(np.pi * t / length) ** 2)
            y *= (.22 if kind == 'cloth' else .32) * np.exp(-t * 3)
        elif kind == 'stone': y = .8 * np.sin(TAU * 185 * t) * np.exp(-t * 18) + soft * np.exp(-t * 12)
        elif kind == 'wood': y = (np.sin(TAU * 420 * t) + .42 * np.sin(TAU * 938 * t)) * np.exp(-t * 28)
        elif kind == 'rope': y = soft * (np.sin(TAU * 45 * t) ** 2) * np.sin(np.pi * t / length) + .18 * np.sin(TAU * 175 * t) * np.exp(-t * 7)
        elif kind == 'bell': y = sum(np.sin(TAU * f * t) * np.exp(-t * (3 + i)) / (i + 1) for i, f in enumerate([924, 1385, 2312, 3515]))
        elif kind == 'fire': y = noise * .13 * np.exp(-t * 3) + .35 * soft * np.sin(TAU * 12 * t) ** 8
        elif kind == 'water': y = soft * np.sin(np.pi * t / length) + .1 * np.sin(TAU * (600 * t - 180 * t * t)) * np.exp(-t * 7)
        elif kind == 'success': y = sum(np.sin(TAU * f * t) * np.exp(-np.maximum(0, t - i * .07) * 7) * (t >= i * .07) / 3 for i, f in enumerate([587.33, 739.99, 880]))
        elif kind == 'talk': y = np.sin(TAU * 660 * t) * np.exp(-t * 40)
        else: y = (np.sin(TAU * 196 * t) + .25 * np.sin(TAU * 207 * t)) * np.exp(-t * 15)
        y *= np.minimum(t / .006, 1) * np.minimum((length - t) / .025, 1)
        item = save(SFX / f'{kind}.wav', y)
        item['kind'] = kind
        results.append(item)
    return results


def main():
    tracks = [track('courtyard', '碑院相逢', 96, [0, 2, 3, 1, 2, 5, 3, 0], 1),
              track('creek', '踏歌过溪', 112, [0, 3, 2, 4, 3, 5, 4, 1], 2),
              track('garden', '暖灯对歌', 108, [2, 3, 5, 4, 3, 6, 5, 2], 1),
              track('finale', '万家同欢', 116, [0, 1, 2, 3, 4, 5, 3, 0], 3)]
    sources = [{'title': '云南非物质文化遗产保护网·彝族烟盒舞', 'url': 'https://www.ynich.cn/item/37.html'},
               {'title': '中国非物质文化遗产网·苗族的芦笙舞', 'url': 'https://www.ihchina.cn/news_1_details/11374.html'}]
    data = {'method': 'Original synthesis; regional dance accompaniment inspires orchestration, not a reproduction of traditional repertoire',
            'composer_source': 'tools/compose_festival_audio.py', 'seed': 1810405, 'inspiration_sources': sources, 'tracks': tracks}
    (OUT / 'SOURCE.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf8')
    (SFX / 'SOURCE.json').write_text(json.dumps({'method': 'Original procedural material Foley, no external samples', 'effects': effects()}, ensure_ascii=False, indent=2), encoding='utf8')
    print('FESTIVAL_AUDIO_OK: four new arrangements, twelve distinct material effects')


if __name__ == '__main__': main()
