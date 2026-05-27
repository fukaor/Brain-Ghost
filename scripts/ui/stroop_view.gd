## StroopView
##
## 色文字ストループのシーンスクリプト。Stroop ロジックを内包し、刺激表示・回答ボタン・
## 3 秒タイムアウト・30 秒ゲームタイマー・正誤フィードバック・ゴーストバーを管理する。
##
## Sumi Ghost (墨絵調) デザイン:
## - 上部: タイトル + タイマー
## - ゴーストバー (タイム系プログレス): PlayerBar / GhostBar (max=20)
## - 中央: StimulusLabel (色付きひらがな) または ShapeContainer (T3 Shape)
## - 下部: 4 色回答ボタン + 正解/誤答カウンタ + ★ベスト
extends Control

const _TierConfig = preload("res://scripts/games/stroop/tier_config.gd")
const _MSYM_FONT = preload("res://assets/fonts/MaterialSymbolsRounded.ttf")
const _SANS_FONT = preload("res://assets/fonts/NotoSansJP-Bold.otf")

const FEEDBACK_DURATION_SEC: float = 0.1
const GHOST_BAR_MAX: float = 20.0

# 残り 5 秒で警告色
const COLOR_TIMER_NORMAL := Color(0.722, 0.878, 1, 1)
const COLOR_TIMER_WARN := Color(1.0, 0.914, 0.659, 1)
const COLOR_FEEDBACK_OK := Color(0.435, 0.847, 0.624, 1)
const COLOR_FEEDBACK_NG := Color(0.78, 0.824, 0.91, 0.85)


@onready var _timer_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/TimerChip/TimerLabel
@onready var _stimulus_label: Label = $SafeAreaMargin/MainColumn/StimulusArea/StimulusLabel
@onready var _shape_container: CenterContainer = $SafeAreaMargin/MainColumn/StimulusArea/ShapeContainer
@onready var _shape_panel: PanelContainer = $SafeAreaMargin/MainColumn/StimulusArea/ShapeContainer/ShapePanel
@onready var _shape_inner: Label = $SafeAreaMargin/MainColumn/StimulusArea/ShapeContainer/ShapePanel/InnerLabel
@onready var _feedback_label: Label = $SafeAreaMargin/MainColumn/StimulusArea/FeedbackLabel
@onready var _answer_buttons: HBoxContainer = $SafeAreaMargin/MainColumn/AnswerButtons
@onready var _score_label: Label = $SafeAreaMargin/MainColumn/FooterArea/ScoreLabel
@onready var _best_label: Label = $SafeAreaMargin/MainColumn/FooterArea/BestRow/BestPill/BestLabel
@onready var _player_bar: ProgressBar = $SafeAreaMargin/MainColumn/GhostArea/PlayerRow/PlayerBar
@onready var _player_value: Label = $SafeAreaMargin/MainColumn/GhostArea/PlayerRow/PlayerValue
@onready var _ghost_bar: ProgressBar = $SafeAreaMargin/MainColumn/GhostArea/GhostRow/GhostBar
@onready var _ghost_value: Label = $SafeAreaMargin/MainColumn/GhostArea/GhostRow/GhostValue


var _game: Stroop
var _seed_value: int = -1
var _answer_timer: Timer
var _is_locked: bool = false      # フィードバック表示中はボタン押下無視
var _ghost_target: int = 10
var _button_order: Array[String] = []
var _last_displayed_remaining: int = -1
var _pending_finish_log: PlayLog = null


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _game = Stroop.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)

    _ghost_target = _TierConfig.get_initial_ghost(_game.get_tier())
    _player_bar.max_value = GHOST_BAR_MAX
    _ghost_bar.max_value = GHOST_BAR_MAX

    _setup_answer_buttons()
    _update_best_display()
    _update_score_label()
    _update_timer_label()
    _setup_answer_timer()

    _game.start()
    _present_current()


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec: float = float(_game.get_elapsed_ms()) / 1000.0
    var remaining: float = max(0.0, Stroop.GAME_DURATION_SEC - elapsed_sec)
    _update_timer_label(remaining)
    _update_ghost_bars(elapsed_sec)
    if remaining <= 0.0:
        # close-race 対策: time_over 発火直後に answer_timer を停止
        if _answer_timer != null:
            _answer_timer.stop()
        _game.handle_input({"type": "time_over"})


func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


# ---------------------------------------------------------------------------
# 回答ボタンセットアップ
# ---------------------------------------------------------------------------

func _setup_answer_buttons() -> void:
    for child in _answer_buttons.get_children():
        child.queue_free()
    _button_order = []
    for c in _TierConfig.COLORS:
        _button_order.append(String(c))
    _render_answer_buttons()


func _shuffle_button_order() -> void:
    _button_order.shuffle()
    _render_answer_buttons()


func _render_answer_buttons() -> void:
    for child in _answer_buttons.get_children():
        child.queue_free()
    for color in _button_order:
        var btn := _build_answer_button(color)
        _answer_buttons.add_child(btn)


func _build_answer_button(color: String) -> Button:
    var color_rgb: Color = _TierConfig.COLOR_RGB.get(color, Color.WHITE)
    var glyph: String = _TierConfig.SHAPE_GLYPH.get(color, "circle")
    var jp: String = _TierConfig.JP_NAMES.get(color, "")

    var btn := Button.new()
    btn.custom_minimum_size = Vector2(76, 92)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.910, 0.863, 0.753, 0.7)
    sb.border_width_left = 1
    sb.border_width_top = 1
    sb.border_width_right = 1
    sb.border_width_bottom = 1
    sb.border_color = Color(0.435, 0.706, 1, 0.45)
    sb.corner_radius_top_left = 14
    sb.corner_radius_top_right = 14
    sb.corner_radius_bottom_right = 14
    sb.corner_radius_bottom_left = 14
    sb.content_margin_left = 6
    sb.content_margin_top = 6
    sb.content_margin_right = 6
    sb.content_margin_bottom = 6
    btn.add_theme_stylebox_override("normal", sb)
    btn.add_theme_stylebox_override("hover", sb)
    btn.add_theme_stylebox_override("pressed", sb)
    btn.add_theme_stylebox_override("focus", sb)

    var vbox := VBoxContainer.new()
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 2)
    btn.add_child(vbox)

    var icon := Label.new()
    icon.text = glyph
    icon.add_theme_font_override("font", _MSYM_FONT)
    icon.add_theme_font_size_override("font_size", 36)
    icon.add_theme_color_override("font_color", color_rgb)
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(icon)

    var name_label := Label.new()
    name_label.text = jp
    name_label.add_theme_font_override("font", _SANS_FONT)
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.add_theme_color_override("font_color", Color(0.957, 0.969, 1, 0.9))
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(name_label)

    btn.pressed.connect(_on_answer_pressed.bind(color))
    return btn


# ---------------------------------------------------------------------------
# タイムアウト Timer
# ---------------------------------------------------------------------------

func _setup_answer_timer() -> void:
    _answer_timer = Timer.new()
    _answer_timer.one_shot = true
    _answer_timer.timeout.connect(_on_answer_timeout_timer)
    add_child(_answer_timer)


func _start_answer_timeout() -> void:
    if _answer_timer == null:
        return
    _answer_timer.start(float(Stroop.ANSWER_TIMEOUT_MS) / 1000.0)


func _on_answer_timeout_timer() -> void:
    if _game == null or not _game._is_active:
        return
    if _is_locked:
        return
    _is_locked = true
    _flash_feedback(false)
    _game.handle_input({"type": "answer_timeout"})
    _update_score_label()
    await get_tree().create_timer(FEEDBACK_DURATION_SEC).timeout
    _maybe_shuffle_buttons()
    _present_current()


# ---------------------------------------------------------------------------
# 刺激提示
# ---------------------------------------------------------------------------

func _present_current() -> void:
    # close-race ガード: time_over や手動 finish 後の遅延コールで状態が壊れないように
    if _game == null or not _game._is_active:
        return
    var stim: Dictionary = _game.get_current_stimulus()
    if stim.is_empty():
        return
    var display_color_key: String = String(stim.get("display_color", "red"))
    var display_color: Color = _TierConfig.COLOR_RGB.get(display_color_key, Color.WHITE)

    if String(stim.get("type", "")) == "shape":
        _stimulus_label.visible = false
        _shape_container.visible = true
        _render_shape(stim, display_color)
    else:
        _shape_container.visible = false
        _stimulus_label.visible = true
        _stimulus_label.text = String(stim.get("text", ""))
        _stimulus_label.add_theme_color_override("font_color", display_color)

    _game.notify_stimulus_presented()
    _is_locked = false
    _start_answer_timeout()


func _render_shape(stim: Dictionary, display_color: Color) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = display_color
    sb.corner_radius_top_left = 18
    sb.corner_radius_top_right = 18
    sb.corner_radius_bottom_right = 18
    sb.corner_radius_bottom_left = 18
    sb.content_margin_left = 32
    sb.content_margin_top = 32
    sb.content_margin_right = 32
    sb.content_margin_bottom = 32
    _shape_panel.add_theme_stylebox_override("panel", sb)
    _shape_inner.text = String(stim.get("text", ""))
    _shape_inner.add_theme_color_override("font_color", Color(0.957, 0.969, 1, 1))


# ---------------------------------------------------------------------------
# 回答処理
# ---------------------------------------------------------------------------

func _on_answer_pressed(color: String) -> void:
    if _is_locked:
        return
    if _game == null or not _game._is_active:
        return
    _is_locked = true
    if _answer_timer != null:
        _answer_timer.stop()
    var stim: Dictionary = _game.get_current_stimulus()
    var is_correct: bool = (color == String(stim.get("correct_answer", "")))
    _flash_feedback(is_correct)
    _game.handle_input({"type": "answer", "color": color})
    _update_score_label()
    await get_tree().create_timer(FEEDBACK_DURATION_SEC).timeout
    _maybe_shuffle_buttons()
    _present_current()


func _maybe_shuffle_buttons() -> void:
    if _game == null:
        return
    var every: int = _TierConfig.get_shuffle_every(_game.get_tier())
    if every <= 0:
        return
    var idx: int = _game.get_current_index()
    if idx > 0 and idx % every == 0:
        _shuffle_button_order()


func _flash_feedback(is_correct: bool) -> void:
    _feedback_label.text = "check" if is_correct else "close"
    var c: Color = COLOR_FEEDBACK_OK if is_correct else COLOR_FEEDBACK_NG
    _feedback_label.add_theme_color_override("font_color", c)
    _feedback_label.modulate.a = 1.0
    var tween := create_tween()
    tween.tween_property(_feedback_label, "modulate:a", 0.0, FEEDBACK_DURATION_SEC * 2.0)


# ---------------------------------------------------------------------------
# HUD 更新
# ---------------------------------------------------------------------------

func _update_score_label() -> void:
    if _game == null:
        return
    _score_label.text = "正解: %d  誤答: %d" % [_game.get_correct_count(), _game.get_wrong_count()]


func _update_timer_label(remaining: float = -1.0) -> void:
    var r: float = remaining
    if r < 0.0:
        r = Stroop.GAME_DURATION_SEC
    var rounded: int = int(ceil(r))
    if rounded == _last_displayed_remaining:
        return
    _last_displayed_remaining = rounded
    _timer_label.text = "%ds" % rounded
    if rounded <= 5:
        _timer_label.add_theme_color_override("font_color", COLOR_TIMER_WARN)
    else:
        _timer_label.add_theme_color_override("font_color", COLOR_TIMER_NORMAL)


func _update_ghost_bars(elapsed_sec: float) -> void:
    if _game == null:
        return
    _player_bar.value = float(_game.get_correct_count())
    _player_value.text = "%d問" % _game.get_correct_count()
    var ghost_eta: float = float(_ghost_target) * (elapsed_sec / Stroop.GAME_DURATION_SEC)
    _ghost_bar.value = ghost_eta
    _ghost_value.text = "%d問" % int(round(ghost_eta))


func _update_best_display() -> void:
    var ds := get_node_or_null("/root/DataStore")
    if ds == null or not ds.has_method("load_best"):
        _best_label.text = "★ ベスト: — pts"
        return
    var best = ds.load_best("stroop")
    var bs: int = int(best.best_score) if best != null and "best_score" in best else 0
    if bs <= 0:
        _best_label.text = "★ ベスト: — pts"
    else:
        _best_label.text = "★ ベスト: %d pts" % bs


# ---------------------------------------------------------------------------
# 終了処理
# ---------------------------------------------------------------------------

func _on_game_finished(log: PlayLog) -> void:
    _pending_finish_log = log
    if _answer_timer != null:
        _answer_timer.stop()
    var timer := get_tree().create_timer(0.4)
    timer.timeout.connect(_trigger_pending_finish)


func _trigger_pending_finish() -> void:
    if _pending_finish_log == null:
        return
    var log: PlayLog = _pending_finish_log
    _pending_finish_log = null
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_game_finished_handler"):
        gm.on_game_finished_handler(log)
    else:
        push_warning("[StroopView] GameManager not found; log dropped: score=%d" % log.score)
