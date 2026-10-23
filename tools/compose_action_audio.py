"""Procedural UI/action Foley and a seamless creek bed; no external recordings."""
import json
import numpy as np
from compose_festival_audio import save, SFX, RATE, TAU

rng = np.random.default_rng(181805)


def sound(kind, duration):
    t = np.arange(round(duration * RATE), dtype=np.float32) / RATE
    noise = rng.normal(0, 1, len(t)).astype(np.float32)
    low = np.convolve(noise, np.ones(65) / 65, mode='same')
    if kind == 'button':
        y = np.sin(TAU * 790 * t) * np.exp(-t * 65) + .5 * low * np.exp(-t * 45)
    elif kind == 'card_flip':
        y = (noise - .75 * np.roll(noise, 1)) * np.sin(np.pi * t / duration) ** 4 * .12
        y += .2 * np.sin(TAU * (500 * t - 220 * t * t)) * np.exp(-t * 20)
    elif kind == 'card_pick':
        y = sum(np.sin(TAU * f * t) / (i + 1) for i, f in enumerate([880, 1320, 1760])) * np.exp(-t * 6)
    elif kind == 'jump':
        y = .16 * noise * np.sin(np.pi * t / duration) ** 2 + np.sin(TAU * (180 * t + 440 * t * t)) * np.exp(-t * 15)
    elif kind == 'stream':
        # Periodic filtered turbulence plus many small, rounded bubble chirps.
        y = .8 * low + .11 * noise
        for _ in range(130):
            start = rng.integers(0, len(t))
            length = rng.integers(round(.035 * RATE), round(.16 * RATE))
            tt = np.arange(length) / RATE
            freq = rng.uniform(450, 1900)
            ripple = np.sin(TAU * (freq * tt - freq * 1.1 * tt * tt)) * np.sin(np.pi * tt / (length / RATE)) ** 2
            np.add.at(y, (np.arange(length) + start) % len(t), ripple * rng.uniform(.025, .09))
        y *= .84 + .10 * np.sin(TAU * t / duration * 3) + .06 * np.sin(TAU * t / duration * 7)
    else:
        material = kind.removeprefix('hold_')
        phase = TAU * t / duration
        envelope = .35 + .65 * np.sin(phase * 3) ** 8
        if material == 'wood': y = envelope * (np.sin(TAU * 420 * t) * .35 + low * .5)
        elif material == 'stone': y = envelope * (low + .15 * np.sin(TAU * 160 * t))
        elif material == 'rope': y = low * (.3 + .7 * np.sin(phase * 5) ** 2) + .1 * np.sin(TAU * 180 * t)
        elif material == 'paper': y = noise * .12 * envelope
        elif material == 'fire': y = noise * .09 + low * .6 * envelope
        elif material == 'bell': y = np.sin(TAU * 920 * t) * envelope * .15 + low * .15
        else: y = low * .5 * envelope
    if kind == 'stream' or kind.startswith('hold_'):
        # Make the wrap continuous without a silent interval.
        edge = min(round(.04 * RATE), len(y) // 4)
        ramp = np.linspace(0, 1, edge)
        blend = y[-edge:] * (1 - ramp) + y[:edge] * ramp
        y = np.concatenate([blend, y[edge:-edge]])
    else:
        y *= np.minimum(t / .004, 1) * np.minimum((duration - t) / .025, 1)
    item = save(SFX / (kind + '.wav'), y)
    item['kind'] = kind
    item['loop'] = kind == 'stream' or kind.startswith('hold_')
    return item


if __name__ == '__main__':
    data = [sound(k, d) for k, d in [('button', .11), ('card_flip', .21), ('card_pick', .65), ('jump', .18), ('stream', 8.0)]]
    data += [sound('hold_' + kind, 1.0) for kind in ['wood', 'stone', 'rope', 'paper', 'fire', 'cloth', 'bell']]
    (SFX / 'ACTION_SOURCE.json').write_text(json.dumps({'method': 'Original procedural Foley, no external recordings or samples', 'effects': data}, ensure_ascii=False, indent=2), encoding='utf8')
    print('ACTION_AUDIO_OK: buttons, orbital card turns/reveal, subtle jumps, seven continuous task textures, seamless creek')
