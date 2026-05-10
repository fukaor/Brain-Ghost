---
name: brain-ghost-design
description: Use this skill to generate well-branded interfaces and assets for ブレインゴースト (Brain Ghost), a Japanese brain-training × ghost-battle Godot app by ReigalLabs. Contains essential design guidelines, colors, type, fonts, brand illustrations, and an app UI kit for prototyping screens, decks, and marketing artifacts.
user-invocable: true
---

Read the `README.md` file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts *or* production code, depending on the need.

## Key anchors inside this skill

- `README.md` — brand context, voice + tone, visual foundations, index
- `ICONOGRAPHY.md` — Material Symbols usage + brand illustrations
- `colors_and_type.css` — the CSS custom properties. Import this first in any new HTML.
- `fonts/NotoSansJP-Bold.otf` — the only text font. Ship it with the artifact.
- `assets/characters/ghost_seirei.png` — THE brand mascot. Use whenever you want to set the mood.
- `assets/icons/hitodama_lv1..5.png` — ability-ring donuts. Use for accuracy / achievement.
- `assets/textures/gradients/*.png` — pre-baked page/card/CTA gradients.
- `ui_kits/app/` — Brain Ghost mobile app UI kit (720×1280 portrait, Japanese).

## Hard rules (never violate)

1. **No red.** Ever. Loss states are `--fg-neutral-gray`. There is no `RED` constant in the source.
2. **No emoji in-product.** Noto Sans JP has no emoji glyphs. Use Material Symbols Rounded.
3. **Japanese copy only** in product UI. Voice = warm, child-like, encouraging. Address user as きみ. Never negative on a loss ("惜しい" / "次は行ける", never "ダメ").
4. **Type scale is closed:** 14 / 18 / 24 / 32 / 40 / 64pt. No intermediates.
5. **Single font weight — Bold.** Do not introduce Regular or Light.
6. **Bottom-thumb-zone CTAs.** On a 720×1280 canvas the primary CTA must sit below y≈853.
7. **Elevation by surface color + shadow, never borders.** No left-border color accents on cards.
8. **Gold is achievement-only.** Primary CTAs are `--bg-primary-blue` (#0058BA). Gold is best-update / stamp only.
