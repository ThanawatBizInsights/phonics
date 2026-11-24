#!/usr/bin/env python3
"""Builds PhonicsPond/PhonicsPond/Resources/Content/curriculum.json.

The JSON file is the source the app and tests read. This script is only a
convenience for writing it: it segments each reading word into graphemes using
the cumulative inventory, and lets a word override the phoneme of a grapheme
(th voiced/unvoiced, plural s as /s/ or /z/). tools/validate_content.py checks
the result independently.

Accent: General American, cot-caught merged (o in hot/dog/off is always /ɑ/).
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "PhonicsPond", "PhonicsPond", "Resources", "Content", "curriculum.json")

# (grapheme, phoneme, audio id or None, label)
LEVELS = [
 dict(level=1, title="s a t p", playable=True, characters=["Pat"],
      graphemes=[("s","s","phoneme_s","s as in sat"),("a","æ","phoneme_short_a","short a as in sat"),
                 ("t","t","phoneme_t","t as in sat"),("p","p","phoneme_p","p as in pat")],
      tricky=[],
      reading=["sat","tap","pat","at"],
      listening=["sock","pen","pot","spoon","soap","pillow"],
      sentences=[], focus="Final /t/ and /p/ are released and heard."),
 dict(level=2, title="i n m d", playable=False, characters=["Pip"],
      graphemes=[("i","ɪ",None,"short i as in sit"),("n","n",None,""),("m","m",None,""),("d","d",None,"")],
      tricky=[("I","")],
      reading=["pin","tin","sit","man","mad","dad","dip","it","in","nap","pit"],
      listening=[], sentences=["I sit.","I nap."], focus="Final /d/ stays voiced. Short /ɪ/ stays short."),
 dict(level=3, title="g o c k", playable=False, characters=[],
      graphemes=[("g","g",None,""),("o","ɑ",None,"short o as in hot (GA)"),("c","k",None,""),("k","k",None,"")],
      tricky=[("the",""),("to","")],
      reading=["dog","cot","got","cap","kit","pot","top","can","on"],
      listening=["goat","coat","sock","back"], sentences=["to the dog","to the pot"],
      focus="Voiced /g/. Final /k/ released."),
 dict(level=4, title="ck e u r", playable=False, characters=[],
      graphemes=[("ck","k",None,""),("e","ɛ",None,"short e as in bed"),("u","ʌ",None,"short u as in cup"),("r","r",None,"")],
      tricky=[("no",""),("go","")],
      reading=["sock","duck","peg","pen","red","rug","sun","cup","kick","run"],
      listening=["led","bed","bad"], sentences=[], focus="/ɛ/ vs /æ/ (pen/pan; bed/bad by ear). /r/ vs /l/."),
 dict(level=5, title="h b f l ff ll ss", playable=False, characters=[],
      graphemes=[("h","h",None,""),("b","b",None,""),("f","f",None,""),("ff","f",None,""),
                 ("l","l",None,""),("ll","l",None,""),("ss","s",None,"")],
      tricky=[("into",""),("he",""),("she",""),
              ("a","Tricky word: the article 'a' (said /ə/). Separate from Level 1 grapheme a = /æ/."),
              ("is","Tricky word: s says /z/ here.")],
      reading=["hat","big","bus","fan","fun","leg","hill","bell","kiss","off","doll"],
      listening=["ball","path"], sentences=["he got a big hat","she is on a bus"],
      focus="Final /l/ is not /n/. Final /s/ and /f/."),
 dict(level=6, title="review", playable=False, characters=[],
      graphemes=[], tricky=[("we",""),("me",""),("be","")],
      reading=["bug","hot"], listening=[],
      sentences=["a red bug in a hot pot","red bus","big dog"], focus="Every final sound."),
 dict(level=7, title="j v w x", playable=False, characters=[],
      graphemes=[("j","dʒ",None,""),("v","v",None,""),("w","w",None,""),("x","ks",None,"")],
      tricky=[("was",""),("my","")],
      reading=["jam","jet","van","vet","web","wet","box","fox","six"],
      listening=["vine","wine","vest","west"], sentences=["my jam","was in a box"],
      focus="/v/ is not /w/. Final /ks/."),
 dict(level=8, title="y z zz qu", playable=False, characters=[],
      graphemes=[("y","j",None,""),("z","z",None,""),("zz","z",None,""),("qu","kw",None,"")],
      tricky=[("you",""),("they","")],
      reading=["yes","yet","zip","zap","buzz","fizz","quiz","quick","quit"],
      listening=["sue","zoo"], sentences=[], focus="/z/ buzzes. Aim for awareness."),
 dict(level=9, title="sh ch th", playable=False, characters=[],
      graphemes=[("sh","ʃ",None,""),("ch","tʃ",None,""),("th","θ",None,"th as in thin"),("th","ð",None,"th as in this")],
      tricky=[("all",""),("are","")],
      reading=["ship","shop","fish","chip","chin","much","thin","this","bath","moth","with"],
      listening=["chips","have"], sentences=["all the fish are in the shop"],
      focus="/ʃ/ is not /tʃ/. th with the tongue showing (/θ/ and /ð/ tracked separately)."),
 dict(level=10, title="ng nk plural s", playable=False, characters=[],
      graphemes=[("ng","ŋ",None,""),("nk","ŋk",None,""),("s","z",None,"plural s as in dogs")],
      tricky=[("her",""),("said","")],
      reading=["ring","sing","king","pink","bank","sink","cats","dogs","hens","pens","kings"],
      listening=["bananas","spoons","pegs"], sentences=["she said the kings sing"],
      focus="Keep plural /s/ and /z/."),
 dict(level=11, title="starting blends", playable=False, characters=[],
      graphemes=[], tricky=[("have",""),("like","")],
      reading=["stop","spot","snap","slip","flag","plum","clap","frog","trip","grin","frogs","legs"],
      listening=[], sentences=["I like to clap.","frogs have legs"],
      focus="No extra vowel inside a blend. Keep the /r/."),
 dict(level=12, title="ending blends", playable=False, characters=[],
      graphemes=[], tricky=[("some",""),("come","")],
      reading=["fast","best","hand","sand","jump","lamp","tent","milk","nest","lost"],
      listening=[], sentences=[], focus="Say both final sounds."),
]

# Per-word phoneme overrides: list of (grapheme, phoneme) in order, used when
# the default phoneme for a grapheme is ambiguous.
OVERRIDES = {
  "this": [("th","ð"),("i","ɪ"),("s","s")],
  "with": [("w","w"),("i","ɪ"),("th","θ")],
  "dogs": [("d","d"),("o","ɑ"),("g","g"),("s","z")],
  "hens": [("h","h"),("e","ɛ"),("n","n"),("s","z")],
  "pens": [("p","p"),("e","ɛ"),("n","n"),("s","z")],
  "kings":[("k","k"),("i","ɪ"),("ng","ŋ"),("s","z")],
  "frogs":[("f","f"),("r","r"),("o","ɑ"),("g","g"),("s","z")],
  "legs": [("l","l"),("e","ɛ"),("g","g"),("s","z")],
}

PICTURES = {"sat":"pat_sitting_log","pat":"pat_patting","tap":"pat_tapping","at":None,
            "sock":"object_sock","pen":"object_pen","pot":"object_pot"}
THAI = {"sat":"นั่ง (แล้ว)","tap":"แตะ, เคาะเบาๆ","pat":"ตบเบาๆ, ลูบ","at":"ที่",
        "sock":"ถุงเท้า","pen":"ปากกา","pot":"หม้อ","spoon":"ช้อน","soap":"สบู่","pillow":"หมอน"}
LEVEL1_AUDIO = {"sat","tap","pat","at","sock","pen","pot"}

def segment(word, inventory):
    graphs = sorted({g for g,_ in inventory}, key=len, reverse=True)
    out, i = [], 0
    while i < len(word):
        for g in graphs:
            if word.startswith(g, i):
                out.append(g); i += len(g); break
        else:
            raise SystemExit(f"cannot segment {word!r} at {word[i:]!r}")
    return out

def main():
    inventory = []  # cumulative (grapheme, phoneme)
    levels = []
    for L in LEVELS:
        inventory += [(g, p) for g, p, _, _ in L["graphemes"]]
        default = {}
        for g, p in inventory:
            default.setdefault(g, p)          # first taught phoneme is the default
        words = []
        for w in L["reading"]:
            if w in OVERRIDES:
                gpcs = OVERRIDES[w]
            else:
                gpcs = [(g, default[g]) for g in segment(w, inventory)]
            words.append(dict(text=w, role="reading",
                              gpcs=[dict(grapheme=g, phoneme=p) for g, p in gpcs],
                              audio=f"word_{w}" if (L["level"] == 1 and w in LEVEL1_AUDIO) else None,
                              picture=PICTURES.get(w) if L["level"] == 1 else None,
                              thai=THAI.get(w) if L["level"] == 1 else None))
        for w in L["listening"]:
            words.append(dict(text=w, role="listening", gpcs=None,
                              audio=f"word_{w}" if (L["level"] == 1 and w in LEVEL1_AUDIO) else None,
                              picture=PICTURES.get(w) if L["level"] == 1 else None,
                              thai=THAI.get(w) if L["level"] == 1 else None))
        levels.append(dict(
            level=L["level"], title=L["title"], playable=L["playable"], characters=L["characters"],
            focus=L["focus"],
            graphemes=[dict(grapheme=g, phoneme=p, audio=a, label=lab) for g, p, a, lab in L["graphemes"]],
            tricky=[dict(word=w, note=n or None) for w, n in L["tricky"]],
            words=words, sentences=L["sentences"]))
    doc = dict(version=1, accent="General American (cot-caught merged: short o is /ɑ/)", levels=levels)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("wrote", os.path.relpath(OUT, ROOT))

if __name__ == "__main__":
    main()
