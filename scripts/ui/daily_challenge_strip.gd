## DailyChallengeStrip — デイリーチャレンジ帯（コンポーネント 2-5）
##
## 参照: docs/ideas/sumi-theme/references/ui_parts_home_daily.png
## 「今日のチャレンジ」見出し + 3 ゲーム枠 + 「始める」(SumiButton ACCENT)。
## アイコンは Material Symbols グリフ（ligature）。絵文字は色フォント非搭載のため使わない。
## 汚染パーツ game_icon_* / hitodama.png は使わず、Material Symbols で代替（README 方針）。
@tool
class_name DailyChallengeStrip
extends PanelContainer

signal start_pressed()

## [{name: String, icon: String(Material Symbols ligature)}] の配列。
@export var challenge_games: Array[Dictionary] = [
	{"name": "ゴースト7番勝負", "icon": "bolt"},
	{"name": "色文字ストループ", "icon": "palette"},
	{"name": "神経衰弱", "icon": "style"},
]:
	set(value):
		challenge_games = value
		_rebuild_games()

@onready var _games_row: HBoxContainer = $Margin/Content/BodyRow/GamesRow
@onready var _start_button: Button = $Margin/Content/BodyRow/StartButton


func _ready() -> void:
	if _start_button.has_signal("pressed"):
		_start_button.pressed.connect(func() -> void: start_pressed.emit())
	_rebuild_games()


func _rebuild_games() -> void:
	if not is_node_ready():
		return
	for c in _games_row.get_children():
		c.queue_free()
	for game in challenge_games:
		_games_row.add_child(_make_game_frame(String(game.get("name", "")), String(game.get("icon", ""))))


func _make_game_frame(game_name: String, icon: String) -> Control:
	var frame := VBoxContainer.new()
	frame.custom_minimum_size = Vector2(80, 0)
	frame.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_theme_constant_override("separation", 4)

	var icon_label := Label.new()
	icon_label.theme_type_variation = &"icon_lg"
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(icon_label)

	var name_label := Label.new()
	name_label.theme_type_variation = &"caption"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.text = game_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(name_label)

	return frame
