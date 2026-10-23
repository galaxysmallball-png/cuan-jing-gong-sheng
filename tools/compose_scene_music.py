"""Original deterministic instrumental scores, synthesized without samples.

Render four independently arranged pentatonic cues as seamless PCM loops.
No downloaded recording, model, third-party melody or instrument sample is used.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'
RATE = 32000
RNG = np.random.default_rng(405458)
TAU = 2 * np.pi


def tone(midi, duration, kind):
    n = int(duration * RATE)
    t = np.arange(n, dtype=np.float64) / RATE
    f = 440 * 2 ** ((midi - 69) / 12)
    attack = {'pluck': .009, 'flute': .15, 'strings': .30, 'brass': .12, 'bell': .004}[kind]
    env = np.minimum(t / attack, 1) * np.minimum((duration - t) / min(.5, duration * .25), 1)
    if kind == 'pluck':
        y = sum(np.sin(TAU * f * h * t + .025 * h) * np.exp(-t * (1.1 + h * .65)) / h ** 1.25 for h in range(1, 10))
    elif kind == 'flute':
        phase = TAU * f * t + .027 * np.sin(TAU * 5.2 * t) * np.minimum(t / .8, 1)
        y = np.sin(phase) + .13 * np.sin(2 * phase) + .055 * np.sin(3 * phase)
        y += RNG.normal(0, .009, n) * np.sin(TAU * 1200 * t)
    elif kind == 'strings':
        y = np.zeros(n)
        for cents in [-6, 0, 5]:
            phase = TAU * f * 2 ** (cents / 1200) * t + .015 * np.sin(TAU * 4.7 * t)
            y += sum(np.sin(h * phase) / h ** 1.65 for h in range(1, 9)) / 3
        env *= .82 + .18 * np.sin(np.pi * t / duration)
    elif kind == 'brass':
        phase = TAU * f * t + .011 * np.sin(TAU * 4.2 * t)
        y = sum(np.sin(h * phase) / h ** 1.25 * (1 + .2 * np.sin(np.pi * t / duration)) for h in range(1, 8))
        env *= .8 + .2 * np.sin(np.pi * t / duration)
    else:
        y = sum(np.sin(TAU * f * h * t) * np.exp(-t * (1.1 + h * .2)) / h ** 1.3 for h in [1, 2.01, 2.98, 4.12, 5.3])
    return (y * np.maximum(env, 0)).astype(np.float32)


def percussion(duration, low=True):
    t = np.arange(int(duration * RATE)) / RATE
    if low:
        phase = TAU * (48 * t + 32 * .045 * (1 - np.exp(-t / .045)))
        y = np.sin(phase) * np.exp(-t * 5) + .16 * RNG.normal(0, 1, len(t)) * np.exp(-t * 24)
    else:
        noise = RNG.normal(0, 1, len(t))
        y = (noise - np.roll(noise, 1)) * np.exp(-t * 4) * .16
    return (y * np.minimum(t / .004, 1)).astype(np.float32)


def cue(key, title, bpm, major, energy):
    beat = 60 / bpm
    duration = 64 * beat
    count = round(duration * RATE)
    score = np.zeros((count, 2), dtype=np.float32)

    def put(sound, at, gain, pan=0):
        # Wrap release tails across the loop boundary, preserving continuity.
        values = sound * gain
        loc = (np.arange(len(values)) + round(at * RATE)) % count
        np.add.at(score[:, 0], loc, values * np.sqrt((1 - pan) / 2))
        np.add.at(score[:, 1], loc, values * np.sqrt((1 + pan) / 2))

    scale = [62, 64, 66 if major else 67, 69, 71, 74, 76, 78 if major else 79]
    motifs = {
        'courtyard': [0, 1, 3, 2, 1, 0, 2, 3, 5, 3, 2, 1, 0, 2, 1, 0],
        'creek': [0, 3, 2, 1, 0, 1, 3, 4, 3, 2, 1, 3, 5, 4, 3, 1],
        'garden': [0, 2, 3, 5, 4, 3, 2, 1, 2, 3, 5, 6, 5, 3, 2, 0],
        'finale': [0, 1, 2, 3, 4, 3, 5, 4, 3, 2, 1, 2, 3, 5, 3, 0],
    }
    roots = [50, 47, 43, 45] if not major else [50, 47, 43, 45]
    for bar in range(16):
        root = roots[(bar // 2) % 4]
        chord = [root, root + 7, root + 12, root + (16 if major else 15)]
        growth = 0.82 + .18 * np.sin(np.pi * bar / 16)
        for i, note in enumerate(chord):
            put(tone(note, beat * 4.7, 'strings'), bar * 4 * beat, (.05 + energy * .024) * growth, [-.5, .35, -.2, .55][i])
        for off in range(4 if energy < 2 else 8):
            time = bar * 4 * beat + off * beat * (1 if energy < 2 else .5)
            note = chord[(off + bar) % 4] + 12
            put(tone(note, beat * 2.0, 'pluck'), time, .12 if key != 'finale' else .085, -.35 if off % 2 else .35)
        if key == 'creek':
            for off in [0, 2.5]: put(percussion(.8), (bar * 4 + off) * beat, .16, -.1)
            for off in [1, 3]: put(percussion(.3, False), (bar * 4 + off) * beat, .18, .35)
        if key == 'finale':
            for off in [0, 2]: put(percussion(1.1), (bar * 4 + off) * beat, .28, -.08)
            if bar % 4 == 0: put(percussion(2.5, False), bar * 4 * beat, .35, .15)
            for i, note in enumerate([root + 12, root + 19]):
                put(tone(note, beat * 3.5, 'brass'), bar * 4 * beat, .063 * growth, -.3 + i * .6)
        if key in ['garden', 'finale'] and bar % 2 == 0:
            put(tone(scale[(bar // 2) % 5] + 12, 3.5, 'bell'), (bar * 4 + .05) * beat, .08, -.5)
    for phrase in range(4):
        for i in range(8):
            index = motifs[key][(phrase * 4 + i) % 16]
            note = scale[index] + (12 if key == 'finale' and phrase >= 2 else 0)
            length = [1.6, 1.6, 2.3, 1.2, 1.6, 1.6, 2.0, 2.4][i]
            put(tone(note, length * beat, 'flute' if key != 'finale' else 'strings'), (phrase * 16 + i * 2) * beat, .14 if key != 'finale' else .19, .08)
    dry = score.copy()
    for delay, gain in [(0.113, .12), (.237, .10), (.373, .075), (.539, .055), (.761, .035)]:
        score[:, 0] += np.roll(dry[:, 1], round(delay * RATE)) * gain
        score[:, 1] += np.roll(dry[:, 0], round((delay + .017) * RATE)) * gain
    score -= score.mean(axis=0)
    peak = float(np.max(np.abs(score)))
    score = np.tanh(score * .78 / peak)
    pcm = (score * 32767).astype('<i2')
    target = OUT / f'{key}.wav'
    with wave.open(str(target), 'wb') as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(pcm.tobytes())
    return {'file': target.name, 'title': title, 'bpm': bpm, 'duration_seconds': count / RATE,
            'sample_rate': RATE, 'channels': 2, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
            'rms_dbfs': float(20 * np.log10(np.sqrt(np.mean(score ** 2)))),
            'peak_dbfs': float(20 * np.log10(np.max(np.abs(score)))),
            'loop_seam_delta': float(np.max(np.abs(score[0] - score[-1])))}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    tracks = [cue('courtyard', '碑院听风', 72, False, 0), cue('creek', '断溪同行', 92, False, 2),
              cue('garden', '庭前暖灯', 78, True, 1), cue('finale', '万家共生', 88, True, 3)]
    for track in tracks:
        assert -24 < track['rms_dbfs'] < -8 and track['peak_dbfs'] < -1
    (OUT / 'SOURCE.json').write_text(json.dumps({'method': 'Original deterministic synthesis; no third-party samples or recordings',
        'composer_source': 'tools/compose_scene_music.py', 'seed': 405458, 'tracks': tracks}, ensure_ascii=False, indent=2), encoding='utf8')
    print('SCENE_MUSIC_RENDERED', json.dumps(tracks, ensure_ascii=True))


if __name__ == '__main__': main()
