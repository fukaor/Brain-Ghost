## FlashCalcView
##
## フラッシュ暗算シーンスクリプト。FlashCalc ロジックを内包し、
## テンキー入力 + 問題表示 + タイマー + ゴーストバトルバーを管理する。
##
## Stitch デザイン準拠:
## - 上部: 超大文字の計算式 ("23 - 12")、演算子色分け（＋=青、−=赤）
## - 中央: 回答表示 ("???" → ユーザー入力)
## - 右上: 円形タイマー（残り秒数）
## - 下部: ゴーストバトルバー（共有シーン） + テンキーパッド
extends Control

const COLOR_PLUS := Color(0, 0.484, 1, 1)   # 青
const COLOR_MINUS := Color(0.702, 0.106, 0.145, 1)  # 赤
const GHOST_CORRECT_PLACEHOLDER: int = 6  # ゴーストの仮正解数

@onready var _num1_label: Label = $SafeAreaMargin/MainColumn/CalcArea/CalcRow/Num1Label
@onready var _operator_label: Label = $SafeAreaMargin/MainColumn/CalcArea/CalcRow/OperatorLabel
@onready var _num2_label: Label = $SafeAreaMargin/MainColumn/CalcArea/CalcRow/Num2Label
@onready var _answer_label: Label = $SafeAreaMargin/MainColumn/CalcArea/AnswerLabel
@onready var _timer_label: Label = $TimerRing/TimerLabel
@onready var _ghost_battle_bar = $SafeAreaMargin/MainColumn/GhostBattleBar
@onready var _keypad_grid: GridContainer = $SafeAreaMargin/MainColumn/KeypadCard/KeypadGrid
@onready var _timeout_timer: Timer = $TimeoutTimer

var _game: FlashCalc
var _seed_value: int = -1
var _input_buffer: String = ""


func _ready() -> void:
	_game = FlashCalc.new()
	add_child(_game)
	_game.game_finished.connect(_on_game_finished)
	_game.setup(_seed_value)
	_game.start()
	_wire_keypad()
	_display_problem()
	_update_timer()
	_ghost_battle_bar.set_ghost_score(GHOST_CORRECT_PLACEHOLDER)
	_ghost_battle_bar.set_player_score(0)
	_timeout_timer.wait_time = float(FlashCalc.TIME_LIMIT_SEC)
	_timeout_timer.start()


func set_seed(seed_value: int) -> void:
	_seed_value = seed_value


func _process(_delta: float) -> void:
	if _game == null or not _game._is_active:
		return
	_update_timer()
	# タイムアップチェック
	if _game.is_time_up():
		_game.handle_input({"type": "timeout"})


func _wire_keypad() -> void:
	for child in _keypad_grid.get_children():
		if child is Button:
			var btn := child as Button
			# ノード名でキーを識別（アイコンボタンはtextが空白のため）
			var key_id: String = btn.name.replace("Btn", "")
			btn.pressed.connect(_on_key_pressed.bind(key_id))


func _on_key_pressed(key: String) -> void:
	if _game == null or not _game._is_active:
		return

	if key == "BS":
		if _input_buffer.length() > 0:
			_input_buffer = _input_buffer.substr(0, _input_buffer.length() - 1)
	elif key == "OK":
		if _input_buffer != "":
			var answer: int = int(_input_buffer)
			_game.handle_input({"type": "submit", "answer": answer})
			_input_buffer = ""
			if _game._is_active:
				_display_problem()
			_ghost_battle_bar.set_player_score(_game.get_correct_count())
	else:
		# 数字 0-9
		if _input_buffer.length() < 4:
			_input_buffer += key

	_update_answer_display()


func _display_problem() -> void:
	var p: Dictionary = _game.get_current_problem()
	if p.is_empty():
		return
	_num1_label.text = str(p["num1"])
	_num2_label.text = str(p["num2"])
	_operator_label.text = p["operator"]

	# 演算子の色分け（＋=青、−=赤）
	if p["operator"] == "-":
		_operator_label.add_theme_color_override("font_color", COLOR_MINUS)
	else:
		_operator_label.add_theme_color_override("font_color", COLOR_PLUS)


func _update_answer_display() -> void:
	if _input_buffer == "":
		_answer_label.text = "???"
		_answer_label.add_theme_color_override("font_color", Color(0.137, 0.173, 0.318, 0.2))
	else:
		_answer_label.text = _input_buffer
		_answer_label.add_theme_color_override("font_color", Color(0.137, 0.173, 0.318, 1))


func _update_timer() -> void:
	if _game == null:
		return
	_timer_label.text = str(_game.get_remaining_sec())


func _on_timeout_timer_timeout() -> void:
	if _game != null and _game._is_active:
		_game.handle_input({"type": "timeout"})


func _on_game_finished(log: PlayLog) -> void:
	_timeout_timer.stop()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("on_game_finished_handler"):
		gm.on_game_finished_handler(log)
	else:
		push_warning("[FlashCalcView] GameManager not found; log dropped: score=%d" % log.score)
