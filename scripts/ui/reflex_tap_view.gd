## ReflexTapView
##
## 反射タップゲームのシーンスクリプト。`scripts/games/reflex_tap.gd` の
## ロジッククラスを内包し、以下の責務を負う:
##
## 1. ReflexTap インスタンスのライフサイクル管理 (setup → start → finish)
## 2. Timer によるターゲット出現スケジュール
## 3. Control ノードの動的生成 (Button with theme variation "target_circle")
## 4. HUD (残りタップ数・経過時間) の更新
## 5. ユーザーのタップを ReflexTap.handle_input() に仲介
## 6. game_finished シグナルを GameManager に中継
##
## [b]設計原則:[/b] ロジックは reflex_tap.gd 側、表示・タイミング制御は本ファイル側。
## 色・フォント・サイズは Theme 一任（`target_circle` / `target_circle_fake` variation）。
extends Control

const GAME_AREA_MIN_SIZE: Vector2i = Vector2i(720, 900)  # GameArea の論理サイズ（位置計算用）

@onready var _progress_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/ProgressPill/HBox/ProgressValue
@onready var _elapsed_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/ElapsedPill/HBox/ElapsedValue
@onready var _speed_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/SpeedPill/HBox/SpeedValue
@onready var _game_area: Control = $SafeAreaMargin/MainColumn/GameArea
@onready var _spawn_timer: Timer = $SpawnTimer

var _game: ReflexTap
var _current_target: Button = null
var _seed_value: int = -1


func _ready() -> void:
    _game = ReflexTap.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)
    _game.start()
    _progress_label.text = "0 / %d" % _game.get_total_count()
    _elapsed_label.text = "0.0s"
    _speed_label.text = "— ms"
    # 最初のターゲットを少し待ってから出す
    _schedule_next_target()


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec: float = float(_game.get_elapsed_ms()) / 1000.0
    _elapsed_label.text = "%.1fs" % elapsed_sec
    _progress_label.text = "%d / %d" % [_game.get_tapped_count(), _game.get_total_count()]


## GameManager から外部シードを注入するための setter（デイリーチャレンジ用）
func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


func _schedule_next_target() -> void:
    if _game == null or not _game._is_active:
        return
    var wait_ms: int = _game.pick_wait_ms()
    _spawn_timer.wait_time = float(wait_ms) / 1000.0
    _spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
    _spawn_target()


func _spawn_target() -> void:
    if _game == null or not _game._is_active:
        return

    var is_fake: bool = _game.should_show_fake()
    var size: int = _game.pick_target_size()
    var area_size: Vector2i = Vector2i(_game_area.size) if _game_area.size.x > 0 else GAME_AREA_MIN_SIZE
    # ReflexTap の generate_target_position はロジック上は別コンテキスト（viewport フル）だが、
    # 本シーンでは GameArea 内に配置する。area_size を使って計算する。
    # ただし rng を進めるため、reflex_tap の generate_target_position は呼ばずに
    # 独自のマージン計算で済ませる（rng は pick_target_size/pick_wait_ms で進んでいる）
    var margin: int = ReflexTap.SCREEN_MARGIN_PX
    var max_x: int = max(margin, area_size.x - margin - size)
    var max_y: int = max(margin, area_size.y - margin - size)
    var x: int = _game.rng.randi_range(margin, max_x)
    var y: int = _game.rng.randi_range(margin, max_y)

    var btn := Button.new()
    btn.theme_type_variation = "target_circle_fake" if is_fake else "target_circle"
    btn.custom_minimum_size = Vector2(size, size)
    btn.size = Vector2(size, size)
    btn.position = Vector2(x, y)
    btn.pressed.connect(_on_target_pressed.bind(is_fake))

    _game_area.add_child(btn)
    _current_target = btn

    _game.mark_target_shown(is_fake)

    if is_fake:
        _game.advance_fake_schedule()


func _on_target_pressed(is_fake: bool) -> void:
    if _current_target != null:
        _current_target.queue_free()
        _current_target = null

    if is_fake:
        _game.handle_input({"type": "fake_tap"})
    else:
        _game.handle_input({"type": "target_tap"})
        var last_reaction: int = _game._reaction_times_ms[-1] if _game._reaction_times_ms.size() > 0 else 0
        _speed_label.text = "%d ms" % last_reaction

    # ゲームがまだアクティブなら次のターゲットをスケジュール
    if _game._is_active:
        _schedule_next_target()


func _on_game_finished(log: PlayLog) -> void:
    _spawn_timer.stop()
    if _current_target != null:
        _current_target.queue_free()
        _current_target = null
    # GameManager に通知
    if Engine.has_singleton("GameManager"):
        var gm = Engine.get_singleton("GameManager")
        if gm.has_method("on_reflex_tap_finished"):
            gm.on_reflex_tap_finished(log)
    elif get_node_or_null("/root/GameManager") != null:
        var gm = get_node("/root/GameManager")
        if gm.has_method("on_reflex_tap_finished"):
            gm.on_reflex_tap_finished(log)
    else:
        push_warning("[ReflexTapView] GameManager not found; log dropped: score=%d" % log.score)
