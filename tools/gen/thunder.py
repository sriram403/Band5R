# Generates FindingNaresh/audio/thunder_far.wav: 7 s of distant thunder, a
# soft crack then a long rolling rumble that dies away (E7, the storm over
# the ghat, seen from Bessi). Original, procedurally made (no samples).
# Run: python tools/gen/thunder.py
import numpy as np, wave
SR = 22050
N = int(SR * 7.0)
rng = np.random.default_rng(9)
t = np.arange(N) / SR
f = np.fft.rfftfreq(N, 1 / SR)


def band(lo, hi):
    s = np.fft.rfft(rng.standard_normal(N))
    s *= 1 / (1 + (lo / np.maximum(f, 1)) ** 2) / (1 + (f / hi) ** 4)
    x = np.fft.irfft(s, N)
    return x / np.max(np.abs(x))


crack = band(300, 2500) * np.exp(-np.clip(t - 0.15, 0, None) / 0.18) * (t > 0.15)
roll = band(25, 180)
# the roll: a few swells as the sound comes back off the hills
swell = np.zeros(N)
for at, amp, w in [(0.4, 1.0, 0.9), (1.5, 0.8, 1.2), (2.8, 0.6, 1.4), (4.2, 0.35, 1.6)]:
    swell += amp * np.exp(-((t - at) / w) ** 2)
roll *= swell * np.clip((7.0 - t) / 1.5, 0, 1)
out = crack * 0.35 + roll
out /= np.max(np.abs(out)) * 1.1
pcm = (out * 32767).astype(np.int16)
with wave.open("FindingNaresh/audio/thunder_far.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("wrote", len(pcm) / SR, "s")
