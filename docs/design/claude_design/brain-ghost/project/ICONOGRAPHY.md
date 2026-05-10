# Iconography

## The short rule

1. **Material Symbols Rounded** is the icon system for all UI chrome (nav, HUD pills, action cards, inline icons).
2. **Brand illustrations** live under `assets/` as PNG/SVG — imported verbatim from the repo, never redrawn.
3. **No emoji. No Unicode symbol hacks. No hand-rolled SVGs** for UI icons.

## Material Symbols Rounded

- **Source:** Google, Apache 2.0 (`github.com/google/material-design-icons`). Credits in `assets/CREDITS.md`.
- **In Godot:** loaded as `assets/fonts/MaterialSymbolsRounded.ttf` and referenced via Label `theme_type_variation` (`icon_nav`, `icon_pill`, `icon_card`, `icon_hero`, `icon_tip`).
- **In these HTML UI kits:** loaded from the Google Fonts CDN (see `colors_and_type.css`). Use `<span class="icon">home</span>` — the text content is a **ligature name**, not a unicode codepoint.
- **Why Rounded (not Outlined / Sharp):** softness matches the brand's round-corners-only rule.

### Variation table

| Class | Size | Color | Where |
|---|---|---|---|
| `.icon--nav`  | 28 | `--fg-neutral-gray` | bottom nav, drawer |
| `.icon--pill` | 20 | `--bg-gold` | leading icon inside a HUD pill |
| `.icon--card` | 32 | `--fg1` | action-card left icon, stamp cell |
| `.icon--hero` | 24 | `--fg1` | hero-card prefix icon, section headers |
| `.icon--tip`  | 24 | `--bg-accent-blue` | tip/lightbulb card |

Axis: `FILL=0` by default. Add `.icon--filled` for the filled state (active nav tab, selected cell).

### Finding ligatures

Browse `fonts.google.com/icons?icon.set=Material+Symbols&icon.style=Rounded` and paste the ligature name (`home`, `settings`, `calendar_month`, `bolt`, `emoji_events`, `auto_awesome`) into the element's text content.

## ⚠️ Substitution flagged to the user

The repo's `assets/CREDITS.md` **declares** `assets/fonts/MaterialSymbolsRounded.ttf` — but the file itself is **not committed** on the `develop` branch (only `NotoSansJP-Bold.otf` is present under `assets/fonts/`).

This design system therefore loads Material Symbols Rounded **from the Google Fonts CDN** in its HTML UI kits. This is fine for online previews, but:

- If the user needs an offline-capable build, please add `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` to this project's `fonts/` directory.
- The Godot export should do the same under `assets/fonts/`.

**No functional substitution was made** — the icon set is exactly what the repo's docs specify; only the delivery path differs.

## Brand assets (copied verbatim from the repo)

| File | What it is | Where it belongs |
|---|---|---|
| `assets/icon.svg` | The **app icon** — a green `#22C55E` rounded square with bold `BG` lettering. 128×128. | App-icon slots, launcher, favicons. |
| `assets/characters/ghost_seirei.png` | **The Ghost** — watercolour illustration of "yesterday's you" standing on a cloud. This single image carries the brand mood. | Wherever `GhostCharacter` is used. Opacity animates with accuracy (0.0 – 1.0). |
| `assets/characters/ghost_placeholder.svg` | SVG fallback for the ghost used during development. | Same slot as above, when the PNG isn't loaded. |
| `assets/icons/hitodama_lv1..5.png` | **Ability-ring donuts** — 5 levels of the "hitodama" (soul flame) ring. Levels 1→5 correspond to increasing fill / saturation. | Radar chart nodes, accuracy indicator cells, achievement rings. |

### Hitodama ring — how it's used

The PNGs are **rendered, not drawn at runtime**. They go into:

- The **accuracy HUD pill** (one ring per minigame played).
- The **radar chart nodes** (one ring per ability axis, sized by score).
- **Achievement cells** (e.g. "5日連続プレイ" lights up lv5).

Use them at their native 128×128 or downscale preserving alpha. Never recolor — the levels *are* the levels.

## Gradient textures

Under `assets/textures/gradients/` are pre-baked gradient strips used by Godot's `StyleBoxTexture`. They're reproduced as CSS gradients in the HTML UI kits for fidelity (and left as PNGs for cases that need the exact same pixels, e.g. slide exports).

| File | Used on |
|---|---|
| `page_bg.png` | Full-screen page background (cream → violet-white vertical). |
| `hero_card_bg.png` | Hero card fill (cream #FFFCED base). |
| `cta_blue.png` / `cta_gold.png` | Primary CTA faces (+ `_pressed` variants). |
| `glass_surface.png` | Subtle white tint for surface-container-lowest cards. |
| `ability_circle_blue.png` | Radar chart / ability-ring fills. |
| `accent_blue/gold/green/purple.png` | Small 1-2px strips used as accent underlines. |
| `pill_neutral.png` | HUD pill fill. |

## What's not allowed

- ❌ **Emoji in UI copy.** Noto Sans JP Bold contains no emoji glyphs. `🏠` renders as tofu (□). Use Material Symbols `home` instead.
- ❌ **Unicode dingbat hacks** (`✓`, `★`, `→`) where a Material Symbol exists. Use `check`, `star`, `arrow_forward`.
- ❌ **Hand-rolled SVG icons** in place of Material Symbols. If a glyph doesn't exist, stop and ask for guidance — do not draw one.
- ❌ **Recoloring the brand illustrations**. The Ghost is not a mascot that takes team colors; she's a single canonical image.
- ❌ **Left-aligned colored border accents** on cards (the "AI-slop rounded card with blue left border" pattern). Depth is expressed with surface color + shadow — never with a stripe.
