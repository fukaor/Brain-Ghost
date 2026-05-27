## NumberCell
##
## 数字さがしのグリッドセル。Button をベースに、normal / found の 2 状態を
## StyleBox で切替する Sumi Ghost 系コンポーネント。
##
## 親 (NumberSearchView) からは:
## - set_number(n) で表示数字を設定
## - mark_found() で緑ハイライトに切替
## - reset() で normal 状態に戻す
##
## tap シグナル: pressed → number_cell_pressed(cell_index: int) を発火。
class_name NumberCell
extends Button

signal number_cell_pressed(cell_index: int)

## グリッド内のセル番号 (0..max_number-1)。
@export var cell_index: int = -1

## このセルに割り当てられた数字 (1..max_number)。
var _number: int = 0
var _is_found: bool = false

# Sumi Ghost (墨絵調) パレット
const COLOR_NORMAL_TEXT := Color(0.957, 0.969, 1, 0.95)              # INK_100
const COLOR_FOUND_TEXT  := Color(0.957, 0.969, 1, 0.65)              # INK_100 dim

const COLOR_NORMAL_BG := Color(0.910, 0.863, 0.753, 0.55)            # 暗グラス
const COLOR_NORMAL_BORDER := Color(0.435, 0.706, 1, 0.25)            # CYAN_400 dim

const COLOR_FOUND_BG := Color(0.157, 0.514, 0.357, 0.92)             # Emerald 系 (game_search.png 準拠)
const COLOR_FOUND_BORDER := Color(0.435, 0.847, 0.624, 1.0)          # Emerald 300

const FONT_SIZE_DEFAULT: int = 32


func _ready() -> void:
    pressed.connect(_on_pressed)
    custom_minimum_size = Vector2(96, 96)
    add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
    add_theme_font_size_override("font_size", FONT_SIZE_DEFAULT)
    _apply_normal_style()


func set_number(n: int) -> void:
    _number = n
    text = str(n)


func get_number() -> int:
    return _number


func mark_found() -> void:
    _is_found = true
    _apply_found_style()
    add_theme_color_override("font_color", COLOR_FOUND_TEXT)


func reset() -> void:
    _is_found = false
    _apply_normal_style()
    add_theme_color_override("font_color", COLOR_NORMAL_TEXT)


func _on_pressed() -> void:
    if _is_found:
        # 既タップ済みは無視 (spec §2-4 表)
        return
    number_cell_pressed.emit(cell_index)


# --- StyleBox ---

func _apply_normal_style() -> void:
    var sb := _build_style(COLOR_NORMAL_BG, COLOR_NORMAL_BORDER, 1)
    add_theme_stylebox_override("normal", sb)
    add_theme_stylebox_override("hover", sb)
    add_theme_stylebox_override("pressed", sb)
    add_theme_stylebox_override("disabled", sb)
    add_theme_stylebox_override("focus", sb)


func _apply_found_style() -> void:
    var sb := _build_style(COLOR_FOUND_BG, COLOR_FOUND_BORDER, 2)
    add_theme_stylebox_override("normal", sb)
    add_theme_stylebox_override("hover", sb)
    add_theme_stylebox_override("pressed", sb)
    add_theme_stylebox_override("disabled", sb)
    add_theme_stylebox_override("focus", sb)


func _build_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_width_left = border_width
    sb.border_width_top = border_width
    sb.border_width_right = border_width
    sb.border_width_bottom = border_width
    sb.border_color = border
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_right = 10
    sb.corner_radius_bottom_left = 10
    sb.content_margin_left = 4
    sb.content_margin_top = 4
    sb.content_margin_right = 4
    sb.content_margin_bottom = 4
    return sb
