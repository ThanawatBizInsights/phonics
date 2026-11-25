# Phonics Pond (iPad, SwiftUI)

An original phonics app for a 6-year-old Thai learner of English. iPad landscape, laid out on an
11-inch canvas (1194 × 834 pt) and scaled to other iPads.

## v1.1: Storybook, Phonics, Stickers

- **Home** has three large cards (Storybook, Phonics, Stickers) with Pat by the pond, plus a hold-to-open
  **Grown-ups** lock. Cards come from one array in `UI/V11/HomeView.swift`, and the row below is kept clear
  for future activities.
- **Storybook shelf**: 12 illustrated covers on two screens of six. A cover is open, finished (big trophy),
  locked, or coming soon. Unlocked covers say **Open book** (unfinished) or **Read again** (finished).
- **Every book opens at Page 1**, from the shelf, Grown-ups › Books or the level trophy's Next level, whether it's new,
  unfinished or finished. A short trip to the background keeps the open page. Leaving the book and opening it again
  starts at Page 1. Earned trophies, unlocks and sticker practice are kept, and rereading never awards a duplicate.
- **Story pages** work for books of any length (Level 1 has 5). Each page shows:
  - Back to books, "Level 1 · Page X of Y", and Read to me.
  - The layered scene, the line, and one to three word chips.
  - Hear sounds (where set), and previous/next. The last page shows Finish story.
- **Trophies**: the first finish of a page earns a small trophy, and finishing every required page earns
  the level's big trophy. Both are saved in one write with the unlock. Rereading never awards a duplicate.
- **Phonics** is one "Listen and repeat" screen.
  - A level menu (unlocked levels only) and IPA sound tabs (Level 1: /s/ /æ/ /t/ /p/).
  - The large sound with Pat and the gesture picture, one **Hear sound** button, and "Your turn!".
  - **Try these words**: rows with fixed picture, word and speaker columns. The speaker is labelled "Hear pat".
  - No mouth pictures or mouth instructions. The `mouth_*` art stays in the asset catalog for a later
    pronunciation update. There are no video controls in this release.
- **Stickers**: random word or sound from completed levels only, with no repeats until the pool is used up.
  There's an optional single-level filter and My trophies. With nothing finished, it says
  "Finish Level 1 to start sticker practice."
- **Levels**: only Level 1 ("Pat by the Pond") is `ready`. Levels 2–12 are `draft`: they have titles,
  covers, story beats and target words, but no lines or scenes, so they stay "coming soon".
  To finish a level:
  1. Write its lines and layers in `tools/build_storybooks.py`.
  2. Set it to `ready`.
  3. Run `tools/build_storybooks.py` and `tools/validate_content.py`.
- **Controls in a row line up.** Buttons, word chips and speakers sharing a row use one height, one padding,
  and one centre line (`ControlMetrics`, `PillLabel`, `alignedRow()` in `UI/V11/V11Components.swift`).
  - On story pages, Previous page stays at the left edge and Next page / Finish story at the right, on the same
    row as the word chips.
  - Control labels follow the system text size, capped at about Accessibility 1. They wrap to two lines
    rather than being cut off.
  - The story row stacks the word chips above the navigation when it doesn't fit.
  - A control with no recording shows a small clock inside the button instead of a caption below it.
- The old five-stone Level 1 lessons are retired from navigation. Their code (`LessonView`,
  `UI/Activities`, `LegacyLessonHomeView`) is kept.

### Background music

- **The track:** `Resources/Audio/music_pond_loop.wav` is one original instrumental loop, generated with
  ElevenLabs Music in instrumental mode.
- **How the loop was made:**
  - Cut at 42.0 s, before the source fade-out.
  - A 2 s equal-power crossfade into the head.
  - −23 LUFS.
  - Bundled as 16-bit WAV, because an IMA4 CAF clicked at the seam.
  - Rebuild it with `tools/make_music_loop.py`.
- **Status:** the loop is auto-checked but still needs your listening sign-off. The seam preview is
  `docs/audio-review/music_loop_seam_preview.wav`.
- **Playback (`Audio/MusicPlayer.swift`):**
  - One player for the whole app.
  - Low under story and phonics screens (0.16), a little louder elsewhere (0.28).
  - Ducks to 0.05 while any teaching clip plays.
  - Pauses when the app leaves the foreground, and resumes only if **Grown-ups → Settings → Background
    music** is on. That setting is saved.

### Voice on hold

- **Waiting for recordings:** story narration (`story_l1_p1…p5`), phonemes and blends.
- **Controls without a recording** are disabled, with a "coming later" caption and the accessibility label
  "… Audio coming later".
- **Pages never need audio** to be read or finished.
- **The Ava word clips still play.**
- **No text-to-speech or voice selection** is in this update.

## Open, run, test

Requirements: Xcode 16 or later (the project uses synchronized folders), iOS 17 SDK.

1. Open `PhonicsPond/PhonicsPond.xcodeproj`.
2. Select the **PhonicsPond** scheme and an **iPad Pro 11-inch** or **iPad Air 11-inch** simulator.
3. Set your team under Signing & Capabilities if you run on a device (bundle ID `app.phonicspond.PhonicsPond`).
4. Run (⌘R). Test (⌘U) runs the unit tests and the UI flow tests.

Manual check on the simulator:
1. Home → each of the three cards.
2. Storybook: both shelf screens.
3. Read all five Level 1 pages; each first finish shows a small trophy, and Finish story shows the big trophy.
4. Open an unfinished book and a finished one (Read again): both start at Page 1. Trophies and unlocks are unchanged
   after rereading, and no new trophy appears.
5. Press Home during a book and come back: the same page is still open.
6. Stickers: random word and sound, then the Level 1 filter.
7. Phonics: four IPA tabs, one Hear sound, example rows aligned, and no mouth pictures.
   Repeat steps 3 and 7 at Settings › Accessibility › Display & Text Size › Larger Text (Accessibility sizes):
   labels fit and rows stay aligned.
8. Music keeps looping across screens and stays lower on story pages.
9. Grown-ups → Settings → Background music Off survives a relaunch.

From the command line:

```bash
xcodebuild test -project PhonicsPond/PhonicsPond.xcodeproj -scheme PhonicsPond -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

Checks that run without Xcode (content, audio list, Swift syntax):

```bash
python3 tools/validate_content.py
```

```bash
pip install tree-sitter tree-sitter-language-pack && python3 tools/check_swift_syntax.py
```

## Audio status (Level 1)

34 voice clips (plus the music loop) are bundled in `Resources/Audio/`. They use one General American ElevenLabs voice (Ava – Clear Warm Educator) and include every instruction and cue line plus the 7 whole words. Each passed automated checks: the line matches the screen text, /æ/ formants, the final consonant is released, and nothing is clipped. **No one has listened to them yet.** Their status is "Ready – auto-checked; needs your listening sign-off".

These 6 clips are **Needs human recording**: `phoneme_s`, `phoneme_short_a`, `phoneme_t`, `phoneme_p`, `blend_s_a_t`, `blend_p_a_t`. The ElevenLabs takes added vowels or letter names, so they're kept out of the app. They're in `docs/audio-review/rejected/` for reference. Until the recordings arrive, "hear the sounds" and letter taps show the debug "audio pending" banner.

Details for every take are in `docs/design/level-1-audio-manifest.csv` and `docs/audio-review/`. To re-run the acoustic checks:

```bash
python3 tools/audio_review.py PhonicsPond/PhonicsPond/Resources/Audio
```

## Where to put recordings

Drop finished `.wav` files into **`PhonicsPond/PhonicsPond/Resources/Audio/`**, named exactly as in
`docs/design/level-1-audio-manifest.csv` (for example `phoneme_s.wav`, `word_sat.wav`, `prompt_your_turn.wav`).
The folder is synchronized with the app target, so the next build bundles them; no project edits.
Then change the row's status in the CSV from "Needs human recording" to "Ready …" and run `tools/validate_content.py`. It fails if a "Needs human recording" clip is bundled, or if a "Ready" clip is missing.

Missing recordings never block a lesson. In Debug builds an orange "audio pending" banner names the clip,
and **Grown-ups → Recordings** lists every clip with its status and a play button.
Do not add text-to-speech phonemes or word models.

## Where to put artwork

Add images to `Resources/Assets.xcassets` using the names in `docs/design/level-1-asset-list.md`.
Anything missing shows a marked "art needed" placeholder with the asset name.

## Structure

| Folder | Contents |
|---|---|
| `PhonicsPond/App` | App entry, `AppModel` (routes, content, store, audio) |
| `PhonicsPond/Core` | Pure logic: curriculum + eligibility validator, storybooks + trophies + sticker pools (`Storybook.swift`), progress, lesson plan, Word Builder, tracing, audio IDs |
| `PhonicsPond/Audio` | `AudioPlayer` (one speech channel, stop-before-play, interruptions, missing files); `MusicPlayer` (looping background music, ducking) |
| `PhonicsPond/UI/V11` | v1.1 Home, shelf, story pages, trophy overlays and shelf, Phonics, Stickers, shared kit components |
| `PhonicsPond/UI` | Theme, components, root routing, Parent Area, retired lesson screens |
| `PhonicsPond/UI/Activities` | Picture tap, sound cards, review, offline card, oral blend, trace, Word Builder, last sound, read words, grown-up check, finish |
| `PhonicsPond/Resources/Content` | `curriculum.json` (Levels 1–12), `storybooks.json` (12 books), `phonics_examples.json`, `lesson_level1.json` (retired lessons) |
| `PhonicsPondTests` | Content eligibility, storybooks, trophies, unlocks, sticker pools, old-save decoding, music, Word Builder, tracing, audio player |
| `PhonicsPondUITests` | Home destinations, 12 covers, read + resume, trophies once, missing audio, sticker filter, music toggle, Reduce Motion |
| `tools/` | Generators for the curriculum JSON, recording list and Xcode project; validators |

`curriculum.json` is generated by `tools/build_curriculum.py`; `storybooks.json` and `phonics_examples.json` by `tools/build_storybooks.py`; the Xcode project by `tools/gen_xcodeproj.py`;
the recording list by `tools/build_audio_manifest.py`.

## Motion and feedback

- The pond background never moves. Pat and friends are separate cut-out layers that sway around their feet, each at a different rhythm. Tapping one gives a single brief wobble.
- Text, word tiles and navigation never move. Attention cues are a softly fading ring, not a bounce.
- Reduce Motion (Settings › Accessibility › Motion) stops all sway and replaces the tap wobble with a soft glow. For UI tests, the `-reduceMotion` launch argument does the same.
- Idle motion pauses when a screen is offscreen or the app isn't active.
- Buttons give a brief press-and-release; with Reduce Motion they only change brightness.
- The letter, word or picture whose clip is playing gets a butter highlight right away.
- A new tap stops the current clip first. "next" ignores double taps.
- A soft chime marks a completed activity. The next instruction waits for it, so effects never overlap narration. Phonics buttons make no sound except their teaching audio.

## Fonts

Andika Regular/Bold (SIL Open Font License, `Resources/Fonts/Andika-OFL.txt`) for the single-storey a and g.
Registered at launch, so no Info.plist entry is needed.
