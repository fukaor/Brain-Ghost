## build_theme.gd
##
## ブレインゴースト の共通 Theme Resource を生成するビルダスクリプト。
## `docs/design/manifest.md` の仕様に従って `assets/themes/default_theme.tres` を組み立てる。
##
## 実行方法:
##     godot --headless --script scripts_build/build_theme.gd
##
## このスクリプトは編集中にトークン値を変えたくなったら再実行して .tres を再生成する用途。
## 値を変える前に必ず manifest.md を更新すること（Single Source of Truth は manifest.md）。
extends SceneTree

const FONT_PATH := "res://assets/fonts/NotoSansJP-Bold.otf"
const ICON_FONT_PATH := "res://assets/fonts/MaterialSymbolsRounded.ttf"
const THEME_OUT := "res://assets/themes/default_theme.tres"

# グラデーションテクスチャのパス（build_gradients.gd で事前生成される）
const TEX_CTA_GOLD         := "res://assets/textures/gradients/cta_gold.png"
const TEX_CTA_GOLD_PRESSED := "res://assets/textures/gradients/cta_gold_pressed.png"
const TEX_HERO_CARD_BG     := "res://assets/textures/gradients/hero_card_bg.png"
const TEX_PILL_NEUTRAL     := "res://assets/textures/gradients/pill_neutral.png"
const TEX_ACTION_CARD_BG   := "res://assets/textures/gradients/action_card_bg.png"

# v2 Animated Intellectual (DESIGN.md)
const TEX_CTA_BLUE         := "res://assets/textures/gradients/cta_blue.png"
const TEX_CTA_BLUE_PRESSED := "res://assets/textures/gradients/cta_blue_pressed.png"
const TEX_ABILITY_CIRCLE   := "res://assets/textures/gradients/ability_circle_blue.png"

# v2 Blue palette (DESIGN.md)
const PRIMARY_BLUE      := Color(0.0, 0.345, 0.729)        # #0058ba
const PRIMARY_DIM       := Color(0.0, 0.302, 0.643)        # #004da4
const PRIMARY_CONTAINER := Color(0.424, 0.624, 1.0)        # #6c9fff
const PRIMARY_FIXED_DIM := Color(0.314, 0.569, 1.0)        # #5091ff
const ON_PRIMARY        := Color(0.941, 0.949, 1.0)        # #f0f2ff
const SURFACE_BG_V2     := Color(0.969, 0.961, 1.0)        # #f7f5ff
const SURFACE_LOWEST    := Color(1, 1, 1)                  # #ffffff
const SURFACE_LOW_V2    := Color(0.937, 0.937, 1.0)        # #efefff
const SURFACE_CONT_V2   := Color(0.894, 0.906, 1.0)        # #e4e7ff
const SURFACE_HIGH_V2   := Color(0.867, 0.882, 1.0)        # #dde1ff
const ON_SURFACE_V2     := Color(0.137, 0.173, 0.318)      # #232c51
const ON_SURFACE_VAR_V2 := Color(0.314, 0.353, 0.506)      # #505a81
const OUTLINE_VARIANT_V2 := Color(0.635, 0.671, 0.843)     # #a2abd7

# Font リソースの UID パス（ThemeResource 側から参照させるためのパス）
# `load()` は .import が無いと失敗するため、FontFile.load_dynamic_font() で直接ロードして
# Theme に埋め込む。ResourceSaver.save() 時に Theme 内部で外部リソース参照として書き出される。

# --- ColorPaletteUtil 定数の値（manifest.md §2 カラートークン表と同期）---
# 注: Theme Resource は生 Color を埋め込む必要があるため、ここでは値を直書きする。
# この build script は build-time tool であり、production scene/controller からの
# 生 hex 禁止ルールは本スクリプトには適用されない（Resource 生成の定義本体であるため）。
const BG_LIGHT         := Color(0.973, 0.980, 0.988)  # #F8FAFC
const BG_DARK          := Color(0.059, 0.090, 0.165)  # #0F172A
const POSITIVE_GREEN   := Color(0.133, 0.773, 0.369)  # #22C55E
const POSITIVE_GOLD    := Color(0.980, 0.800, 0.082)  # #FACC15
const NEUTRAL_GRAY     := Color(0.392, 0.455, 0.545)  # #64748B
const NEUTRAL_LIGHT_GRAY := Color(0.886, 0.910, 0.941)  # #E2E8F0
const NEUTRAL_SLATE    := Color(0.580, 0.639, 0.722)  # #94A3B8
const ACCENT_BLUE      := Color(0.231, 0.510, 0.965)  # #3B82F6

# --- サイズ定数（manifest.md §3 / §4 / §5 と同期）---
const SIZE_CAPTION := 14
const SIZE_BODY    := 18
const SIZE_BUTTON  := 20
const SIZE_H2      := 24
const SIZE_H1      := 32
const SIZE_DISPLAY := 64

const SPACE_SM := 8
const SPACE_MD := 16
const SPACE_LG := 24

const RADIUS_MD := 16
const RADIUS_LG := 24

# --- シャドウ（manifest.md §8 と同期）---
const SHADOW_STD_COLOR      := Color(0, 0, 0, 0.08)
const SHADOW_STD_OFFSET     := Vector2(0, 2)
const SHADOW_STD_SIZE       := 8

const SHADOW_ELEVATED_COLOR  := Color(0, 0, 0, 0.12)
const SHADOW_ELEVATED_OFFSET := Vector2(0, 4)
const SHADOW_ELEVATED_SIZE   := 12


func _init() -> void:
    print("[build_theme] Loading font: %s" % FONT_PATH)
    # font_data_dynamic importer によって生成済みの FontFile リソースを load() で取得する。
    # これにより Theme の .tres 側は ext_resource 参照となり、ファイルサイズが劇的に小さくなる
    # （4.6MB のフォントが毎回埋め込まれるのを避ける）。
    # 前提: `godot --headless --editor --quit-after 3600` を 1 度走らせて .import を生成しておくこと。
    var font := load(FONT_PATH) as Font
    if font == null:
        push_error("[build_theme] Failed to load font: %s (did you run godot --headless --editor --quit-after 3600 first?)" % FONT_PATH)
        quit(1)
        return
    print("[build_theme] Font loaded: name=%s" % font.get_font_name())

    var theme := Theme.new()
    theme.default_font = font
    theme.default_font_size = SIZE_BODY

    _build_button(theme)
    _build_label(theme)
    _build_panel_container(theme)
    _build_progress_bar(theme)
    _build_premium_variations(theme)
    _build_icon_variations(theme)
    _build_speech_bubble(theme)
    _build_v2_animated_intellectual(theme)

    var err := ResourceSaver.save(theme, THEME_OUT)
    if err != OK:
        push_error("[build_theme] Failed to save theme (err=%d): %s" % [err, THEME_OUT])
        quit(1)
        return
    print("[build_theme] Saved: %s" % THEME_OUT)
    quit(0)


func _build_button(theme: Theme) -> void:
    # Button: CTA ゴールド基調。normal/hover/pressed/disabled の 4 状態。
    theme.set_color("font_color", "Button", BG_DARK)
    theme.set_color("font_hover_color", "Button", BG_DARK)
    theme.set_color("font_pressed_color", "Button", BG_DARK)
    theme.set_color("font_disabled_color", "Button", NEUTRAL_SLATE)
    theme.set_font_size("font_size", "Button", SIZE_BUTTON)

    theme.set_stylebox("normal", "Button", _button_stylebox(POSITIVE_GOLD, 0))
    theme.set_stylebox("hover", "Button", _button_stylebox(_darken(POSITIVE_GOLD, 0.90), 0))
    theme.set_stylebox("pressed", "Button", _button_stylebox(_darken(POSITIVE_GOLD, 0.80), 2))
    theme.set_stylebox("disabled", "Button", _button_stylebox(NEUTRAL_LIGHT_GRAY, 0))

    # focus ring はアクセントブルーで薄く
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color(0, 0, 0, 0)
    focus.border_width_left = 2
    focus.border_width_right = 2
    focus.border_width_top = 2
    focus.border_width_bottom = 2
    focus.border_color = ACCENT_BLUE
    _set_corner_radius(focus, RADIUS_LG)
    theme.set_stylebox("focus", "Button", focus)

    # --- Secondary Button variation: ニュートラルグレー背景、陰影控えめ ---
    # CTA プライマリとの視覚的差別化。manifest §5 では radius/md (16px)
    theme.set_type_variation("secondary", "Button")
    theme.set_color("font_color", "secondary", BG_DARK)
    theme.set_color("font_hover_color", "secondary", BG_DARK)
    theme.set_color("font_pressed_color", "secondary", BG_DARK)
    theme.set_font_size("font_size", "secondary", SIZE_BUTTON)
    theme.set_stylebox("normal", "secondary", _secondary_stylebox(NEUTRAL_LIGHT_GRAY))
    theme.set_stylebox("hover", "secondary", _secondary_stylebox(_darken(NEUTRAL_LIGHT_GRAY, 0.96)))
    theme.set_stylebox("pressed", "secondary", _secondary_stylebox(_darken(NEUTRAL_LIGHT_GRAY, 0.92)))


func _button_stylebox(bg: Color, press_offset: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    _set_corner_radius(sb, RADIUS_LG)
    sb.content_margin_left = SPACE_LG
    sb.content_margin_right = SPACE_LG
    sb.content_margin_top = SPACE_MD + press_offset
    sb.content_margin_bottom = SPACE_MD - press_offset if press_offset > 0 else SPACE_MD
    sb.shadow_color = SHADOW_STD_COLOR
    sb.shadow_offset = SHADOW_STD_OFFSET
    sb.shadow_size = SHADOW_STD_SIZE
    return sb


func _secondary_stylebox(bg: Color) -> StyleBoxFlat:
    # セカンダリボタン: CTA より控えめ。角丸 16、シャドウなし
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    _set_corner_radius(sb, RADIUS_MD)
    sb.content_margin_left = SPACE_LG
    sb.content_margin_right = SPACE_LG
    sb.content_margin_top = SPACE_MD
    sb.content_margin_bottom = SPACE_MD
    return sb


func _build_label(theme: Theme) -> void:
    # default Label: body 18pt / NEUTRAL_GRAY
    theme.set_color("font_color", "Label", NEUTRAL_GRAY)
    theme.set_font_size("font_size", "Label", SIZE_BODY)

    # Type Variations
    theme.set_type_variation("h1", "Label")
    theme.set_font_size("font_size", "h1", SIZE_H1)
    theme.set_color("font_color", "h1", BG_DARK)

    theme.set_type_variation("h2", "Label")
    theme.set_font_size("font_size", "h2", SIZE_H2)
    theme.set_color("font_color", "h2", BG_DARK)

    theme.set_type_variation("display", "Label")
    theme.set_font_size("font_size", "display", SIZE_DISPLAY)
    theme.set_color("font_color", "display", BG_DARK)

    theme.set_type_variation("caption", "Label")
    theme.set_font_size("font_size", "caption", SIZE_CAPTION)
    theme.set_color("font_color", "caption", NEUTRAL_SLATE)


func _build_panel_container(theme: Theme) -> void:
    # default PanelContainer: 透明（使わない想定だが安全に空スタイル）
    var default_panel := StyleBoxEmpty.new()
    theme.set_stylebox("panel", "PanelContainer", default_panel)

    # card variation
    theme.set_type_variation("card", "PanelContainer")
    var card := _card_stylebox(SHADOW_STD_COLOR, SHADOW_STD_OFFSET, SHADOW_STD_SIZE)
    theme.set_stylebox("panel", "card", card)

    # card_elevated variation
    theme.set_type_variation("card_elevated", "PanelContainer")
    var elevated := _card_stylebox(SHADOW_ELEVATED_COLOR, SHADOW_ELEVATED_OFFSET, SHADOW_ELEVATED_SIZE)
    theme.set_stylebox("panel", "card_elevated", elevated)


## ウマ娘風プレミアム UI のための追加 variation 群。
## カード類は StyleBoxFlat で強い陰影 + 色付きアクセントボーダー。
## CTA ボタンだけは StyleBoxTexture でグラデ表現（shadow 非対応の制約は影なしで許容、代わりに
## 極太ゴールドでインパクトを出す）。
func _build_premium_variations(theme: Theme) -> void:
    # --- cta_gradient Button: グラデーションゴールドの大型 CTA ---
    # StyleBoxTexture は shadow 非対応なので、周囲の hero_card の強い影で相対的に浮いて見せる
    theme.set_type_variation("cta_gradient", "Button")
    theme.set_color("font_color", "cta_gradient", BG_DARK)
    theme.set_color("font_hover_color", "cta_gradient", BG_DARK)
    theme.set_color("font_pressed_color", "cta_gradient", BG_DARK)
    theme.set_font_size("font_size", "cta_gradient", SIZE_H2)
    theme.set_stylebox("normal", "cta_gradient", _cta_gradient_stylebox(TEX_CTA_GOLD, false))
    theme.set_stylebox("hover", "cta_gradient", _cta_gradient_stylebox(TEX_CTA_GOLD, false))
    theme.set_stylebox("pressed", "cta_gradient", _cta_gradient_stylebox(TEX_CTA_GOLD_PRESSED, true))
    theme.set_stylebox("disabled", "cta_gradient", _cta_gradient_stylebox(TEX_CTA_GOLD_PRESSED, false))

    # --- hero_card PanelContainer: Hero セクション。クリーム bg + 強シャドウ + ゴールド帯 ---
    theme.set_type_variation("hero_card", "PanelContainer")
    var hero_sb := StyleBoxFlat.new()
    hero_sb.bg_color = Color(1.0, 0.988, 0.929, 1)  # 非常に淡いクリーム（ゴールド系の柔らかいベース）
    _set_corner_radius(hero_sb, 24)
    hero_sb.content_margin_left = 24
    hero_sb.content_margin_right = 24
    hero_sb.content_margin_top = 28
    hero_sb.content_margin_bottom = 28
    hero_sb.shadow_color = Color(0, 0, 0, 0.22)
    hero_sb.shadow_offset = Vector2(0, 8)
    hero_sb.shadow_size = 20
    hero_sb.border_width_bottom = 4
    hero_sb.border_color = POSITIVE_GOLD
    theme.set_stylebox("panel", "hero_card", hero_sb)

    # --- pill_chip PanelContainer: トップ HUD のピル型チップ。白 bg + 中シャドウ ---
    theme.set_type_variation("pill_chip", "PanelContainer")
    var pill_sb := StyleBoxFlat.new()
    pill_sb.bg_color = Color(1, 1, 1, 1)
    _set_corner_radius(pill_sb, 16)
    pill_sb.content_margin_left = 12
    pill_sb.content_margin_right = 12
    pill_sb.content_margin_top = 12
    pill_sb.content_margin_bottom = 12
    pill_sb.shadow_color = Color(0, 0, 0, 0.12)
    pill_sb.shadow_offset = Vector2(0, 4)
    pill_sb.shadow_size = 10
    pill_sb.border_width_top = 2
    pill_sb.border_color = NEUTRAL_LIGHT_GRAY
    theme.set_stylebox("panel", "pill_chip", pill_sb)

    # --- action_card PanelContainer: アクションカードグリッド。白 bg + 影 ---
    theme.set_type_variation("action_card", "PanelContainer")
    var action_sb := StyleBoxFlat.new()
    action_sb.bg_color = Color(1, 1, 1, 1)
    _set_corner_radius(action_sb, 16)
    action_sb.content_margin_left = 14
    action_sb.content_margin_right = 14
    action_sb.content_margin_top = 14
    action_sb.content_margin_bottom = 14
    action_sb.shadow_color = Color(0, 0, 0, 0.14)
    action_sb.shadow_offset = Vector2(0, 4)
    action_sb.shadow_size = 12
    theme.set_stylebox("panel", "action_card", action_sb)

    # --- Label: value variation（HUD ピル内のメイン数値表示）---
    theme.set_type_variation("value", "Label")
    theme.set_font_size("font_size", "value", 26)
    theme.set_color("font_color", "value", BG_DARK)

    # --- Label: value_label variation（HUD ピル内のキャプション）---
    theme.set_type_variation("value_label", "Label")
    theme.set_font_size("font_size", "value_label", 12)
    theme.set_color("font_color", "value_label", NEUTRAL_GRAY)

    # --- Label: hero_big variation（ヒーローカードのメインタイトル。大型 + やや暗めゴールド色で差別化）---
    theme.set_type_variation("hero_big", "Label")
    theme.set_font_size("font_size", "hero_big", 40)
    theme.set_color("font_color", "hero_big", BG_DARK)

    # --- Label: card_title variation（アクションカードのタイトル）---
    theme.set_type_variation("card_title", "Label")
    theme.set_font_size("font_size", "card_title", 18)
    theme.set_color("font_color", "card_title", BG_DARK)

    # --- ホーム画面ゴーストバトル勝敗バー (win 側) ---
    theme.set_type_variation("win_bar", "PanelContainer")
    var win_sb := StyleBoxFlat.new()
    win_sb.bg_color = POSITIVE_GOLD
    win_sb.corner_radius_top_left = 10
    win_sb.corner_radius_bottom_left = 10
    win_sb.content_margin_left = 10
    win_sb.content_margin_right = 6
    win_sb.content_margin_top = 4
    win_sb.content_margin_bottom = 4
    theme.set_stylebox("panel", "win_bar", win_sb)

    # --- ホーム画面ゴーストバトル勝敗バー (loss 側) ---
    theme.set_type_variation("loss_bar", "PanelContainer")
    var loss_sb := StyleBoxFlat.new()
    loss_sb.bg_color = NEUTRAL_SLATE
    loss_sb.corner_radius_top_right = 10
    loss_sb.corner_radius_bottom_right = 10
    loss_sb.content_margin_left = 6
    loss_sb.content_margin_right = 10
    loss_sb.content_margin_top = 4
    loss_sb.content_margin_bottom = 4
    theme.set_stylebox("panel", "loss_bar", loss_sb)

    # --- 勝敗バー内テキスト ---
    theme.set_type_variation("bar_text", "Label")
    theme.set_font_size("font_size", "bar_text", 11)
    theme.set_color("font_color", "bar_text", BG_DARK)

    # --- ボトムナビのアイコン: アクティブ状態 (ホームタブ) ---
    var icon_font2 := load(ICON_FONT_PATH) as Font
    if icon_font2 != null:
        theme.set_type_variation("icon_nav_active", "Label")
        theme.set_font("font", "icon_nav_active", icon_font2)
        theme.set_font_size("font_size", "icon_nav_active", 28)
        theme.set_color("font_color", "icon_nav_active", POSITIVE_GOLD)

    # --- ボトムナビのラベル ---
    theme.set_type_variation("nav_label", "Label")
    theme.set_font_size("font_size", "nav_label", 11)
    theme.set_color("font_color", "nav_label", NEUTRAL_SLATE)

    theme.set_type_variation("nav_label_active", "Label")
    theme.set_font_size("font_size", "nav_label_active", 11)
    theme.set_color("font_color", "nav_label_active", POSITIVE_GOLD)

    # --- Button: target_circle variation（反射タップゲームの丸いターゲット）---
    # 強いシャドウ + pill 形状 + ゴールド bg でタップしたくなる誘目を作る
    theme.set_type_variation("target_circle", "Button")
    theme.set_color("font_color", "target_circle", BG_DARK)
    theme.set_color("font_hover_color", "target_circle", BG_DARK)
    theme.set_color("font_pressed_color", "target_circle", BG_DARK)
    theme.set_font_size("font_size", "target_circle", SIZE_CAPTION)
    theme.set_stylebox("normal", "target_circle", _target_stylebox(POSITIVE_GOLD, true))
    theme.set_stylebox("hover", "target_circle", _target_stylebox(POSITIVE_GOLD, true))
    theme.set_stylebox("pressed", "target_circle", _target_stylebox(_darken(POSITIVE_GOLD, 0.80), true))
    theme.set_stylebox("disabled", "target_circle", _target_stylebox(NEUTRAL_LIGHT_GRAY, true))

    # --- Button: target_circle_fake variation（フェイクターゲット、グレー bg）---
    theme.set_type_variation("target_circle_fake", "Button")
    theme.set_color("font_color", "target_circle_fake", NEUTRAL_GRAY)
    theme.set_color("font_hover_color", "target_circle_fake", NEUTRAL_GRAY)
    theme.set_color("font_pressed_color", "target_circle_fake", NEUTRAL_GRAY)
    theme.set_font_size("font_size", "target_circle_fake", SIZE_CAPTION)
    theme.set_stylebox("normal", "target_circle_fake", _target_stylebox(NEUTRAL_LIGHT_GRAY, true))
    theme.set_stylebox("hover", "target_circle_fake", _target_stylebox(NEUTRAL_LIGHT_GRAY, true))
    theme.set_stylebox("pressed", "target_circle_fake", _target_stylebox(_darken(NEUTRAL_LIGHT_GRAY, 0.85), true))
    theme.set_stylebox("disabled", "target_circle_fake", _target_stylebox(NEUTRAL_LIGHT_GRAY, true))


## v2: Animated Intellectual 用の variation 群。
## DESIGN.md ("The Playful Polymath") に準拠し、blue primary + 3D button +
## glassmorphism + circular ability icon を提供する。
##
## 既存の gold 系 variation (cta_gradient, hero_card, pill_chip など) は
## 後方互換のため残置。v2 を使う scene は v2 variation 名を指定する。
func _build_v2_animated_intellectual(theme: Theme) -> void:
    var icon_font := load(ICON_FONT_PATH) as Font

    # --- v2: 3D CTA Button (cta_blue) ---
    # 青グラデ + 下辺 6px の濃い青ストロークで物理的な押下感を演出
    theme.set_type_variation("cta_blue", "Button")
    theme.set_color("font_color", "cta_blue", ON_PRIMARY)
    theme.set_color("font_hover_color", "cta_blue", ON_PRIMARY)
    theme.set_color("font_pressed_color", "cta_blue", ON_PRIMARY)
    theme.set_font_size("font_size", "cta_blue", SIZE_H2)

    var cta_normal := StyleBoxTexture.new()
    var cta_tex := load(TEX_CTA_BLUE) as Texture2D
    if cta_tex != null:
        cta_normal.texture = cta_tex
    cta_normal.content_margin_left = 32
    cta_normal.content_margin_right = 32
    cta_normal.content_margin_top = 22
    cta_normal.content_margin_bottom = 26  # 下に少し厚みを持たせ 3D 感
    theme.set_stylebox("normal", "cta_blue", cta_normal)

    var cta_pressed := StyleBoxTexture.new()
    var cta_p_tex := load(TEX_CTA_BLUE_PRESSED) as Texture2D
    if cta_p_tex != null:
        cta_pressed.texture = cta_p_tex
    cta_pressed.content_margin_left = 32
    cta_pressed.content_margin_right = 32
    cta_pressed.content_margin_top = 26
    cta_pressed.content_margin_bottom = 22
    theme.set_stylebox("pressed", "cta_blue", cta_pressed)
    theme.set_stylebox("hover", "cta_blue", cta_normal)
    theme.set_stylebox("disabled", "cta_blue", cta_normal)

    # --- v2: glass_bubble (speech bubble) ---
    # Glassmorphism 代替: 高 alpha の白 + 広い角丸 + 柔らかい影
    theme.set_type_variation("glass_bubble", "PanelContainer")
    var glass_sb := StyleBoxFlat.new()
    glass_sb.bg_color = Color(1, 1, 1, 0.85)  # ほぼ白 + 透過
    _set_corner_radius(glass_sb, 24)
    glass_sb.content_margin_left = 24
    glass_sb.content_margin_right = 24
    glass_sb.content_margin_top = 18
    glass_sb.content_margin_bottom = 18
    glass_sb.shadow_color = Color(0.137, 0.173, 0.318, 0.10)  # on_surface 10%
    glass_sb.shadow_offset = Vector2(0, 10)
    glass_sb.shadow_size = 28
    theme.set_stylebox("panel", "glass_bubble", glass_sb)

    # --- v2: header_pill (脳年齢/ゴーストバトルの丸っこいカード) ---
    # No-Line rule: ボーダーなし、surface container tier で境界を作る
    theme.set_type_variation("header_pill", "PanelContainer")
    var hp_sb := StyleBoxFlat.new()
    hp_sb.bg_color = Color(1, 1, 1, 0.78)
    _set_corner_radius(hp_sb, 20)
    hp_sb.content_margin_left = 16
    hp_sb.content_margin_right = 16
    hp_sb.content_margin_top = 12
    hp_sb.content_margin_bottom = 12
    hp_sb.shadow_color = Color(0.137, 0.173, 0.318, 0.08)
    hp_sb.shadow_offset = Vector2(0, 6)
    hp_sb.shadow_size = 20
    theme.set_stylebox("panel", "header_pill", hp_sb)

    # --- v2: ability_container (6 能力アビリティカードの親) ---
    theme.set_type_variation("ability_container", "PanelContainer")
    var ac_sb := StyleBoxFlat.new()
    ac_sb.bg_color = Color(1, 1, 1, 0.85)
    _set_corner_radius(ac_sb, 28)
    ac_sb.content_margin_left = 20
    ac_sb.content_margin_right = 20
    ac_sb.content_margin_top = 18
    ac_sb.content_margin_bottom = 18
    ac_sb.shadow_color = Color(0.137, 0.173, 0.318, 0.08)
    ac_sb.shadow_offset = Vector2(0, 10)
    ac_sb.shadow_size = 32
    theme.set_stylebox("panel", "ability_container", ac_sb)

    # --- v2: ability_circle (6 能力の円形アイコン背景) ---
    # TextureRect で ability_circle_blue.png を使う方式と、StyleBoxTexture を
    # TextureRect に当てる方式があるが、ここでは TextureRect + PanelContainer
    # ラップで実現する想定。本 variation は PanelContainer に適用する
    # circular bg (StyleBoxFlat + pill corner) として定義
    theme.set_type_variation("ability_circle", "PanelContainer")
    var circ_sb := StyleBoxFlat.new()
    circ_sb.bg_color = PRIMARY_BLUE
    _set_corner_radius(circ_sb, 9999)
    circ_sb.content_margin_left = 10
    circ_sb.content_margin_right = 10
    circ_sb.content_margin_top = 10
    circ_sb.content_margin_bottom = 10
    circ_sb.shadow_color = Color(0, 0.345, 0.729, 0.35)
    circ_sb.shadow_offset = Vector2(0, 4)
    circ_sb.shadow_size = 10
    theme.set_stylebox("panel", "ability_circle", circ_sb)

    # --- v2: icon_ability_white (アビリティ円内のアイコン、白色) ---
    if icon_font != null:
        theme.set_type_variation("icon_ability_white", "Label")
        theme.set_font("font", "icon_ability_white", icon_font)
        theme.set_font_size("font_size", "icon_ability_white", 26)
        theme.set_color("font_color", "icon_ability_white", Color(1, 1, 1))

    # --- v2: ability_label (アビリティ下のキャプション) ---
    theme.set_type_variation("ability_label", "Label")
    theme.set_font_size("font_size", "ability_label", 12)
    theme.set_color("font_color", "ability_label", ON_SURFACE_V2)

    # --- v2: display_primary (大型数値、青色) ---
    theme.set_type_variation("display_primary", "Label")
    theme.set_font_size("font_size", "display_primary", 32)
    theme.set_color("font_color", "display_primary", PRIMARY_BLUE)

    # --- v2: caption_label (全キャプション用、v2 色) ---
    theme.set_type_variation("caption_v2", "Label")
    theme.set_font_size("font_size", "caption_v2", 11)
    theme.set_color("font_color", "caption_v2", ON_SURFACE_VAR_V2)

    # --- v2: headline_v2 (カード見出し、青系) ---
    theme.set_type_variation("headline_v2", "Label")
    theme.set_font_size("font_size", "headline_v2", 16)
    theme.set_color("font_color", "headline_v2", ON_SURFACE_V2)

    # --- v2: bar_win_v2 / bar_loss_v2 (勝敗バー 青/淡青) ---
    theme.set_type_variation("bar_win_v2", "PanelContainer")
    var bw_sb := StyleBoxFlat.new()
    bw_sb.bg_color = PRIMARY_BLUE
    bw_sb.corner_radius_top_left = 12
    bw_sb.corner_radius_bottom_left = 12
    bw_sb.content_margin_left = 10
    bw_sb.content_margin_right = 6
    bw_sb.content_margin_top = 4
    bw_sb.content_margin_bottom = 4
    theme.set_stylebox("panel", "bar_win_v2", bw_sb)

    theme.set_type_variation("bar_loss_v2", "PanelContainer")
    var bl_sb := StyleBoxFlat.new()
    bl_sb.bg_color = SURFACE_HIGH_V2
    bl_sb.corner_radius_top_right = 12
    bl_sb.corner_radius_bottom_right = 12
    bl_sb.content_margin_left = 6
    bl_sb.content_margin_right = 10
    bl_sb.content_margin_top = 4
    bl_sb.content_margin_bottom = 4
    theme.set_stylebox("panel", "bar_loss_v2", bl_sb)

    theme.set_type_variation("bar_text_win_v2", "Label")
    theme.set_font_size("font_size", "bar_text_win_v2", 11)
    theme.set_color("font_color", "bar_text_win_v2", ON_PRIMARY)

    theme.set_type_variation("bar_text_loss_v2", "Label")
    theme.set_font_size("font_size", "bar_text_loss_v2", 11)
    theme.set_color("font_color", "bar_text_loss_v2", ON_SURFACE_VAR_V2)

    # --- v2: nav_tab_active (ホームタブのアクティブ状態、青のピル) ---
    theme.set_type_variation("nav_tab_active", "PanelContainer")
    var nav_active_sb := StyleBoxFlat.new()
    nav_active_sb.bg_color = PRIMARY_BLUE
    _set_corner_radius(nav_active_sb, 18)
    nav_active_sb.content_margin_left = 14
    nav_active_sb.content_margin_right = 14
    nav_active_sb.content_margin_top = 8
    nav_active_sb.content_margin_bottom = 8
    nav_active_sb.shadow_color = Color(0, 0.345, 0.729, 0.35)
    nav_active_sb.shadow_offset = Vector2(0, 4)
    nav_active_sb.shadow_size = 10
    theme.set_stylebox("panel", "nav_tab_active", nav_active_sb)

    # アクティブタブ内のアイコン + ラベルは白
    if icon_font != null:
        theme.set_type_variation("icon_nav_active_v2", "Label")
        theme.set_font("font", "icon_nav_active_v2", icon_font)
        theme.set_font_size("font_size", "icon_nav_active_v2", 24)
        theme.set_color("font_color", "icon_nav_active_v2", Color(1, 1, 1))

    theme.set_type_variation("nav_label_active_v2", "Label")
    theme.set_font_size("font_size", "nav_label_active_v2", 10)
    theme.set_color("font_color", "nav_label_active_v2", Color(1, 1, 1))

    # 非アクティブ nav v2
    theme.set_type_variation("nav_label_v2", "Label")
    theme.set_font_size("font_size", "nav_label_v2", 10)
    theme.set_color("font_color", "nav_label_v2", ON_SURFACE_VAR_V2)

    if icon_font != null:
        theme.set_type_variation("icon_nav_v2", "Label")
        theme.set_font("font", "icon_nav_v2", icon_font)
        theme.set_font_size("font_size", "icon_nav_v2", 24)
        theme.set_color("font_color", "icon_nav_v2", ON_SURFACE_VAR_V2)


func _target_stylebox(bg: Color, pill: bool) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    # 大きな角丸でほぼ円形に見せる
    var r: int = 9999 if pill else 16
    sb.corner_radius_top_left = r
    sb.corner_radius_top_right = r
    sb.corner_radius_bottom_left = r
    sb.corner_radius_bottom_right = r
    sb.content_margin_left = 0
    sb.content_margin_right = 0
    sb.content_margin_top = 0
    sb.content_margin_bottom = 0
    sb.shadow_color = Color(0, 0, 0, 0.18)
    sb.shadow_offset = Vector2(0, 4)
    sb.shadow_size = 12
    return sb


## Material Symbols Rounded によるアイコン variation 群。
## Label に `theme_type_variation = "icon_nav"` 等を設定し、text に Material Symbols の
## リガチャ名 (例: "home", "settings", "calendar_month") を入れることでアイコンが描画される。
##
## リガチャ名の一覧: https://fonts.google.com/icons?icon.set=Material+Symbols&icon.style=Rounded
func _build_icon_variations(theme: Theme) -> void:
    var icon_font := load(ICON_FONT_PATH) as Font
    if icon_font == null:
        push_error("[build_theme] Failed to load icon font: %s" % ICON_FONT_PATH)
        return

    # icon_nav: ボトムナビ用 (28pt)
    theme.set_type_variation("icon_nav", "Label")
    theme.set_font("font", "icon_nav", icon_font)
    theme.set_font_size("font_size", "icon_nav", 28)
    theme.set_color("font_color", "icon_nav", NEUTRAL_GRAY)

    # icon_pill: HUD ピル用 (20pt、アイコンは小さめでラベル数値と並ぶ)
    theme.set_type_variation("icon_pill", "Label")
    theme.set_font("font", "icon_pill", icon_font)
    theme.set_font_size("font_size", "icon_pill", 20)
    theme.set_color("font_color", "icon_pill", POSITIVE_GOLD)

    # icon_card: アクションカード用 (32pt、カテゴリアイコンの主役級)
    theme.set_type_variation("icon_card", "Label")
    theme.set_font("font", "icon_card", icon_font)
    theme.set_font_size("font_size", "icon_card", 32)
    theme.set_color("font_color", "icon_card", BG_DARK)

    # icon_hero: ヒーロー CTA の前置アイコン (24pt)
    theme.set_type_variation("icon_hero", "Label")
    theme.set_font("font", "icon_hero", icon_font)
    theme.set_font_size("font_size", "icon_hero", 24)
    theme.set_color("font_color", "icon_hero", BG_DARK)

    # icon_tip: ヒントカードの電球アイコン (24pt、アクセントブルー)
    theme.set_type_variation("icon_tip", "Label")
    theme.set_font("font", "icon_tip", icon_font)
    theme.set_font_size("font_size", "icon_tip", 24)
    theme.set_color("font_color", "icon_tip", ACCENT_BLUE)


## 吹き出し (SpeechBubble) の PanelContainer variation。
## 現段階では角丸のみ (尾びれは iter10 以降で TextureRect 追加予定)。
func _build_speech_bubble(theme: Theme) -> void:
    theme.set_type_variation("speech_bubble", "PanelContainer")
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(1, 1, 1, 1)
    _set_corner_radius(sb, 20)
    sb.content_margin_left = 18
    sb.content_margin_right = 18
    sb.content_margin_top = 16
    sb.content_margin_bottom = 16
    sb.border_width_left = 0
    sb.border_width_right = 0
    sb.border_width_top = 0
    sb.border_width_bottom = 3
    sb.border_color = NEUTRAL_LIGHT_GRAY
    sb.shadow_color = Color(0, 0, 0, 0.15)
    sb.shadow_offset = Vector2(0, 4)
    sb.shadow_size = 12
    theme.set_stylebox("panel", "speech_bubble", sb)


func _cta_gradient_stylebox(tex_path: String, pressed: bool) -> StyleBoxTexture:
    var sb := StyleBoxTexture.new()
    var tex := load(tex_path) as Texture2D
    if tex != null:
        sb.texture = tex
    sb.content_margin_left = 32
    sb.content_margin_right = 32
    var offset := 2 if pressed else 0
    sb.content_margin_top = 20 + offset
    sb.content_margin_bottom = 20 - offset
    return sb


func _build_progress_bar(theme: Theme) -> void:
    # ProgressBar: 背景 = NEUTRAL_LIGHT_GRAY、fill = POSITIVE_GOLD（ブランド色）
    # 角丸はバーの高さに合わせて pill 風にしたいが、高さ可変のため固定 4px 角丸
    var bg := StyleBoxFlat.new()
    bg.bg_color = NEUTRAL_LIGHT_GRAY
    bg.corner_radius_top_left = 4
    bg.corner_radius_top_right = 4
    bg.corner_radius_bottom_left = 4
    bg.corner_radius_bottom_right = 4
    theme.set_stylebox("background", "ProgressBar", bg)

    var fill := StyleBoxFlat.new()
    fill.bg_color = POSITIVE_GOLD
    fill.corner_radius_top_left = 4
    fill.corner_radius_top_right = 4
    fill.corner_radius_bottom_left = 4
    fill.corner_radius_bottom_right = 4
    theme.set_stylebox("fill", "ProgressBar", fill)

    theme.set_color("font_color", "ProgressBar", BG_DARK)
    theme.set_font_size("font_size", "ProgressBar", SIZE_CAPTION)


func _card_stylebox(shadow_col: Color, shadow_off: Vector2, shadow_sz: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = BG_LIGHT
    _set_corner_radius(sb, RADIUS_MD)
    sb.content_margin_left = SPACE_MD
    sb.content_margin_right = SPACE_MD
    sb.content_margin_top = SPACE_MD
    sb.content_margin_bottom = SPACE_MD
    sb.shadow_color = shadow_col
    sb.shadow_offset = shadow_off
    sb.shadow_size = shadow_sz
    return sb


func _set_corner_radius(sb: StyleBoxFlat, radius: int) -> void:
    sb.corner_radius_top_left = radius
    sb.corner_radius_top_right = radius
    sb.corner_radius_bottom_left = radius
    sb.corner_radius_bottom_right = radius


func _darken(color: Color, factor: float) -> Color:
    # HSV ベースで v を下げると色味が保たれる（RGB 乗算だとグレーに寄る）
    var h := color.h
    var s := color.s
    var v := color.v * factor
    var result := Color.from_hsv(h, s, v)
    result.a = color.a
    return result
