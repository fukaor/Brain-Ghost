## ColorPaletteUtil
##
## ブレインゴースト の色定数。色はすべてここから引く。
## ハードコードされた Color() / #xxxxxx はレビューで必ず指摘すること。
##
## [b]パレット v3 "Midnight Cat":[/b] 漆黒 void + シアン発光 + 明朝。
## 2026-05-02 更新。promo 画像 (docs/design/promotion/*.png) の最終形。
## 旧 "Animated Intellectual" 白系パレットは廃止。
##
## [b]禁止色:[/b] 赤系（#EF4444, Color(1, 0, 0) 等）。
## GDD §6 および development-guidelines.md §色の使用 の通り、負け表示にも
## ネガティブ色を使わない設計のため、[code]RED[/code] 定数は意図的に定義しない。
##
## [b]命名について:[/b] Godot 4.6 でネイティブクラス [code]ColorPalette[/code] が
## 追加されたため衝突回避として [code]ColorPaletteUtil[/code] とする。
class_name ColorPaletteUtil
extends RefCounted

# ============================================================
# --- v3: Midnight Cat パレット (mocks/reflex/variant-b.jsx 準拠) ---
# ============================================================
# 漆黒 void を主背景に、シアン発光をプライマリ、ゴールドを
# YOU 側エフェクト＋アチーブメント、明朝で見出しを組む。
# 値は mocks/reflex/variant-b.jsx の T 定数と一致（2026-05-02 補正）

# --- ink stack (text / silhouette) ---
const INK_100 := Color(0.957, 0.969, 1.0)               # #F4F7FF
const INK_80  := Color(0.780, 0.824, 0.910)             # #C7D2E8
const INK_60  := Color(0.533, 0.588, 0.690)             # #8896B0
const INK_40  := Color(0.290, 0.333, 0.439)             # #4A5570
const INK_20  := Color(0.137, 0.169, 0.247)             # #232B3F

# --- cyan accent (CTA / win / GHOST orb) ---
const CYAN_300 := Color(0.722, 0.878, 1.0)              # #B8E0FF
const CYAN_400 := Color(0.435, 0.706, 1.0)              # #6FB4FF
const CYAN_500 := Color(0.239, 0.545, 0.910)            # #3D8BE8
const CYAN_GLOW := Color(0.435, 0.706, 1.0, 0.55)

# --- gold (YOU orb / GATE / PERFECT) ---
const GOLD_300 := Color(1.0, 0.914, 0.659)              # #FFE9A8
const GOLD_400 := Color(0.961, 0.780, 0.416)            # #F5C76A
const GOLD_GLOW := Color(0.961, 0.780, 0.416, 0.6)

# --- red (LOSE / miss marker — 装飾用、UI には使わない) ---
const RED_400 := Color(0.898, 0.353, 0.353)             # #E55A5A
const RED_500 := Color(0.780, 0.231, 0.231)             # #C73B3B
const RED_GLOW := Color(0.906, 0.353, 0.353, 0.5)

# --- surfaces ---
const BG_VOID  := Color(0.0, 0.0, 0.0)                  # #000000 (alias of BACKGROUND)
const BG_DEEP  := Color(0.024, 0.035, 0.071)            # #060912
const BG_PANEL := Color(0.043, 0.071, 0.125)            # #0B1220
const BG_ELEV  := Color(0.067, 0.094, 0.153)            # #111827

# --- 旧名 (互換、これらが variant-b 実値とずれている — 段階移行のため alias) ---
const PRIMARY_CYAN := CYAN_400                          # 旧 #7dd3fc → 正は CYAN_400
const PRIMARY_CYAN_DIM := CYAN_500
const PRIMARY_CYAN_GLOW := CYAN_300
const ON_PRIMARY := BG_PANEL

# YOU 側アクセント（金 / 白 → 金グラデ） — 旧名互換
const YOU_GOLD := GOLD_400
const YOU_WARM_WHITE := GOLD_300

# Surface stack — 漆黒 void に微差で階層 (旧名互換)
const BACKGROUND := BG_VOID
const SURFACE_LOW := BG_DEEP
const SURFACE_MID := BG_PANEL
const SURFACE_HIGH := BG_ELEV
const SURFACE_GLOW := INK_20

# Text on dark — 旧名互換
const ON_SURFACE := INK_100
const ON_SURFACE_VARIANT := INK_80
const ON_SURFACE_MUTED := INK_60
const OUTLINE := INK_20

# --- ポジティブ系（アチーブメント・勝利演出・ベスト更新）---
const POSITIVE_GREEN := Color(0.133, 0.773, 0.369)      # #22C55E
const POSITIVE_GOLD := Color(0.980, 0.800, 0.082)       # #FACC15

# --- ニュートラル（敗北・無効・GHOST 側） ---
const NEUTRAL_GRAY := Color(0.392, 0.455, 0.545)        # #64748B
const NEUTRAL_LIGHT_GRAY := Color(0.886, 0.910, 0.941)  # #E2E8F0
const NEUTRAL_SLATE := Color(0.580, 0.639, 0.722)       # #94A3B8

# --- セマンティック ---
static func win_color() -> Color:
    return POSITIVE_GREEN

static func lose_color() -> Color:
    return NEUTRAL_GRAY

static func best_score_color() -> Color:
    return POSITIVE_GOLD

# --- 旧 v2 互換エイリアス（呼び出し側を段階的に移行するため） ---
# 旧コードが直接参照しているので暫く残す。撤去は別 PR。
const PRIMARY_BLUE := PRIMARY_CYAN
const PRIMARY_DIM := PRIMARY_CYAN_DIM
const PRIMARY_CONTAINER := PRIMARY_CYAN_GLOW
const PRIMARY_FIXED_DIM := PRIMARY_CYAN_GLOW
const BACKGROUND_V2 := BACKGROUND
const SURFACE_CONTAINER_LOWEST := SURFACE_HIGH
const SURFACE_CONTAINER_LOW := SURFACE_LOW
const SURFACE_CONTAINER := SURFACE_MID
const SURFACE_CONTAINER_HIGH := SURFACE_HIGH
const ON_SURFACE_VARIANT_LEGACY := ON_SURFACE_VARIANT
const OUTLINE_VARIANT := OUTLINE
const ACCENT_BLUE := PRIMARY_CYAN
const BG_LIGHT := BACKGROUND
const BG_DARK := BACKGROUND
