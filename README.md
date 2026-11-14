# Fruit Fall (Godot 4.7)

Ukiyo-e / woodblock fruit-merging puzzle. Portrait 720×1280 design, centred with the paper background filling any extra space
(stretch aspect `expand`, so tall phones and wide tablets get no black bars). Version 0.2.0.

## Run
- **Editor:** `godot -e --path /workspace/fruit-fall-godot` then F5 (main scene `scenes/main.tscn`).
- **Run directly:** `godot --path /workspace/fruit-fall-godot`
- **Linux build:** `export/linux/FruitFall.x86_64` (single file, pck embedded).
- **Web build:** serve `export/web/` with any static server and open `index.html`
  (e.g. `cd export/web && python3 -m http.server 8000`). Single-threaded build, so no COOP/COEP headers needed.
- **Android APK:** preset "Android" (com.veilmoth.fruitfall, portrait, arm64-v8a + armeabi-v7a, min SDK 24).
  Release-signed with a keystore kept outside the repo (box: `~/keystores/fruit-fall.keystore`), passed via env vars:
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`, then
  `godot --headless --path . --export-release "Android" export/android/fruit-fall-v0.2.0.apk`.
  Bump `version/code` + `version/name` in the preset and `application/config/version` for each release.
- **Re-export:** `godot --headless --path . --export-release "Linux" export/linux/FruitFall.x86_64`
  and `--export-release "Web" export/web/index.html`.

## Controls
Mouse/touch move the crane, click/tap (release) drops. Keyboard: ←/→ or A/D move, Space/Enter/↓ drop, M mute.
Best score and mute are saved in `user://fruitfall.cfg`.

## Automated test
`godot --path . -- --autotest` drops a scripted sequence (cherry+cherry merge check, pile build, forced game over),
prints rotation/sleep/merge stats and saves screenshots to `shots/`. Add `--write-movie out.avi` before `--` to record.

## Physics (scripts/fruit.gd, project.godot)
- RigidBody2D + CircleShape2D per fruit; rotation never locked; CCD (cast shape); can_sleep.
- Mass = r²/400 (cherry 1.0 … watermelon 38).
- Fruit material: friction 0.85, bounce 0.10. Walls: friction 0.6, bounce 0.05.
  (Godot uses min() for friction and adds bounces → fruit-fruit 0.85 / 0.20, fruit-wall 0.6 / 0.15.)
- Gravity 2600 px/s² (~0.8 s from crane to floor), 120 physics ticks/s, 24 solver iterations.
- Damping: linear 0.05, angular 2.0 (acts as rolling resistance so fruit rolls, then settles).
- Sleep: linear threshold 4 px/s, 0.4 s before sleep. Merges wake and gently push neighbours.
- Merge: a real contact between equal fruits opens a 25 ms window; merges if still within 24 px. Resting
  fruits touching within 1.5 px also merge. The new fruit spawns at the midpoint at the old radius and grows
  over 0.16 s (no overlap explosion) with a small upward hop.
- Drop cooldown 0.55 s. Game over: a landed fruit above the dashed line for 2 s.

## Credits / licences
- Font: Yuji Syuku (subset), © The Yuji Project Authors, SIL Open Font License 1.1 — `fonts/YujiSyuku-OFL.txt`.
- All art is procedural (`scripts/fruit_art.gd`, shaders); all sounds are synthesised at startup (`scripts/sfx.gd`).
- No third-party code other than the Godot engine (MIT).
