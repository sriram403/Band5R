# Generates FindingNaresh/audio/pour_glug.wav: a seamless 2 s loop of liquid
# glugging out of a can (bubbles rising through the spout over a soft stream).
# Original, procedurally made (no samples). Run: python tools/gen/glug.py
import numpy as np, wave
SR = 44100
N = SR * 2
rng = np.random.default_rng(7)
out = np.zeros(N)
# soft stream: band-limited noise, made circular by generating 3 loops and taking the middle
noise = rng.standard_normal(N * 3)
k = np.exp(-np.arange(64) / 10.0); k /= k.sum()
lo = np.convolve(noise, k, mode="same")
hi = lo - np.convolve(lo, np.ones(400) / 400, mode="same")
stream = hi[N:2 * N]
out += stream * 0.35
# bubbles: rising, decaying tones placed around the loop (wrapping at the end)
t = 0
while t < N:
    f0 = rng.uniform(170, 360)
    dur = rng.uniform(0.035, 0.075)
    n = int(dur * SR)
    tt = np.arange(n) / SR
    f = f0 * (1 + 0.9 * tt / dur)             # the pitch rises as the bubble escapes
    ph = 2 * np.pi * np.cumsum(f) / SR
    env = (1 - np.exp(-tt / 0.004)) * np.exp(-tt / (dur * 0.35))
    b = (np.sin(ph) + 0.35 * np.sin(2.02 * ph)) * env * rng.uniform(0.5, 1.0)
    idx = (t + np.arange(n)) % N
    out[idx] += b
    t += int(rng.uniform(0.055, 0.13) * SR)
out /= np.max(np.abs(out)) * 1.15
pcm = (out * 32767).astype(np.int16)
with wave.open("FindingNaresh/audio/pour_glug.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("wrote", len(pcm) / SR, "s")
