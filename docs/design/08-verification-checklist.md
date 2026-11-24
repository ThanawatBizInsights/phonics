# 08 · Verification Checklist

Run this before each level ships. Every box needs a name and a date.

## 1 · Word eligibility

- [ ] Every `reading` item's grapheme–phoneme pairs are in the cumulative taught set for its level (validator passes).
- [ ] Every tricky word shown was introduced at or before this level.
- [ ] No reading item uses s = /z/ before Level 8 (no "as", "is", "has", "his" unless taught as tricky).
- [ ] No article "a" in reading text before it's introduced as a tricky word.
- [ ] No capital letters in reading text in Level 1. Names (Pat, Pip) appear only in narration until their letters and capitals are taught.
- [ ] Every `listening` item renders as picture + audio only, never as text.
- [ ] Every reading word has a picture a 6-year-old can recognise and a Thai meaning (for the reveal).
- [ ] Words that differ by accent are checked against the chosen accent (bath, fast, grass, can't).
- [ ] Tile trays contain only taught letters.
- [ ] Every flag in `06-curriculum-flags.md` for this level is closed or explicitly accepted.

## 2 · Pronunciation (per clip, from the manifest)

- [ ] Same voice and accent as every other clip.
- [ ] Phonemes: pure, no added "uh"; continuous sounds (s, m, n, f, l, v, z, sh, th) sustained about 1.5 s; stops (t, p, k, b, d, g) short and crisp.
- [ ] Short vowels short (a ≠ แอ, i ≠ อี).
- [ ] Voiced vs voiceless correct (d vs t, g vs k, z vs s, v vs f), including at the end of words.
- [ ] Final consonants released in every word model.
- [ ] Segmented prompts: even gaps (about 0.5 s), no vowel between sounds.
- [ ] Narration lines that contain a phoneme or target word are human recordings.
- [ ] Every ElevenLabs clip listened to and approved by name.
- [ ] Loudness within spec; no clipping on /p/ and /t/ puffs.
- [ ] Phoneme and word clips signed off by a second reviewer with phonics experience.

## 3 · Audio replay and playback

- [ ] Every audio-dependent screen has the 🔁 button in the same position.
- [ ] Tapping a new sound stops the old one first (test by tapping s, a, t, p fast).
- [ ] No effect or chime plays over a phoneme, segmented prompt or word.
- [ ] Interruption test: start a word, lock the iPad, unlock. Audio stopped, screen unchanged, 🔁 pulses, nothing auto-plays.
- [ ] Call / app-switch test: same result.
- [ ] Whole-word audio is not reachable before the reading attempt (no chip, no picture tap, no 🔁 shortcut).
- [ ] "hear the word" appears after 5 s of no taps or after every letter has been tapped, with no visible timer.
- [ ] Pictures on reading screens appear only after the word is heard. Listening screens show pictures from the start.
- [ ] Narration repeats at most twice automatically.
- [ ] Works with the device at low volume; sound check in setup plays correctly.

## 4 · Child experience

- [ ] Home → today's lesson is one tap for a returning child.
- [ ] All child touch targets at least 88 pt with 24 pt gaps.
- [ ] One instruction per screen, spoken and shown.
- [ ] No timer, score, red ✗ or buzzer anywhere.
- [ ] ✋? help works on every screen and escalates (replay → hint → grown-up tip).
- [ ] ⌂ → "Stop for today?" works on every lesson screen, and resuming returns to the same stage.
- [ ] A full page takes 15 minutes or less including off-screen work (time 3 test sessions).
- [ ] Any page in an open level can be chosen; repeating a page keeps its done mark.

## 5 · Parent progress tracking

- [ ] Parent Area opens only with a 3-second hold.
- [ ] Skills tracked separately: sound recognition, blending, segmenting, letter formation, final-sound clarity.
- [ ] App-checked results (hear-and-find, trace, sound boxes, builder) are shown apart from grown-up marks.
- [ ] Oral skills (saying sounds, blending aloud, final-sound clarity) can only be marked by a grown-up.
- [ ] Marks are "On her own / With help / Not yet" (pronoun from profile; Thai ทำได้เอง / ทำได้เมื่อช่วย / ยังไม่ได้), each dated.
- [ ] Marks survive app restart and device reboot (local storage).
- [ ] "Stay on this page tomorrow" pins ▶ today; "Open level 2" unlocks the next level.
- [ ] Reset needs two confirmations and clears everything.
- [ ] No network calls, accounts, microphone or speech scoring (check with a network monitor).
- [ ] Thai text on, then off: all grown-up text still makes sense in English alone.
