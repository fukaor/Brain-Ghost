#!/usr/bin/env python3
"""墨絵テーマシート切り出しスクリプト

References: /workspace/docs/ideas/sumi-theme/references/
Output:     /workspace/docs/ideas/sumi-theme/parts/

7 シートから以下を切り出す:
- ui_parts_sheet.png    : 3 buttons + 6 badges + 4 decorations + 4 score elements
- game_cards.png        : 6 game cards (each card cropped whole as game_icon_*.png)
- card_states.png       : 3 frame states (normal / locked / selected)
- ui_parts_home_*.png   : currently used as visual reference only (not cropped further)

白透過 + 周囲トリム + padding 2px。`--threshold 230` で閾値を下げて再実行可能。
"""

import argparse
import os
from PIL import Image

ROOT = "/workspace/docs/ideas/sumi-theme"
REFS = f"{ROOT}/references"
OUT  = f"{ROOT}/parts"

# (sheet_basename, parts_subdir/filename, x0, y0, x1, y1)
CROPS = [
    # ---- ui_parts_sheet ---- buttons (y=97..220) ----
    ("ui_parts_sheet.png", "buttons/btn_primary.png",        70,  85,  500, 230),
    ("ui_parts_sheet.png", "buttons/btn_secondary.png",     530,  85,  880, 230),
    ("ui_parts_sheet.png", "buttons/btn_accent.png",        915,  85, 1080, 230),

    # ---- ui_parts_sheet ---- badges (y=375..507) ----
    ("ui_parts_sheet.png", "badges/badge_best.png",          40, 365,  225, 515),
    ("ui_parts_sheet.png", "badges/badge_new.png",          240, 365,  430, 515),
    ("ui_parts_sheet.png", "badges/badge_tier_frame.png",   445, 365,  615, 515),
    ("ui_parts_sheet.png", "badges/mark_win.png",           635, 365,  805, 515),
    ("ui_parts_sheet.png", "badges/mark_lose.png",          820, 365,  980, 515),
    ("ui_parts_sheet.png", "badges/stamp_shuin.png",        985, 365, 1080, 515),

    # ---- ui_parts_sheet ---- dividers (y=590..760 approx) ----
    ("ui_parts_sheet.png", "decorations/divider_thick.png",  50, 590,  500, 660),
    ("ui_parts_sheet.png", "decorations/divider_thin.png",  520, 590,  900, 660),
    ("ui_parts_sheet.png", "decorations/divider_section.png",50, 670, 1080, 750),

    # ---- ui_parts_sheet ---- indicators (y=775..1090) ----
    ("ui_parts_sheet.png", "bars/bar_fill_ink.png",          50, 775, 1080, 900),
    ("ui_parts_sheet.png", "bars/stamp_row_ref.png",         50, 905, 1080, 960),
    ("ui_parts_sheet.png", "bars/bar_fill_blue.png",         50, 970, 1080, 1090),

    # ---- ui_parts_sheet ---- score elements (y=1150..1310) ----
    ("ui_parts_sheet.png", "decorations/score_value_ref.png",30, 1150, 380, 1310),
    ("ui_parts_sheet.png", "decorations/arrow_up_brush.png",385, 1150, 600, 1310),
    ("ui_parts_sheet.png", "decorations/arrow_down_brush.png",605,1150, 820, 1310),
    ("ui_parts_sheet.png", "decorations/timer_value_ref.png", 825,1150, 1080, 1310),

    # ---- game_cards ---- 6 cards ----
    ("game_cards.png", "game_icons/game_icon_7ban.png",       30,  80,  720,  370),
    ("game_cards.png", "game_icons/game_icon_ippon.png",     740,  80, 1420,  370),
    ("game_cards.png", "game_icons/game_icon_search.png",     30, 390,  720,  690),
    ("game_cards.png", "game_icons/game_icon_stroop.png",    740, 390, 1420,  690),
    ("game_cards.png", "game_icons/game_icon_sequence.png",   30, 770,  720, 1040),
    ("game_cards.png", "game_icons/game_icon_memory.png",    740, 770, 1420, 1040),

    # ---- card_states ---- 3 frames ----
    ("card_states.png", "frames/frame_ink_border.png",         30, 110,  720,  520),  # 通常 (top-left)
    ("card_states.png", "frames/frame_ink_border_locked.png", 740, 110, 1430,  520),  # ロック (top-right)
    ("card_states.png", "frames/frame_ink_border_selected.png",740, 620, 1430, 1030),  # ティア選択 (bottom-right)
    ("card_states.png", "frames/frame_ink_border_new.png",     30, 620,  720, 1030),  # NEW badge (bottom-left) — オマケ

    # ---- card_states ---- 抜き出し用: lock icon (only) ----
    # ロックカード内の右側に錠前があるので、その部分だけ別 crop も保存
    ("card_states.png", "badges/icon_lock.png",              1080, 250, 1280, 430),
    # NEW バッジ部分 (左下カードの右上隅)
    ("card_states.png", "badges/badge_new_corner.png",       540, 130,  720, 290),

    # ---- game_cards ---- hitodama (左下隅の青い炎) ----
    # 1枚目の左下隅から hitodama を抜き出す
    ("game_cards.png", "decorations/hitodama.png",            35, 290,   95,  365),
]


def make_transparent(img: Image.Image, threshold: int) -> Image.Image:
    """RGB → RGBA + white pixels (R,G,B all >= threshold) become alpha=0."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (r, g, b, 0)
    return img


def trim_and_pad(img: Image.Image, padding: int = 2) -> Image.Image:
    """Trim non-transparent bbox, add padding."""
    bbox = img.getbbox()
    if bbox is None:
        return img  # all transparent — return as-is
    img = img.crop(bbox)
    w, h = img.size
    new = Image.new("RGBA", (w + padding * 2, h + padding * 2), (0, 0, 0, 0))
    new.paste(img, (padding, padding))
    return new


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--threshold", type=int, default=240,
                        help="White transparency threshold (default 240)")
    parser.add_argument("--no-trim", action="store_true",
                        help="Skip trim+pad step (useful for testing crop coords)")
    args = parser.parse_args()

    sheet_cache = {}
    warnings = 0

    for sheet_name, out_rel, x0, y0, x1, y1 in CROPS:
        sheet_path = f"{REFS}/{sheet_name}"
        if sheet_name not in sheet_cache:
            sheet_cache[sheet_name] = Image.open(sheet_path).convert("RGB")
        sheet = sheet_cache[sheet_name]

        sw, sh = sheet.size
        if x0 < 0 or y0 < 0 or x1 > sw or y1 > sh:
            print(f"WARN: {out_rel} rect ({x0},{y0},{x1},{y1}) outside sheet size {sw}x{sh}")
            warnings += 1
            x0 = max(0, x0); y0 = max(0, y0)
            x1 = min(sw, x1); y1 = min(sh, y1)

        cropped = sheet.crop((x0, y0, x1, y1))
        rgba = make_transparent(cropped, args.threshold)
        if not args.no_trim:
            rgba = trim_and_pad(rgba)

        # Size sanity
        ow, oh = rgba.size
        if ow < 5 or oh < 5:
            print(f"WARN: {out_rel} too small after trim: {ow}x{oh}")
            warnings += 1

        # Save
        out_path = f"{OUT}/{out_rel}"
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        rgba.save(out_path, "PNG")
        print(f"OK   {out_rel:50s}  {ow}x{oh}")

    print(f"\nDone. {len(CROPS)} parts cut, {warnings} warnings.")


if __name__ == "__main__":
    main()
