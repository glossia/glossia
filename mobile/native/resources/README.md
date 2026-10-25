# Toki

Toki is Glossia's plush language companion, not the name of the app.
The transparent artwork comes from the supplied character reference and
Painter-generated boards. `toki-rig-sheet.png` contains the body and two separate
arms; `toki-sheet.png` provides the language/globe prop poses.
`prepare_toki.py` produces matching iOS and Android assets without runtime
downloads. Regenerate with Pillow installed:

```sh
python3 mobile/native/resources/prepare_toki.py
```

The three rig textures share a 512 × 512 canvas. Draw left arm, right arm, then
body. Shoulder pivots are left (137, 250) and right (375, 250). Neutral arms point
down/out; rotate the right arm approximately −115° for a wave. Native players
interpolate joint keyframes for a 2.4-second tap greeting, continuing from the
current pose on repeated taps. Stop playback when hidden or inactive.

The generated Curious, Wave, Delighted, and Focused poses also have two arms.
Decorative avatars use static poses; Reduce Motion uses static tap expressions.
No sprite or UI animation claims to measure model progress.
