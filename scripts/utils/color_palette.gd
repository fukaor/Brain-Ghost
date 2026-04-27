## ColorPaletteUtil
##
## ブレインゴースト の色定数。色はすべてここから引く。
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

# ============================================================
# --- v2: Animated Intellectual パレット (DESIGN.md 準拠) ---
# ============================================================
# 2026-04-13 DESIGN.md 追加により導入。既存のゴールド系は
# アチーブメント/ベスト更新など「勝利演出」専用に降格し、
# プライマリは Primary Blue に移行。

# Primary Blue — CTA、アクティブ状態、3D ボタン主色
const PRIMARY_BLUE := Color(0.0, 0.345, 0.729)         # #0058ba
const PRIMARY_DIM := Color(0.0, 0.302, 0.643)          # #004da4 — 3D ボタン下辺ストローク
const PRIMARY_CONTAINER := Color(0.424, 0.624, 1.0)    # #6c9fff — グラデ終端・アクセント
const PRIMARY_FIXED_DIM := Color(0.314, 0.569, 1.0)    # #5091ff — ホバー/中間トーン
const ON_PRIMARY := Color(0.941, 0.949, 1.0)           # #f0f2ff — ボタン上の文字色

# Surface Container (階層深度用、ボーダー禁止ルールの代替)
const BACKGROUND_V2 := Color(0.969, 0.961, 1.0)              # #f7f5ff — Level 0 キャンバス
const SURFACE_CONTAINER_LOWEST := Color(1, 1, 1)              # #ffffff — Level 2 アクティブカード
const SURFACE_CONTAINER_LOW := Color(0.937, 0.937, 1.0)       # #efefff — Level 1 サブセクション
const SURFACE_CONTAINER := Color(0.894, 0.906, 1.0)           # #e4e7ff
const SURFACE_CONTAINER_HIGH := Color(0.867, 0.882, 1.0)      # #dde1ff

# Text Colors
const ON_SURFACE := Color(0.137, 0.173, 0.318)         # #232c51 — 重要テキスト
const ON_SURFACE_VARIANT := Color(0.314, 0.353, 0.506) # #505a81 — 本文
const OUTLINE_VARIANT := Color(0.635, 0.671, 0.843)    # #a2abd7 — かろうじて境界

# --- ポジティブ系（アチーブメント・勝利演出・ベスト更新）---
# v1 のゴールドはプライマリから降格し、アチーブメント専用に
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
