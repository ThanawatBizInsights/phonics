# 07 · Level Map 2–12 and Screen Reuse

Every level reuses the same five-stage page (ears → sounds → try → words → sticker) and the same set of screen templates. A level is data, not new screens.

## Screen templates

| ID | Template | Checks (app) | Used for |
|---|---|---|---|
| T1 | Sound Card | — (oral) | New sound, mouth cue, action |
| T2 | Trace | Stroke path | Letter formation, rice-tray toggle |
| T3 | Word Builder | Tile per slot | Build, change one sound, add a letter |
| T4 | Listen & Pick | Tap choice | First/middle/last sound, minimal pairs (vet/wet), one or many |
| T5 | Read-then-reveal | — (oral, grown-up) | Words, phrases, sentences |
| T6 | Sound Boxes | Tap count | Segmenting 2–5 sounds |
| T7 | Sort Cups | Drag to cup | sh/ch/th, vowel houses, s vs z |
| T8 | Grown-up Card | — | Off-screen activity (hunt, tray, tissue, mirror, hopscotch) |
| T9 | Hear-and-find | Tap letter | Review stage |
| T10 | Picture Listen | — | Listening-only words, warm-up |
| T11 | Session Finish + Parent check | — | Stage 5, last page of each level |

## Map

Reading sets below already apply the fixes in `06-curriculum-flags.md`. Tricky words are the source's list plus **a, is** in Level 5 (flag C6/C7). "Listen-only" items are heard and pictured, never shown as reading text.

| Level | New graphemes | Reading set (eligible) | Tricky words | Listen-only | Pages | Page templates (try stage) | Thai-interference focus |
|---|---|---|---|---|---|---|---|
| 1 | s a t p | sat tap pat at | — | sock spoon soap pen pot pillow cat cup hat map | 5 | T10/T8 hunt · T2 · T3 · T4 last · T5 show | Final /t/ /p/ released |
| 2 | i n m d | pin tin sit man mad dad dip it in nap pit | I | — | 5 | T1 mirror m/n · T2 · T6 · T4 mad/mat · T5 "I sit" | Final /d/ voiced; short /i/ |
| 3 | g o c k | dog cot got cap kit pot top can | the, to | goat/coat, sock, back | 5 | T1 gulp · T2 back-writing card · T3 ladder cot→pot · T5 fishing · T5 "to the dog" | Voiced /g/; final /k/ |
| 4 | ck e u r | sock duck peg bed red rug sun cup kick run | no, go | led | 5 | T7 vowel houses · T2 · T4 bed/bad · T4 r (led listen-only) · T11 Milestone 1 | /e/ vs /a/; /r/ vs /l/ |
| 5 | h b f l ff ll ss | hat big bus fan fun leg hill bell kiss off doll | into, he, she, **a, is** | ball, path | **6** | T1 lollipop l · T8 flashlight · T3 doubles · T6 bounce · T5 "he got a big hat", "she is on a bus" · review | Final /l/ ≠ /n/; final /s/ /f/ |
| 6 | review | mixed CVC: red bus, big dog, a red bug in a hot pot | we, me, be | — | **4** | T6 sandwich · T2 dictation · T5 silly sentence · T8 treasure hunt + show | All final sounds |
| 7 | j v w x | jam jet van vet web wet box fox six | was, my | vine/wine, vest/west | 5 | T1 v vs w · T2 · T4 vet/wet · T8 box game · T5 "my jam" | /v/ ≠ /w/; final /ks/ |
| 8 | y z zz qu | yes yet zip zap buzz fizz quiz quick quit | you, they | sue/zoo | 5 | T7 bee/snake · T2 · T3 · T4 sip/zip · T11 Milestone 2 | /z/ buzz; final /z/ (aim: awareness) |
| 9 | sh ch th | ship shop fish chip chin much thin this **moth with** | all, are | ball, have, chips | **6** | T1 shh vs ch · T1 th tongue · T7 sh/ch/th cups · T8 fish shop · T5 "all the fish are in the shop" · review | sh ≠ ch; th (/θ/, /ð/ tracked separately) |
| 10 | ng nk, plural -s (/s/, /z/) | ring sing king pink bank sink cats dogs hens pens | her, said | bananas, spoons, pegs | 5 | T1 ring · T4 one/many · T3 add s · T8 counting hunt · T5 "she said the kings sing" | Keep plural /s/ /z/ |
| 11 | blends st sp sn sl fl pl cl fr tr gr | stop spot snap **slip** flag plum clap frog trip grin | have, like | — | **6** | T1 glue pegs · T2 squish · T3 · T8 hop the blend · T5 "I like to clap", "frogs have legs" · review | No extra vowel; keep /r/ |
| 12 | final blends -st -nd -mp -nt -lk | **lost** best hand sand jump lamp tent milk nest | some, come | — | **6** | T2 two-tail · T2 sand · T6 four cups · T8 final hunt · T5 graduation · T11 Final Milestone | Both final sounds |

## How the data drives eligibility

Each level file lists:

```
level: 3
graphemes: [ {g: "g", p: "/g/"}, {g: "o", p: "/ɒ/"}, {g: "c", p: "/k/"}, {g: "k", p: "/k/"} ]
tricky: ["the", "to"]
words:
  - text: "dog"   role: reading    gpcs: [d:/d/, o:/ɒ/, g:/g/]
  - text: "goat"  role: listening  (no gpcs needed)
```

A build-time validator walks every page item and fails the build if a `reading` item uses a grapheme–phoneme pair that isn't in the cumulative taught set for its level, or isn't a tricky word already introduced. Plurals record which phoneme the -s makes. Listening items can't render as text.

## What changes between levels

Only data: letters on the Home button, Sound Card content and mouth cues, tile trays (always the taught letters only, plus 1–2 distractors from earlier levels), word lists, grown-up cards, and the Parent check rows. No new screen types are needed until Level 13 (long vowels), where the Word Builder needs two-letter tiles. Those already exist for ck, ff, ll, ss, zz, qu, sh, ch, th, ng, nk.

Pages per level stay within 4–6: 4 for the review level, 6 where there are more than four new graphemes or two-sound graphemes (th), or a milestone check.
