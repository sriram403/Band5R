# Generates FindingNaresh/audio/rumble_rise.wav: 11 s of a deep rumble that
# swells and dies away, the ground shifting as the Five Roses rise out of the
# sand (design/BESSI.md, E4), with grit and a few low knocks.
# Original, procedurally made (no samples). Run: python tools/gen/rumble.py
import numpy as np, wave
SR = 22050
N = int(SR * 11.0)
rng = np.random.default_rng(5)
t = np.arange(N) / SR
# brown noise, low-passed hard: the ground itself
white = rng.standard_normal(N)
brown = np.cumsum(white)
brown -= np.convolve(brown, np.ones(4000) / 4000, mode="same")     # no drift
spec = np.fft.rfft(brown)
f = np.fft.rfftfreq(N, 1 / SR)
spec *= 1 / (1 + (f / 90.0) ** 4)
low = np.fft.irfft(spec, N)
low /= np.max(np.abs(low))
# a slow, beating tone under it
tone = np.sin(2 * np.pi * 38 * t + 0.6 * np.sin(2 * np.pi * 0.7 * t)) * 0.5 + np.sin(2 * np.pi * 57 * t) * 0.25
# grit: sand pouring, band-passed noise
g = np.fft.rfft(rng.standard_normal(N))
g *= np.exp(-((f - 1400) / 900) ** 2)
grit = np.fft.irfft(g, N)
grit /= np.max(np.abs(grit))
# the swell: up over 4 s, held, down over the last 4
env = np.clip(t / 4.0, 0, 1) ** 1.5 * np.clip((11.0 - t) / 4.0, 0, 1)
out = (low * 0.9 + tone * 0.5) * env + grit * 0.12 * env ** 2
for at in [1.8, 3.9, 5.2, 7.4]:
    n = int(0.5 * SR)
    k = np.arange(n) / SR
    knock = np.sin(2 * np.pi * 45 * k) * np.exp(-k / 0.12)
    i = int(at * SR)
    out[i:i + n] += knock * 0.6
out /= np.max(np.abs(out)) * 1.1
pcm = (out * 32767).astype(np.int16)
with wave.open("FindingNaresh/audio/rumble_rise.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("wrote", len(pcm) / SR, "s")
