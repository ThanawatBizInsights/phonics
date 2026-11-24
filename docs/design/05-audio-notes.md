# 05 · Audio Manifest Notes

> **Build 1 update:** for Level 1, `level-1-audio-manifest.csv` replaces the Level 1 rows of `05-audio-manifest.csv`.
> It lists only clips the app actually plays (40), uses the new file names (`phoneme_s.wav`, `word_sat.wav`, `prompt_your_turn.wav`),
> maps each row to the design-phase clip(s) it replaces, and uses **General American** (approved), not the British accent below.
> Design-phase clips not used in this build: ph_s_tile (merged into phoneme_s), seg_tap, seg_at, wd_spoon, wd_soap, wd_pillow,
> wd_cat, wd_cup, wd_hat, wd_map, the per-page intros for pages 2–5 (one "Tap the glowing stone." line instead),
> nar_g_hear_word, nar_g_tap_boxes, nar_g_tap_sound_you_hear, nar_g_tap_again, nar_g_all_done, nar_l1p1_hunt_s/p,
> nar_l1p2_watch, nar_l1p2_tray, nar_l1p3_watch, nar_l1p5_build_at, the UI tap effects and the separate sticker pop.

The manifest itself is `05-audio-manifest.csv` (72 assets for Level 1). Columns: filename, asset type, exact script or phoneme, IPA, delivery notes, playback trigger, pages used, source, review status, reviewer, review date, Thai gloss for adults.

## Voice and accent

- **One voice** for every phoneme, segmented prompt, word and narration line. Warm, clear, adult, unhurried.
- **Accent: Standard Southern British English** (see `06-curriculum-flags.md` section B). Decide before any recording; switching later means re-recording everything.
- Short a in **sat** is /æ/. /t/ and /p/ are aspirated and released. /s/ is sustained with no vowel. Nothing gets an added "uh".
- Final consonants in natural words are fully released (sat, tap, pat, at; cat, cup, hat, map). This is the main Thai-interference target, so the model must exaggerate it slightly without becoming unnatural.

## Asset types and sources

| Type | Prefix | Count (L1) | Source |
|---|---|---|---|
| Isolated phoneme | `ph_` | 5 | Human recording only, each clip reviewed |
| Segmented prompt | `seg_` | 4 | Human recording only, each clip reviewed |
| Whole word (reading) | `wd_` | 4 | Human recording only, each clip reviewed |
| Whole word (listening-only) | `wd_` | 10 | Human recording only, each clip reviewed |
| Narration | `nar_` | 37 | ElevenLabs allowed, except the 5 lines that contain a phoneme or target word (marked in the CSV), which are human |
| Feedback | `fb_` | 6 | ElevenLabs allowed |
| Effects / chime | `sfx_`, `mus_` | 6 | Licensed or made in-house |

If ElevenLabs is used for narration, the voice must be matched to the human actor's accent and timbre, and **every generated clip is listened to** before it gets "approved". TTS is never used for phonemes, segmented prompts or word models.

## Recording spec

- Masters: WAV, 48 kHz, 24-bit, mono, quiet room, pop filter (the /p/ and /t/ puffs must be audible but not clip).
- Delivery: AAC `.m4a`, 48 kHz mono, loudness-normalised (speech -16 LUFS, effects -18 LUFS or quieter).
- Trim: 30 ms of silence before, 80 ms after. No fades that cut the release of a final stop.
- Record 3 takes of each phoneme and word; the reviewer picks one.

## Review status values

`not recorded` → `recorded` → `in review` → `approved` or `redo (reason)`.

Reviewer checks per clip: correct accent, pure sound (no "uh"), final consonant released, no clipping or mouth noise, loudness in range, filename matches the script. Phonemes and words need a second reviewer who teaches phonics.

## Playback rules (for engineering)

1. One speech channel. Starting any speech clip **stops the clip already playing** first, then plays the new one.
2. Effects and the chime never play over a speech clip. A tile-place click is skipped if its phoneme starts within 100 ms.
3. Every clip is replayable: the 🔁 button replays the screen's instruction; tapping any letter, tile, picture or word replays its own clip.
4. Interruption (call, background, lock): stop audio, save state, do not auto-resume. On return, pulse 🔁 and play `nar_g_tap_again` only when the child taps.
5. Narration never plays automatically more than twice on one screen.
6. Device mute switch: the app plays speech regardless (it's the lesson), but respects the volume level. Grown-up setup checks volume.
