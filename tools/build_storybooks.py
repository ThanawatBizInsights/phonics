#!/usr/bin/env python3
"""Writes Resources/Content/storybooks.json and Resources/Content/phonics_examples.json.

Storybooks follow Phonics-Pond-Storybook-Wireframe-v2. Level 1 is a ready book;
Levels 2–12 are drafts (story beats + example targets) and stay locked as "coming soon"
until their lines and scenes are written. Every chip and example is checked by
tools/validate_content.py against the curriculum's grapheme–phoneme sequence.
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "PhonicsPond", "PhonicsPond", "Resources", "Content")

def layer(asset, x, width, wobble=True):
    """A scene layer: horizontal centre x and width as fractions of the scene; feet sit on the ground line."""
    return {"asset": asset, "x": x, "width": width, "wobble": wobble}

LEVEL1 = {
    "id": "book.l1", "level": 1, "title": "Pat by the Pond", "status": "ready", "cover": "book_cover_01",
    "cast": ["pat", "puppy"],
    "pages": [
        {"id": "l1.p1", "mode": "tryReading", "line": "Pat sat.", "chips": ["sat"],
         "beat": "Pat sits on a log and looks across the pond.",
         "layers": [layer("pat_sitting_on_log", 0.5, 0.56)], "narration": "story_l1_p1", "hearSounds": "sat"},
        {"id": "l1.p2", "mode": "tryReading", "line": "Tap, tap!", "chips": ["tap"],
         "beat": "Pat taps the log and listens.",
         "layers": [layer("pat_tapping_log", 0.5, 0.56)], "narration": "story_l1_p2", "hearSounds": None},
        {"id": "l1.p3", "mode": "readTogether", "line": "Pat gives the puppy a pat.", "chips": ["pat"],
         "beat": "A golden puppy comes over. Pat gently pats its head.",
         "layers": [layer("pat_patting", 0.5, 0.58)], "narration": "story_l1_p3", "hearSounds": "pat"},
        {"id": "l1.p4", "mode": "readTogether", "line": "Pat taps at the edge of the log.", "chips": ["at", "tap"],
         "beat": "Pat taps the log again and looks toward the water.",
         "layers": [layer("pat_tapping_log", 0.42, 0.52), layer("puppy_sitting", 0.8, 0.22)],
         "narration": "story_l1_p4", "hearSounds": None},
        {"id": "l1.p5", "mode": "readTogether", "line": "Pat sat. The puppy stayed beside him.",
         "chips": ["sat", "pat", "tap"],
         "beat": "Pat sits beside the puppy in the sunset.",
         "layers": [layer("pat_and_puppy_on_log", 0.5, 0.58)], "narration": "story_l1_p5", "hearSounds": None, "sunset": True},
    ],
}

# Levels 2–12: wireframe beats and example targets (drafts, locked until written).
DRAFTS = [
    (2, "Pip Comes to Play", ["Pip arrives", "sits with Pat", "finds a tin", "settles for a nap", "wakes up"],
     ["sit", "pin", "tin", "nap", "mad"]),
    (3, "The Pond Map", ["Pat and Pip find a map", "pick up a cap", "cross a mat", "find a pot", "spot a dog"],
     ["map", "cap", "mat", "pot", "dog"]),
    (4, "Duck Day", ["They spot a duck", "find a sock", "cross to a red peg", "bring a cup", "watch the duck rest"],
     ["duck", "sock", "red", "peg", "cup"]),
    (5, "Fan and Tub", ["Pip finds a fan", "sees the dog by the pot", "cools the dog", "brings a tub", "watches the duck splash"],
     ["fan", "dog", "pot", "tub", "hill"]),
    (6, "Pack a Bag", ["They pack a bag", "spot a red bug", "take a break in the heat", "find a lost cup", "unpack together"],
     ["bag", "red", "bug", "hot", "cup"]),
    (7, "The Rainy Box", ["Rain starts", "a box gets wet", "a fox arrives", "they spot a van", "move the box to shelter"],
     ["jam", "wet", "box", "fox", "van"]),
    (8, "Buzz and Quiz", ["A bee buzzes", "Pip checks a zipper", "Pat finds a quiz card", "they play", "listen for the bee again"],
     ["buzz", "zip", "quiz", "quick", "yes"]),
    (9, "Ship and Fish", ["They see a ship", "spot a fish", "find a chip", "cross a thin board", "point to the ship again"],
     ["ship", "fish", "chip", "thin", "this"]),
    (10, "Ring and Sing", ["A bell rings", "birds sing", "they spot a pink sign", "meet cats", "count the dogs"],
     ["ring", "sing", "pink", "cats", "dogs"]),
    (11, "Frog Spot", ["They stop at a spot", "find a flag", "spot a frog", "clap", "grin at the finish"],
     ["stop", "spot", "flag", "frog", "clap", "grin"]),
    (12, "Camp by the Pond", ["They make a handprint", "cross sand", "jump", "pitch a tent", "have milk at camp"],
     ["hand", "sand", "jump", "tent", "milk"]),
]

def draft_book(level, title, beats, targets):
    chips = [[t] for t in targets[:5]]
    for extra in targets[5:]:
        chips[-1].append(extra)
    pages = [{"id": f"l{level}.p{i+1}", "mode": "readTogether", "line": None, "chips": chips[i],
              "beat": beats[i][0].upper() + beats[i][1:] + ".", "layers": [],
              "narration": f"story_l{level}_p{i+1}", "hearSounds": None} for i in range(5)]
    return {"id": f"book.l{level}", "level": level, "title": title, "status": "draft",
            "cover": f"book_cover_{level:02d}", "cast": ["pat", "pip"], "pages": pages}

def fill_page_defaults(book):
    for p in book["pages"]:
        p.setdefault("required", True)
        p.setdefault("sunset", False)
    return book

books = [fill_page_defaults(LEVEL1)] + [fill_page_defaults(draft_book(*d)) for d in DRAFTS]

# Phonics: sound tiles per level with 2–3 curriculum-checked examples.
cur = json.load(open(os.path.join(CONTENT, "curriculum.json"), encoding="utf-8"))
levels = {L["level"]: L for L in cur["levels"]}

def words_with(grapheme, phoneme, through):
    out = []
    for n in range(1, through + 1):
        for w in levels[n]["words"]:
            if w["role"] == "reading" and any(g["grapheme"] == grapheme and g["phoneme"] == phoneme for g in w["gpcs"]):
                if w["text"] not in out:
                    out.append(w["text"])
    return out

# s has one example: "sat" is the only Level 1 reading word with s ("sap" is left out: no clear meaning picture).
LEVEL1_EXAMPLES = {"s": ["sat"], "a": ["at", "sat"], "t": ["tap", "at"], "p": ["pat", "tap"]}

phonics = []
for n in range(1, 13):
    L = levels[n]
    tiles = []
    if L["graphemes"]:
        for g in L["graphemes"]:
            if n == 1:
                ex = LEVEL1_EXAMPLES[g["grapheme"]]
            else:
                ex = [w for w in words_with(g["grapheme"], g["phoneme"], n) if w in [x["text"] for x in L["words"]]][:3] \
                     or words_with(g["grapheme"], g["phoneme"], n)[:3]
            tiles.append({"id": f"l{n}.{g['grapheme']}.{g['phoneme']}", "grapheme": g["grapheme"], "phoneme": g["phoneme"],
                          "label": g.get("label") or "", "audio": g.get("audio") or f"phoneme_{g['grapheme']}",
                          "examples": ex})
    else:
        # Review and blend levels revisit earlier sounds or show the level's blends.
        if n == 6:
            for v, ph in [("a", "æ"), ("e", "ɛ"), ("i", "ɪ"), ("o", "ɑ"), ("u", "ʌ")]:
                tiles.append({"id": f"l6.{v}.{ph}", "grapheme": v, "phoneme": ph, "label": "review",
                              "audio": "phoneme_short_a" if v == "a" else f"phoneme_{v}",
                              "examples": [w for w in words_with(v, ph, 6) if len(w) == 3][-3:]})
        else:
            blends = ["st", "sp", "sn", "sl", "fl", "pl", "cl", "fr", "tr", "gr"] if n == 11 else ["st", "nd", "mp", "nt", "lk"]
            for b in blends:
                ex = [x["text"] for x in L["words"] if x["role"] == "reading" and
                      (x["text"].startswith(b) if n == 11 else x["text"].endswith(b))][:3]
                tiles.append({"id": f"l{n}.blend.{b}", "grapheme": b if n == 11 else "-" + b, "phoneme": "",
                              "label": "blend", "audio": f"blend_{b}", "examples": ex})
    phonics.append({"level": n, "tiles": tiles})

json.dump({"version": 1, "books": books}, open(os.path.join(CONTENT, "storybooks.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"version": 1, "levels": phonics}, open(os.path.join(CONTENT, "phonics_examples.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
print("books", len(books), "· phonics levels", len(phonics), "· tiles", sum(len(p["tiles"]) for p in phonics))
for p in phonics:
    print(p["level"], [(t["grapheme"], t["examples"]) for t in p["tiles"]])
