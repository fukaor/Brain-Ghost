## SumiButton — 共通ボタン（コンポーネント 2-8）
##
## ベース: Button。3 バリアント（PRIMARY / SECONDARY / ACCENT）を StyleBoxFlat で構築する。
## 汚染パーツ btn_*.png は使わない（README 方針）。将来クリーンな質感パーツが
## 用意できたら texture_bg で差し替え可能。
@tool
class_name SumiButton
extends Button

enum ButtonStyle { PRIMARY, SECONDARY, ACCENT }

const CORNER_RADIUS := 6
const HOVER_ALPHA := 0.85
const PRESS_SCALE := 0.97
const PRESS_TWEEN_SEC := 0.08

@export var button_style: ButtonStyle = ButtonStyle.PRIMARY:
	set(value):
		button_style = value
		_rebuild_styles()
@export var label_text: String = "ボタン":
	set(value):
		label_text = value
		text = value
## 将来 btn_*.png のクリーン版に差し替えるためのフック（設定時は塗りに優先）。
@export var texture_bg: Texture2D:
	set(value):
		texture_bg = value
		_rebuild_styles()

var _press_tween: Tween


func _ready() -> void:
	# 親シーンで custom_minimum_size を指定済みなら尊重する（埋め込み時に幅を固定しない）
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(280, 48)
	text = label_text
	add_theme_font_size_override("font_size", 16)
	_rebuild_styles()
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _rebuild_styles() -> void:
	var bg: Color
	var fg: Color
	var border: int = 0
	match button_style:
		ButtonStyle.SECONDARY:
			bg = Color(0, 0, 0, 0)
			fg = SumiColors.SUMI_DARK
			border = 1
		ButtonStyle.ACCENT:
			bg = SumiColors.SHU
			fg = Color.WHITE
		_:  # PRIMARY
			bg = SumiColors.SUMI_DARK
			fg = Color.WHITE

	var normal := _make_box(bg, border)
	for state in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, normal)

	# フォーカス枠は人魂青の細枠
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	_set_border(focus, 2, SumiColors.HITODAMA)
	_set_corner(focus)
	add_theme_stylebox_override("focus", focus)

	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(c, fg)


func _make_box(bg: Color, border: int) -> StyleBox:
	if texture_bg != null:
		var st := StyleBoxTexture.new()
		st.texture = texture_bg
		st.texture_margin_left = 24; st.texture_margin_right = 24
		st.texture_margin_top = 24; st.texture_margin_bottom = 24
		st.content_margin_left = 20; st.content_margin_right = 20
		st.content_margin_top = 12; st.content_margin_bottom = 12
		return st
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	_set_corner(box)
	box.content_margin_left = 20; box.content_margin_right = 20
	box.content_margin_top = 12; box.content_margin_bottom = 12
	if border > 0:
		_set_border(box, border, SumiColors.SUMI_DARK)
	return box


func _set_corner(box: StyleBoxFlat) -> void:
	box.corner_radius_top_left = CORNER_RADIUS
	box.corner_radius_top_right = CORNER_RADIUS
	box.corner_radius_bottom_left = CORNER_RADIUS
	box.corner_radius_bottom_right = CORNER_RADIUS


func _set_border(box: StyleBoxFlat, w: int, c: Color) -> void:
	box.border_width_left = w; box.border_width_right = w
	box.border_width_top = w; box.border_width_bottom = w
	box.border_color = c


# --- 振る舞い ---------------------------------------------------------------
func _on_hover_enter() -> void:
	modulate.a = HOVER_ALPHA

func _on_hover_exit() -> void:
	modulate.a = 1.0

func _on_button_down() -> void:
	_tween_scale(PRESS_SCALE)

func _on_button_up() -> void:
	_tween_scale(1.0)

func _tween_scale(target: float) -> void:
	pivot_offset = size * 0.5
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2(target, target), PRESS_TWEEN_SEC)
