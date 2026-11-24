# Level 1 Artwork: Supplied and Still Needed

## v1.1: Transparent Asset Kit

The Phonics Pond Transparent Asset Kit is merged into `Assets.xcassets`, which now holds 73 image sets.

**Covers and Home**
- Covers: `book_cover_01…12`. The level number, lock and trophy badges are live overlays.
- Home tiles: `home_storybook`, `home_phonics`, `home_stickers`, `home_grownups`.

**Level 1 scenes** (layered over `pond_background`; each character wobbles)

| Page | Scene |
|---|---|
| 1 | `pat_sitting_on_log` |
| 2 | `pat_tapping_log` |
| 3 | `pat_patting` |
| 4 | `pat_tapping_log` + `puppy_sitting` |
| 5 | `pat_and_puppy_on_log`, with a sunset tint |

**Rewards, stickers, icons and friends**
- Rewards: `trophy_page`, `trophy_level`.
- Stickers: `sticker_album`, `sticker_blank_star`.
- Icons: `icon_*`, used in round buttons. A system symbol is the fallback.
- Friends for later books: `pip_waving_cutout`, `duck_sitting`, plus the props `prop_daisies`, `prop_lily_pad` and `prop_log`.

**Not used as controls**
- `button_*`, `home_card` and `story_panel` are kept in the catalog, but panels and buttons stay native SwiftUI, as the kit README recommends.
- These PNGs are 362 px squares without stretch insets, so they can't be stretched into controls.

**Fixes made to the kit art**
- **Removed a faint alpha haze around the art** on `book_cover_07…12`, `duck_sitting`, `puppy_sitting`, `prop_daisies`, `prop_lily_pad` and `prop_log`: alpha below 64 → 0, a ramp from 64 to 128, then trimmed. Each was checked visually.
- **Kept the existing higher-resolution versions** of `pat_waving_cutout`, `pat_patting` and `pat_tapping` (1200 px), because the art matches the kit.
- **Replaced with the kit version:** `action_s/a/t/p` (now transparent) and `sticker_star`.
- **Renamed:**
  - `sticker_penguin` became `sticker_pat`, and `sticker_lilypad` became `sticker_lily`.
  - Saved stickers keep their old IDs and are mapped to the new art.

The puppy and Pip cut-outs listed as needed below are now supplied: `puppy_sitting` and `pip_waving_cutout`.

**Still needed for v1.1**
- Page scenes for Levels 2–12, once their stories are written.
- Meaning pictures for later-level words, where the Phonics and Stickers screens show one.

Every screen is built live in SwiftUI (buttons, text, letters, panels). Artwork is used only for illustrations
without baked-in controls or lesson text. The approved reference images all contain controls or text, so they were
used as layout references, and only clean regions were cropped as interim illustrations.

Add finished art to `PhonicsPond/PhonicsPond/Resources/Assets.xcassets` with the exact name below. The app picks it up
automatically; missing art shows a marked "art needed" placeholder with the asset name.

## Supplied

| Asset | Source | Used on |
|---|---|---|
| `pond_background` | Sunny Pond Storybook Landscape (artwork pack 3) | Fixed background behind every screen |
| `pat_waving_cutout` | Pat the plush penguin waving (pack 2), transparent, trimmed to the feet | Pat on Home and every lesson screen (wobbling layer) |
| `pat_patting` | Pat pats a golden puppy (pack 4), transparent | Meaning picture for **pat** (wobbling layer) |
| `pat_tapping` | Pat Taps a Wooden Table (pack 1), transparent | Meaning picture for **tap** (wobbling layer). Pack 11 is an alternate take, not used |
| `pat_sitting_log` | Crop of "Sat: Penguin Sitting on a Log" (reference 14) | Meaning picture for **sat** |
| `mouth_a`, `mouth_t`, `mouth_p` | Short A mouth shape (7), Tongue tip meets the alveolar ridge (9), Closed lips for /p/ (8) | Sound Cards a, t, p |
| `action_a`, `action_t`, `action_p` | Three felt ants on an arm (10), Fingertip tap on a table (6), Puppet blows a candle (5) | Sound Cards a, t, p |
| `mouth_s`, `action_s` | Crops of "Pat practices the letter s" (reference 3) | Sound Card s |
| `object_sock`, `object_pen`, `object_pot` | Crops of the Picture Tap reference (4) | Picture-tap warm-up, sound-hunt card |
| `sticker_penguin`, `sticker_lilypad`, `sticker_star` | Crops of the Sticker Celebration reference (7) | Finish, sticker book |
| `pat_waving` | Crop of reference 12 | Fallback only (if the cut-out is removed) |
| App icon | Phonics-Pond-App-Icon (1254 px, resized to 1024 px, no alpha) | `AppIcon.appiconset` |

## Still needed

| Asset | What it should show | Why |
|---|---|---|
| `puppy_cutout` | The golden puppy alone, transparent, feet at the bottom edge | Pages 3 and 5 list the puppy in their cast. In pack 4, Pat's hand covers the puppy's head, so it can't be separated. Until this arrives, the puppy appears only inside the "pat" picture |
| `pip_cutout` (Level 2) | Pip, transparent, feet at the bottom edge | Pip joins in Level 2 with short i |

Character cut-outs are separate layers that sway around their feet. Each character has its own rhythm: Pat 2.8 s, puppy 2.15 s, Pip 3.25 s. A tap adds one quick wobble. With Reduce Motion, characters stay still and a tap shows a soft glow instead.

## Reference images not used for layout

- "Pat's Pondside Letter Trail" (2) shows **a m t** in "today's lesson". **m** isn't taught in Level 1, so that panel was left out. The open-pond stone picker (11) was used instead.
- "Phonics Pond_ Pat's Level 1" (1) has replay and lock swapped. The revised Home (12) was used: lock on the left, replay on the right.
- "Pebble's Word Builder" (9/13) and "Word Builder: Pat by the pond" (5/14) informed the sat and pat layouts. Their lowercase instruction ("say the sounds…") is shown in sentence case to match the recorded line.
