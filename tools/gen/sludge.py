"""The water works' sludge sounds, made here (no samples, nothing to credit).

  squelch_1..3.wav  a wet footstep (a covered player's steps)
  gurgle_1.wav      the grey tank filling up: bubbles rising
  groan_1.wav       the full tank straining before it bursts
  splat_1.wav       the burst: a heavy wet slap and the rain of sludge

Run: python tools/gen/sludge.py  (writes FindingNaresh/audio/)
"""
import os
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "FindingNaresh", "audio")
rng = np.random.default_rng(7)


def lowpass(x, k):
    """A cheap one-pole low-pass; k in (0, 1), smaller = darker."""
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def write(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("wrote", name, "%.2f s" % (len(x) / RATE))


def t(sec):
    return np.arange(int(sec * RATE)) / RATE


def squelch(seed):
    r = np.random.default_rng(seed)
    tt = t(0.32)
    noise = lowpass(r.standard_normal(len(tt)), 0.08)
    # a sucking pitch drop under the noise
    f = 260 * np.exp(-tt * 9) + 70
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE)
    env = (1 - np.exp(-tt * 120)) * np.exp(-tt * 13)
    return (noise * 1.4 + tone * 0.6) * env


def bubble(tt, at, f0):
    """One bubble: a short rising blip."""
    d = tt - at
    on = d >= 0
    d = np.where(on, d, 0)
    f = f0 * (1 + d * 14)
    ph = 2 * np.pi * np.cumsum(np.where(on, f, 0)) / RATE
    return np.where(on, np.sin(ph) * np.exp(-d * 40), 0)


def gurgle():
    tt = t(1.4)
    x = np.zeros(len(tt))
    for k in range(26):
        x += bubble(tt, rng.uniform(0, 1.25), rng.uniform(140, 420)) * rng.uniform(0.4, 1.0)
    x += lowpass(rng.standard_normal(len(tt)), 0.02) * 0.6
    return x * np.minimum(1, tt * 8) * np.minimum(1, (1.4 - tt) * 6)


def groan():
    tt = t(2.0)
    # a stressed metal tank: a low wavering tone with grinding noise
    f = 48 + 6 * np.sin(2 * np.pi * 1.7 * tt) + tt * 10
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE)
    tone += 0.4 * np.sin(2 * np.pi * np.cumsum(f * 2.03) / RATE)
    grind = lowpass(rng.standard_normal(len(tt)), 0.05) * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * tt) ** 2)
    env = np.minimum(1, tt * 2.5) * np.minimum(1, (2.0 - tt) * 5)
    return (tone + grind * 0.8) * env


def splat():
    tt = t(2.2)
    slap = lowpass(rng.standard_normal(len(tt)), 0.25) * np.exp(-tt * 18)
    thump = np.sin(2 * np.pi * np.cumsum(90 * np.exp(-tt * 6) + 30) / RATE) * np.exp(-tt * 7)
    # the rain of sludge after it: many small splats thinning out
    rain = np.zeros(len(tt))
    for k in range(90):
        at = 0.15 + rng.exponential(0.45)
        if at < 2.1:
            d = tt - at
            rain += np.where(d >= 0, lowpass(rng.standard_normal(len(tt)), 0.12) * np.exp(-np.maximum(d, 0) * 60), 0) * rng.uniform(0.2, 0.6)
    return slap * 1.6 + thump * 1.2 + rain * 0.5


if __name__ == "__main__":
    for i in range(3):
        write("squelch_%d.wav" % (i + 1), squelch(11 + i))
    write("gurgle_1.wav", gurgle())
    write("groan_1.wav", groan())
    write("splat_1.wav", splat())
