"""Problem's sounds (puzzle #6, the ghat), made here (no samples, nothing to credit).

  sniff_1.wav, sniff_2.wav  two or three short wet inhales through a big nose,
                            low and breathy (it crouches at the van and sniffs)
  gasp_1.wav                a player's sharp gasp after holding their breath too long

Run: python tools/gen/problem_sounds.py  (writes FindingNaresh/audio/)
"""
import os
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "FindingNaresh", "audio")
rng = np.random.default_rng(66)


def t_of(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def bandpass(x, lo, hi):
    """Crude band-pass in the frequency domain (fine for one-shot effects)."""
    f = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1.0 / RATE)
    f[(freqs < lo) | (freqs > hi)] = 0.0
    return np.fft.irfft(f, len(x))


def write(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    fade = min(len(x), 400)
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("wrote", name, "%.2f s" % (len(x) / RATE))


def inhale(seconds, lo, hi):
    t = t_of(seconds)
    env = np.sin(np.pi * np.clip(t / seconds, 0, 1)) ** 0.7
    # rising airflow: louder and brighter towards the end of each sniff
    env *= 0.4 + 0.6 * (t / seconds)
    return bandpass(rng.normal(0, 1, len(t)), lo, hi) * env


def sniff(n, gap, lo, hi):
    parts = []
    for k in range(n):
        parts.append(inhale(rng.uniform(0.13, 0.2), lo * rng.uniform(0.9, 1.1), hi))
        parts.append(np.zeros(int(RATE * gap * rng.uniform(0.8, 1.2))))
    return np.concatenate(parts)


def gasp():
    t = t_of(0.55)
    env = np.exp(-((t - 0.12) / 0.09) ** 2) + 0.35 * np.exp(-((t - 0.3) / 0.12) ** 2)
    breath = bandpass(rng.normal(0, 1, len(t)), 500, 4500) * env
    # a little voice in it: a short rising vowel
    voice = np.sin(2 * np.pi * (220 + 180 * t) * t) * np.exp(-((t - 0.12) / 0.07) ** 2) * 0.35
    return breath + voice


if __name__ == "__main__":
    write("sniff_1.wav", sniff(3, 0.08, 250, 2200))
    write("sniff_2.wav", sniff(2, 0.12, 200, 1800))
    write("gasp_1.wav", gasp())
