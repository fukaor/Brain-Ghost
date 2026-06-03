## GameListCard — ゲーム一覧カード 1 枚分（コンポーネント 2-6）
##
## 参照: docs/ideas/sumi-theme/references/game_cards.png / card_states.png
## Sumi Ghost (墨絵調) v4。縦 160×200 の PanelContainer。
##   MarginContainer(12) → VBox(center) → [アイコン / ゲーム名 / 能力 / ベスト記録]
##
## アイコンは Material Symbols グリフ（ligature）テキスト。絵文字は色フォント
## 非搭載のため使わない（README 方針）。汚染パーツ game_icon_* は texture 直貼り
## せず、将来差し替え用に @export var texture_icon のみ用意する。
##
## 状態は @export（is_locked / is_new / is_selected）で切替し、StyleBoxFlat の
## bg/border を差し替える。hover で地色を僅かに持ち上げ、press で 0.97→1.0 の
## scale tween を掛ける。タップで card_pressed(game_id) を発火する。
@tool
class_name GameListCard
extends PanelContainer

signal card_pressed(game_id: String)

const _C := preload("res://scripts/constants/colors.gd")

const _CORNER_RADIUS: int = 10
const _HOVER_ALPHA_BOOST: float = 0.05
const _PRESS_SCALE: float = 0.97
const _PRESS_TWEEN_SEC: float = 0.1

@export var game_id: String = "":
	set(v):
		game_id = v
@export var game_name: String = "ゲーム名":
	set(v):
		game_name = v
		_apply_content()
@export var ability_label: String = "能力":
	set(v):
		ability_label = v
		_apply_content()
## Material Symbols ligature 名 or emoji。
@export var icon_text: String = "sports_esports":
	set(v):
		icon_text = v
		_apply_content()
@export var best_score: String = "":
	set(v):
		best_score = v
		_apply_content()
@export var is_locked: bool = false:
	set(v):
		is_locked = v
		_apply_state()
@export var is_new: bool = false:
	set(v):
		is_new = v
		_apply_state()
@export var is_selected: bool = false:
	set(v):
		is_selected = v
		_apply_state()
## 将来 game_icon_*.png 等のクリーンアセットが用意できたら差し替える枠。
@export var texture_icon: Texture2D = null:
	set(v):
		texture_icon = v
		_apply_content()

@onready var _icon: Label = $Margin/VBox/Icon
@onready var _icon_tex: TextureRect = $Margin/VBox/IconTex
@onready var _name_label: Label = $Margin/VBox/Name
@onready var _ability_label: Label = $Margin/VBox/Ability
@onready var _best_label: Label = $Margin/VBox/Best
@onready var _lock_overlay: Label = $LockOverlay
@onready var _new_badge: Label = $NewBadge

var _hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = custom_minimum_size * 0.5
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	_apply_content()
	_apply_state()


func _apply_content() -> void:
	if not is_node_ready():
		return
	# テクスチャが渡された場合のみ画像アイコン、なければ Material Symbols テキスト。
	if texture_icon != null:
		_icon_tex.texture = texture_icon
		_icon_tex.visible = true
		_icon.visible = false
	else:
		_icon.text = icon_text
		_icon.visible = true
		_icon_tex.visible = false
	_name_label.text = game_name
	_ability_label.text = ability_label
	# ロック時はベスト欄を空にし、中央のロックオーバーレイで表現する
	# （絵文字 🔒 は色フォント非搭載のため使わず、Material Symbols の lock を中央に出す）。
	if is_locked:
		_best_label.text = ""
	else:
		_best_label.text = best_score if best_score != "" else "ベスト --"


func _apply_state() -> void:
	if not is_node_ready():
		return
	_new_badge.visible = is_new and not is_locked
	_lock_overlay.visible = is_locked
	var dim := 0.4 if is_locked else 1.0
	for n in [_icon, _icon_tex, _name_label, _ability_label, _best_label]:
		(n as CanvasItem).modulate.a = dim
	add_theme_stylebox_override("panel", _build_panel_style(_hovered))


## 状態に応じた StyleBoxFlat を生成する。
## normal: 地=WASHI / 枠 1px SUMI_LIGHT
## locked: 地=SUMI_LIGHT a0.1 / 枠 1px SUMI_LIGHT
## selected: 枠 2px HITODAMA
## hover: 地色の alpha を僅かに持ち上げる
func _build_panel_style(hovered: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(_CORNER_RADIUS)
	sb.set_content_margin_all(0)
	if is_locked:
		var bg := _C.SUMI_LIGHT
		bg.a = 0.1
		sb.bg_color = bg
		sb.set_border_width_all(1)
		sb.border_color = _C.SUMI_LIGHT
	else:
		var bg := _C.WASHI
		if hovered:
			bg = bg.lightened(_HOVER_ALPHA_BOOST)
		sb.bg_color = bg
		if is_selected:
			sb.set_border_width_all(2)
			sb.border_color = _C.HITODAMA
		else:
			sb.set_border_width_all(1)
			sb.border_color = _C.SUMI_LIGHT
	return sb


func _on_mouse_entered() -> void:
	_hovered = true
	if not is_locked:
		add_theme_stylebox_override("panel", _build_panel_style(true))


func _on_mouse_exited() -> void:
	_hovered = false
	add_theme_stylebox_override("panel", _build_panel_style(false))


func _on_gui_input(event: InputEvent) -> void:
	if is_locked:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_play_press_tween()
			card_pressed.emit(game_id)


func _play_press_tween() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(_PRESS_SCALE, _PRESS_SCALE)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, _PRESS_TWEEN_SEC) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
