"""Original bright bamboo/plucked/chime cues and a raised-key scroll arrangement.

No recordings, external samples, or claim to reproduce a traditional tune.
Run once to generate versioned assets; never overwrites the earlier score.
"""
from pathlib import Path
import json
import numpy as np
import compose_festival_audio as score
from compose_scene_music import RATE, tone

OUT = Path(__file__).resolve().parents[1] / 'assets/audio/folk_cues_20261020'
RNG = np.random.default_rng(20261020)
TAU = 2 * np.pi


def note(frequency, duration, colour='pluck'):
    t = np.arange(round(duration * RATE)) / RATE
    if colour == 'bamboo':
        y = np.sin(TAU * frequency * t) + .35 * np.sin(TAU * frequency * 2.76 * t)
        y *= np.exp(-t * 25)
    elif colour == 'bell':
        y = sum(np.sin(TAU * frequency * ratio * t) * np.exp(-t * (4 + i * 2)) / (i + 1)
                for i, ratio in enumerate([1, 2, 3.01, 4.02]))
    elif colour == 'flute':
        y = np.sin(TAU * frequency * t + .025 * np.sin(TAU * 4.8 * t))
        y += .14 * np.sin(TAU * frequency * 2 * t)
        y *= np.minimum(t / .045, 1) * np.minimum((duration - t) / .09, 1)
    else:
        y = sum(np.sin(TAU * frequency * h * t) * np.exp(-t * (8 + h * 4)) / h ** 1.6 for h in [1, 2, 3, 4])
    y *= np.minimum(t / .003, 1) * np.minimum((duration - t) / .02, 1)
    return y.astype(np.float32)


def phrase(notes, colour='pluck', interval=.07, length=.55):
    y = np.zeros(round(length * RATE), np.float32)
    for i, frequency in enumerate(notes):
        start = round(i * interval * RATE)
        sound = note(frequency, length - start / RATE, colour)
        y[start:start + len(sound)] += sound / max(1, len(notes) ** .5)
    return y


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    cues = {
        'paper': ([880], 'bamboo', .28), 'stone': ([523.25, 1046.5], 'bell', .46),
        'wood': ([783.99], 'bamboo', .25), 'rope': ([659.25, 880], 'pluck', .38),
        'bell': ([1046.5, 1567.98], 'bell', .95), 'fire': ([783.99, 987.77], 'bamboo', .34),
        'water': ([1174.66, 880], 'bell', .38), 'cloth': ([987.77], 'bamboo', .24),
        'page': ([880, 1174.66], 'bamboo', .28), 'success': ([659.25, 783.99, 987.77, 1318.51], 'bell', .80),
        'talk': ([783.99], 'pluck', .16), 'wrong': ([880, 659.25], 'bamboo', .32),
        'button': ([987.77], 'bamboo', .12), 'card_flip': ([1174.66], 'pluck', .17),
        'card_pick': ([783.99, 987.77, 1174.66], 'pluck', .35), 'jump': ([659.25, 987.77], 'pluck', .26),
        'folk_reed': ([659.25], 'flute', .62)}
    results = []
    for key, (frequencies, colour, length) in cues.items():
        signal = phrase(frequencies, colour, min(.07, length / 5), length)
        if key in ['paper', 'cloth', 'page']:
            t = np.arange(len(signal)) / RATE
            noise = RNG.normal(0, .015, len(signal))
            signal += (noise - np.roll(noise, 1)) * np.sin(np.pi * t / length) ** 2
        item = score.save(OUT / f'{key}.wav', signal)
        item.update(kind=key, colour=colour, fundamentals_hz=frequencies)
        results.append(item)
    for key in ['paper', 'wood', 'stone', 'rope', 'fire', 'cloth', 'bell']:
        frequencies, colour, _ = cues[key]
        signal = np.zeros(round(1.2 * RATE), np.float32)
        for i in range(4):
            sound = note(frequencies[i % len(frequencies)], .27, colour)
            start = round(i * .3 * RATE)
            signal[start:start + len(sound)] += sound * (.72 if i % 2 else 1)
        item = score.save(OUT / f'hold_{key}.wav', signal)
        item.update(kind='hold_' + key, colour=colour, fundamentals_hz=frequencies)
        results.append(item)
    # Reorchestrate the established finale motif in E pentatonic (+2 semitones),
    # 126 BPM versus 116, with clean flute response, bright strings and dance pulse.
    score.OUT = OUT
    score.tone = lambda midi, duration, kind: tone(midi + 2, duration, kind)
    score.reed = lambda midi, duration: tone(midi + 2, duration, 'flute')
    track = score.track('finale', '长卷同欢·升调', 126, [0, 1, 2, 3, 4, 5, 3, 0], 4)
    (OUT / 'finale.wav').rename(OUT / 'scroll_festival.wav')
    track.update(file='scroll_festival.wav', transpose_semitones=2, previous_bpm=116)
    for item in results + [track]:
        assert item['peak_dbfs'] < -3 and item['rms_dbfs'] > -35
    manifest = dict(method='Original procedural composition, no external audio samples; folk-inspired timbres, not a traditional recording',
                    generator='tools/compose_clear_folk_audio.py', seed=20261020, effects=results, scroll_track=track)
    (OUT / 'SOURCE.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf8')
    print('CLEAR_FOLK_AUDIO_OK: 24 cues and loops; raised-key E pentatonic 126 BPM scroll arrangement; PCM peaks below -3 dBFS')


if __name__ == '__main__':
    main()
