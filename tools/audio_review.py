#!/usr/bin/env python3
"""Objective acoustic checks for Phonics Pond clips (a screen, not a substitute for listening).

For each clip: duration, leading/trailing silence, peak level, voiced/unvoiced segments
(autocorrelation pitch detector, 10 ms frames), and vowel formants (LPC) where useful.

Phonics-specific rules:
  phoneme_s        no voiced frames longer than 40 ms (a pure hiss, no vowel, not "ess")
  phoneme_short_a  one voiced segment, F1 > 650 Hz and F2 > 1600 Hz (front, open /æ/)
  phoneme_t/p      no voiced segment after the burst (no "tuh"/"tee")
  blend_*          exactly one voiced segment (the vowel); nothing voiced around the stops
  word_* ending in t/p/k  unvoiced burst energy in the final 160 ms after the vowel (release)
Usage: audio_review.py <dir with .mp3 or .wav> [--json out.json]
"""
import json, os, subprocess, sys
import numpy as np

SR = 16000
FRAME = 160  # 10 ms

def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0

def frames(x):
    n = len(x) // FRAME
    return x[: n * FRAME].reshape(n, FRAME)

def voicing(x):
    """Per-frame (rms, voiced) using 30 ms windows and normalized autocorrelation in 75–400 Hz."""
    out = []
    win = 480
    for i in range(0, len(x) - win, FRAME):
        w = x[i:i + win] * np.hanning(win)
        rms = np.sqrt(np.mean(w ** 2))
        ac = np.correlate(w, w, "full")[win - 1:]
        if ac[0] <= 0:
            out.append((rms, False)); continue
        ac = ac / ac[0]
        lo, hi = SR // 400, SR // 75
        peak = ac[lo:hi].max()
        zcr = np.mean(np.abs(np.diff(np.sign(w))) > 0)
        out.append((rms, bool(peak > 0.3 and zcr < 0.3 and rms > 0.006)))
    return out

def segments(flags):
    segs, start = [], None
    for i, f in enumerate(flags + [False]):
        if f and start is None: start = i
        if not f and start is not None:
            segs.append((start, i)); start = None
    return [(a * 10, b * 10) for a, b in segs if b - a >= 3]  # ms, ignore <30 ms blips

def formants(x):
    """F1, F2 from LPC on the middle 40 ms of the longest voiced segment (16 kHz, order 12)."""
    w = x * np.hamming(len(x))
    w = np.append(w[0], w[1:] - 0.63 * w[:-1])
    order = 12
    r = np.correlate(w, w, "full")[len(w) - 1: len(w) + order]
    a = np.zeros(order + 1); a[0] = 1; e = r[0]
    for i in range(1, order + 1):  # Levinson–Durbin
        k = -(r[i] + np.dot(a[1:i], r[i - 1:0:-1])) / e
        a[1:i + 1] = a[1:i + 1] + k * np.append(a[i - 1:0:-1], 1)
        e *= 1 - k * k
    roots = [z for z in np.roots(a) if np.imag(z) >= 0]
    fr = sorted(f for f, bw in ((np.angle(z) * SR / (2 * np.pi), -SR / np.pi * np.log(abs(z))) for z in roots)
                if 200 < f < 4000 and bw < 400)
    return (fr + [0, 0])[:2]

def analyse(path):
    x = load(path)
    dur = len(x) / SR
    env = np.sqrt(np.mean(frames(x) ** 2, axis=1))
    thr = max(env.max() * 0.03, 0.003)
    active = np.where(env > thr)[0]
    lead = active[0] * 10 if len(active) else 0
    trail = (len(env) - 1 - active[-1]) * 10 if len(active) else 0
    v = voicing(x)
    vsegs = segments([f for _, f in v])
    info = dict(duration_s=round(dur, 3), lead_ms=int(lead), trail_ms=int(trail),
                peak_dbfs=round(20 * np.log10(np.abs(x).max() + 1e-9), 1), voiced_ms=vsegs)
    if vsegs:
        a, b = max(vsegs, key=lambda s: s[1] - s[0])
        mid = (a + b) // 2
        seg = x[int((mid - 20) * SR / 1000): int((mid + 20) * SR / 1000)]
        if len(seg) > 200:
            info["F1_F2"] = [int(f) for f in formants(seg)]
    # final stop release: peak energy after the closure, relative to the loudest frame (vowel)
    db = 20 * np.log10(env + 1e-9)
    vmax = db.max()
    loud = np.where(db > vmax - 15)[0]
    if len(loud):
        after = db[loud[-1] + 1:]
        if len(after) > 2:
            cl = int(np.argmin(after[:25]))
            info["release_db_rel"] = round(float(after[cl:].max() - vmax), 1)
            info["closure_ms"] = cl * 10
    # energy after the last voiced segment (release burst / frication)
    if vsegs:
        end_v = vsegs[-1][1]
        tail = x[int(end_v * SR / 1000):]
        info["post_vowel_energy_db"] = round(20 * np.log10(np.sqrt(np.mean(tail ** 2)) + 1e-9), 1) if len(tail) else -120
        info["post_vowel_ms"] = int(len(tail) / SR * 1000)
    return info

def judge(name, i):
    v = i["voiced_ms"]
    vlen = [b - a for a, b in v]
    problems = []
    if i["peak_dbfs"] > -0.3: problems.append("clipping risk")
    if name == "phoneme_s":
        if any(l > 40 for l in vlen): problems.append(f"voiced portion {vlen} ms (vowel or letter name)")
        if i["duration_s"] < 0.8: problems.append("too short for a sustained /s/")
    elif name == "phoneme_short_a":
        if len(v) != 1: problems.append(f"{len(v)} voiced segments")
        f1, f2 = i.get("F1_F2", [0, 0])
        if not (f1 > 650 and f2 > 1600): problems.append(f"formants F1={f1} F2={f2} not /æ/-like")
    elif name in ("phoneme_t", "phoneme_p"):
        if v: problems.append(f"voiced {vlen} ms after the stop (added vowel / letter name)")
    elif name.startswith("blend_"):
        if len(v) != 1: problems.append(f"{len(v)} voiced segments {v} (expected only the vowel)")
    elif name.startswith("word_") and name[-1] in "tpk":
        if i.get("release_db_rel", -120) < -45:
            problems.append(f"final stop release weak ({i.get('release_db_rel')} dB re vowel)")
    if i["lead_ms"] > 400: problems.append("long leading silence")
    return problems

def main():
    d = sys.argv[1]
    out = {}
    for f in sorted(os.listdir(d)):
        if not f.endswith((".mp3", ".wav")): continue
        name = os.path.splitext(f)[0].replace("cand_", "")
        info = analyse(os.path.join(d, f))
        info["problems"] = judge(name, info)
        out[os.path.splitext(f)[0]] = info
        flag = "OK " if not info["problems"] else "!! "
        print(f"{flag}{os.path.splitext(f)[0]:30} {info['duration_s']:5.2f}s voiced={info['voiced_ms']} "
              f"F={info.get('F1_F2','')} release={info.get('release_db_rel','')}dB "
              f"peak={info['peak_dbfs']} {'; '.join(info['problems'])}")
    if "--json" in sys.argv:
        json.dump(out, open(sys.argv[sys.argv.index("--json") + 1], "w"), indent=1)

if __name__ == "__main__":
    main()
