"""The barn maze's sounds (puzzle #3), made here (no samples, nothing to credit).

  bell_1.wav   the farm bell in the courtyard: a bronze strike, long ring
  caw_1..2.wav a crow: a harsh nasal "kraa"
  moo_1.wav    a cow on the other side of the hedge
  sting_1.wav  a jump-scare stab: a dissonant hit with a scrape
  crack_1.wav  rotten boards giving way: a crack and splinters

Run: python tools/gen/maze_sounds.py  (writes FindingNaresh/audio/)
"""
import os
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "FindingNaresh", "audio")
rng = np.random.default_rng(31)


def t_of(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def lowpass(x, k):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


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


def bell():
    # inharmonic partials of a bell (hum, prime, tierce, quint, nominal...)
    t = t_of(4.5)
    base = 392.0
    parts = [(0.5, 1.0, 1.4), (1.0, 0.8, 1.9), (1.19, 0.6, 2.4), (1.5, 0.45, 2.8), (2.0, 0.7, 3.2), (2.5, 0.3, 4.0), (3.0, 0.25, 5.0), (4.2, 0.15, 7.0)]
    x = np.zeros_like(t)
    for ratio, amp, decay in parts:
        f = base * ratio
        x += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * np.exp(-t * decay * 0.6)
    strike = rng.normal(0, 1, len(t)) * np.exp(-t * 60) * 0.5
    write("bell_1.wav", x + strike)


def caw(name, pitch):
    t = t_of(0.45)
    f0 = pitch * (1 + 0.15 * np.sin(2 * np.pi * 3 * t)) * (1 - 0.25 * t)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    saw = 2 * (phase / (2 * np.pi) % 1.0) - 1
    rough = saw * (1 + 0.6 * rng.normal(0, 1, len(t)))
    # a nasal formant: band-pass by two low-passes
    hi = lowpass(rough, 0.5) - lowpass(rough, 0.12)
    env = np.minimum(1, t * 40) * np.exp(-t * 3)
    x = np.concatenate([hi * env, np.zeros(int(RATE * 0.08))])
    t2 = t_of(0.35)
    x2 = hi[: len(t2)] * np.minimum(1, t2 * 40) * np.exp(-t2 * 5)
    write(name, np.concatenate([x, x2]))


def moo():
    t = t_of(1.6)
    f0 = 110 * (1 + 0.25 * np.sin(np.pi * t / 1.6)) - 15 * t
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    x = np.zeros_like(t)
    for h in range(1, 12):
        x += np.sin(h * phase) / h * (1.0 if h < 4 else 0.5)
    x = lowpass(x, 0.08) + 0.3 * lowpass(x, 0.3)
    env = np.minimum(1, t * 6) * np.minimum(1, (1.6 - t) * 4)
    write("moo_1.wav", x * env)


def sting():
    t = t_of(1.4)
    x = np.zeros_like(t)
    for f in (233.1, 246.9, 329.6, 466.2, 493.9):    # a cluster: B-flat, B, E...
        x += np.sin(2 * np.pi * f * t) * np.exp(-t * 2.5)
    scrape = lowpass(rng.normal(0, 1, len(t)), 0.35) * np.exp(-t * 4) * np.sin(2 * np.pi * 7 * t) ** 2
    hit = rng.normal(0, 1, len(t)) * np.exp(-t * 40)
    write("sting_1.wav", x * 0.8 + scrape * 1.5 + hit * 0.8)


def crack():
    t = t_of(0.9)
    x = rng.normal(0, 1, len(t)) * np.exp(-t * 25)
    # splinters: short clicks after the main crack
    for k in range(14):
        at = rng.uniform(0.05, 0.6)
        i = int(at * RATE)
        n = int(RATE * 0.012)
        x[i:i + n] += rng.normal(0, 1, n) * np.exp(-np.arange(n) / (n / 4)) * rng.uniform(0.3, 0.9)
    thud = np.sin(2 * np.pi * 70 * t) * np.exp(-t * 9) * 0.8
    write("crack_1.wav", lowpass(x, 0.55) + thud)


if __name__ == "__main__":
    bell()
    caw("caw_1.wav", 520)
    caw("caw_2.wav", 470)
    moo()
    sting()
    crack()
