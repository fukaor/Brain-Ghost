## FlashCalcPlayView
##
## フラッシュ暗算 試合画面の View コントローラ。
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md §3-2 / §3-3。
##
## ## 状態マシン
## ```
## idle → pre_announce → flashing → input → judging → result → done
## ```
##
## - pre_announce: 1.5s の予告 ("READY?")
## - flashing: 数字を intervals_ms に従って順次表示
## - input: テンキー入力 + ゴースト CD バー減少。入力確定 or CD ゼロで遷移
## - judging: FlashCalc に submit_answer / timeout を呼んで判定
## - result: 結果ポップアップ表示 (PERFECT / WIN / DRAW / TIME_LOSE / WRONG)
## - done: GameManager.on_game_finished_handler に PlayLog を渡して result 画面へ
extends Control

const FlashCalcScript = preload("res://scripts/games/flash_calc/flash_calc.gd")
const _Tier = preload("res://scripts/games/flash_calc/tier_config.gd")

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------

@onready var _title_label: Label = $SafeArea/MainColumn/HeaderRow/TitleLabel
@onready var _ghost_stats_label: Label = $SafeArea/MainColumn/HeaderRow/GhostStatsLabel
@onready var _number_flash_label: Label = $SafeArea/MainColumn/StageArea/NumberFlashLabel
@onready var _phase_label: Label = $SafeArea/MainColumn/StageArea/PhaseLabel
@onready var _ghost_cd_bar: ProgressBar = $SafeArea/MainColumn/StageArea/GhostCdBar
@onready var _ghost_cd_label: Label = $SafeArea/MainColumn/StageArea/GhostCdLabel
@onready var _answer_label: Label = $SafeArea/MainColumn/InputArea/AnswerLabel
@onready var _keypad: GridContainer = $SafeArea/MainColumn/InputArea/Keypad
@onready var _result_popup: Control = $ResultPopup
@onready var _result_text: Label = $ResultPopup/Panel/VBox/ResultText
@onready var _result_score: Label = $ResultPopup/Panel/VBox/ResultScore

# ---------------------------------------------------------------------------
# 状態
# ---------------------------------------------------------------------------

var _game: FlashCalc
var _state: String = "idle"
var _cd_tween: Tween = null
var _input_started_at_ms: int = 0


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _wire_keypad()
    _result_popup.visible = false
    _phase_label.text = "READY?"
    _number_flash_label.text = ""
    _ghost_cd_bar.visible = false
    _ghost_cd_label.visible = false
    _answer_label.text = ""

    _game = FlashCalcScript.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)

    var tier: String = GameManager.get_current_tier()
    if tier == "":
        tier = "T1"  # フォールバック: ティア未選択時は T1
    _title_label.text = "🥋 %s ／ フラッシュ暗算 一本勝負" % tier
    var ghost_delta: int = FlashCalcGhostStore.get_delta_for_tier(tier)
    var play_count: int = FlashCalcGhostStore.get_play_count(tier)
    var ghost_label: String = "練習仲間" if play_count < 4 else "いつもの自分"
    _ghost_stats_label.text = "👻 %s: %.1f 秒で解答" % [ghost_label, float(ghost_delta) / 1000.0]

    _game.setup_with_tier(tier, -1)
    _game.start()
    _game.notify_tier_started()
    _enter_state("pre_announce")


# ---------------------------------------------------------------------------
# キーパッド配線
# ---------------------------------------------------------------------------

func _wire_keypad() -> void:
    for child in _keypad.get_children():
        if child is Button:
            var btn := child as Button
            var meta: String = String(btn.get_meta("key", ""))
            btn.pressed.connect(_on_keypad_pressed.bind(meta))


func _on_keypad_pressed(key: String) -> void:
    if _state != "input":
        return
    match key:
        "back":
            _game.handle_input({"type": "backspace"})
        "submit":
            _game.handle_input({"type": "submit"})
        _:
            if key.is_valid_int():
                _game.handle_input({"type": "digit", "value": int(key)})
    _answer_label.text = _game.get_current_input()


# ---------------------------------------------------------------------------
# 状態マシン
# ---------------------------------------------------------------------------

func _enter_state(s: String) -> void:
    _state = s
    match s:
        "pre_announce":
            _phase_label.text = "READY?"
            _phase_label.visible = true
            _number_flash_label.text = ""
            await get_tree().create_timer(1.5).timeout
            _enter_state("flashing")
        "flashing":
            _phase_label.visible = false
            await _play_flash_sequence()
            _enter_state("input")
        "input":
            _number_flash_label.text = "?"
            _game.notify_flash_completed()
            _input_started_at_ms = Time.get_ticks_msec()
            _ghost_cd_bar.visible = true
            _ghost_cd_label.visible = true
            _start_ghost_cd_bar()


func _play_flash_sequence() -> void:
    var problem: Dictionary = _game.get_problem()
    var numbers: Array = problem.get("numbers", [])
    var intervals: Array = problem.get("intervals_ms", [])
    for i in numbers.size():
        _number_flash_label.text = str(numbers[i])
        var ms: int = int(intervals[i]) if i < intervals.size() else 400
        await get_tree().create_timer(float(ms) / 1000.0).timeout


# ---------------------------------------------------------------------------
# ゴースト CD バー
# ---------------------------------------------------------------------------

func _start_ghost_cd_bar() -> void:
    var ghost_delta: int = _game.get_ghost_delta_ms()
    _ghost_cd_bar.min_value = 0
    _ghost_cd_bar.max_value = ghost_delta
    _ghost_cd_bar.value = ghost_delta
    _ghost_cd_label.text = "👻 残り %.1f 秒" % (float(ghost_delta) / 1000.0)
    if _cd_tween != null:
        _cd_tween.kill()
    _cd_tween = create_tween()
    _cd_tween.tween_property(_ghost_cd_bar, "value", 0, float(ghost_delta) / 1000.0)
    _cd_tween.tween_callback(_on_ghost_cd_zero)


func _process(_delta: float) -> void:
    if _state == "input" and _ghost_cd_bar.visible:
        var remain: float = max(0.0, _ghost_cd_bar.value / 1000.0)
        _ghost_cd_label.text = "👻 残り %.1f 秒" % remain
        # バーの色を残量で変化させる (cyan → orange dim → gray dim)
        var ratio: float = _ghost_cd_bar.value / max(_ghost_cd_bar.max_value, 1.0)
        var c: Color
        if ratio > 0.5:
            c = Color(0.435, 0.706, 1.0)
        elif ratio > 0.25:
            c = Color(1.0, 0.6, 0.3)
        else:
            c = Color(0.6, 0.65, 0.75)
        var sb := _ghost_cd_bar.get_theme_stylebox("fill") as StyleBoxFlat
        if sb != null:
            sb.bg_color = c


func _on_ghost_cd_zero() -> void:
    if _state != "input":
        return
    _game.handle_input({"type": "timeout"})


# ---------------------------------------------------------------------------
# 結果表示
# ---------------------------------------------------------------------------

func _show_result_popup() -> void:
    _ghost_cd_bar.visible = false
    _ghost_cd_label.visible = false
    if _cd_tween != null:
        _cd_tween.kill()
    var v: int = _game.get_verdict()
    var text: String = ""
    var color: Color = Color(1.0, 0.914, 0.659)
    match v:
        FlashCalc.Verdict.PERFECT:
            text = "✨ PERFECT ✨"
        FlashCalc.Verdict.GREAT:
            text = "GREAT!"
        FlashCalc.Verdict.WIN:
            text = "WIN"
        FlashCalc.Verdict.DRAW:
            text = "DRAW"
            color = Color(0.7, 0.93, 1.0)
        FlashCalc.Verdict.TIME_LOSE:
            text = "TIME UP"
            color = Color(0.78, 0.824, 0.91)
        FlashCalc.Verdict.WRONG:
            text = "答えは %d" % int(_game.get_problem().get("answer", 0))
            color = Color(0.78, 0.824, 0.91)
    _result_text.text = text
    _result_text.add_theme_color_override("font_color", color)
    _result_score.text = "スコア: %d" % _game.get_final_score()
    _result_popup.visible = true


# ---------------------------------------------------------------------------
# ゲーム終了 → GameManager に PlayLog 引渡し
# ---------------------------------------------------------------------------

func _on_game_finished(play_log: PlayLog) -> void:
    _state = "result"
    # ティア別ストアに保存
    FlashCalcGhostStore.save_play(_game.get_tier(), _game.get_response_time_ms(), _game.get_is_won(), _game.get_final_score())
    # 解放判定
    var next_t: String = _Tier.next_tier(_game.get_tier())
    if next_t != "" and not FlashCalcGhostStore.is_unlocked(next_t):
        if FlashCalcGhostStore.get_recent_wins(_game.get_tier()) >= FlashCalcGhostStore.UNLOCK_REQUIRED_WINS:
            FlashCalcGhostStore.unlock(next_t)
    # 結果ポップアップを表示してから GameManager 共通ハンドラへ
    _show_result_popup()
    await get_tree().create_timer(3.0).timeout
    GameManager.on_game_finished_handler(play_log)
