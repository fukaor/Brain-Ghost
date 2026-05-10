# Brain Ghost — Mobile UI Kit

Interactive recreation of the **脳ゴースト (Brain Ghost)** Android/iOS app home & training flow.

## Files
- `index.html` — entry; mounts `<App/>` inside an Android device frame
- `android-frame.jsx` — stock M3 device bezel (status bar / nav pill)
- `components.jsx` — atoms: `HudPill`, `BattlePill`, `SpeechBubble`, `AbilityCard`, `PrimaryCTA`, `BottomNav`, `PageBg`, `Icon`
- `screens.jsx` — `HomeScreen`, `GameSelectScreen`, `ReactGameScreen`, `ResultScreen`
- `app.jsx` — router & state for the click-through

## Flow
1. **Home** — HUD (brain age + ghost-battle W/L pill), floating ghost seirei with speech bubble, 3×2 ability grid (each ability shows its hitodama level asset), big blue 3D **はじめる** CTA, bottom nav.
2. Tap **はじめる** → **Game Select** (2×2 / 2×3 grid of the six brain domains)
3. Tap a domain → **React-Tap mini-game** — wait for green, tap, see your reaction time
4. Finish → **Result** — brain-age reveal, year-over-year delta chip, earned hitodama row

## Visual sources
- `assets/ghost_seirei.png` — main character (from `assets/characters/`)
- `assets/hitodama_lv1…lv5.png` — level badges (from `assets/icons/`)
- Radial sky-blue gradient bg matches `scenes/home/home.tscn` camera background
- Blue CTA shadow echoes the Godot 3D-button press feel

## Fidelity caveats
- The real Godot app renders scene nodes with physics; this is a cosmetic HTML recreation
- Japanese copy is reconstructed from `ui_strings.md`, matching the ですます polite tone
- Icons use Google Material Symbols Rounded as the repo has no bundled icon font
