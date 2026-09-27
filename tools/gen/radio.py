# Generates FindingNaresh/audio/radio_tune.wav: a seamless 24 s loop of an old
# transistor radio playing softly in an empty beach stall (design/BESSI.md:
# "a radio in one stall plays softly"). A plucked melody on a five-note scale
# (Mohanam: Sa Ri Ga Pa Dha) over a tanpura-like drone, squeezed through a
# small speaker's band (300-3000 Hz), with hiss and the odd crackle.
# Original, procedurally made (no samples). Run: python tools/gen/radio.py
import numpy as np, wave
SR = 22050
SECONDS = 24
N = SR * SECONDS
rng = np.random.default_rng(11)
out = np.zeros(N)
SA = 196.0                                   # G3 as Sa
SCALE = [0, 2, 4, 7, 9, 12, 14, 16]         # semitones: Sa Ri Ga Pa Dha Sa' Ri' Ga'


def add(sig, start):
    idx = (start + np.arange(len(sig))) % N      # wraps round: the loop is seamless
    out[idx] += sig


def pluck(freq, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    env = (1 - np.exp(-t / 0.003)) * np.exp(-t / (dur * 0.28))
    ph = 2 * np.pi * freq * t
    # a bright string: a few decaying harmonics, the upper ones dying first
    s = np.sin(ph) + 0.5 * np.sin(2 * ph) * np.exp(-t / 0.25) + 0.25 * np.sin(3 * ph) * np.exp(-t / 0.12)
    return s * env * amp


# the drone: Sa Pa Sa' Sa, plucked round and round every 2 s
beat = SR * 2
for k in range(SECONDS // 2):
    for j, st in enumerate([7, 12, 12, 0]):
        add(pluck(SA * 0.5 * 2 ** (st / 12), 1.6, 0.18), k * beat + j * beat // 4)

# the melody: a lazy phrase walked up and down the scale, 16 bars of 1.5 s
phrase = [0, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 5, 4, 3, 2, 0, 1, 2, 4, 5, 6, 5, 4, 3, 2, 3, 2, 1, 0, 1, 0, 0]
step = int(0.75 * SR)
for i, deg in enumerate(phrase):
    if i * step >= N:
        break
    f = SA * 2 ** (SCALE[deg] / 12)
    add(pluck(f, 1.1, 0.55 if i % 4 == 0 else 0.4), i * step)
    if i % 8 == 7:                                # a grace note now and then
        add(pluck(f * 2 ** (2 / 12), 0.25, 0.2), i * step + step // 2)

# a small speaker: cut the lows and the highs (circular filters, so it still loops)
spec = np.fft.rfft(out)
freqs = np.fft.rfftfreq(N, 1 / SR)
band = 1 / (1 + (300 / np.maximum(freqs, 1)) ** 4) / (1 + (freqs / 3000) ** 4)
out = np.fft.irfft(spec * band, N)
out /= np.max(np.abs(out))
# hiss and crackle
out += rng.standard_normal(N) * 0.03
for _ in range(40):
    at = rng.integers(0, N)
    n = int(rng.uniform(0.002, 0.01) * SR)
    add(rng.standard_normal(n) * rng.uniform(0.1, 0.35) * np.exp(-np.arange(n) / (n * 0.3)), at)
out /= np.max(np.abs(out)) * 1.2
pcm = (out * 32767).astype(np.int16)
with wave.open("FindingNaresh/audio/radio_tune.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("wrote", len(pcm) / SR, "s")
