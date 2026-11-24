#!/usr/bin/env python3
"""Writes docs/design/level-1-audio-manifest.csv: the Level 1 recording list for this build.

It replaces the Level 1 rows of the design-phase manifest (docs/design/05-audio-manifest.csv):
`replaces` names the old clip(s) each row supersedes, so no clip is recorded twice.
tools/validate_content.py checks this list against the Swift code and lesson data.
"""
import csv, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "design", "level-1-audio-manifest.csv")
VOICE = "ElevenLabs · Ava – Clear Warm Educator (Qm3vYqvY6yNUsbo2dIyn) · eleven_multilingual_v2"
READY = "Ready – auto-checked; needs your listening sign-off"
HUMAN = "Needs human recording"

# What happened to each clip in this pass (see docs/audio-review/).
REVIEW = {
  "phoneme_s": (HUMAN, "ElevenLabs candidate kept out: pure hiss but only 0.75 s and quiet; cannot be confirmed as a sustained, uh-free /s/"),
  "phoneme_short_a": (HUMAN, "ElevenLabs candidate kept out: two voiced segments, F1 881 / F2 1522 Hz – not a clean short /æ/"),
  "phoneme_t": (HUMAN, "ElevenLabs candidate kept out: 270 ms of voicing after the burst (\"tee\"/\"tuh\")"),
  "phoneme_p": (HUMAN, "ElevenLabs candidate kept out: 250 ms of voicing after the burst (\"pee\"/\"puh\")"),
  "blend_s_a_t": (HUMAN, "ElevenLabs candidate kept out: voicing around the /t/ (added vowel); short vowel segment"),
  "blend_p_a_t": (HUMAN, "ElevenLabs candidate kept out: three voiced segments (vowels added to /p/ and /t/)"),
  "word_sat": (READY, "Take 3 of 4 (\"sat!\" b). /æ/ F1 1099 / F2 1908 Hz; final /t/ release -34.6 dB re vowel. Take 1 rejected: release -52 dB"),
  "word_tap": (READY, "Take 4 of 4 (\"tap!\" c). /æ/ F1 1207 / F2 1952 Hz; /p/ release -31.9 dB. Take 1 weak release; take 3 added a vowel after /p/"),
  "word_pat": (READY, "Take 1. /æ/ F1 1157 / F2 1855 Hz; aspirated /p/; final /t/ release -32.1 dB"),
  "word_at": (READY, "Take 1. /æ/ F1 1002 / F2 1872 Hz (stressed /æt/); /t/ release -27.2 dB"),
  "word_sock": (READY, "Take 1. Final /k/ release -22.2 dB"),
  "word_pen": (READY, "Take 1. Voiced vowel F1 419 / F2 2011 Hz (/ɛ/ range); nasal ending"),
  "word_pot": (READY, "Take 1. Final /t/ release -32.5 dB after 80 ms closure"),
  "effect_soft_chime": ("Ready – generated tone (not speech)", "Synthesised in tools; peak -14 dBFS"),
}

ROWS = [
 # batch, id, line or sound, clip type, screen, trigger, pronunciation notes, replaces
 ("1 Isolated sounds", "phoneme_s", "/s/", "isolated sound",
  "Sound Card s (P1 P2 P3 P5); review tiles; Word Builder; tracing s; Read the words letters",
  "Tap s letter or hear; tile placed; blend swipe; tracing starts; letter tapped",
  "Gentle sustained hiss, about 1–1.5 s. Teeth together. No vowel before or after. Not the letter name \"ess\".", "ph_s; ph_s_tile"),
 ("1 Isolated sounds", "phoneme_short_a", "/æ/ as in sat", "isolated sound",
  "Sound Card a; review tiles; Word Builder; tracing a; Read the words letters",
  "Tap a letter or hear; tile placed; blend swipe; tracing starts; letter tapped",
  "Short (about 0.3 s), open jaw, the vowel of sat. No glottal catch before it. Not \"ay\", not a long แอ.", "ph_a"),
 ("1 Isolated sounds", "phoneme_t", "/t/", "isolated sound",
  "Sound Card t (P1 P2 P3 P4 P5); review tiles; Word Builder; tracing t; Read the words letters",
  "Tap t letter or hear; tile placed; blend swipe; tracing stroke starts; letter tapped",
  "Short, crisp, aspirated puff. Voiceless. No \"tuh\". Not \"tee\".", "ph_t"),
 ("1 Isolated sounds", "phoneme_p", "/p/", "isolated sound",
  "Sound Card p (P1 P2 P4 P5); review tiles; Word Builder; tracing p; Read the words letters",
  "Tap p letter or hear; tile placed; tracing stroke starts; letter tapped",
  "Short, crisp, aspirated puff. Voiceless. No \"puh\". Not \"pee\".", "ph_p"),

 ("2 Whole words", "word_sat", "sat", "whole word",
  "P1 oral blend; P2 read; P3 Word Builder; P4 last sound; P5 read",
  "Hear the word (after the attempt); last-sound hear and round start",
  "Natural /sæt/. Final t fully released: no flap, no glottal stop.", "wd_sat"),
 ("2 Whole words", "word_tap", "tap", "whole word",
  "P3 read; P4 last sound; P5 read",
  "Hear the word (after the attempt); last-sound hear and round start",
  "Natural /tæp/. Final p released and audible.", "wd_tap"),
 ("2 Whole words", "word_pat", "pat", "whole word",
  "P1 oral blend; P3 Word Builder (change step); P5 read",
  "Hear the word (after the attempt)",
  "Natural /pæt/. Final t released: no flap, no glottal stop.", "wd_pat"),
 ("2 Whole words", "word_at", "at", "whole word",
  "P4 read; P5 read",
  "Hear the word (after the attempt)",
  "Stressed citation form /æt/, not the weak /ət/. Final t released.", "wd_at"),
 ("2 Whole words", "word_sock", "sock", "whole word (listening only)",
  "P1 picture tap; P1 sound-hunt card picture",
  "Tap the sock picture",
  "General American /sɑk/. Final k released. Spoken only, never printed.", "wd_sock"),
 ("2 Whole words", "word_pen", "pen", "whole word (listening only)",
  "P1 picture tap; P1 sound-hunt card picture",
  "Tap the pen picture",
  "/pɛn/ with a clear /ɛ/, distinct from pin (no pin–pen merger). Spoken only.", "wd_pen"),
 ("2 Whole words", "word_pot", "pot", "whole word (listening only)",
  "P1 picture tap; P1 sound-hunt card picture",
  "Tap the pot picture",
  "General American /pɑt/. Final t released. Spoken only.", "wd_pot"),

 ("3 Blending help", "blend_s_a_t", "s … a … t", "segmented model",
  "P1 oral blend; P3 Word Builder; P2/P5 read words (sat)",
  "\"hear the sounds\" button; after a misplaced-tile hint; help taps 1–2. Separate from \"hear the word\"",
  "Three pure sounds with even gaps of about 0.5 s. /s/ held about 0.8 s; /æ/ short; /t/ crisp. No vowel added between or after.", "seg_sat"),
 ("3 Blending help", "blend_p_a_t", "p … a … t", "segmented model",
  "P1 oral blend; P3 Word Builder change step; P5 read words (pat)",
  "\"hear the sounds\" button; after a misplaced-tile hint; help taps 1–2. Separate from \"hear the word\"",
  "Same pacing as blend_s_a_t. /p/ and /t/ short and crisp even in this slow model.", "seg_pat"),

 ("4 Instructions and feedback", "prompt_tap_to_start", "Tap to start.", "instruction", "Home",
  "1 s after Home opens (first visit or no page in progress); once more after 10 s idle; replay", "Warm and clear.", "nar_home_tap_start"),
 ("4 Instructions and feedback", "prompt_welcome_back", "Welcome back. Tap to go on.", "instruction", "Home",
  "1 s after Home opens when a page is in progress; replay", "Warm and clear.", "nar_home_welcome_back"),
 ("4 Instructions and feedback", "prompt_today_four_sounds", "Today you meet four sounds.", "instruction", "Page 1 stone picker",
  "Stone picker opens on page 1; replay", "", "nar_l1p1_intro"),
 ("4 Instructions and feedback", "prompt_tap_glowing_stone", "Tap the glowing stone.", "instruction", "Pages 2–5 stone picker",
  "Stone picker opens on pages 2–5; replay", "New line for this build.", ""),
 ("4 Instructions and feedback", "prompt_tap_a_picture", "Tap a picture.", "instruction", "P1 picture tap",
  "Screen opens; replay", "", "nar_g_tap_picture"),
 ("4 Instructions and feedback", "prompt_tap_to_hear_sound", "Tap to hear the sound.", "instruction", "Sound Cards; review sounds (P2–P5)",
  "Each card opens; replay", "", "nar_g_tap_hear"),
 ("4 Instructions and feedback", "prompt_your_turn", "Your turn.", "instruction", "Sound Cards",
  "After the first sound and its cue; then 4 s of quiet", "Inviting, not rushed.", "nar_g_your_turn"),
 ("4 Instructions and feedback", "prompt_trace_the_letter", "Trace the letter.", "instruction", "P2 tracing",
  "Each letter opens; replay", "", "nar_l1p2_trace"),
 ("4 Instructions and feedback", "prompt_listen_what_word", "Listen. What word is it?", "instruction", "P1 oral blend",
  "Each word opens (then blend plays); replay", "", "nar_g_what_word"),
 ("4 Instructions and feedback", "prompt_build_sat", "Build sat.", "instruction", "P3 Word Builder",
  "Builder opens; replay", "Say \"sat\" naturally with a released final t.", "nar_l1p3_build_sat"),
 ("4 Instructions and feedback", "prompt_try_first_sound", "Try the first sound.", "feedback", "P3 Word Builder",
  "Wrong tile in the first box; all boxes full and the first needs changing", "Calm and even.", "fb_first_sound"),
 ("4 Instructions and feedback", "prompt_try_middle_sound", "Try the middle sound.", "feedback", "P3 Word Builder",
  "Wrong tile in the middle box", "Calm and even.", "fb_middle_sound"),
 ("4 Instructions and feedback", "prompt_try_last_sound", "Try the last sound.", "feedback", "P3 Word Builder; P4 last sound",
  "Wrong tile in the last box; wrong choice on P4 (then the word replays)", "Calm and even.", "fb_last_sound"),
 ("4 Instructions and feedback", "prompt_say_sounds_say_word", "Say the sounds. Now say the word.", "instruction", "P3 Word Builder; P2–P4 single-word reading",
  "Word completed in the builder; single-word reading opens; replay", "Leave a short natural pause between the two sentences.", "nar_g_say_sounds; nar_g_now_word"),
 ("4 Instructions and feedback", "prompt_change_make_pat", "Change one sound. Make pat.", "instruction", "P3 Word Builder",
  "Change step opens; replay", "Say \"pat\" naturally with a released final t.", "nar_l1p3_change_pat"),
 ("4 Instructions and feedback", "prompt_changed_one_sound", "You changed one sound and made a new word!", "feedback", "P3 Word Builder",
  "pat completed (before \"Say the sounds…\")", "Pleased, not over the top.", "fb_changed_one"),
 ("4 Instructions and feedback", "prompt_what_sound_at_end", "What sound do you hear at the end?", "instruction", "P4 last sound",
  "Screen opens (then the word plays); replay", "", "nar_l1p4_tap_last"),
 ("4 Instructions and feedback", "prompt_thats_it", "That's it!", "feedback", "P4 last sound",
  "Right choice", "Calm, same energy as other feedback.", "fb_thats_it"),
 ("4 Instructions and feedback", "prompt_read_the_words", "Read the words.", "instruction", "P5 read the words",
  "Screen opens; replay", "", "nar_l1p5_read_to"),
 ("4 Instructions and feedback", "prompt_grown_up_time", "Grown-up time!", "instruction", "P5 grown-up check",
  "Screen opens; replay", "", "nar_l1p5_grownup"),
 ("4 Instructions and feedback", "prompt_stop_for_today", "Stop for today?", "instruction", "Any lesson screen",
  "Home button tapped during a lesson", "Gentle question.", "nar_g_stop_q"),
 ("4 Instructions and feedback", "prompt_pick_a_sticker", "Pick a sticker.", "instruction", "Finish",
  "Finish opens; replay", "", "nar_g_pick_sticker"),
 ("4 Instructions and feedback", "cue_s", "Snake sound. Teeth together.", "mouth/action cue", "Sound Card s",
  "After the first /s/ on the card; tap the mouth or action picture", "No isolated phoneme inside the line.", "nar_mouth_s"),
 ("4 Instructions and feedback", "cue_short_a", "Open wide. Quick!", "mouth/action cue", "Sound Card a",
  "After the first /æ/ on the card; tap the mouth or action picture", "", "nar_mouth_a"),
 ("4 Instructions and feedback", "cue_t", "Tongue taps. Feel the puff.", "mouth/action cue", "Sound Card t",
  "After the first /t/ on the card; tap the mouth or action picture", "", "nar_mouth_t"),
 ("4 Instructions and feedback", "cue_p", "Lips pop. Feel the puff.", "mouth/action cue", "Sound Card p",
  "After the first /p/ on the card; tap the mouth or action picture", "", "nar_mouth_p"),

 ("5 Optional effect", "effect_soft_chime", "Soft two-note chime (E6 then A6), 1.4 s", "effect", "Any activity; Finish",
  "A stage is completed; a sticker is picked (if Chime is on). Speech waits for it; never plays over narration",
  "Generated tone, peak -14 dBFS, quieter than speech. Not teaching audio.", "mus_chime_finish; sfx_sticker_land; effect_sticker_chime"),
]

def main():
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["batch", "audio_id", "filename", "line_or_sound", "clip_type", "screen",
                    "playback_trigger", "pronunciation_notes", "status", "source", "review_notes", "replaces_design_ids"])
        for b, i, line, t, screen, trig, notes, rep in ROWS:
            accent = "General American. " if not i.startswith("effect") else ""
            status, review = REVIEW.get(i, (READY, "Take 1. Exact line; passes level and timing checks"))
            source = "" if status == HUMAN else ("tools (generated tone)" if i.startswith("effect") else VOICE)
            w.writerow([b, i, f"{i}.wav", line, t, screen, trig, (accent + notes).strip(), status, source, review, rep])
    print("wrote", os.path.relpath(OUT, ROOT), len(ROWS), "clips")

if __name__ == "__main__":
    main()
