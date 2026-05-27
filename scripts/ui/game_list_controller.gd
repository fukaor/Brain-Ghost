## GameListController
##
## 脳トレ一覧画面のコントローラ。Sumi Ghost (墨絵調) v4 スタイル。
## 6 枚の GameListCard を 2 列 GridContainer に展開し、
## タップで GameManager.start_game() を呼び出す。
##
## カルーセル / 3D パースペクティブ風は v3 で廃止し、
## 静的グリッドに簡素化（読み込み速度 + UX の単純化）。
extends Control

## カードデータ (データ駆動)
const GAME_CARDS: Array[Dictionary] = [
	{
		"id": "ghost_7ban_shobu",
		"icon": preload("res://assets/textures/game_icons/game_icon_7ban.png"),
		"name": "ゴースト7番勝負",
		"skill": "反射力",
	},
	{
		"id": "flash_calc",
		"icon": preload("res://assets/textures/game_icons/game_icon_ippon.png"),
		"name": "フラッシュ暗算",
		"skill": "計算力",
	},
	{
		"id": "sequence_memory",
		"icon": preload("res://assets/textures/game_icons/game_icon_sequence.png"),
		"name": "順番記憶",
		"skill": "記憶力",
	},
	{
		"id": "stroop",
		"icon": preload("res://assets/textures/game_icons/game_icon_stroop.png"),
		"name": "色文字ストループ",
		"skill": "注意力",
	},
	{
		"id": "card_match",
		"icon": preload("res://assets/textures/game_icons/game_icon_memory.png"),
		"name": "神経衰弱",
		"skill": "判断力",
	},
	{
		"id": "number_search",
		"icon": preload("res://assets/textures/game_icons/game_icon_search.png"),
		"name": "数字さがし",
		"skill": "観察力",
	},
]

## NEW バッジ対象の game_id (DataStore に best が無いゲームを NEW 扱い)
const NEW_THRESHOLD_BEST: int = 0

@onready var _grid: GridContainer = $SafeArea/MainColumn/Grid
@onready var _back_button: Button = $SafeArea/MainColumn/HeaderRow/BackButton

var _implemented_games: Array[String] = []
var _cards: Array = []


func _ready() -> void:
	_load_implemented_games()
	_populate_cards()
	_back_button.pressed.connect(_on_back_pressed)


func _load_implemented_games() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var scenes: Dictionary = gm.GAME_SCENES
	_implemented_games.assign(scenes.keys())


func _populate_cards() -> void:
	_cards.clear()
	for i in GAME_CARDS.size():
		var card_node := _grid.get_node_or_null("Card%d" % i)
		if card_node == null:
			continue
		_cards.append(card_node)
		var data: Dictionary = GAME_CARDS[i]
		var game_id: String = data["id"]
		var best_text: String = _load_best_score_text(game_id)
		card_node.set_card(game_id, data["icon"], data["name"], data["skill"], best_text)
		# 状態判定: 未実装 → LOCKED、ベスト未登録 → NEW、それ以外 → NORMAL
		var state: int = card_node.State.NORMAL
		if not _implemented_games.has(game_id):
			state = card_node.State.LOCKED
		elif best_text == "ベスト --":
			state = card_node.State.NEW
		card_node.set_state(state)
		if card_node.has_signal("tapped"):
			card_node.tapped.connect(_on_card_tapped)


func _load_best_score_text(game_type: String) -> String:
	var ds := get_node_or_null("/root/DataStore")
	if ds == null or not ds.has_method("load_best"):
		return "ベスト --"
	var best = ds.load_best(game_type)
	if best == null or best.best_score <= NEW_THRESHOLD_BEST:
		return "ベスト --"
	return "ベスト %s" % _format_thousands(best.best_score)


func _on_card_tapped(game_id: String) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("start_game"):
		return
	gm.start_game(game_id)


func _on_back_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_home"):
		gm.go_home()
	else:
		get_tree().change_scene_to_file("res://scenes/main/home.tscn")


static func _format_thousands(n: int) -> String:
	var negative := n < 0
	var s := str(absi(n))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" + result) if negative else result
