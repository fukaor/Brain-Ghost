## FlashCalcView
##
## フラッシュ暗算シーンスクリプト。FlashCalc ロジックを内包し、
## テンキー入力 + 問題表示 + HUD 更新を担当する。
extends Control

@onready var _progress_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/ProgressPill/HBox/ProgressValue
@onready var _elapsed_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/ElapsedPill/HBox/ElapsedValue
@onready var _correct_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/CorrectPill/HBox/CorrectValue

@onready var _problem_label: Label = $SafeAreaMargin/MainColumn/CenterColumn/ProblemLabel
@onready var _input_label: Label = $SafeAreaMargin/MainColumn/CenterColumn/InputLabel
@onready var _numpad: GridContainer = $SafeAreaMargin/MainColumn/NumPad
@onready var _timeout_timer: Timer = $TimeoutTimer

var _game: FlashCalc
var _seed_value: int = -1
var _current_input: String = ""


func _ready() -> void:
    _game = FlashCalc.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)
    _game.start()
    _wire_numpad()
    _refresh_problem()
    _refresh_hud()
    _timeout_timer.wait_time = float(FlashCalc.TIME_LIMIT_SEC)
    _timeout_timer.start()


func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    _refresh_hud()


func _wire_numpad() -> void:
    for child in _numpad.get_children():
        if child is Button:
            var btn := child as Button
            var label: String = btn.text
            btn.pressed.connect(_on_numpad_pressed.bind(label))


func _on_numpad_pressed(label: String) -> void:
    if _game == null or not _game._is_active:
        return
    if label == "C":
        _current_input = ""
    elif label == "OK":
        if _current_input != "":
            var answer: int = int(_current_input)
            _game.handle_input({"type": "submit", "answer": answer})
            _current_input = ""
            _refresh_problem()
    else:
        # 数字ボタン (0-9)
        if _current_input.length() < 4:  # 最大 4 桁
            _current_input += label
    _input_label.text = _current_input if _current_input != "" else "—"


func _refresh_problem() -> void:
    if _game == null or not _game._is_active:
        _problem_label.text = ""
        return
    var text: String = _game.get_current_problem_text()
    _problem_label.text = "%s = ?" % text


func _refresh_hud() -> void:
    if _game == null:
        return
    _progress_label.text = "%d / %d" % [_game.get_current_index(), _game.get_total_problems()]
    _elapsed_label.text = "%ds" % _game.get_remaining_sec()
    _correct_label.text = "%d 正解" % _game.get_correct_count()


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
