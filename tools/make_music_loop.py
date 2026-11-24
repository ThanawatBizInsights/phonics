#!/usr/bin/env python3
"""Builds a seamless background-music loop from a generated track.

Finds a loop point before the source's fade-out where the rhythm and spectrum best match the
opening (onset-envelope correlation + spectral cosine), then crossfades the audio just after the
loop point into the head (equal power), so playback wraps from the end straight back to the start.

Usage: make_music_loop.py SOURCE OUT_WAV PREVIEW_WAV [min_s max_s crossfade_s [target_lufs]]
The loop length is a multiple of 64 samples (whole IMA4 packets, so a CAF encode adds no padding),
and loudness is set with one exact gain (no time-shifting filters).
Prints seam measurements; never claims the result sounds right (a person must listen).
"""
import subprocess, sys, wave
import numpy as np

src, out, preview = sys.argv[1:4]
lo, hi, xf = (float(v) for v in (sys.argv[4:7] if len(sys.argv) >= 7 else (40, 46, 2.0)))
target_lufs = float(sys.argv[7]) if len(sys.argv) >= 8 else -23.0
sr = 48000
raw = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-ac", "2", "-ar", str(sr), "-f", "s16le", "-"],
                     capture_output=True, check=True).stdout
x = np.frombuffer(raw, dtype=np.int16).astype(np.float64).reshape(-1, 2) / 32768
m = x.mean(1)
hop = 240

def onset(seg):
    fr = seg[:len(seg) // hop * hop].reshape(-1, hop)
    e = np.sqrt((fr ** 2).mean(1)); o = np.maximum(0, np.diff(e))
    return (o - o.mean()) / (o.std() + 1e-9)

def spec(seg):
    s = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))); return s / (np.linalg.norm(s) + 1e-9)

def rms(a): return 20 * np.log10(np.sqrt(np.mean(a ** 2)) + 1e-9)

# Fade-out guard: the loop point plus crossfade must end before the level drops > 6 dB below the body.
body = np.median([rms(m[i * sr:(i + 1) * sr]) for i in range(len(m) // sr)])
fade_at = next((i for i in range(len(m) // sr) if i > 10 and rms(m[i * sr:(i + 1) * sr]) < body - 6), len(m) // sr)
hi = min(hi, fade_at - xf - 0.05)

W = int(3 * sr); ref_on, ref_sp = onset(m[:W]), spec(m[:W]); best = None
for L in range(int(lo * sr), int(hi * sr), int(0.005 * sr)):
    seg = m[L:L + W]; c_on = float(np.dot(ref_on, onset(seg)) / len(ref_on)); c_sp = float(np.dot(ref_sp, spec(seg)))
    if best is None or c_on + c_sp > best[0]: best = (c_on + c_sp, L, c_on, c_sp)
_, L, c_on, c_sp = best
L = L // 64 * 64
X = int(xf * sr); t = np.linspace(0, np.pi / 2, X)
y = x[:L].copy()
y[:X] = np.sin(t)[:, None] * x[:X] + np.cos(t)[:, None] * x[L:L + X]

# Exact gain to the target loudness (measured by ffmpeg's EBU R128 meter on a 3x repeat).
import json, os, tempfile
tmp = tempfile.mktemp(suffix=".wav")
def _write(name, a):
    a = np.clip(a, -1, 1); f = wave.open(name, "wb"); f.setnchannels(2); f.setsampwidth(2); f.setframerate(sr)
    f.writeframes((a * 32767).astype("<i2").tobytes()); f.close()
_write(tmp, np.concatenate([y, y, y]))
meas = subprocess.run(["ffmpeg", "-hide_banner", "-i", tmp, "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                      capture_output=True, text=True).stderr
os.remove(tmp)
lufs = float(json.loads(meas[meas.rindex("{"):])["input_i"])
y = y * 10 ** ((target_lufs - lufs) / 20)
print(f"loudness {lufs:.1f} -> {target_lufs:.1f} LUFS (gain {target_lufs - lufs:+.1f} dB)")

ring = np.concatenate([y[-4800:], y[:4800]])
seam_step = float(np.abs(np.diff(ring[:, 0])).max()); body_step = float(np.percentile(np.abs(np.diff(y[:, 0])), 99.9))
print(f"source fade-out starts ≈ {fade_at} s; loop point {L / sr:.3f} s; crossfade {xf:.1f} s")
print(f"rhythm match {c_on:.2f}  spectral match {c_sp:.2f}")
print(f"RMS last 1 s {rms(y[-sr:]):.1f} dB, first 1 s {rms(y[:sr]):.1f} dB")
print(f"largest step across seam {seam_step:.4f} vs body 99.9th pct {body_step:.4f} -> {'no click' if seam_step <= body_step * 1.25 else 'CHECK seam'}")

def write(name, a):
    a = np.clip(a, -1, 1); f = wave.open(name, "wb"); f.setnchannels(2); f.setsampwidth(2); f.setframerate(sr)
    f.writeframes((a * 32767).astype("<i2").tobytes()); f.close()

write(out, y)
write(preview, np.concatenate([y[-8 * sr:], y[:8 * sr]]))
print(f"loop length {len(y) / sr:.3f} s -> {out}; seam preview (last 8 s + first 8 s) -> {preview}")
