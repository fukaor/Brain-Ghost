## GameListController
##
## 脳トレ一覧画面のコントローラ。
## ポケポケ風 3D ルーレットカルーセル。
##
## 6 種のミニゲームを楕円軌道上に配置し、
## 全カードが常に見える状態で前後に回転する。
## 手前のカードが最も大きく、奥へ行くほど縮小・暗転する。
##
## [b]設計原則:[/b]
## - 色・フォント・サイズは Theme 一任（GDScript ハードコード禁止）
## - GAME_CARDS 配列にエントリ追加するだけで新ゲーム対応
## - Platform Autoload 経由のプラットフォーム分岐
extends Control

# ---------------------------------------------------------------------------
# ゲームカード定義（データ駆動）
# ---------------------------------------------------------------------------

## Material Symbols Rounded のアイコン名をテキストとして使用
const GAME_CARDS: Array[Dictionary] = [
	{"id": "reflex_tap",       "icon": "touch_app",  "name": "反射タップ",     "desc": "出現するターゲットを即座にタップ！\n反応速度を測定します。",             "metric_caption": "High Score"},
	{"id": "flash_calc",       "icon": "calculate",  "name": "フラッシュ暗算", "desc": "次々と表示される数字を暗算。\n計算力を鍛えます。",                     "metric_caption": "High Score"},
	{"id": "sequence_memory",  "icon": "graphic_eq", "name": "順番記憶",       "desc": "パネルが光る順番を記憶して再現。\n短期記憶をトレーニング。",           "metric_caption": "High Score"},
	{"id": "stroop",           "icon": "palette",    "name": "色文字テスト",   "desc": "文字の内容ではなく「色」を回答。\n注意力を磨きます。",                 "metric_caption": "High Score"},
	{"id": "card_match",       "icon": "layers",     "name": "神経衰弱",       "desc": "ペアのカードを素早く見つける。\n判断力と記憶力の勝負。",               "metric_caption": "High Score"},
	{"id": "number_search",    "icon": "visibility",  "name": "数字さがし",     "desc": "1 から順番に数字をタップ。\n周辺視野と集中力を強化。",                "metric_caption": "Best Time"},
]

## GameManager.GAME_SCENES に登録済みのゲーム = プレイ可能
var _implemented_games: Array[String] = []

# ---------------------------------------------------------------------------
# 3D ルーレット設定
# ---------------------------------------------------------------------------
const CARD_WIDTH: float = 340.0
const CARD_HEIGHT: float = 480.0

## 楕円軌道の半径（X方向=横幅、Y方向=奥行き感）
const ELLIPSE_RX: float = 240.0
const ELLIPSE_RY: float = 90.0

## スケール範囲: 最前面=1.0, 最背面=BACK_SCALE
const FRONT_SCALE: float = 1.0
const BACK_SCALE: float = 0.45

## 明るさ範囲: 最前面=1.0, 最背面=BACK_BRIGHTNESS
const FRONT_BRIGHTNESS: float = 1.0
const BACK_BRIGHTNESS: float = 0.35

const TWEEN_DURATION: float = 0.45

## スワイプ閾値（px）
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
@onready var _play_button: Button = $SafeAreaMargin/MainColumn/PlayButton
@onready var _coming_soon_badge: PanelContainer = $SafeAreaMargin/MainColumn/ComingSoonBadge

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
	# レイアウト確定後にカルーセル配置（size.x が 0 のまま計算されるのを防ぐ）
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

		var icon_label: Label = card.get_node_or_null("CardMargin/CardVBox/IconLabel")
		var name_label: Label = card.get_node_or_null("CardMargin/CardVBox/GameNameLabel")
		var desc_label: Label = card.get_node_or_null("CardMargin/CardVBox/DescriptionLabel")
		var metric_caption: Label = card.get_node_or_null("CardMargin/CardVBox/MetricRow/MetricCaption")
		var metric_value: Label = card.get_node_or_null("CardMargin/CardVBox/MetricRow/MetricValue")

		if icon_label != null:
			icon_label.text = data["icon"]
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
	_play_button.pressed.connect(_on_play_pressed)

	# カードタップ
	for i in range(_cards.size()):
		_cards[i].gui_input.connect(_on_card_gui_input.bind(i))

	# ボトムナビ
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
			# 他のカードタップ → そのカードを手前に回転
			_current_index = card_index
			_apply_carousel_layout(true)
			_update_dots()
			_update_play_button()


# ---------------------------------------------------------------------------
# 3D ルーレット操作
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


## 全カードを楕円軌道上に配置する 3D ルーレットレイアウト。
## 各カードの角度: angle = (i - _current_index) * (2π / N)
## 手前（angle=0）が最大、奥（angle=π）が最小。
func _apply_carousel_layout(animate: bool) -> void:
	if _carousel_tween != null and _carousel_tween.is_running():
		_carousel_tween.kill()

	var center_x: float = _carousel_area.size.x / 2.0
	var center_y: float = _carousel_area.size.y / 2.0
	var n: int = _cards.size()
	var angle_step: float = TAU / float(n)

	if animate:
		_carousel_tween = create_tween().set_parallel(true)
		_carousel_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	# 各カードの depth（cos値）を計算して Z-order 用にソート
	var depth_order: Array[Dictionary] = []

	for i in range(n):
		var card: PanelContainer = _cards[i]
		# 角度: 選択中カードが手前（角度 0 = 画面下手前）
		var angle: float = float(i - _current_index) * angle_step

		# 深度: cos(angle) が 1.0 = 最前面、-1.0 = 最背面
		var depth: float = cos(angle)
		# 0.0〜1.0 に正規化（0=最背面, 1=最前面）
		var depth_norm: float = (depth + 1.0) / 2.0

		# 楕円上の位置（手前=下、奥=上で俯瞰視点の円柱感）
		var offset_x: float = sin(angle) * ELLIPSE_RX
		var offset_y: float = cos(angle) * ELLIPSE_RY

		# スケール: 背面→前面で BACK_SCALE → FRONT_SCALE
		var target_scale: float = lerpf(BACK_SCALE, FRONT_SCALE, depth_norm)

		# 明るさ: modulate で暗くする（alpha ではなく RGB を下げて奥行き感）
		var brightness: float = lerpf(BACK_BRIGHTNESS, FRONT_BRIGHTNESS, depth_norm)

		# カード中心位置
		var target_x: float = center_x + offset_x - CARD_WIDTH * target_scale / 2.0
		var target_y: float = center_y + offset_y - CARD_HEIGHT * target_scale / 2.0
		var target_pos := Vector2(target_x, target_y)
		var target_sc := Vector2(target_scale, target_scale)
		var target_color := Color(brightness, brightness, brightness, 1.0)

		card.pivot_offset = Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
		card.visible = true

		if animate:
			_carousel_tween.tween_property(card, "position", target_pos, TWEEN_DURATION)
			_carousel_tween.tween_property(card, "scale", target_sc, TWEEN_DURATION)
			_carousel_tween.tween_property(card, "modulate", target_color, TWEEN_DURATION)
		else:
			card.position = target_pos
			card.scale = target_sc
			card.modulate = target_color

		depth_order.append({"index": i, "depth": depth})

	# Z-order: 奥のカードを先に描画、手前のカードを最後に描画
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
			dot.custom_minimum_size.x = 24
			dot.modulate.a = 1.0
		else:
			dot.custom_minimum_size.x = 11
			dot.modulate.a = 0.4


# ---------------------------------------------------------------------------
# プレイボタン / COMING SOON
# ---------------------------------------------------------------------------

func _update_play_button() -> void:
	var game_id: String = GAME_CARDS[_current_index]["id"]
	var is_implemented: bool = game_id in _implemented_games
	_play_button.visible = is_implemented
	_coming_soon_badge.visible = not is_implemented


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
