## GameListCard
##
## 脳トレ一覧画面の 1 枚のカード。Sumi Ghost (墨絵調) v4 スタイル。
## washi_card PanelContainer + HBox(IconBadge + VBox(name / skill / best)) を内包し、
## 状態 (通常 / NEW / ロック / 選択中) を `set_state()` で切替する。
##
## 注: 旧実装は frame_ink_border*.png を NinePatchRect の texture として使っていたが、
## それらの PNG は cut_sumi_sheets.py の切り出し範囲不備によりサンプルカード
## (「数字さがし / 観察力 / ベスト:22秒」「竹のイラスト」) が焼き込まれていた。
## 全カードに同じ内容が透ける事故を起こすため、PanelContainer + 状態 modulate に変更。
##
## クリック検出のため `gui_input` を購読し、`tapped(game_id)` を発火する。
class_name GameListCard
extends Control

signal tapped(game_id: String)

enum State { NORMAL, NEW, LOCKED, SELECTED }

const STATE_MODULATE_NORMAL: Color = Color(1, 1, 1, 1)
const STATE_MODULATE_LOCKED: Color = Color(1, 1, 1, 0.55)
const STATE_BORDER_SELECTED: Color = Color(0.722, 0.847, 0.910, 1.0)  # HITODAMA

@onready var _icon_art: TextureRect = $Content/Row/IconArt
@onready var _name_label: Label = $Content/Row/VBox/Name
@onready var _skill_label: Label = $Content/Row/VBox/Skill
@onready var _best_label: Label = $Content/Row/VBox/Best
@onready var _new_badge: TextureRect = $NewBadge
@onready var _lock_overlay: Label = $LockOverlay

var _game_id: String = ""
var _state: State = State.NORMAL


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_apply_state()


## icon_tex はゲーム別アートを表示する TextureRect 用テクスチャ。
## ホーム/ゲーム一覧では game_icon_*_art.png (game_icon_*.png から右側のアート
## 部分のみを切り出したクロップ済みアセット) を渡す。
func set_card(game_id: String, icon_tex: Texture2D, name_text: String, skill_text: String, best_text: String) -> void:
	_game_id = game_id
	if _icon_art:
		_icon_art.texture = icon_tex
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
	if _new_badge == null or _lock_overlay == null:
		return
	match _state:
		State.NORMAL:
			_new_badge.visible = false
			_lock_overlay.visible = false
			modulate = STATE_MODULATE_NORMAL
		State.NEW:
			_new_badge.visible = true
			_lock_overlay.visible = false
			modulate = STATE_MODULATE_NORMAL
		State.LOCKED:
			_new_badge.visible = false
			_lock_overlay.visible = true
			modulate = STATE_MODULATE_LOCKED
		State.SELECTED:
			_new_badge.visible = false
			_lock_overlay.visible = false
			modulate = STATE_MODULATE_NORMAL


func _on_gui_input(event: InputEvent) -> void:
	if _state == State.LOCKED:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(_game_id)
