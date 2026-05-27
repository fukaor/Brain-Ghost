## GameListCard
##
## 脳トレ一覧画面の 1 枚のカード。Sumi Ghost (墨絵調) v4 スタイル。
## NinePatchRect 背景 + HBox(icon + VBox(name / skill / best)) を内包し、
## 状態 (通常 / NEW / ロック / 選択中) を `set_state()` で切替する。
##
## クリック検出のため `gui_input` を購読し、`tapped(game_id)` を発火する。
class_name GameListCard
extends NinePatchRect

signal tapped(game_id: String)

enum State { NORMAL, NEW, LOCKED, SELECTED }

const FRAME_NORMAL: Texture2D = preload("res://assets/textures/frames/frame_ink_border.png")
const FRAME_NEW: Texture2D = preload("res://assets/textures/frames/frame_ink_border_new.png")
const FRAME_LOCKED: Texture2D = preload("res://assets/textures/frames/frame_ink_border_locked.png")
const FRAME_SELECTED: Texture2D = preload("res://assets/textures/frames/frame_ink_border_selected.png")

const BADGE_NEW: Texture2D = preload("res://assets/textures/badges/badge_new_corner.png")
const ICON_LOCK: Texture2D = preload("res://assets/textures/badges/icon_lock.png")

@onready var _icon: TextureRect = $Margin/Row/Icon
@onready var _name_label: Label = $Margin/Row/VBox/Name
@onready var _skill_label: Label = $Margin/Row/VBox/Skill
@onready var _best_label: Label = $Margin/Row/VBox/Best
@onready var _new_badge: TextureRect = $NewBadge
@onready var _lock_overlay: TextureRect = $LockOverlay

var _game_id: String = ""
var _state: State = State.NORMAL


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_apply_state()


func set_card(game_id: String, icon_tex: Texture2D, name_text: String, skill_text: String, best_text: String) -> void:
	_game_id = game_id
	if _icon:
		_icon.texture = icon_tex
	if _name_label:
		_name_label.text = name_text
	if _skill_label:
		_skill_label.text = skill_text
	if _best_label:
		_best_label.text = best_text


func set_state(s: int) -> void:
	_state = s as State
	_apply_state()


func _apply_state() -> void:
	# 既定 (ノード未準備時) は no-op
	if _new_badge == null or _lock_overlay == null:
		return
	match _state:
		State.NORMAL:
			texture = FRAME_NORMAL
			_new_badge.visible = false
			_lock_overlay.visible = false
			modulate = Color(1, 1, 1, 1)
		State.NEW:
			texture = FRAME_NEW
			_new_badge.visible = true
			_lock_overlay.visible = false
			modulate = Color(1, 1, 1, 1)
		State.LOCKED:
			texture = FRAME_LOCKED
			_new_badge.visible = false
			_lock_overlay.visible = true
			modulate = Color(1, 1, 1, 0.55)
		State.SELECTED:
			texture = FRAME_SELECTED
			_new_badge.visible = false
			_lock_overlay.visible = false
			modulate = Color(1, 1, 1, 1)


func _on_gui_input(event: InputEvent) -> void:
	if _state == State.LOCKED:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(_game_id)
