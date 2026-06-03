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
##
## アイコンは Material Symbols グリフ（ligature）。汚染パーツ game_icon_* の
## texture 直貼りは README 方針で禁止のため使わない。将来クリーンな
## game_icon_*.png が用意できたら GameListCard.texture_icon へ差し替える。
const GAME_CARDS: Array[Dictionary] = [
	{
		"id": "ghost_7ban_shobu",
		"icon": "bolt",
		"name": "ゴースト7番勝負",
		"skill": "反射力",
	},
	{
		"id": "flash_calc",
		"icon": "calculate",
		"name": "フラッシュ暗算",
		"skill": "計算力",
	},
	{
		"id": "sequence_memory",
		"icon": "format_list_numbered",
		"name": "順番記憶",
		"skill": "記憶力",
	},
	{
		"id": "stroop",
		"icon": "palette",
		"name": "色文字ストループ",
		"skill": "注意力",
	},
	{
		"id": "card_match",
		"icon": "style",
		"name": "神経衰弱",
		"skill": "判断力",
	},
	{
		"id": "number_search",
		"icon": "search",
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
		# 新 GameListCard API（@export プロパティ + card_pressed signal）でバインド。
		card_node.game_id = game_id
		card_node.game_name = data["name"]
		card_node.ability_label = data["skill"]
		card_node.icon_text = data["icon"]
		card_node.best_score = best_text
		# 状態判定: 未実装 → ロック、ベスト未登録 → NEW、それ以外 → 通常。
		var locked: bool = not _implemented_games.has(game_id)
		card_node.is_locked = locked
		card_node.is_new = (not locked) and best_text == "ベスト --"
		if card_node.has_signal("card_pressed") and not card_node.card_pressed.is_connected(_on_card_tapped):
			card_node.card_pressed.connect(_on_card_tapped)


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
