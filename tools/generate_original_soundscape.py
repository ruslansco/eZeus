#!/usr/bin/env python3
"""Original development score and ambience. No recordings, external samples or quotations.

Offline synthesis only; game playback uses WAV streams, never runtime synthesis.
Reproducible seed and source hashes are recorded beside the audio for provenance.
"""
from array import array
import hashlib
import json
import math
from pathlib import Path
import random
import wave

OUT = Path(__file__).resolve().parents[1] / 'godot/assets/audio/original'
RATE = 24000
SECONDS = 48
FRAMES = RATE * SECONDS
TAU = math.tau


def voice(buffer, at, note, duration, gain, flute=False):
    frequency = 440 * 2 ** ((note - 69) / 12)
    for i in range(int(duration * RATE)):
        t = i / RATE
        if flute:
            envelope = min(1, t / .12) * min(1, (duration - t) / .18)
            phase = TAU * frequency * t + .016 * math.sin(TAU * 5.1 * t)
            value = (math.sin(phase) + .10 * math.sin(phase * 2)) * envelope
        else:
            envelope = min(1, t / .008) * math.exp(-3.2 * t) * min(1, (duration - t) / .05)
            phase = TAU * frequency * t
            value = (math.sin(phase) + .36 * math.sin(phase*2) + .12 * math.sin(phase*3)) * envelope
        buffer[(round(at * RATE) + i) % FRAMES] += gain * value


def score():
    sound = array('f', [0]) * FRAMES
    chords = [(50, 53, 57), (55, 59, 62), (48, 52, 55), (53, 57, 60)]
    # Newly composed, sparse Dorian phrases. Empty beats leave room for city sound.
    phrases = [(74, 77, None, 76), (79, None, 77, 74), (72, 76, None, 79), (77, None, 76, 74)]
    beat = .75
    for bar in range(16):
        chord = chords[(bar // 2) % 4]
        for step in range(8):
            voice(sound, bar * 3 + step * beat / 2, chord[step % 3] + 12, 2.0, .08)
        voice(sound, bar * 3, chord[0] - 12, 2.8, .065)
        if bar % 2:
            for i, note in enumerate(phrases[(bar // 2) % 4]):
                if note is not None:
                    voice(sound, bar * 3 + i * beat, note, .64 if i < 3 else 1.4, .048, True)
    return sound


def ambience():
    sound = array('f', [0]) * FRAMES
    rng = random.Random(20261007)
    slow = 0.0
    for i in range(FRAMES):
        t = i / RATE
        slow = .994 * slow + .006 * rng.uniform(-1, 1)
        sound[i] = slow * (.30 + .09 * math.sin(TAU*t/SECONDS))
    # Synthesized birds, individually spaced rather than a continuous chirp bed.
    for at in (3.1, 11.7, 21.3, 34.6, 43.2):
        for j in range(3):
            start = round((at+j*.28)*RATE)
            for i in range(round(.16*RATE)):
                t = i/RATE
                envelope = math.sin(math.pi*t/.16) ** 2
                phase = TAU*(1800*t+2600*t*t)
                sound[(start+i)%FRAMES] += .017*math.sin(phase)*envelope
    # A short, inaudible wind fade keeps both sides of the loop at zero.
    overlap = round(RATE*.04)
    for i in range(overlap):
        weight = i / overlap
        sound[i] *= weight
        sound[-1-i] *= weight
    return sound


def save(name, samples):
    mean = sum(samples) / len(samples)
    peak = max(abs(x-mean) for x in samples)
    scale = min(1, .65/max(peak, .0001))
    pcm = array('h', [round(max(-.99, min(.99, (x-mean)*scale))*32767) for x in samples])
    path = OUT / name
    with wave.open(str(path), 'wb') as file:
        file.setnchannels(1); file.setsampwidth(2); file.setframerate(RATE); file.writeframes(pcm.tobytes())
    rms = math.sqrt(sum((x/32767)**2 for x in pcm)/len(pcm))
    return {'file': name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'seconds': SECONDS, 'rate': RATE,
            'peak': max(abs(x/32767) for x in pcm), 'rms': rms, 'channels': 1}


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    records = [save('settlement.wav', score()), save('countryside.wav', ambience())]
    (OUT/'PROVENANCE.json').write_text(json.dumps({'revision':'original-synth-v1', 'source':'tools/generate_original_soundscape.py',
        'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'external_samples':[],
        'notes':'New development composition and procedural ambience. Listening and final production mastering remain pending.', 'assets':records}, indent=2)+'\n')
    print(json.dumps(records))
