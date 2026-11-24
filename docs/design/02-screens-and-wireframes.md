# 02 · Screens and Wireframes

Visual wireframes (iPad landscape, plus an iPhone adaptation) are in `wireframes.html`. This file is the written spec behind them.

## Global layout rules

| Rule | Value |
|---|---|
| Canvas | iPad landscape 1194 × 834 pt, 12-column grid, 32 pt margins |
| Fixed chrome | ⌂ home top-left (88 pt), level/page pill top-centre, 🔁 replay top-right (88 pt), ✋? help bottom-right (88 pt) |
| Child touch targets | 88 pt minimum. Letter tiles 140 × 160 pt. Main action 120 pt high. 24 pt gaps between targets |
| Letters | Lowercase only, Andika (single-storey a, g). Sound Card letter 300 pt; tiles 110 pt; reading words 140 pt |
| Instruction | One short line per screen, shown under the pill at 34 pt and spoken. Icons always carry a 1–2 word label |
| Palette (pastel) | sky #CFE6F7, mint #CFEFDF, lavender #E3DAF5, butter #FFF1C2, peach #FFDCC8, ink #1E2A44 (letters), cloud #FBF8F2 (cards) |
| Feedback colours | Neutral lavender glow for "listen again". No red, no ✗, no buzzer |
| Motion | Under 300 ms, no flashing, reduced-motion respected |
| Audio | One speech channel. A new tap stops the previous clip. Effects are silent while a phoneme, segmented prompt or word plays. No background music in v1; the only music is the optional finish chime |
| Grown-up areas | Reached only by a 3-second hold on the 🔒 icon. Text in English + optional Thai |

**iPhone adaptation (later).** Same screens, same order. Chrome shrinks to 56 pt; the side panel on Sound Card moves under the letter as a swipe row; Word Builder keeps the slot row on top and the tile tray in one row underneath (tiles 72 × 84 pt). No screen depends on the side-by-side layout.

## 1 · Home

**Job:** a returning child reaches today's lesson in one tap.

```
┌───────────────────────────────────────────────────────────────┐
│                                                       [🔁]     │
│        (pastel pond scene, Pat the penguin waving)            │
│                                                               │
│                 ┌─────────────────────────────┐               │
│                 │   ▶     s  a  t  p           │  ← 360×220   │
│                 │          today               │               │
│                 └─────────────────────────────┘               │
│                     level 1 · page 1                           │
│                                                               │
│ [📖 stickers]                                         [🔒]     │
└───────────────────────────────────────────────────────────────┘
spoken: "Tap to start."   resume: "Welcome back. Tap to go on."
```

- The ▶ today button shows the letters of the current level, so Iris sees what she'll practise.
- Sticker book opens a read-only grid of earned stickers (no store, no currency).
- 🔒 grown-ups: hold 3 s. A progress ring fills as she holds; a quick tap does nothing.

## 2 · Today's Lesson

**Job:** show where she is in the 5 stages, and let families pick any page in the level.

```
┌───────────────────────────────────────────────────────────────┐
│ [⌂]              ( level 1 · page 1 )                  [🔁]   │
│                 Today you meet four sounds.                    │
│                                                               │
│    (👂)───(👄)───(✋)───(🧱)───(⭐)        stepping stones       │
│    ears   sounds  try    words  sticker                       │
│     ▶                                                          │
│                                                               │
│   pages:  [1] [2] [3] [4] [5]          (done pages show ⭐)     │
└───────────────────────────────────────────────────────────────┘
```

- Stone labels are the same on every page: **ears, sounds, try, words, sticker** (stages 1–5).
- The next stone has the ▶ on it. Earlier stones can be replayed.

## 3 · Sound Card

**Job:** hear one sound, see the mouth, copy it.

```
┌───────────────────────────────────────────────────────────────┐
│ [⌂]           ( level 1 · page 1 · ●○○○ )             [🔁]    │
│                 Tap to hear the sound.                         │
│ ┌─────────────────────────┐  ┌─────────────────────────────┐  │
│ │                         │  │   [ mouth picture ]          │  │
│ │           s             │  │   teeth together, hiss       │  │
│ │       (300 pt)          │  │                              │  │
│ │                         │  │   [ 🐍 action ]  snake hand   │  │
│ │       [ 🔊 hear ]       │  │                              │  │
│ └─────────────────────────┘  │   [ 🪞 your turn ]           │  │
│                              └─────────────────────────────┘  │
│                                     [ → next ]         [✋?]  │
└───────────────────────────────────────────────────────────────┘
```

Behaviour:
1. Enter → "Tap to hear the sound." Nothing else plays automatically.
2. Tap letter or 🔊 → phoneme. Letter glows for the clip's length.
3. After the first play, the mouth tip line plays once ("Snake sound. Teeth together.").
4. Then "Your turn." and the mirror chip appears. 4 s of quiet.
5. → next appears after the first play. It is never forced and never timed.
6. ✋? help, 1st tap: replays the phoneme slowly with the mouth picture animating. 2nd tap: shows the parent tip (EN/TH) in a small sheet.

Mouth cues for Level 1:

| Letter | Mouth picture | Child label | Spoken tip | Action |
|---|---|---|---|---|
| s | teeth together, smile, air line | teeth together | "Snake sound. Teeth together." | snake hand |
| a | jaw dropped, wide | open wide | "Open wide. Quick!" | ants on arm |
| t | tongue tip behind top teeth, puff | tongue taps | "Tongue taps. Feel the puff." | tap the table |
| p | lips together then apart, puff | lips pop | "Lips pop. Feel the puff." | blow a candle |

## 4 · Word Builder (sat → pat)

**Job:** build a word from taught letters, blend it, then change one sound.

```
┌───────────────────────────────────────────────────────────────┐
│ [⌂]              ( level 1 · page 3 )                  [🔁]   │
│                      Build sat.                                │
│                                                               │
│        ┌──────┐   ┌──────┐   ┌──────┐          slots          │
│        │      │   │      │   │      │          (3 for sat)     │
│        └──────┘   └──────┘   └──────┘                          │
│        ════════════ swipe to blend ════════════                │
│                                                               │
│   tray:  [ s ]   [ a ]   [ t ]   [ p ]                         │
│                                                     [✋?]       │
└───────────────────────────────────────────────────────────────┘
```

States (each one is a wireframe in `wireframes.html`):

| State | Screen | Spoken | Tap targets |
|---|---|---|---|
| **A. Build** | Empty slots, tray s a t p | "Build sat." | Tray tiles (tap = moves to the next empty slot and plays its sound; drag also works). 🔁 replays "Build sat." |
| **B. Wrong tile** (e.g. p in slot 1) | Tile sits in slot with lavender glow | Slot-specific: "Try the first sound." (or middle / last), then the segmented prompt "s… a… t" | Tap a placed tile to send it back to the tray |
| **C. Built** | s a t in slots. Blend bar under them lights up | "Say the sounds. Now say the word." Then 3 s of quiet | Each slot tile replays its sound. Swipe/tap the blend bar: tiles light left→right, each sound plays, no whole word yet. "hear the word" button fades in after the quiet gap or after one blend swipe |
| **D. Reveal** | Tap "hear the word" | "sat" (natural word). Then the picture card slides in: Pat sitting on a log. Thai meaning under it only if Thai help is on (นั่ง) | Picture replays the word. → next |
| **E. Change** | Same tiles. Instruction changes | "Change one sound. Make pat." | Tap the s tile to return it, then tap p. No slot is highlighted at first |
| **F. Changed** | p a t in slots | "You changed one sound and made a new word!" then "Say the sounds. Now say the word." | Blend bar, then "hear the word" → "pat" + picture (Pat patting a puppy) |

Help ladder (✋?) on the Word Builder: 1st tap replays the segmented prompt; 2nd tap pulses the slot that's wrong or empty; 3rd tap ghosts the correct tile in that slot so she can drag it. The app logs which help level was used (Parent Area), but never tells the child.

What the app records (local): tiles placed per slot, number of tries per slot, help level used, whether the blend bar was swiped before "hear the word". It does not record or judge what Iris said.

## 5 · Session Finish

```
┌───────────────────────────────────────────────────────────────┐
│ [⌂]                                                    [🔁]   │
│                   All done for today.                          │
│                                                               │
│        [ sticker ]     [ sticker ]     [ sticker ]             │
│                     Pick a sticker.                            │
│                                                               │
│     today: s a t p   ·   words: sat  pat                       │
│                                                               │
│   [ ↻ again ]                     [ ⌂ home ]                   │
│                       (Page 5 only) [ 🔒 grown-up time ]       │
└───────────────────────────────────────────────────────────────┘
```

Optional soft chime plays once after the sticker lands (not during any speech).

## 6 · Parent Area

Reached by a 3-second hold on 🔒. English with Thai underneath when Thai help is on.

| Tab | Contents |
|---|---|
| **Progress** | Per sound and per skill grid (below). App-checked results and grown-up marks are in separate columns |
| **Pages** | Level map, pages done, "Stay on this page tomorrow", open next level |
| **Off-screen cards** | Rice tray, sound hunt, tissue game, mirror: steps in EN/TH, with the sounds to model (🔊) |
| **Settings** | Thai help on/off, chime on/off, sound effects on/off, child's name, reset progress (2-step confirm) |
| **About this level** | Thai-interference focus for the level (from the plan), in plain EN/TH |

Progress grid (Level 1):

| Skill | Type | s | a | t | p | Words |
|---|---|---|---|---|---|---|
| Sound recognition: says sound for letter | Grown-up marks | ○ | ○ | ○ | ○ | — |
| Sound recognition: finds letter for sound | App-checked (review game) | ✓ count | | | | — |
| Blending (says the word from the sounds) | Grown-up marks | — | — | — | — | sat tap pat at |
| Segmenting (taps a box per sound) | App-checked + grown-up | — | — | — | — | sat tap pat |
| Letter formation | App-checked trace + grown-up (rice tray/paper) | ○ | ○ | ○ | ○ | — |
| Final-sound clarity (/t/, /p/ heard) | Grown-up marks only | — | — | ○ | ○ | sat tap |

Grown-up marks use three buttons: **On her own · With help · Not yet** (Thai: ทำได้เอง · ทำได้เมื่อช่วย · ยังไม่ได้). The pronoun follows the child profile. Each mark is dated so trends show over repeats. App-checked results show as counts ("found /p/ 4 of 5 times"), never as a grade.

All progress is stored on the device. No account, no microphone, no speech scoring, no analytics in v1.
