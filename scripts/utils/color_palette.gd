## ColorPaletteUtil
##
## ブレインゴースト の色定数。色はすべてここから引く。
## ハードコードされた Color() / #xxxxxx はレビューで必ず指摘すること。
##
## [b]パレット v4 "Sumi Ghost":[/b] 和紙クリーム + 墨 + 鬼火青。
## 2026-05-25 更新。墨絵調リブランディング。
## ユーザ提供アセット (docs/ideas/character/*.png, docs/ideas/background/*.png) 準拠。
## 旧 v3 "Midnight Cat" 漆黒系パレットは alias として残置（段階移行）。
##
## [b]禁止色:[/b] 赤系（#EF4444, Color(1, 0, 0) 等）の UI 利用。
## GDD §6 および development-guidelines.md §色の使用 の通り、負け表示にも
## ネガティブ色を使わない設計のため、UI 用 RED 定数は意図的に定義しない。
## RED_400 / RED_500 / RED_GLOW は particle 装飾エフェクトでのみ使用可（progress_dots 限定）。
##
## [b]命名について:[/b] Godot 4.6 でネイティブクラス [code]ColorPalette[/code] が
## 追加されたため衝突回避として [code]ColorPaletteUtil[/code] とする。
class_name ColorPaletteUtil
extends RefCounted

# ============================================================
# --- v4: Sumi Ghost パレット (墨絵調、2026-05-25) ---
# ============================================================
# 和紙クリームを主背景、墨を文字/線、鬼火青をプライマリ、古色金を達成色、
# 翠墨をペア成立に。色はユーザ提供アセットから抽出した実値。

# --- 和紙層 (背景階層) ---
const WASHI_BASE  := Color(0.949, 0.914, 0.835)         # #F2E9D5 全画面最背景
const WASHI_PANEL := Color(0.910, 0.863, 0.753)         # #E8DCC0 カード/パネル
const WASHI_SHADE := Color(0.839, 0.812, 0.745)         # #D6CFBE サブパネル/セパレータ

# --- 墨層 (テキスト・線) ---
const SUMI_INK   := Color(0.106, 0.106, 0.122)          # #1B1B1F 主要テキスト/キャラ線
const SUMI_MID   := Color(0.239, 0.239, 0.267)          # #3D3D44 サブテキスト/ボタン文字
const SUMI_LIGHT := Color(0.420, 0.420, 0.447)          # #6B6B72 キャプション/説明文
const SUMI_DIM   := Color(0.639, 0.620, 0.580)          # #A39E94 プレースホルダ/無効

# --- 鬼火青 (主アクセント) ---
const ONIBI_BLUE := Color(0.478, 0.702, 0.878)          # #7AB3E0 CTA/進捗/ハイライト
const ONIBI_GLOW := Color(0.847, 0.922, 0.969)          # #D8EBF7 グロー/明色アクセント
const ONIBI_DEEP := Color(0.239, 0.420, 0.584)          # #3D6B95 押下色/深い鬼火
const ONIBI_GLOW_TRANS := Color(0.478, 0.702, 0.878, 0.55)

# --- 古色金 (NEW BEST / 達成 / 猫目) ---
const GOLD_AGED  := Color(0.784, 0.663, 0.318)          # #C8A951
const GOLD_AGED_GLOW := Color(0.784, 0.663, 0.318, 0.6)

# --- 翠墨 (正解・ペア成立) ---
const JADE_INK := Color(0.353, 0.541, 0.431)            # #5A8A6E

# --- ゴースト滲み墨 (生霊本体) ---
const GHOST_INK := Color(0.478, 0.478, 0.494)           # #7A7A7E (alpha は精度% で変化)


# ============================================================
# --- v3 alias: Midnight Cat 定数 → v4 Sumi Ghost にマップ ---
# ============================================================
# 旧コードが直接参照しているので alias で互換性を保つ。撤去は別 PR。

# --- ink stack (旧名) ---
const INK_100 := SUMI_INK
const INK_80  := SUMI_MID
const INK_60  := SUMI_LIGHT
const INK_40  := SUMI_DIM
const INK_20  := WASHI_SHADE

# --- cyan accent (旧名) → 鬼火青 ---
const CYAN_300 := ONIBI_GLOW
const CYAN_400 := ONIBI_BLUE
const CYAN_500 := ONIBI_DEEP
const CYAN_GLOW := ONIBI_GLOW_TRANS

# --- gold (旧名) → 古色金 ---
const GOLD_300 := Color(0.835, 0.741, 0.490)            # #D5BC7D 古色寄せ
const GOLD_400 := GOLD_AGED
const GOLD_GLOW := GOLD_AGED_GLOW

# --- red (装飾用、UI には使わない / particle 限定) ---
const RED_400 := Color(0.898, 0.353, 0.353)             # #E55A5A
const RED_500 := Color(0.780, 0.231, 0.231)             # #C73B3B
const RED_GLOW := Color(0.906, 0.353, 0.353, 0.5)

# --- surfaces (旧名) → 和紙系 ---
const BG_VOID  := WASHI_BASE
const BG_DEEP  := WASHI_PANEL                            # 旧 BG_DEEP は階層色 → WASHI_PANEL に
const BG_PANEL := WASHI_PANEL
const BG_ELEV  := WASHI_SHADE

# --- 旧 v2 互換エイリアス ---
const PRIMARY_CYAN := CYAN_400
const PRIMARY_CYAN_DIM := CYAN_500
const PRIMARY_CYAN_GLOW := CYAN_300
const ON_PRIMARY := BG_PANEL

const YOU_GOLD := GOLD_400
const YOU_WARM_WHITE := GOLD_300

const BACKGROUND := BG_VOID
const SURFACE_LOW := BG_DEEP
const SURFACE_MID := BG_PANEL
const SURFACE_HIGH := BG_ELEV
const SURFACE_GLOW := INK_20

const ON_SURFACE := SUMI_INK                             # 旧: INK_100 (light), 新: SUMI_INK (dark)
const ON_SURFACE_VARIANT := SUMI_MID
const ON_SURFACE_MUTED := SUMI_LIGHT
const OUTLINE := SUMI_DIM

# --- ポジティブ系 (アチーブメント・勝利演出・ベスト更新) ---
const POSITIVE_GREEN := JADE_INK
const POSITIVE_GOLD := GOLD_AGED

# --- ニュートラル (敗北・無効・GHOST 側) ---
const NEUTRAL_GRAY := GHOST_INK
const NEUTRAL_LIGHT_GRAY := WASHI_SHADE
const NEUTRAL_SLATE := SUMI_DIM

# --- セマンティック ---
static func win_color() -> Color:
    return JADE_INK

static func lose_color() -> Color:
    return GHOST_INK

static func best_score_color() -> Color:
    return GOLD_AGED

# --- 旧 v2 互換エイリアス（呼び出し側を段階的に移行するため） ---
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
