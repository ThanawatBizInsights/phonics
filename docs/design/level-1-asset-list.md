# Level 1 Artwork: Supplied and Still Needed

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
