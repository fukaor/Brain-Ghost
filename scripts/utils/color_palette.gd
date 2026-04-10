## ColorPaletteUtil
##
## Brain Boost の色定数。色はすべてここから引く。
## ハードコードされた Color() / #xxxxxx はレビューで必ず指摘すること。
##
## [b]禁止色:[/b] 赤系（#EF4444, Color(1, 0, 0) 等）。
## GDD §6 および development-guidelines.md §色の使用 の通り、負け表示にも
## ネガティブ色を使わない設計のため、[code]RED[/code] 定数は意図的に定義しない。
## どうしても必要な箇所が発生したら PR で議論すること。
##
## [b]命名について:[/b] Godot 4.6 でネイティブクラス [code]ColorPalette[/code] が
## 追加されたため衝突回避として [code]ColorPaletteUtil[/code] とする。他の util 群
## ([code]DateUtil[/code], [code]JsonUtil[/code], [code]UuidUtil[/code]) と同じ [code]*Util[/code] 接尾辞で統一。
class_name ColorPaletteUtil
extends RefCounted

# --- ポジティブ系（勝利・ベスト更新・スコア上昇）---
const POSITIVE_GREEN := Color(0.133, 0.773, 0.369)  # #22C55E
const POSITIVE_GOLD := Color(0.980, 0.800, 0.082)   # #FACC15

# --- ニュートラル（情報・背景・テキスト）---
const NEUTRAL_GRAY := Color(0.392, 0.455, 0.545)    # #64748B
const NEUTRAL_LIGHT_GRAY := Color(0.886, 0.910, 0.941)  # #E2E8F0
const NEUTRAL_SLATE := Color(0.580, 0.639, 0.722)   # #94A3B8

# --- アクセント（情報系・リンク）---
const ACCENT_BLUE := Color(0.231, 0.510, 0.965)     # #3B82F6

# --- 背景 ---
const BG_LIGHT := Color(0.973, 0.980, 0.988)        # #F8FAFC
const BG_DARK := Color(0.059, 0.090, 0.165)         # #0F172A（v1.1 以降のダークモード用）

# --- セマンティック（ゲーム結果）---
# 勝利表示には POSITIVE_GREEN / POSITIVE_GOLD を使う。
# 敗北表示には NEUTRAL_GRAY を使う（赤は絶対に使わない）。
static func win_color() -> Color:
    return POSITIVE_GREEN

static func lose_color() -> Color:
    return NEUTRAL_GRAY

static func best_score_color() -> Color:
    return POSITIVE_GOLD
