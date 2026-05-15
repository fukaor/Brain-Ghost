## Ghost7BanShobuView (1-lane head-on collision, Midnight Cat v3)
##
## promo `docs/design/promotion/game_tap_touch.png` 準拠：
## - 1 本のレーンを YOU 左→右 / GHOST 右→左 で同時に走り、中央 GATE で正面衝突
## - 5 種レーン形状（line / s_curve / sine_wave / zigzag / arc）がラウンドごとローテ
## - Result はタップ位置に星形バースト + 横レーザー + 縦フレア + ヘッドラインアニメ
##
## ロジック (ghost_7ban_shobu.gd) には触れず、判定は既存の resolve_tap() を使う。
extends Control

const TapBurstScript := preload("res://scripts/ui/effects/tap_burst.gd")
const TapResidueScript := preload("res://scripts/ui/effects/tap_residue.gd")
const SideLaserScript := preload("res://scripts/ui/effects/side_laser.gd")
const LaneShapesScript := preload("res://scripts/games/ghost_7ban_shobu/lane_shapes.gd")

const READY_AUTO_START_DELAY_SEC: float = 0.5
const ANNOUNCE_READY_SEC: float = 0.55
const ANNOUNCE_START_SEC: float = 0.35
const RESULT_VISIBLE_SEC: float = 1.6
const DONE_VISIBLE_SEC: float = 2.4

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------
@onready var _tap_area: Control = $TapArea
@onready var _hud_round: Label = $Hud/RoundLabel
@onready var _progress_dots: Control = $Hud/ProgressDots
@onready var _hud_score_you: Label = $ScoreHud/YouWins
@onready var _hud_score_ghost: Label = $ScoreHud/GhostWins
@onready var _lane_view: Control = $Playfield/Lane
@onready var _effects_layer: Control = $Playfield/EffectsLayer
@onready var _announce_label: Label = $Playfield/AnnounceLabel
@onready var _result_overlay: Control = $ResultOverlay
@onready var _result_headline: Control = $ResultOverlay/HeadlineWrap/Headline
@onready var _result_subtitle: Label = $ResultOverlay/Subtitle
@onready var _ready_overlay: Control = $ReadyOverlay
@onready var _done_overlay: Control = $DoneOverlay
@onready var _done_score: Label = $DoneOverlay/DoneBox/Score
@onready var _done_verdict: Label = $DoneOverlay/DoneBox/Verdict

# ---------------------------------------------------------------------------
# 状態
# ---------------------------------------------------------------------------
var _game: Ghost7BanShobu
var _seed_value: int = -1
var _phase: String = "ready"
var _round_index: int = 0
var _tap_consumed_this_round: bool = false
var _miss_timer_id: int = 0


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------
func _ready() -> void:
    _force_landscape()
    _hide(_announce_label)
    _hide(_result_overlay)
    _hide(_done_overlay)
    _hide(_ready_overlay)  # countdown 経由で来るので待機画面は不要
    _lane_view.clear_state()

    _game = Ghost7BanShobu.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)
    _game.start()

    _tap_area.gui_input.connect(_on_tap_input)

    # 初期化 + 即第 1 戦開始 (旧 _enter_ready の overlay 表示は省略)
    _round_index = 0
    _hud_score_you.text = "0"
    _hud_score_ghost.text = "0"
    _hud_round.text = "第 1 戦 ／ 7"
    _set_progress_dots(0, [])
    _begin_round(0)


func _on_tap_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _handle_tap()
    elif event is InputEventMouseButton and event.pressed:
        _handle_tap()


# ---------------------------------------------------------------------------
# Phase 制御
# ---------------------------------------------------------------------------
func _enter_ready() -> void:
    _phase = "ready"
    _round_index = 0
    _hud_score_you.text = "0"
    _hud_score_ghost.text = "0"
    _hud_round.text = "第 1 戦 ／ 7"
    _set_progress_dots(0, [])
    _show(_ready_overlay)
    _hide(_announce_label)
    _hide(_result_overlay)


func _start_first_round() -> void:
    _hide(_ready_overlay)
    _begin_round(0)


func _begin_round(round_index: int) -> void:
    _round_index = round_index
    _tap_consumed_this_round = false
    _clear_effects()
    var cfg: Dictionary = _game.get_rounds_config()[round_index]
    var ghost_offset_ms: int = _game.get_ghost_deltas()[round_index]
    var shape: String = String(cfg.get("shape", "line"))
    var move_ms: int = int(cfg.get("move", 1500))
    var pre_ms: int = int(cfg.get("pre", 1000))

    _hud_round.text = "第 %d 戦 ／ 7" % (round_index + 1)
    _set_progress_dots(round_index, _game.get_round_results())
    _lane_view.set_round(shape, move_ms, ghost_offset_ms)

    _game.notify_announce_started(round_index)
    _phase = "announce"
    _announce("READY")
    await get_tree().create_timer(ANNOUNCE_READY_SEC).timeout
    if not is_inside_tree() or _phase != "announce":
        return
    _announce("START")
    await get_tree().create_timer(ANNOUNCE_START_SEC).timeout
    if not is_inside_tree():
        return
    _hide(_announce_label)
    _enter_moving(round_index, move_ms, pre_ms)


func _enter_moving(round_index: int, move_ms: int, _pre_ms: int) -> void:
    _phase = "moving"
    var now: int = Time.get_ticks_msec()
    _game.notify_moving_started(round_index, now)
    _lane_view.start_moving(now)

    var timeout_ms: int = move_ms + Ghost7BanShobu.MISS_TIMEOUT_MS
    _miss_timer_id += 1
    var my_id: int = _miss_timer_id
    await get_tree().create_timer(float(timeout_ms) / 1000.0).timeout
    if my_id != _miss_timer_id or _phase != "moving" or _tap_consumed_this_round:
        return
    var miss_result: Dictionary = _game.resolve_miss()
    _enter_result(miss_result)


func _handle_tap() -> void:
    match _phase:
        "ready":
            _start_first_round()
        "moving":
            if _tap_consumed_this_round:
                return
            _tap_consumed_this_round = true
            var now: int = Time.get_ticks_msec()
            var result: Dictionary = _game.resolve_tap(now)
            _lane_view.record_tap(now)
            _enter_result(result)
        _:
            pass


func _enter_result(result: Dictionary) -> void:
    _phase = "result"
    var grade: String = String(result.get("grade", "MISS"))
    var win: bool = bool(result.get("win", false))
    var signed_ms: int = int(result.get("signed_ms", 0))

    _lane_view.enter_result(grade, win, signed_ms)
    _show(_result_overlay)
    _setup_headline(grade, win)
    _spawn_burst_and_lasers(grade, win)

    _hud_score_you.text = str(_game.get_wins())
    _hud_score_ghost.text = str(_game.get_ghost_wins())
    _set_progress_dots(_round_index, _game.get_round_results())

    _game.notify_result_shown(_round_index)

    await get_tree().create_timer(RESULT_VISIBLE_SEC).timeout
    if not is_inside_tree():
        return
    _hide(_result_overlay)
    _clear_effects()
    _lane_view.clear_state()

    if _round_index + 1 >= Ghost7BanShobu.TOTAL_ROUNDS:
        _enter_done()
    else:
        _begin_round(_round_index + 1)


func _enter_done() -> void:
    _phase = "done"
    _game.finalize_game()
    var wins: int = _game.get_wins()
    var ghost_wins: int = _game.get_ghost_wins()
    _done_score.text = "%d — %d" % [wins, ghost_wins]
    if wins > ghost_wins:
        _done_verdict.text = "昨日の自分を、超えた。"
    elif wins == ghost_wins:
        _done_verdict.text = "互角。"
    else:
        _done_verdict.text = "もう一歩。"
    _show(_done_overlay)

    await get_tree().create_timer(DONE_VISIBLE_SEC).timeout
    if not is_inside_tree():
        return
    _game.finish()


# ---------------------------------------------------------------------------
# UI ヘルパ
# ---------------------------------------------------------------------------
func _announce(text: String) -> void:
    _announce_label.text = text
    _show(_announce_label)


func _set_progress_dots(active_index: int, results: Array) -> void:
    if _progress_dots != null and _progress_dots.has_method("set_state"):
        _progress_dots.set_state(active_index, results)


func _setup_headline(grade: String, win: bool) -> void:
    if _result_headline == null:
        return
    # Headline (PERFECT/GREAT/GOOD/MISS) は grade 別の演出色を維持
    var color: Color
    var glow: Color
    if grade == "PERFECT":
        color = Color(1.0, 0.914, 0.659, 1.0)        # gold300
        glow = Color(0.961, 0.780, 0.416, 0.7)
    elif win:
        color = Color(0.722, 0.878, 1.0, 1.0)        # cyan300
        glow = Color(0.435, 0.706, 1.0, 0.6)
    else:
        color = Color(0.78, 0.824, 0.91, 1.0)        # ink80
        glow = Color(0.78, 0.824, 0.91, 0.4)

    # Subtitle (WIN/LOSE/MISS) は grade に関わらず統一: 勝ち=黄金、負け=青~灰色
    var subtitle_color: Color
    if win:
        subtitle_color = Color(1.0, 0.914, 0.659, 1.0)   # 黄金
    else:
        subtitle_color = Color(0.60, 0.70, 0.85, 1.0)    # コールドグレー (青~灰)

    if "text" in _result_headline:
        _result_headline.text = grade
    if "color" in _result_headline:
        _result_headline.color = color
    if "glow_color" in _result_headline:
        _result_headline.glow_color = glow
    if _result_headline.has_method("play"):
        _result_headline.play()

    var subtitle_text: String = "WIN" if win else ("LOSE" if grade != "MISS" else "MISS")
    _result_subtitle.text = subtitle_text
    _result_subtitle.add_theme_color_override("font_color", subtitle_color)


func _spawn_burst_and_lasers(grade: String, win: bool) -> void:
    if _effects_layer == null or _lane_view == null:
        return

    var hot: Color
    var mid: Color
    if grade == "PERFECT":
        hot = Color(1.0, 0.914, 0.659, 1.0)
        mid = Color(0.961, 0.780, 0.416, 1.0)
    elif win:
        hot = Color(0.722, 0.878, 1.0, 1.0)
        mid = Color(0.435, 0.706, 1.0, 1.0)
    else:
        # 負け = グレー (GDD: ネガティブ色禁止)。INK_60 / INK_40 ベース
        hot = Color(0.533, 0.588, 0.690, 1.0)
        mid = Color(0.290, 0.333, 0.439, 1.0)

    # Tap position from lane view (rect center y, hit_x from you_tap_t)
    var lane_rect: Rect2 = _get_lane_rect()
    var hit_pos_local: Vector2 = _lane_view.get_you_tap_position(lane_rect)
    var ghost_pos_local: Vector2 = _lane_view.get_ghost_stop_position(lane_rect)
    # Convert lane-local to effects-layer-local (lane and effects layer have same parent geometry)
    var hit_pos: Vector2 = _lane_view.position + hit_pos_local
    var ghost_pos: Vector2 = _lane_view.position + ghost_pos_local

    # YOU side burst
    var burst := TapBurstScript.new()
    burst.hot_color = hot
    burst.mid_color = mid
    burst.size = _effects_layer.size
    burst.position = hit_pos - _effects_layer.size * 0.5
    _effects_layer.add_child(burst)
    burst.start()

    # 残滓ダスト粒子（promotion の余韻）
    var residue := TapResidueScript.new()
    residue.hot_color = hot
    residue.mid_color = mid
    residue.size = _effects_layer.size
    residue.position = Vector2.ZERO
    _effects_layer.add_child(residue)
    residue.start(hit_pos)

    # YOU laser to left
    var laser_left := SideLaserScript.new()
    laser_left.hot_color = hot
    laser_left.mid_color = mid
    laser_left.size = _effects_layer.size
    laser_left.position = Vector2.ZERO
    _effects_layer.add_child(laser_left)
    laser_left.start(hit_pos, "left", hit_pos.x, 0)

    # GHOST laser to right (weak)
    var laser_right := SideLaserScript.new()
    laser_right.hot_color = Color(0.722, 0.878, 1.0, 1.0)  # cyan300 (ghost side)
    laser_right.mid_color = Color(0.435, 0.706, 1.0, 1.0)
    laser_right.weak = true
    laser_right.size = _effects_layer.size
    laser_right.position = Vector2.ZERO
    _effects_layer.add_child(laser_right)
    laser_right.start(ghost_pos, "right", _effects_layer.size.x - ghost_pos.x, 220)


func _clear_effects() -> void:
    if _effects_layer == null:
        return
    for child in _effects_layer.get_children():
        child.queue_free()


func _get_lane_rect() -> Rect2:
    # match Ghost7BanLaneView._lane_rect
    var pad_top: float = 80.0
    var pad_bot: float = 80.0
    var pad_x: float = 60.0
    var s: Vector2 = _lane_view.size
    return Rect2(Vector2(pad_x, pad_top), Vector2(s.x - pad_x * 2.0, s.y - pad_top - pad_bot))


func _show(node: CanvasItem) -> void:
    if node != null:
        node.visible = true


func _hide(node: CanvasItem) -> void:
    if node != null:
        node.visible = false


# ---------------------------------------------------------------------------
# 終了
# ---------------------------------------------------------------------------
func _on_game_finished(log: PlayLog) -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_game_finished_handler"):
        gm.on_game_finished_handler(log)


func set_seed(s: int) -> void:
    _seed_value = s


# ---------------------------------------------------------------------------
# Orientation
# ---------------------------------------------------------------------------
func _exit_tree() -> void:
    _restore_orientation()


func _force_landscape() -> void:
    OrientationHelper.enter_landscape()


func _restore_orientation() -> void:
    OrientationHelper.enter_portrait()
