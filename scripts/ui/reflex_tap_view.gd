## ReflexTapView
##
## 反射タップゲームのシーンスクリプト。`scripts/games/reflex_tap.gd` の
## ロジッククラスを内包し、以下の責務を負う:
##
## 1. ReflexTap インスタンスのライフサイクル管理 (setup → start → finish)
## 2. Timer によるターゲット出現スケジュール
## 3. Control ノードの動的生成 (Button with theme variation "target_circle")
## 4. HUD (平均反応時間・進捗・パーセンテージ) の更新
## 5. ユーザーのタップを ReflexTap.handle_input() に仲介
## 6. game_finished シグナルを GameManager に中継
##
## Stitch v0.2 デザイン準拠 (2026-04-14):
## - HUD: CURRENT AVG + PROGRESS + 円形プログレス%
## - ゴーストバトルバー: 自分 vs ゴースト リアルタイムスコア
##
## [b]設計原則:[/b] ロジックは reflex_tap.gd 側、表示・タイミング制御は本ファイル側。
## 色・フォント・サイズは Theme 一任（`target_circle` / `target_circle_fake` variation）。
extends Control

const GAME_AREA_MIN_SIZE: Vector2i = Vector2i(720, 900)
const DISMISS_ANIM_SEC: float = 0.18

# ゴーストのプレースホルダー反応時間（ms）— ゴーストシステム実装後に動的化
const GHOST_AVG_REACTION_MS: float = 450.0

# ---------------------------------------------------------------------------
# ノード参照 (Stitch v0.2 HUD)
# ---------------------------------------------------------------------------
@onready var _avg_value: Label = $SafeAreaMargin/MainColumn/TopHudRow/AvgColumn/AvgValue
@onready var _progress_value: Label = $SafeAreaMargin/MainColumn/TopHudRow/ProgressColumn/ProgressValue
@onready var _progress_percent: Label = $SafeAreaMargin/MainColumn/TopHudRow/ProgressRing/ProgressPercent
@onready var _game_area: Control = $SafeAreaMargin/MainColumn/GameArea
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _fake_dismiss_timer: Timer = $FakeDismissTimer

# ゴーストバトルバー (共有シーン scenes/shared/ghost_battle_bar.tscn)
@onready var _ghost_battle_bar = $SafeAreaMargin/MainColumn/GhostBattleBar

var _game: ReflexTap
var _current_target: Button = null
var _current_is_fake: bool = false
var _seed_value: int = -1


func _ready() -> void:
    _game = ReflexTap.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)
    _game.start()
    _avg_value.text = "—"
    _progress_value.text = "0 / %d" % _game.get_total_count()
    _progress_percent.text = "0%"
    _ghost_battle_bar.set_ghost_score(int(round((1000.0 / GHOST_AVG_REACTION_MS) * 300.0)))
    _schedule_next_target()


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return

    var tapped := _game.get_tapped_count()
    var total := _game.get_total_count()

    # PROGRESS
    _progress_value.text = "%d / %d" % [tapped, total]

    # パーセンテージ
    var pct := 0
    if total > 0:
        pct = int(round(float(tapped) / float(total) * 100.0))
    _progress_percent.text = "%d%%" % pct

    # CURRENT AVG (累積平均反応時間を秒で表示)
    if _game._reaction_times_ms.size() > 0:
        var total_ms: float = 0.0
        for ms in _game._reaction_times_ms:
            total_ms += float(ms)
        var avg_sec: float = (total_ms / float(_game._reaction_times_ms.size())) / 1000.0
        _avg_value.text = "%.2fs" % avg_sec
    else:
        _avg_value.text = "—"

    # プレイヤースコア（リアルタイム概算）
    if _game._reaction_times_ms.size() > 0:
        var total_ms_2: float = 0.0
        for ms in _game._reaction_times_ms:
            total_ms_2 += float(ms)
        var avg_ms: float = total_ms_2 / float(_game._reaction_times_ms.size())
        if avg_ms > 0.0:
            _ghost_battle_bar.set_player_score(int(round((1000.0 / avg_ms) * 300.0)))


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

    # ルール説明画面と統一: 淡い背景 + 色付きアイコン
    # TARGET = 青アイコン Color(0, 0.484, 1, 1) / FAKE = 濃グレー半透明 Color(0.424, 0.459, 0.62, 0.4)
    # サイズ比率はルール説明画面の 80px / 107px (≈0.75) に準拠
    var icon_label := Label.new()
    icon_label.theme_type_variation = "icon_ability_white"
    icon_label.add_theme_font_size_override("font_size", int(size * 0.7))
    icon_label.text = "flare"
    icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if is_fake:
        icon_label.add_theme_color_override("font_color", Color(0.424, 0.459, 0.62, 0.4))
    else:
        icon_label.add_theme_color_override("font_color", Color(0, 0.484, 1, 1))
    btn.add_child(icon_label)

    _game_area.add_child(btn)
    _current_target = btn
    _current_is_fake = is_fake

    _game.mark_target_shown(is_fake)

    if is_fake:
        _game.advance_fake_schedule()
        _fake_dismiss_timer.start(float(ReflexTap.FAKE_VISIBLE_MS) / 1000.0)


func _on_target_pressed(is_fake: bool) -> void:
    _fake_dismiss_timer.stop()

    if _current_target != null:
        _dismiss_target(_current_target)
        _current_target = null
    _current_is_fake = false

    if is_fake:
        _game.handle_input({"type": "fake_tap"})
    else:
        _game.handle_input({"type": "target_tap"})

    if _game._is_active:
        _schedule_next_target()


func _on_fake_dismiss_timer_timeout() -> void:
    if _current_target == null or not _current_is_fake:
        return
    _dismiss_target(_current_target)
    _current_target = null
    _current_is_fake = false
    if _game != null and _game._is_active:
        _schedule_next_target()


func _dismiss_target(btn: Button) -> void:
    if btn == null:
        return
    btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.pivot_offset = btn.size * 0.5
    var tween := create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(btn, "scale", Vector2(0.1, 0.1), DISMISS_ANIM_SEC)
    tween.tween_property(btn, "modulate:a", 0.0, DISMISS_ANIM_SEC)
    tween.chain().tween_callback(func():
        if is_instance_valid(btn):
            btn.queue_free()
    )


func _on_game_finished(log: PlayLog) -> void:
    _spawn_timer.stop()
    if _current_target != null:
        _current_target.queue_free()
        _current_target = null
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_game_finished_handler"):
        gm.on_game_finished_handler(log)
    else:
        push_warning("[ReflexTapView] GameManager not found; log dropped: score=%d" % log.score)
