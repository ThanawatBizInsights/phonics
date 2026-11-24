#!/usr/bin/env python3
"""Checks that can run without Xcode.

1. Curriculum: every reading word's graphemes spell it and are taught at or before its level;
   every sentence token is a readable word or an introduced tricky word.
2. Level 1 lesson: every reading target and letter on screen is taught; listening words exist.
3. Audio: the IDs the build can play (Swift Prompt/Effect enums + clips derived from lesson data)
   match docs/design/level-1-audio-manifest.csv exactly, with no duplicates.
4. Artwork: every image the lesson data references exists in the asset catalog or is listed as needed.

Exit code 1 on any problem.
"""
import csv, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "PhonicsPond", "PhonicsPond")
problems = []

cur = json.load(open(os.path.join(APP, "Resources", "Content", "curriculum.json"), encoding="utf-8"))
plan = json.load(open(os.path.join(APP, "Resources", "Content", "lesson_level1.json"), encoding="utf-8"))
levels = sorted(cur["levels"], key=lambda L: L["level"])

def taught(n):
    return {(g["grapheme"], g["phoneme"]) for L in levels if L["level"] <= n for g in L["graphemes"]}

def tricky(n):
    return {t["word"].lower() for L in levels if L["level"] <= n for t in L["tricky"]}

def word(text, n):
    for L in reversed([L for L in levels if L["level"] <= n]):
        for w in L["words"]:
            if w["text"] == text:
                return w
    return None

def readable(text, n):
    if text.lower() in tricky(n):
        return True
    w = word(text, n)
    if not w or w["role"] != "reading" or not w["gpcs"]:
        return False
    gp = [(g["grapheme"], g["phoneme"]) for g in w["gpcs"]]
    return "".join(g for g, _ in gp) == text and all(x in taught(n) for x in gp)

# 1. Curriculum
for L in levels:
    n = L["level"]
    for w in L["words"]:
        if w["role"] == "reading" and not readable(w["text"], n):
            problems.append(f"L{n}: reading word '{w['text']}' uses untaught correspondences")
    for s in L["sentences"]:
        for tok in [t for t in re.split(r"[^a-z]+", s.lower()) if t]:
            if not readable(tok, n):
                problems.append(f"L{n}: sentence '{s}': '{tok}' not readable yet")
    graph_dupes = [g["grapheme"] + g["phoneme"] for g in L["graphemes"]]
    if len(graph_dupes) != len(set(graph_dupes)):
        problems.append(f"L{n}: duplicate grapheme entries")

l5 = next(L for L in levels if L["level"] == 5)
for w in ("a", "is"):
    if w not in [t["word"] for t in l5["tricky"]]:
        problems.append(f"L5 is missing tricky word '{w}'")
if "a" in tricky(4):
    problems.append("tricky 'a' appears before Level 5")

# 2. Lesson plan
n = plan["level"]
letters_taught = {g for g, _ in taught(n)}
reading_shown, listening_used, words_audio, blends = set(), set(), [], []
for page in plan["pages"]:
    stones = [s["stone"] for s in page["stages"]]
    if stones != ["ears", "sounds", "try", "words", "sticker"]:
        problems.append(f"page {page['page']}: stones out of order {stones}")
    for st in page["stages"]:
        a = st["activity"]; t = a["type"]
        reading = []
        if t in ("oralBlend", "readWords", "grownUpCheck"): reading = a["words"]
        if t == "wordBuilder": reading = [a["build"], a["change"]]
        if t == "lastSound": reading = sorted(set(a["rounds"]))
        letters = a.get("letters", []) + a.get("tray", []) + a.get("choices", [])
        for r in reading:
            reading_shown.add(r)
            if not readable(r, n):
                problems.append(f"page {page['page']} {st['stone']}: '{r}' shown for reading but not taught")
        for l in letters:
            if l not in letters_taught:
                problems.append(f"page {page['page']} {st['stone']}: letter '{l}' not taught")
        if t == "pictureTap":
            for w in a["words"]:
                listening_used.add(w)
                e = word(w, n)
                if not e:
                    problems.append(f"page {page['page']}: '{w}' not in word bank")
                elif e["role"] != "listening":
                    problems.append(f"page {page['page']}: picture-tap word '{w}' should be listening-only")
        def addw(w):
            e = word(w, n); i = (e or {}).get("audio") or f"word_{w}"
            if i not in words_audio: words_audio.append(i)
        if t in ("pictureTap", "readWords", "lastSound"):
            for w in a.get("words", a.get("rounds", [])): addw(w)
        if t == "oralBlend":
            for w in a["words"]:
                addw(w); b = "blend_" + "_".join(w)
                if b not in blends: blends.append(b)
        if t == "wordBuilder":
            for w in (a["build"], a["change"]):
                addw(w); b = "blend_" + "_".join(w)
                if b not in blends: blends.append(b)

# 3. Audio IDs: Swift enums + derived clips vs manifest
swift = open(os.path.join(APP, "Core", "AudioIDs.swift"), encoding="utf-8").read()
prompt_block = swift.split("enum Prompt")[1].split("var text")[0]
prompts = re.findall(r'case \w+ = "([a-z_]+)"', prompt_block)
effect_block = swift.split("enum Effect")[1].split("}")[0]
effects = re.findall(r'case \w+ = "([a-z_]+)"', effect_block)
phonemes = [g["audio"] for g in next(L for L in levels if L["level"] == 1)["graphemes"] if g["audio"]]
build_ids = phonemes + words_audio + blends + prompts + effects

# Every Prompt case must have on-screen text
for p in prompts:
    case = re.search(r'case (\w+) = "%s"' % p, prompt_block).group(1)
    if not re.search(r"case \.%s: return \"" % case, swift):
        problems.append(f"Prompt {p} has no text")

manifest_path = os.path.join(ROOT, "docs", "design", "level-1-audio-manifest.csv")
rows = list(csv.DictReader(open(manifest_path, encoding="utf-8")))
mids = [r["audio_id"] for r in rows]
if len(mids) != len(set(mids)):
    problems.append("manifest has duplicate audio IDs")
for r in rows:
    if r["filename"] != r["audio_id"] + ".wav":
        problems.append(f"manifest filename mismatch for {r['audio_id']}")
    if r["status"] != "To record" and not os.path.exists(os.path.join(APP, "Resources", "Audio", r["filename"])):
        problems.append(f"{r['audio_id']} marked '{r['status']}' but file is missing")
    p = re.search(r'case (\w+) = "%s"' % r["audio_id"], prompt_block)
    if p:
        text = re.search(r'case \.%s: return "((?:[^"\\]|\\.)*)"' % p.group(1), swift).group(1).replace('\\"', '"')
        if text != r["line_or_sound"]:
            problems.append(f"manifest line for {r['audio_id']} differs from screen text: {r['line_or_sound']!r} vs {text!r}")
missing_in_manifest = [i for i in build_ids if i not in mids]
unused_in_manifest = [i for i in mids if i not in build_ids]
if missing_in_manifest: problems.append(f"build plays clips not in manifest: {missing_in_manifest}")
if unused_in_manifest: problems.append(f"manifest lists clips the build never plays: {unused_in_manifest}")

# Swift string literals that look like audio IDs must be known
for path, _, files in os.walk(APP):
    for f in files:
        if f.endswith(".swift"):
            for lit in re.findall(r'"((?:phoneme|word|blend|prompt|cue|effect)_[a-z_]+)"', open(os.path.join(path, f), encoding="utf-8").read()):
                if lit not in mids:
                    problems.append(f"{f}: audio literal '{lit}' not in manifest")

# No synthesized audio shipped: everything in Resources/Audio must be a manifest file
audio_dir = os.path.join(APP, "Resources", "Audio")
for f in os.listdir(audio_dir):
    if f.endswith((".wav", ".m4a", ".caf", ".mp3")) and os.path.splitext(f)[0] not in mids:
        problems.append(f"unexpected audio file {f}")
present = [f for f in os.listdir(audio_dir) if f.endswith(".wav")]

# 4. Artwork
assets = {d[:-9] for d in os.listdir(os.path.join(APP, "Resources", "Assets.xcassets")) if d.endswith(".imageset")}
pond = open(os.path.join(APP, "UI", "PondBackground.swift"), encoding="utf-8").read()
required = set(re.findall(r'"([a-z_]+)"', pond.split("static let requiredAssets: [String] = [")[1].split("]")[0]))
required |= set(re.findall(r'static let \w+ = "([a-z_]+)"', pond))
for L in levels:
    for w in L["words"]:
        if w.get("picture") and w["picture"] not in assets and w["picture"] not in required:
            problems.append(f"picture '{w['picture']}' for '{w['text']}' is neither supplied nor listed as needed")
missing_art = sorted(required - assets)

print(f"Curriculum levels: {len(levels)} · Level 1 reading targets on screen: {sorted(reading_shown)}")
print(f"Level 1 listening-only words used: {sorted(listening_used)}")
print(f"Audio clips the build can play: {len(build_ids)} · manifest rows: {len(rows)} · recordings present: {len(present)}")
print(f"Artwork supplied: {sorted(assets)}")
print(f"Artwork still needed (placeholders shown): {missing_art}")
if problems:
    print("\nPROBLEMS:")
    for p in problems: print(" -", p)
    sys.exit(1)
print("\nAll content checks passed.")
