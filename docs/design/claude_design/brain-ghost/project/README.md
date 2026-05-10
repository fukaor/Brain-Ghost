# ブレインゴースト Design System

> **Brain Ghost** — 脳トレ × 自分対戦  
> 毎日2分、昨日の自分に挑め — ミニゲーム詰め合わせ型の脳トレアプリ

---

## Product context

**Brain Ghost（ブレインゴースト）** is a Japanese casual brain-training mobile + web game built in **Godot 4**. The core loop is 3 minigames × 30 seconds = ~2 minutes per session. The defining feature is the **Ghost** system (生霊): a translucent version of "your usual self" — calculated from your rolling 5-game average — that you race every play.

- **Platforms:** Web (Cloudflare Pages at `brain.reigals.com`) + Android (Google Play, with AdMob + a ~¥300–500 ad-removal IAP).
- **Engine:** Godot 4.6, GDScript, GL Compatibility renderer.
- **Developer:** ねこぽ / ReigalLabs — solo + Claude Code.
- **Status:** v1.0 MVP in development.

The audience skews older (commuters, middle-aged Japanese users on the morning train). Every design decision filters through one rule of thumb: *will this still be readable, and will it still not frustrate, a 55-year-old with tired eyes at 7am on a crowded train?*

### The six MVP minigames

1. 反射タップ (Reflex tap) — reaction speed
2. フラッシュ暗算 (Flash math) — calculation
3. 数字さがし (Number search) — observation
4. ストループ (Stroop) — attention / judgement
5. 順番記憶 (Sequence memory) — short-term memory
6. 神経衰弱ライト (Card match lite) — memory / observation

Each maps to one of six fixed ability axes shown on a radar chart: 計算力 / 記憶力 / 注意力 / 反射速度 / 観察力 / 判断力.

### The Ghost (生霊) system

The Ghost is **not a mascot** — it is literally "yesterday's you." Opacity = your *accuracy* (how many of the 6 games you've played at all). Dialogue is always supportive, never negative. Dedicated component: `scenes/ui/ghost_character.tscn`, driven via `set_accuracy()` / `set_dialogue()`.

---

## Sources

Everything here was derived from the **fukaor/Brain-Ghost@develop** repo. Readers without access: the relevant files are quoted verbatim in `colors_and_type.css`, in the preview cards, and in the UI kit README.

| Source | What it gave us |
|---|---|
| `project.godot` | App name, viewport (720×1280), clear color `#F7F5FF`, default theme path |
| `docs/design/manifest.md` | **Single Source of Truth** — color tokens, typescale, spacing, radii, shadows,禁則事項 |
| `docs/design/patterns.md` | Node patterns, Theme variations, 8-band screen template, ghost usage |
| `scripts/utils/color_palette.gd` | `ColorPaletteUtil` — the canonical color constants (v2 "Animated Intellectual" palette + legacy gold) |
| `docs/design/references/competitor-research.md` | Patterns adopted (hanko calendar, radar chart, 2×3 grid) vs rejected (dark theme, red loss states) |
| `CLAUDE.md` | Domain rules, scoring formulas, ghost spec, absolute rules ("no red, ever") |
| `assets/fonts/NotoSansJP-Bold.otf` | Primary font file — shipped as-is |
| `assets/characters/ghost_seirei.png` | Canonical Ghost character illustration |
| `assets/icons/hitodama_lv1..5.png` | Ability-ring donut icons (5 levels of "soul flame") |
| `assets/textures/gradients/*.png` | All gradient surfaces (page bg, hero card, CTA, pills, accents) |

---

## Content fundamentals

**Language.** All product copy is **Japanese**. No English strings in-product. Romanised names only in the repo / docs.

**Voice.** Warm, slightly childlike, always encouraging. The Ghost speaks as your younger, friendlier double — calls you **きみ** (never あなた, never お客様). Sentence endings lean soft: 〜だよ、〜しよう、〜しようね、〜がんばろう.

**Tone by surface:**
- **UI chrome / buttons** — tight, declarative: 「スタート」「もう一度」「シェア」「続ける」.
- **Headings** — short, human phrases: 「今日のチャレンジ」「前回の成績」「今週のハンコ」「ベスト更新！」.
- **Ghost dialogue** — 1–3 lines, 40–80 chars, always forward-looking:
  - Login: 「おかえり！X日連続すごいね。今日もやる？」
  - Pre-game: 「3種類、約2分。一緒にがんばろう！」
  - Win: 「やった！前より早くなってる！」
  - Loss (**never say "dame"**): 「惜しい！でもリアクションは確実に良くなってるよ」
  - Best: 「ベスト更新！今日のきみはすごい！」

**Absolute copy rules:**
- **Never** say 「今日はダメだったね」 or any negative framing on a loss. Reframe as "惜しい" / "次は行ける".
- **Never** claim medical efficacy. 脳年齢 (brain age) is explicitly *entertainment*.
- **Casing / punctuation** — Japanese. Half-width numbers (28歳, 3200点), full-width punctuation only where it reads naturally. No terminal periods on short UI labels.
- **No emoji in-product.** Noto Sans JP has no emoji glyphs — they render as tofu. Use Material Symbols via the `icon_*` Label variations instead.
- **No exclamation-stacking.** One ! max. 「やった！！！」 is off-brand.

---

## Visual foundations

### Palette

Two palettes coexist. The v2 **"Animated Intellectual"** blue palette (added 2026-04-13) is primary — it drives CTAs, active states, 3D button faces, surface containers. The legacy **Gold** is *demoted to achievement-only* — best-score updates, victory flourishes, the hanko/stamp calendar. **Red is banned** — there is no `RED` constant in `ColorPaletteUtil`, by design. Loss states resolve to `NEUTRAL_GRAY`.

- **Primary:** `#0058BA` (PRIMARY_BLUE), with `#004DA4` as the 3D-button bottom stroke and `#6C9FFF` as the gradient terminus.
- **Surface stack:** `#F7F5FF` background → `#EFEFFF` level 1 → `#FFFFFF` level 2 active. No borders — hierarchy comes from surface depth.
- **Text:** `#232C51` (on-surface, strong) / `#505A81` (variant, body) / `#A2ABD7` (outline, barely-there dividers).
- **Positive:** `#22C55E` green (wins), `#FACC15` gold (best / achievement only).

### Type

- **Single family, single weight:** Noto Sans JP **Bold**. No Regular, no Light. Readability > typographic hierarchy-by-weight. Hierarchy comes from *size* only.
- **Type scale (only these 5 sizes exist):** 14 / 18 / 24 / 32 / 64 pt. Intermediate values (20, 22) are禁則.
- **Caption floor = 14pt.** Never smaller — older eyes can't read 12pt.
- `display` (64pt) is reserved for the two "hero" numbers: brain-age on results, and final score. Using it elsewhere devalues it.

### Spacing

Strict **8pt grid.** Tokens: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · 2xl 48 · 3xl 64`. Default screen margin is `lg`. Bottom safe area is **96px** (thumb reach, not OS chrome) — CTAs must sit below y=853 on the 720×1280 canvas. `xs` is the escape-hatch for when 8 is too much, not a default.

### Radii

`sm 8 · md 16 · lg 24 · pill 9999`. **No sharp corners anywhere.** Cards = `md`; primary CTA = `lg` (bigger than cards to invite the tap); chips + streak counters = `pill`. The CTA being rounder than its neighbours is the single most-used hierarchy trick in the system.

### Backgrounds

- **Page background** is a subtle cream→violet-white vertical gradient (`page_bg.png`), not flat. The clear color is `#F7F5FF`.
- **No full-bleed hero photos**, no repeating patterns, no hand-drawn textures. The Ghost illustration is the only representational imagery and lives inside a dedicated `GhostCharacter` scene.
- **Gradients** are pre-baked into small PNG textures (`assets/textures/gradients/*.png`) and sampled via `StyleBoxTexture` — not computed at runtime. This keeps Web/GL compatibility fast.

### Shadows

Two tokens. Shadow is **pure black + alpha only** — no coloured shadows, ever (they dirty the palette).
- `shadow/card`: `rgba(0,0,0,0.08)`, offset `(0, 2)`, blur `8`.
- `shadow/card_elevated`: `rgba(0,0,0,0.12)`, offset `(0, 4)`, blur `12`. **One per screen, max** — usually the main CTA card. Overuse kills the signal.

Card backgrounds are the *same color as the page* — separation comes from shadow alone (material-style elevation).

### Animation

Minimal. The product is morning-commute software — no bounce, no flourish.
- **Entry:** 150–200ms fade + 4px upward translate. Easing: ease-out.
- **Press:** background → `PRIMARY_DIM`, translate +2px down (3D button collapse), 80ms. No scale.
- **Ghost opacity:** animates over ~400ms when accuracy changes — the only "character" animation in the app.
- **Best-update:** one tiny gold spark + stamp press on the hanko calendar. That is the entire celebration vocabulary.
- **No parallax, no particle systems, no sliding sheets.** Screen transitions cross-fade.

### Hover / press states

- **Hover** (web only) — lighten bg ~10%, no movement.
- **Pressed** — bg darkens to `PRIMARY_DIM` for blue CTAs / ~80% saturation for gold, `+2px` translate (the button "collapses" into its 3D base stroke). No scale.
- **Disabled** — bg `#E2E8F0`, text `#94A3B8`, no shadow.

### Borders & dividers

- **No borders on cards.** Ever. Use surface-depth tokens (`SURFACE_CONTAINER_LOW/LOWEST`) to create hierarchy.
- The only stroke in the system is the **3D button bottom edge** — a 4px strip of `PRIMARY_DIM` beneath the CTA face, producing a tactile "chiclet" effect.
- `OUTLINE_VARIANT` (`#A2ABD7`) exists for the rare case you need a 1px separator between list rows — use sparingly.

### Transparency & blur

- Blur is **not used.** No frosted glass, no backdrop filters.
- Transparency is reserved for **Ghost opacity** (data-driven, 0.0–1.0 = accuracy) and entry animations. Arbitrary `modulate.a` tweaks are禁則.

### Imagery tone

Cool, pastel, slightly dreamy. The Ghost illustration (`ghost_seirei.png`) is a soft watercolour of a young girl in a pale blue dress on a cloud — that single image sets the mood for the entire brand. All gradients lean blue/violet/cream. No warm browns, no saturated photography, no grain.

### Layout rules

- Fixed canvas: **720×1280 portrait.** Everything scales from there.
- Always the 8-band vertical template (see patterns): TopHUD · Ghost · Hero · ActionGrid · DataPreview · Tip · FlexSpacer · BottomNav.
- One screen = one primary CTA. Never two.
- Top of screen is read-only; actions live in the bottom third.

---

## Iconography

See `ICONOGRAPHY.md` for the full rules. TL;DR:

1. **Material Symbols Rounded** (variable font, Apache 2.0) is the primary icon set. In Godot it's loaded as a Label font variation; in this design system's HTML UI kits it's loaded from the Google Fonts CDN. Icon names are ligatures: `home`, `settings`, `calendar_month`, `bolt`, etc.
2. **Brand iconography** (lives in `assets/`): the `hitodama_lv1..5.png` ability-ring donuts, the `ghost_seirei.png` character, and the `BG` app icon (`icon.svg`).
3. **No emoji.** Noto Sans JP has no emoji glyphs → tofu. No Unicode symbol abuse either.
4. **No hand-drawn SVG icons.** If a Material Symbols glyph doesn't exist, stop and ask.

---

## Index — what's in this folder

| Path | What it is |
|---|---|
| `README.md` | You are here. Brand overview, content rules, visual foundations. |
| `ICONOGRAPHY.md` | Icon system rules, substitutions, what's copied vs CDN'd. |
| `SKILL.md` | Agent-skill entry point (for Claude Code / skill invocation). |
| `colors_and_type.css` | All CSS custom properties — color tokens, type scale, spacing, radii, shadows, semantic vars. Import this first. |
| `fonts/` | Noto Sans JP Bold OTF + OFL license. |
| `assets/` | Brand illustrations, hitodama icons, gradient textures, app icon. |
| `preview/` | Cards rendered in the Design System tab (colors, type, spacing, components, brand). |
| `ui_kits/app/` | Brain Ghost **mobile app** UI kit — `index.html` click-through, JSX components. |

## Caveats

- **Material Symbols Rounded** font file (`.ttf`) is **not** checked into the repo (it's referenced but not committed under `assets/fonts/`). The UI kits pull it from the Google Fonts CDN. If you need an offline build, please add `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` to `fonts/`.
- Sound / BGM credits in the upstream `CREDITS.md` are marked 未定 — this design system has no audio guidelines because there are no audio assets yet.
- 能力軸 (ability-axis) category colors are flagged in `manifest.md` as "to be decided" for v1.x. This system does **not** invent colors for them; the radar chart in the UI kit renders in a single PRIMARY_BLUE until the spec lands.
- **UI-kit bootstrapping:** `ui_kits/app/index.html` cannot contain inline `<script>` tags (a tooling constraint during authoring), so React + Babel are loaded via a small `bootstrap.js` that's injected on first render by an `<img onerror>`. This is cosmetic plumbing only — if you edit this file, feel free to swap in normal `<script>` tags.
