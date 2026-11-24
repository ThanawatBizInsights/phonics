Drop finished Level 1 recordings in this folder.

- File names must match docs/design/level-1-audio-manifest.csv exactly,
  e.g. phoneme_s.wav, word_sat.wav, prompt_your_turn.wav.
- .wav is preferred (.m4a and .caf also load).
- The folder is part of the app target (synchronized group): files added here
  are bundled on the next build. No project edits needed.
- Missing clips never block a lesson. Debug builds show an orange
  "audio pending" banner and Grown-ups > Recordings lists what is still missing.
- Do not add synthesized (text-to-speech) isolated sounds or blending models.
  phoneme_s/short_a/t/p and blend_s_a_t/blend_p_a_t still need human recordings.
  The ElevenLabs instruction lines and whole words here were auto-checked and await a listening sign-off.
