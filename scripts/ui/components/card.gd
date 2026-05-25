## CardComponent
##
## 神経衰弱の 1 枚カード。face_down / face_up / matched の 3 状態を持ち、
## 表面は Material Symbols Rounded の図形 + 色で描画する。
##
## 構造: Button (背景/枠/タップ) + 子 Label "_IconLabel" (アイコン描画)
##       Button.text を使わないことで、Button 内部のフォント差し替えタイミング
##       問題を回避し、Label 側で確実に icon を表示する。
##
## 親 (CardMatchView) は:
## - setup(cell_index, card_id) で見た目を設定
## - flip_to_front() / flip_to_back() / set_matched() で状態遷移
## - flash_match() / flash_mismatch() で演出
class_name CardComponent
extends Button

signal card_pressed(cell_index: int)

const _TierConfig = preload("res://scripts/games/card_match/tier_config.gd")
const _MSYM_FONT = preload("res://assets/fonts/MaterialSymbolsRounded.ttf")

# Midnight Cat パレット
const COLOR_BACK_BG := Color(0.04, 0.08, 0.16, 0.85)              # 暗グラス
const COLOR_BACK_BORDER := Color(0.435, 0.706, 1, 0.45)           # CYAN_400 dim

const COLOR_FRONT_BG := Color(0.067, 0.094, 0.153, 0.92)          # 表面背景
const COLOR_FRONT_BORDER := Color(0.722, 0.878, 1, 0.85)          # CYAN_300

const COLOR_MATCH_FLASH_BG := Color(0.157, 0.514, 0.357, 0.95)    # Emerald flash
const COLOR_MATCH_FLASH_BORDER := Color(0.435, 0.847, 0.624, 1)

const COLOR_MISMATCH_FLASH_BG := Color(0.4, 0.42, 0.48, 0.85)     # グレー flash (赤禁止)
const COLOR_MISMATCH_FLASH_BORDER := Color(0.78, 0.824, 0.91, 0.85)

const COLOR_MATCHED_BG := Color(0.067, 0.094, 0.153, 0.4)         # 彩度ダウン
const COLOR_MATCHED_BORDER := Color(0.435, 0.706, 1, 0.18)

const FRONT_ICON_SIZE: int = 56


@export var cell_index: int = -1

var _card_id: int = -1
var _is_face_up: bool = false
var _is_matched: bool = false
var _icon_label: Label


func _ready() -> void:
    pressed.connect(_on_pressed)
    custom_minimum_size = Vector2(96, 96)
    # Button.text は使わない (子 Label に描画を委譲)
    text = ""
    _build_icon_label()
    _apply_back()


func _build_icon_label() -> void:
    _icon_label = Label.new()
    _icon_label.name = "_IconLabel"
    _icon_label.add_theme_font_override("font", _MSYM_FONT)
    _icon_label.add_theme_font_size_override("font_size", FRONT_ICON_SIZE)
    _icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _icon_label.visible = false
    add_child(_icon_label)


# 親から呼ぶ。card_id だけ保持し、表面の見た目は flip_to_front で構築する。
func setup(idx: int, card_id: int) -> void:
    cell_index = idx
    _card_id = card_id


func get_card_id() -> int:
    return _card_id


func is_face_up() -> bool:
    return _is_face_up


func is_matched() -> bool:
    return _is_matched


# --- 状態遷移 ---

func flip_to_front() -> void:
    _is_face_up = true
    _apply_front()


func flip_to_back() -> void:
    _is_face_up = false
    _apply_back()


func set_matched() -> void:
    _is_matched = true
    _is_face_up = true
    _apply_matched()


func flash_match() -> void:
    # flash は背景/枠の色だけ差し替える。アイコンは子 Label が保持する。
    _apply_style(COLOR_MATCH_FLASH_BG, COLOR_MATCH_FLASH_BORDER, 3)


func flash_mismatch() -> void:
    _apply_style(COLOR_MISMATCH_FLASH_BG, COLOR_MISMATCH_FLASH_BORDER, 2)


# --- 入力 ---

func _on_pressed() -> void:
    # face_up / matched は無視 (再タップ防止のための View 側ガード補助。
    # 実際の判定は CardMatch._can_tap() で行う)
    if _is_face_up or _is_matched:
        return
    card_pressed.emit(cell_index)


# --- 見た目 ---

func _apply_back() -> void:
    _apply_style(COLOR_BACK_BG, COLOR_BACK_BORDER, 1)
    if _icon_label != null:
        _icon_label.visible = false


func _apply_front() -> void:
    _apply_style(COLOR_FRONT_BG, COLOR_FRONT_BORDER, 2)
    var visual: Dictionary = _TierConfig.get_card_visual(_card_id)
    if _icon_label != null:
        _icon_label.text = String(visual.get("icon", "circle"))
        _icon_label.add_theme_color_override("font_color", visual.get("color", Color.WHITE))
        _icon_label.visible = true


func _apply_matched() -> void:
    _apply_style(COLOR_MATCHED_BG, COLOR_MATCHED_BORDER, 1)
    var visual: Dictionary = _TierConfig.get_card_visual(_card_id)
    if _icon_label != null:
        _icon_label.text = String(visual.get("icon", "circle"))
        var dim: Color = visual.get("color", Color.WHITE)
        dim.a = 0.4
        _icon_label.add_theme_color_override("font_color", dim)
        _icon_label.visible = true


func _apply_style(bg: Color, border: Color, border_width: int) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_width_left = border_width
    sb.border_width_top = border_width
    sb.border_width_right = border_width
    sb.border_width_bottom = border_width
    sb.border_color = border
    sb.corner_radius_top_left = 12
    sb.corner_radius_top_right = 12
    sb.corner_radius_bottom_right = 12
    sb.corner_radius_bottom_left = 12
    sb.content_margin_left = 6
    sb.content_margin_top = 6
    sb.content_margin_right = 6
    sb.content_margin_bottom = 6
    add_theme_stylebox_override("normal", sb)
    add_theme_stylebox_override("hover", sb)
    add_theme_stylebox_override("pressed", sb)
    add_theme_stylebox_override("disabled", sb)
    add_theme_stylebox_override("focus", sb)
