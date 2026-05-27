## build_sumi_theme.gd
##
## Brain Ghost 墨絵テーマ v4 (Sumi Ghost) の Theme リソースを生成する。
## 値の出典: docs/design/sumi_ghost_design_system.md / scripts/constants/colors.gd
##
## 実行方法:
##     godot --headless --script scripts_build/build_sumi_theme.gd
##
## 出力: res://assets/themes/sumi_theme.tres
extends SceneTree

const THEME_OUT := "res://assets/themes/sumi_theme.tres"

const FONT_SERIF := "res://assets/fonts/NotoSerifJP-Bold.otf"
const FONT_SANS  := "res://assets/fonts/NotoSansJP-Bold.otf"
const FONT_SPACE := "res://assets/fonts/SpaceGrotesk-Bold.ttf"
const FONT_MONO  := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const FONT_ICON  := "res://assets/fonts/MaterialSymbolsRounded.ttf"

# ボタンテクスチャ
const TEX_BTN_PRIMARY   := "res://assets/textures/buttons/btn_primary.png"
const TEX_BTN_SECONDARY := "res://assets/textures/buttons/btn_secondary.png"
const TEX_BTN_ACCENT    := "res://assets/textures/buttons/btn_accent.png"

# SumiColors 値（const は class_name 解決順の問題で参照しにくいため値を直書き）
const WASHI       := Color(0.961, 0.941, 0.910)  # #F5F0E8
const SUMI_DARK   := Color(0.173, 0.173, 0.173)  # #2C2C2C
const SUMI_LIGHT  := Color(0.549, 0.549, 0.549)  # #8C8C8C
const HITODAMA    := Color(0.722, 0.847, 0.910)  # #B8D8E8
const WAKATAKE    := Color(0.490, 0.722, 0.541)  # #7DB88A
const KINDEI      := Color(0.788, 0.659, 0.298)  # #C9A84C
const SHU         := Color(0.784, 0.353, 0.290)  # #C85A4A
const GINNEZUMI   := Color(0.620, 0.631, 0.640)  # #9EA1A3

const SIZE_BODY := 16
const SIZE_CAPTION := 12
const SIZE_BUTTON := 18
const SIZE_H2 := 22
const SIZE_H1 := 28
const SIZE_DISPLAY := 48

const RADIUS_MD := 12
const RADIUS_LG := 20


func _init() -> void:
	print("[build_sumi_theme] start")
	var serif := load(FONT_SERIF) as Font
	if serif == null:
		push_error("[build_sumi_theme] missing serif font; run --headless --import first")
		quit(1); return

	# 数字フォント (Space Grotesk Bold) — 取得失敗時は Sans にフォールバック
	var space_font: Font = load(FONT_SPACE) as Font
	if space_font == null:
		print("[build_sumi_theme] Space Grotesk not found, falling back to Sans")
		space_font = load(FONT_SANS) as Font

	# 等幅 (JetBrains Mono Regular) — 取得失敗時は Sans にフォールバック
	var mono_font: Font = load(FONT_MONO) as Font
	if mono_font == null:
		print("[build_sumi_theme] JetBrains Mono not found, falling back to Sans")
		mono_font = load(FONT_SANS) as Font

	var icon_font := load(FONT_ICON) as Font

	var theme := Theme.new()
	theme.default_font = serif
	theme.default_font_size = SIZE_BODY

	_build_button(theme, serif)
	_build_label(theme, serif, space_font, mono_font)
	_build_panel(theme)
	_build_progress_bar(theme)
	_build_icon_variations(theme, icon_font)

	var err := ResourceSaver.save(theme, THEME_OUT)
	if err != OK:
		push_error("[build_sumi_theme] save failed err=%d" % err)
		quit(1); return
	print("[build_sumi_theme] saved: %s" % THEME_OUT)
	quit(0)


func _build_button(theme: Theme, serif: Font) -> void:
	# デフォルト Button: プライマリ (墨色ボタン、白テキスト)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", SUMI_LIGHT)
	theme.set_font_size("font_size", "Button", SIZE_BUTTON)

	# プライマリは btn_primary.png NinePatch
	theme.set_stylebox("normal", "Button", _btn_stylebox(TEX_BTN_PRIMARY))
	theme.set_stylebox("hover", "Button", _btn_stylebox(TEX_BTN_PRIMARY))
	theme.set_stylebox("pressed", "Button", _btn_stylebox(TEX_BTN_PRIMARY))
	theme.set_stylebox("disabled", "Button", _btn_stylebox(TEX_BTN_PRIMARY))

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_width_left = 2; focus.border_width_right = 2
	focus.border_width_top = 2; focus.border_width_bottom = 2
	focus.border_color = HITODAMA
	_set_corner_radius(focus, RADIUS_LG)
	theme.set_stylebox("focus", "Button", focus)

	# Secondary variation: 和紙地 + 墨色テキスト
	theme.set_type_variation("btn_secondary", "Button")
	theme.set_color("font_color", "btn_secondary", SUMI_DARK)
	theme.set_color("font_hover_color", "btn_secondary", SUMI_DARK)
	theme.set_color("font_pressed_color", "btn_secondary", SUMI_DARK)
	theme.set_font_size("font_size", "btn_secondary", SIZE_BUTTON)
	theme.set_stylebox("normal", "btn_secondary", _btn_stylebox(TEX_BTN_SECONDARY))
	theme.set_stylebox("hover", "btn_secondary", _btn_stylebox(TEX_BTN_SECONDARY))
	theme.set_stylebox("pressed", "btn_secondary", _btn_stylebox(TEX_BTN_SECONDARY))
	theme.set_stylebox("disabled", "btn_secondary", _btn_stylebox(TEX_BTN_SECONDARY))

	# Accent variation: 朱色 + 白テキスト
	theme.set_type_variation("btn_accent", "Button")
	theme.set_color("font_color", "btn_accent", Color.WHITE)
	theme.set_color("font_hover_color", "btn_accent", Color.WHITE)
	theme.set_color("font_pressed_color", "btn_accent", Color.WHITE)
	theme.set_font_size("font_size", "btn_accent", SIZE_BUTTON)
	theme.set_stylebox("normal", "btn_accent", _btn_stylebox(TEX_BTN_ACCENT))
	theme.set_stylebox("hover", "btn_accent", _btn_stylebox(TEX_BTN_ACCENT))
	theme.set_stylebox("pressed", "btn_accent", _btn_stylebox(TEX_BTN_ACCENT))
	theme.set_stylebox("disabled", "btn_accent", _btn_stylebox(TEX_BTN_ACCENT))


func _btn_stylebox(tex_path: String) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	var tex := load(tex_path) as Texture2D
	if tex != null:
		sb.texture = tex
	# NinePatch マージン (Godot 4: texture_margin_*)
	sb.texture_margin_left = 24
	sb.texture_margin_right = 24
	sb.texture_margin_top = 24
	sb.texture_margin_bottom = 24
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


func _build_label(theme: Theme, serif: Font, space_font: Font, mono_font: Font) -> void:
	# デフォルト Label: 本文 / Noto Serif JP / 墨色
	theme.set_color("font_color", "Label", SUMI_DARK)
	theme.set_font_size("font_size", "Label", SIZE_BODY)

	# 見出し系
	theme.set_type_variation("h1", "Label")
	theme.set_font_size("font_size", "h1", SIZE_H1)
	theme.set_color("font_color", "h1", SUMI_DARK)

	theme.set_type_variation("h2", "Label")
	theme.set_font_size("font_size", "h2", SIZE_H2)
	theme.set_color("font_color", "h2", SUMI_DARK)

	theme.set_type_variation("caption", "Label")
	theme.set_font_size("font_size", "caption", SIZE_CAPTION)
	theme.set_color("font_color", "caption", SUMI_LIGHT)

	# 数字系: Space Grotesk (スコア・脳年齢)
	theme.set_type_variation("score", "Label")
	theme.set_font("font", "score", space_font)
	theme.set_font_size("font_size", "score", 36)
	theme.set_color("font_color", "score", SUMI_DARK)

	theme.set_type_variation("score_big", "Label")
	theme.set_font("font", "score_big", space_font)
	theme.set_font_size("font_size", "score_big", SIZE_DISPLAY)
	theme.set_color("font_color", "score_big", SUMI_DARK)

	# 等幅: タイマー・反応時間
	theme.set_type_variation("timer", "Label")
	theme.set_font("font", "timer", mono_font)
	theme.set_font_size("font_size", "timer", 18)
	theme.set_color("font_color", "timer", SUMI_DARK)

	# 状態色変種
	theme.set_type_variation("text_light", "Label")
	theme.set_font_size("font_size", "text_light", SIZE_BODY)
	theme.set_color("font_color", "text_light", SUMI_LIGHT)

	theme.set_type_variation("text_win", "Label")
	theme.set_font_size("font_size", "text_win", SIZE_BODY)
	theme.set_color("font_color", "text_win", WAKATAKE)

	theme.set_type_variation("text_lose", "Label")
	theme.set_font_size("font_size", "text_lose", SIZE_BODY)
	theme.set_color("font_color", "text_lose", GINNEZUMI)

	theme.set_type_variation("text_accent", "Label")
	theme.set_font_size("font_size", "text_accent", SIZE_BODY)
	theme.set_color("font_color", "text_accent", SHU)


func _build_panel(theme: Theme) -> void:
	# default Panel: 透明 (背景は WashiBackground TextureRect で別途敷く)
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "Panel", StyleBoxEmpty.new())

	# washi_card variation: 和紙色 + 細い墨色枠
	theme.set_type_variation("washi_card", "PanelContainer")
	var card := StyleBoxFlat.new()
	card.bg_color = Color(WASHI.r, WASHI.g, WASHI.b, 0.85)
	_set_corner_radius(card, RADIUS_MD)
	card.content_margin_left = 16; card.content_margin_right = 16
	card.content_margin_top = 12; card.content_margin_bottom = 12
	card.border_width_left = 1; card.border_width_right = 1
	card.border_width_top = 1; card.border_width_bottom = 1
	card.border_color = Color(SUMI_DARK.r, SUMI_DARK.g, SUMI_DARK.b, 0.25)
	theme.set_stylebox("panel", "washi_card", card)

	# pill_chip: 丸っこい小カード (脳年齢・スコア表示用)
	theme.set_type_variation("pill_chip", "PanelContainer")
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(WASHI.r, WASHI.g, WASHI.b, 0.9)
	_set_corner_radius(pill, RADIUS_LG)
	pill.content_margin_left = 14; pill.content_margin_right = 14
	pill.content_margin_top = 10; pill.content_margin_bottom = 10
	pill.border_width_bottom = 2
	pill.border_color = Color(SUMI_DARK.r, SUMI_DARK.g, SUMI_DARK.b, 0.18)
	theme.set_stylebox("panel", "pill_chip", pill)


func _build_progress_bar(theme: Theme) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(SUMI_LIGHT.r, SUMI_LIGHT.g, SUMI_LIGHT.b, 0.25)
	_set_corner_radius(bg, 4)
	theme.set_stylebox("background", "ProgressBar", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = HITODAMA
	_set_corner_radius(fill, 4)
	theme.set_stylebox("fill", "ProgressBar", fill)

	theme.set_color("font_color", "ProgressBar", SUMI_DARK)
	theme.set_font_size("font_size", "ProgressBar", SIZE_CAPTION)


func _build_icon_variations(theme: Theme, icon_font: Font) -> void:
	if icon_font == null:
		return

	theme.set_type_variation("icon", "Label")
	theme.set_font("font", "icon", icon_font)
	theme.set_font_size("font_size", "icon", 24)
	theme.set_color("font_color", "icon", SUMI_DARK)

	theme.set_type_variation("icon_lg", "Label")
	theme.set_font("font", "icon_lg", icon_font)
	theme.set_font_size("font_size", "icon_lg", 36)
	theme.set_color("font_color", "icon_lg", SUMI_DARK)

	theme.set_type_variation("icon_accent", "Label")
	theme.set_font("font", "icon_accent", icon_font)
	theme.set_font_size("font_size", "icon_accent", 24)
	theme.set_color("font_color", "icon_accent", SHU)

	theme.set_type_variation("icon_blue", "Label")
	theme.set_font("font", "icon_blue", icon_font)
	theme.set_font_size("font_size", "icon_blue", 24)
	theme.set_color("font_color", "icon_blue", HITODAMA)


func _set_corner_radius(sb: StyleBoxFlat, r: int) -> void:
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
