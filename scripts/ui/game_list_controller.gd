## GameListController
##
## 脳トレ一覧画面のコントローラ。
## Stitch準拠 3D パースペクティブ風カルーセル。
##
## 6 種のミニゲームを水平ストリップ上に配置し、
## 中央のカードが最も大きく、隣接カードは縮小・減光して奥行きを演出する。
##
## [b]設計原則:[/b]
## - 色・フォント・サイズは Theme 一任（GDScript ハードコード禁止）
## - GAME_CARDS 配列にエントリ追加するだけで新ゲーム対応
## - Platform Autoload 経由のプラットフォーム分岐
extends Control

# ---------------------------------------------------------------------------
# ゲームカード定義（データ駆動）
# ---------------------------------------------------------------------------

const GAME_CARDS: Array[Dictionary] = [
	{"id": "reflex_tap",       "icon": "touch_app",  "category": "REACTION",    "name": "反射タップ",     "desc": "出現するターゲットを即座にタップ！\n反応速度を測定します。",  "metric_caption": "High Score"},
	{"id": "flash_calc",       "icon": "calculate",  "category": "CALCULATION", "name": "フラッシュ暗算", "desc": "次々と表示される数字を暗算。\n計算力を鍛えます。",          "metric_caption": "High Score"},
	{"id": "sequence_memory",  "icon": "graphic_eq", "category": "MEMORY",      "name": "順番記憶",       "desc": "パネルが光る順番を記憶して再現。\n短期記憶をトレーニング。","metric_caption": "High Score"},
	{"id": "stroop",           "icon": "palette",    "category": "ATTENTION",   "name": "色文字テスト",   "desc": "文字の内容ではなく「色」を回答。\n注意力を磨きます。",      "metric_caption": "High Score"},
	{"id": "card_match",       "icon": "layers",     "category": "JUDGMENT",    "name": "神経衰弱",       "desc": "ペアのカードを素早く見つける。\n判断力と記憶力の勝負。",    "metric_caption": "High Score"},
	{"id": "number_search",    "icon": "visibility",  "category": "OBSERVATION", "name": "数字さがし",     "desc": "1 から順番に数字をタップ。\n周辺視野と集中力を強化。",     "metric_caption": "Best Time"},
]

var _implemented_games: Array[String] = []

# ---------------------------------------------------------------------------
# カルーセル設定（水平ストリップ方式）
# ---------------------------------------------------------------------------
const CARD_WIDTH: float = 400.0
const CARD_HEIGHT: float = 600.0

## 隣接カード: 中心からのオフセットとスケール
const ADJACENT_OFFSET_X: float = 300.0
const ADJACENT_SCALE: float = 0.72
const ADJACENT_BRIGHTNESS: float = 0.70
const ADJACENT_ALPHA: float = 0.60

## 遠方カード（2 つ先）
const FAR_OFFSET_X: float = 480.0
const FAR_SCALE: float = 0.52
const FAR_BRIGHTNESS: float = 0.50
const FAR_ALPHA: float = 0.25

const TWEEN_DURATION: float = 0.5
const SWIPE_THRESHOLD: float = 60.0

var _current_index: int = 0
var _drag_accumulator: float = 0.0
var _is_dragging: bool = false
var _carousel_tween: Tween = null

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------
@onready var _carousel_area: Control = $SafeAreaMargin/MainColumn/CarouselArea
@onready var _dot_container: HBoxContainer = $SafeAreaMargin/MainColumn/DotRow/DotIndicators

# ボトムナビ
@onready var _nav_train: Button = $BottomNavPanel/BottomNavBar/NavTrainActive/NavTrainButton
@onready var _nav_analytics: Button = $BottomNavPanel/BottomNavBar/NavAnalyticsButton
@onready var _nav_home: Button = $BottomNavPanel/BottomNavBar/NavHomeButton
@onready var _nav_award: Button = $BottomNavPanel/BottomNavBar/NavAwardButton
@onready var _nav_settings: Button = $BottomNavPanel/BottomNavBar/NavSettingsButton

var _cards: Array[PanelContainer] = []


func _ready() -> void:
	_load_implemented_games()
	_collect_card_nodes()
	_populate_cards()
	_wire_signals()
	_update_dots()
	_update_play_button()
	await get_tree().process_frame
	_apply_carousel_layout(false)


func _load_implemented_games() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and "GAME_SCENES" in gm:
		_implemented_games.assign(gm.GAME_SCENES.keys())


func _collect_card_nodes() -> void:
	_cards.clear()
	for i in range(GAME_CARDS.size()):
		var card: PanelContainer = _carousel_area.get_node_or_null("Card%d" % i)
		if card != null:
			_cards.append(card)


func _populate_cards() -> void:
	for i in range(_cards.size()):
		if i >= GAME_CARDS.size():
			break
		var data: Dictionary = GAME_CARDS[i]
		var card: PanelContainer = _cards[i]

		var icon_label: Label = card.get_node_or_null("CardMargin/CardVBox/IconCircle/IconLabel")
		var category_label: Label = card.get_node_or_null("CardMargin/CardVBox/CategoryLabel")
		var name_label: Label = card.get_node_or_null("CardMargin/CardVBox/GameNameLabel")
		var desc_label: Label = card.get_node_or_null("CardMargin/CardVBox/DescriptionLabel")
		var metric_caption: Label = card.get_node_or_null("CardMargin/CardVBox/MetricPanel/MetricVBox/MetricCaption")
		var metric_value: Label = card.get_node_or_null("CardMargin/CardVBox/MetricPanel/MetricVBox/MetricValue")

		if icon_label != null:
			icon_label.text = data["icon"]
		if category_label != null:
			category_label.text = data["category"]
		if name_label != null:
			name_label.text = data["name"]
		if desc_label != null:
			desc_label.text = data["desc"]
		if metric_caption != null:
			metric_caption.text = data["metric_caption"]
		if metric_value != null:
			metric_value.text = _load_best_score_text(data["id"])


func _load_best_score_text(game_type: String) -> String:
	var ds := get_node_or_null("/root/DataStore")
	if ds == null or not ds.has_method("load_best"):
		return "--"
	var best = ds.load_best(game_type)
	if best == null or best.best_score <= 0:
		return "--"
	return str(best.best_score)


# ---------------------------------------------------------------------------
# シグナル接続
# ---------------------------------------------------------------------------

func _wire_signals() -> void:
	for i in range(_cards.size()):
		_cards[i].gui_input.connect(_on_card_gui_input.bind(i))
		var play_btn: Button = _cards[i].get_node_or_null("CardMargin/CardVBox/CardPlayButton")
		if play_btn != null:
			play_btn.pressed.connect(_on_play_pressed)

	_nav_home.pressed.connect(_on_nav_home)
	_nav_train.pressed.connect(func(): pass)  # 既にこの画面
	_nav_analytics.pressed.connect(func(): print("[GameList] NavAnalytics (TODO)"))
	_nav_award.pressed.connect(func(): print("[GameList] NavAward (TODO)"))
	_nav_settings.pressed.connect(func(): print("[GameList] NavSettings (TODO)"))


func _on_card_gui_input(event: InputEvent, card_index: int) -> void:
	if event is InputEventScreenTouch and event.pressed == false:
		if _is_dragging:
			return
		if card_index == _current_index:
			_try_start_game()
		else:
			_current_index = card_index
			_apply_carousel_layout(true)
			_update_dots()
			_update_play_button()


# ---------------------------------------------------------------------------
# カルーセル操作（水平ストリップ）
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_is_dragging = true
		_drag_accumulator += event.relative.x
		if absf(_drag_accumulator) >= SWIPE_THRESHOLD:
			if _drag_accumulator < 0:
				_navigate_carousel(1)
			else:
				_navigate_carousel(-1)
			_drag_accumulator = 0.0
	elif event is InputEventScreenTouch:
		if event.pressed:
			_drag_accumulator = 0.0
			_is_dragging = false
		else:
			_is_dragging = false
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT:
			_navigate_carousel(-1)
		elif event.keycode == KEY_RIGHT:
			_navigate_carousel(1)


func _navigate_carousel(direction: int) -> void:
	var new_index: int = _current_index + direction
	if new_index < 0:
		new_index = GAME_CARDS.size() - 1
	elif new_index >= GAME_CARDS.size():
		new_index = 0
	_current_index = new_index
	_apply_carousel_layout(true)
	_update_dots()
	_update_play_button()


## 全カードを水平ストリップ上に配置する。
## diff=0 が中央（最大）、±1 が隣接（縮小+減光）、±2 が遠方、それ以上は非表示。
func _apply_carousel_layout(animate: bool) -> void:
	if _carousel_tween != null and _carousel_tween.is_running():
		_carousel_tween.kill()

	var center_x: float = _carousel_area.size.x / 2.0
	var center_y: float = _carousel_area.size.y / 2.0
	var n: int = _cards.size()

	if animate:
		_carousel_tween = create_tween().set_parallel(true)
		_carousel_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	var depth_order: Array[Dictionary] = []

	for i in range(n):
		var card: PanelContainer = _cards[i]

		# ループ対応の相対距離
		var diff: int = i - _current_index
		if diff > n / 2:
			diff -= n
		if diff < -(n / 2):
			diff += n
		var abs_diff: int = absi(diff)

		var target_pos: Vector2
		var target_sc: Vector2
		var target_color: Color
		var z_depth: int

		if abs_diff == 0:
			# 中央（アクティブ）
			target_pos = Vector2(
				center_x - CARD_WIDTH / 2.0,
				center_y - CARD_HEIGHT / 2.0)
			target_sc = Vector2(1.0, 1.0)
			target_color = Color.WHITE
			z_depth = 100
		elif abs_diff == 1:
			# 隣接
			var dir: float = signf(float(diff))
			var sx: float = CARD_WIDTH * ADJACENT_SCALE
			var sy: float = CARD_HEIGHT * ADJACENT_SCALE
			target_pos = Vector2(
				center_x + dir * ADJACENT_OFFSET_X - sx / 2.0,
				center_y - sy / 2.0)
			target_sc = Vector2(ADJACENT_SCALE, ADJACENT_SCALE)
			target_color = Color(
				ADJACENT_BRIGHTNESS, ADJACENT_BRIGHTNESS, ADJACENT_BRIGHTNESS,
				ADJACENT_ALPHA)
			z_depth = 50
		elif abs_diff == 2:
			# 遠方
			var dir: float = signf(float(diff))
			var sx: float = CARD_WIDTH * FAR_SCALE
			var sy: float = CARD_HEIGHT * FAR_SCALE
			target_pos = Vector2(
				center_x + dir * FAR_OFFSET_X - sx / 2.0,
				center_y - sy / 2.0)
			target_sc = Vector2(FAR_SCALE, FAR_SCALE)
			target_color = Color(
				FAR_BRIGHTNESS, FAR_BRIGHTNESS, FAR_BRIGHTNESS,
				FAR_ALPHA)
			z_depth = 10
		else:
			# 非表示
			card.visible = false
			depth_order.append({"index": i, "depth": 0})
			continue

		card.visible = true
		card.pivot_offset = Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)

		if animate:
			_carousel_tween.tween_property(card, "position", target_pos, TWEEN_DURATION)
			_carousel_tween.tween_property(card, "scale", target_sc, TWEEN_DURATION)
			_carousel_tween.tween_property(card, "modulate", target_color, TWEEN_DURATION)
		else:
			card.position = target_pos
			card.scale = target_sc
			card.modulate = target_color

		depth_order.append({"index": i, "depth": z_depth})

	# Z-order: 奥のカードを先に描画、手前を最後に
	depth_order.sort_custom(func(a, b): return a["depth"] < b["depth"])
	for z in range(depth_order.size()):
		_carousel_area.move_child(_cards[depth_order[z]["index"]], z)


# ---------------------------------------------------------------------------
# ドットインジケーター
# ---------------------------------------------------------------------------

func _update_dots() -> void:
	if _dot_container == null:
		return
	for i in range(_dot_container.get_child_count()):
		var dot: PanelContainer = _dot_container.get_child(i) as PanelContainer
		if dot == null:
			continue
		if i == _current_index:
			dot.custom_minimum_size.x = 32
			dot.modulate.a = 1.0
		else:
			dot.custom_minimum_size.x = 11
			dot.modulate.a = 0.4


# ---------------------------------------------------------------------------
# プレイボタン / COMING SOON
# ---------------------------------------------------------------------------

func _update_play_button() -> void:
	for i in range(_cards.size()):
		var card: PanelContainer = _cards[i]
		var play_btn: Button = card.get_node_or_null("CardMargin/CardVBox/CardPlayButton")
		var coming_soon: PanelContainer = card.get_node_or_null("CardMargin/CardVBox/CardComingSoon")
		var is_active: bool = (i == _current_index)
		var game_id: String = GAME_CARDS[i]["id"]
		var is_implemented: bool = game_id in _implemented_games
		if play_btn != null:
			play_btn.visible = is_active and is_implemented
		if coming_soon != null:
			coming_soon.visible = is_active and not is_implemented


func _try_start_game() -> void:
	var game_id: String = GAME_CARDS[_current_index]["id"]
	if game_id not in _implemented_games:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_game"):
		gm.start_game(game_id)


func _on_play_pressed() -> void:
	_try_start_game()


# ---------------------------------------------------------------------------
# ナビゲーション
# ---------------------------------------------------------------------------

func _on_nav_home() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("navigate_to_home"):
		gm.navigate_to_home()
	else:
		get_tree().change_scene_to_file("res://scenes/main/home.tscn")
