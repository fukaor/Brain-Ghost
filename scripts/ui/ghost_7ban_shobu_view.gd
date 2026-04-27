## Ghost7BanShobuView
##
## ゴースト7番勝負のシーン制御スクリプト。
## variant-b.jsx のビジュアル（放射グラデオーブ、発光 GHOST LINE、グリッド背景、
## 状態別履歴タイル、ダーク結果カード）を Godot で再現する。
##
## [b]配色規約:[/b] 生 hex は書かず ColorPaletteUtil から引く。Color(1,1,1,a) は
## data-driven alpha 例外（patterns.md §7 準拠）。
extends Control

const VIEWPORT_W: float = 1280.0
const VIEWPORT_H: float = 720.0

## カウントダウンの各ステップ間隔（JSX: 700ms）
const COUNTDOWN_STEP_MS: int = 700

## 結果フェーズ最短表示時間（スクリーンの視認猶予）
const RESULT_MIN_VISIBLE_MS: int = 300

## Orb サイズ（JSX の Player 36 / Ghost 32 を 1280/892 倍率でスケール）
const PLAYER_ORB_SIZE: float = 52.0
const GHOST_ORB_SIZE: float = 46.0

## オーブのトレイル長（オーブ中心を起点に外側へ伸ばす）
## variant-b は 70px (892 基準) だが、ここではより dramatic な演出にするため 150px。
const ORB_TRAIL_LENGTH: float = 150.0
## メイントレイル高さ
const ORB_TRAIL_HEIGHT: float = 12.0
## 背面のソフト（より広くて薄い）トレイル高さ。ぼかしの代替として 2 層で奥行を出す
const ORB_TRAIL_SOFT_HEIGHT: float = 28.0

## トラックの左右余白（JSX: 24 → 1280 スケール）
const TRACK_MARGIN_PX: float = 36.0

## Progress dots 1 点のサイズ
const PROGRESS_DOT_SIZE := Vector2(30, 5)

## GHOST LINE のパルス周期
const LINE_PULSE_PERIOD_SEC: float = 0.55

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------

@onready var _page_background: TextureRect = $PageBackground
@onready var _ambient_grid: TextureRect = $AmbientGrid
@onready var _tap_area: Control = $TapArea
@onready var _hud: PanelContainer = $Hud
@onready var _round_indicator: Label = $Hud/HudRow/RoundIndicator
@onready var _progress_dots: HBoxContainer = $Hud/HudRow/ProgressDots
@onready var _you_wins_label: Label = $Hud/HudRow/ScoreRow/YouWins
@onready var _ghost_wins_label: Label = $Hud/HudRow/ScoreRow/GhostWins

@onready var _playfield: Control = $Playfield
@onready var _you_lane: PanelContainer = $Playfield/YouLane
@onready var _ghost_lane: PanelContainer = $Playfield/GhostLane
@onready var _you_orb_layer: Control = $Playfield/YouLane/YouOrbLayer
@onready var _ghost_orb_layer: Control = $Playfield/GhostLane/GhostOrbLayer
@onready var _ghost_line: PanelContainer = $Playfield/GhostLine
@onready var _ghost_readout: Label = $Playfield/GhostReadout
@onready var _announce_overlay: Label = $Playfield/AnnounceOverlay

@onready var _history_strip: HBoxContainer = $HistoryStrip
@onready var _ready_overlay: Control = $ReadyOverlay
@onready var _countdown_overlay: Label = $CountdownOverlay
@onready var _result_card: PanelContainer = $ResultCard
@onready var _result_grade: Label = $ResultCard/ResultVBox/GradeLabel
@onready var _result_you_delta: Label = $ResultCard/ResultVBox/DeltaRow/YouCol/YouDelta
@onready var _result_ghost_delta: Label = $ResultCard/ResultVBox/DeltaRow/GhostCol/GhostDelta
@onready var _result_verdict: Label = $ResultCard/ResultVBox/VerdictLabel

@onready var _done_overlay: Control = $DoneOverlay
@onready var _done_you_wins: Label = $DoneOverlay/DoneVBox/DoneScoreRow/DoneYouWins
@onready var _done_ghost_wins: Label = $DoneOverlay/DoneVBox/DoneScoreRow/DoneGhostWins
@onready var _done_verdict: Label = $DoneOverlay/DoneVBox/DoneVerdict

@onready var _ready_character_root: Control = $ReadyOverlay/ReadyCharacterRoot
@onready var _ready_cat_portrait: TextureRect = $ReadyOverlay/ReadyCharacterRoot/ReadyCatPortrait
@onready var _ready_bubble_text: Label = $ReadyOverlay/ReadyCharacterRoot/ReadyBubble/ReadyBubbleText

@onready var _miss_timer: Timer = $MissTimer
@onready var _announce_timer: Timer = $AnnounceTimer

# ---------------------------------------------------------------------------
# 状態
# ---------------------------------------------------------------------------

var _game: Ghost7BanShobu
var _seed_value: int = -1
var _history_tiles: Array[PanelContainer] = []
var _progress_dot_nodes: Array[ColorRect] = []

var _player_orb: Control
var _ghost_orb: Control
var _ghost_stop_marker: Control

var _ghost_fired: bool = false
var _result_enter_ms: int = 0
var _saved_orientation: int = -1
var _line_pulse_tween: Tween
var _ready_bob_tween: Tween


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _force_landscape()
    _build_progress_dots()
    _build_history_tiles()
    _start_ghost_line_pulse()
    _start_ready_character_bob()
    _notify_ghost_character("duelist", "今日は本気でいくよ")

    _game = Ghost7BanShobu.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)
    _game.start()

    _enter_ready()


func _exit_tree() -> void:
    _restore_orientation()


func _process(_delta: float) -> void:
    if _game == null:
        return
    var phase := _game.get_phase()
    if phase != "announce" and phase != "moving":
        return

    var round_idx: int = _game.get_current_round_index()
    var cfg_all: Array[Dictionary] = _game.get_rounds_config()
    if round_idx >= cfg_all.size():
        return
    var cfg: Dictionary = cfg_all[round_idx]

    var track_start := TRACK_MARGIN_PX
    var track_end := VIEWPORT_W - TRACK_MARGIN_PX
    var from_left: bool = String(cfg.dir) == "left"
    var start_x: float = track_start - 30.0 if from_left else track_end + 30.0
    var end_x: float = track_end + 30.0 if from_left else track_start - 30.0

    var x: float = start_x
    if phase == "moving":
        var now_ms: int = Time.get_ticks_msec()
        var move_ms: int = int(cfg.move)
        var elapsed: float = float(now_ms - _game.get_move_start_ms())
        var t: float = clampf(elapsed / float(move_ms), 0.0, 1.0)
        x = start_x + (end_x - start_x) * t

        if not _ghost_fired:
            var ghost_delta: int = _game.get_ghost_deltas()[round_idx]
            var ghost_pass_ms: int = _game.get_line_pass_ms() + ghost_delta
            if now_ms >= ghost_pass_ms:
                _ghost_fired = true
                var t_ghost: float = clampf(float(ghost_pass_ms - _game.get_move_start_ms()) / float(move_ms), 0.0, 1.0)
                var ghost_stop_x: float = start_x + (end_x - start_x) * t_ghost
                _show_ghost_stop_marker(ghost_stop_x)
                _update_ghost_readout(true, ghost_delta)

        if t >= 1.0 and _miss_timer.is_stopped():
            _miss_timer.start(float(Ghost7BanShobu.MISS_TIMEOUT_MS) / 1000.0)

    _position_orb(_player_orb, _you_orb_layer, x, from_left)
    _position_orb(_ghost_orb, _ghost_orb_layer, x, from_left, _ghost_fired)


# ---------------------------------------------------------------------------
# 外部 API
# ---------------------------------------------------------------------------

func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


# ---------------------------------------------------------------------------
# フェーズ遷移
# ---------------------------------------------------------------------------

func _enter_ready() -> void:
    _ready_overlay.visible = true
    _countdown_overlay.visible = false
    _result_card.visible = false
    _done_overlay.visible = false
    _announce_overlay.visible = false
    _playfield.visible = false
    _history_strip.visible = false
    _hud.visible = false  # JSX: phase !== 'ready' && phase !== 'done' でのみ表示
    _clear_round_artifacts()


func _start_countdown() -> void:
    _ready_overlay.visible = false
    _countdown_overlay.visible = true
    _playfield.visible = true
    _history_strip.visible = true
    _hud.visible = true
    _tick_countdown(3)


func _tick_countdown(n: int) -> void:
    if n <= 0:
        _countdown_overlay.visible = false
        _start_round(0)
        return
    _countdown_overlay.text = str(n)
    _countdown_overlay.modulate = Color(1, 1, 1, 0)
    _countdown_overlay.scale = Vector2(0.6, 0.6)
    _countdown_overlay.pivot_offset = _countdown_overlay.size / 2.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(_countdown_overlay, "modulate:a", 1.0, 0.22)
    tween.tween_property(_countdown_overlay, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(float(COUNTDOWN_STEP_MS - 320) / 1000.0)
    tween.tween_callback(func():
        _tick_countdown(n - 1)
    )


func _start_round(round_index: int) -> void:
    _clear_round_artifacts()
    _ghost_fired = false
    _update_hud(round_index)
    _update_progress_dots(round_index)

    var cfg_all: Array[Dictionary] = _game.get_rounds_config()
    if round_index >= cfg_all.size():
        _enter_done()
        return
    var cfg: Dictionary = cfg_all[round_index]

    _game.notify_announce_started(round_index)
    _show_announce_overlay(String(cfg.dir))
    _announce_timer.start(float(int(cfg.pre)) / 1000.0)
    _create_orbs(String(cfg.dir))
    _update_ghost_readout(false, _game.get_ghost_deltas()[round_index])
    _set_current_tile_style(round_index)
    _set_background_state("neutral")


func _enter_moving() -> void:
    _announce_overlay.visible = false
    var round_idx: int = _game.get_current_round_index()
    _game.notify_moving_started(round_idx, Time.get_ticks_msec())


func _enter_result(round_result: Dictionary) -> void:
    _miss_timer.stop()
    _announce_timer.stop()
    _result_enter_ms = Time.get_ticks_msec()
    _game.notify_result_shown(_game.get_current_round_index())

    _render_result_card(round_result)
    _result_card.visible = true
    _update_hud(_game.get_current_round_index())
    _update_history_tile(_game.get_current_round_index(), round_result)
    _set_background_state(_background_state_for(round_result))

    _notify_ghost_character_for_round(round_result)


func _advance_after_result() -> void:
    _result_card.visible = false
    var next_idx: int = _game.get_current_round_index() + 1
    if next_idx >= _game.get_total_rounds():
        _enter_done()
    else:
        _start_round(next_idx)


func _enter_done() -> void:
    _playfield.visible = false
    _history_strip.visible = false
    _announce_overlay.visible = false
    _hud.visible = false
    _clear_round_artifacts()
    _set_background_state("neutral")

    var wins: int = _game.get_wins()
    var ghost_wins: int = _game.get_ghost_wins()
    _done_you_wins.text = str(wins)
    _done_ghost_wins.text = str(ghost_wins)
    if wins > ghost_wins:
        _done_you_wins.theme_type_variation = &"display_on_dark_green"
        _done_ghost_wins.theme_type_variation = &"display_on_dark_slate"
        _done_verdict.text = "プレイヤー勝越"
    elif wins < ghost_wins:
        _done_you_wins.theme_type_variation = &"display_on_dark"
        _done_ghost_wins.theme_type_variation = &"display_on_dark_slate"
        _done_verdict.text = "ゴースト勝越"
    else:
        _done_you_wins.theme_type_variation = &"display_on_dark"
        _done_ghost_wins.theme_type_variation = &"display_on_dark"
        _done_verdict.text = "互角"
    _done_overlay.visible = true

    _notify_ghost_character_done(wins, ghost_wins)
    _game.finalize_game()


# ---------------------------------------------------------------------------
# タップ入力
# ---------------------------------------------------------------------------

func _on_tap_area_input(event: InputEvent) -> void:
    if not (event is InputEventScreenTouch or event is InputEventMouseButton):
        return
    if not event.pressed:
        return

    if _ready_overlay.visible:
        _start_countdown()
        return

    if _countdown_overlay.visible:
        return

    if _done_overlay.visible:
        _reset_for_replay()
        return

    if _result_card.visible:
        var elapsed: int = Time.get_ticks_msec() - _result_enter_ms
        if elapsed < RESULT_MIN_VISIBLE_MS:
            return
        _advance_after_result()
        return

    var phase := _game.get_phase()
    if phase == "announce" or phase == "moving":
        var result: Dictionary = _game.resolve_tap(Time.get_ticks_msec())
        if not result.is_empty():
            _spawn_tap_flash()
            _enter_result(result)


func _on_miss_timer_timeout() -> void:
    if _game == null:
        return
    if _game.get_phase() != "moving":
        return
    var result: Dictionary = _game.resolve_miss()
    if not result.is_empty():
        _enter_result(result)


func _on_announce_timer_timeout() -> void:
    if _game == null:
        return
    if _game.get_phase() != "announce":
        return
    _enter_moving()


# ---------------------------------------------------------------------------
# HUD / 履歴
# ---------------------------------------------------------------------------

func _build_progress_dots() -> void:
    _progress_dot_nodes.clear()
    for i in range(Ghost7BanShobu.TOTAL_ROUNDS):
        var dot := ColorRect.new()
        dot.custom_minimum_size = PROGRESS_DOT_SIZE
        dot.color = Color(1, 1, 1, 0.2)
        _progress_dots.add_child(dot)
        _progress_dot_nodes.append(dot)


func _update_progress_dots(active_index: int) -> void:
    for i in range(_progress_dot_nodes.size()):
        var dot: ColorRect = _progress_dot_nodes[i]
        var results: Array[Dictionary] = _game.get_round_results()
        if i < results.size():
            var r: Dictionary = results[i]
            if bool(r.get("win", false)):
                dot.color = Color(ColorPaletteUtil.POSITIVE_GREEN.r, ColorPaletteUtil.POSITIVE_GREEN.g, ColorPaletteUtil.POSITIVE_GREEN.b, 0.9)
            else:
                dot.color = Color(ColorPaletteUtil.NEUTRAL_SLATE.r, ColorPaletteUtil.NEUTRAL_SLATE.g, ColorPaletteUtil.NEUTRAL_SLATE.b, 0.9)
        elif i == active_index:
            dot.color = Color(1, 1, 1, 0.75)
        else:
            dot.color = Color(1, 1, 1, 0.2)


func _update_hud(round_index: int) -> void:
    _round_indicator.text = "⚔ 第 %d 戦 / %d" % [round_index + 1, Ghost7BanShobu.TOTAL_ROUNDS]
    _you_wins_label.text = str(_game.get_wins())
    _ghost_wins_label.text = str(_game.get_ghost_wins())


func _build_history_tiles() -> void:
    _history_tiles.clear()
    for i in range(Ghost7BanShobu.TOTAL_ROUNDS):
        var tile := PanelContainer.new()
        tile.theme_type_variation = &"g7_tile_idle"
        tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tile.size_flags_vertical = Control.SIZE_EXPAND_FILL

        var inner := VBoxContainer.new()
        inner.name = "TileBody"
        inner.alignment = BoxContainer.ALIGNMENT_BEGIN
        inner.add_theme_constant_override("separation", 6)
        tile.add_child(inner)

        var header := Label.new()
        header.name = "Header"
        header.theme_type_variation = &"caption_on_dark_muted"
        header.add_theme_font_size_override("font_size", 11)
        header.text = "R%d" % (i + 1)
        inner.add_child(header)

        var body := Label.new()
        body.name = "Body"
        body.theme_type_variation = &"display_on_dark"
        body.add_theme_font_size_override("font_size", 22)
        body.text = "—"
        inner.add_child(body)

        var verdict := Label.new()
        verdict.name = "Verdict"
        verdict.theme_type_variation = &"caption_on_dark_muted"
        verdict.add_theme_font_size_override("font_size", 11)
        verdict.text = "—"
        inner.add_child(verdict)

        _history_strip.add_child(tile)
        _history_tiles.append(tile)


func _set_current_tile_style(round_index: int) -> void:
    for i in range(_history_tiles.size()):
        var tile := _history_tiles[i]
        var header: Label = tile.get_node("TileBody/Header") as Label
        if i < _game.get_round_results().size():
            # すでに埋まっているタイルは _update_history_tile で設定済み
            continue
        if i == round_index:
            tile.theme_type_variation = &"g7_tile_current"
            header.theme_type_variation = &"caption_on_dark_gold"
            (tile.get_node("TileBody/Verdict") as Label).text = "進行中"
        else:
            tile.theme_type_variation = &"g7_tile_idle"
            header.theme_type_variation = &"caption_on_dark_muted"
            (tile.get_node("TileBody/Verdict") as Label).text = "—"


func _update_history_tile(round_index: int, result: Dictionary) -> void:
    if round_index < 0 or round_index >= _history_tiles.size():
        return
    var tile: PanelContainer = _history_tiles[round_index]
    var body: Label = tile.get_node("TileBody/Body") as Label
    var verdict: Label = tile.get_node("TileBody/Verdict") as Label
    var header: Label = tile.get_node("TileBody/Header") as Label

    var grade := String(result.get("grade", ""))
    if grade == "FLYING" or grade == "MISS":
        body.text = "ー"
    else:
        body.text = "%d ms" % int(result.get("delta", 0))

    var is_win := bool(result.get("win", false))
    if is_win:
        tile.theme_type_variation = &"g7_tile_win"
        body.theme_type_variation = &"display_on_dark_green"
        verdict.theme_type_variation = &"caption_on_dark_green"
        verdict.text = "○ 勝ち"
    else:
        tile.theme_type_variation = &"g7_tile_lose"
        body.theme_type_variation = &"display_on_dark_slate"
        verdict.theme_type_variation = &"caption_on_dark_slate"
        verdict.text = "× 負け"
    header.theme_type_variation = &"caption_on_dark_muted"


# ---------------------------------------------------------------------------
# Orb（放射グラデ + 発光 + トレイル）
# ---------------------------------------------------------------------------

func _create_orbs(_dir: String) -> void:
    _player_orb = _build_orb_node(true)
    _ghost_orb = _build_orb_node(false)
    _you_orb_layer.add_child(_player_orb)
    _ghost_orb_layer.add_child(_ghost_orb)
    _position_orb(_player_orb, _you_orb_layer, -200.0, _dir == "left")
    _position_orb(_ghost_orb, _ghost_orb_layer, -200.0, _dir == "left")


func _build_orb_node(is_player: bool) -> Control:
    var size_px := PLAYER_ORB_SIZE if is_player else GHOST_ORB_SIZE
    var base_color: Color = ColorPaletteUtil.POSITIVE_GREEN if is_player else ColorPaletteUtil.NEUTRAL_SLATE
    var glow_color := Color(0.718, 0.961, 0.784) if is_player else Color(0.796, 0.835, 0.882)

    var root := Control.new()
    root.name = "Orb"
    root.custom_minimum_size = Vector2(size_px, size_px)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # トレイルは 2 層構成で奥行を演出：
    #   - SoftTrail: 広く薄い下地（ぼかし代替）
    #   - Trail: 細く鋭い光条。明端がオーブ中心に届く
    # 参考: variant-b.jsx は filter:blur(2px) を使うが Godot の Control 層ではシェーダ
    # なしでは blur が出せないため、2 層重ねで同等の柔らかさを作る。
    var soft_gradient := Gradient.new()
    soft_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
    soft_gradient.colors = PackedColorArray([
        Color(glow_color.r, glow_color.g, glow_color.b, 0.0),
        Color(glow_color.r, glow_color.g, glow_color.b, 0.12),
        Color(glow_color.r, glow_color.g, glow_color.b, 0.35),
    ])
    var soft_texture := GradientTexture2D.new()
    soft_texture.gradient = soft_gradient
    soft_texture.width = 192
    soft_texture.height = 8
    soft_texture.fill_from = Vector2(0, 0)
    soft_texture.fill_to = Vector2(1, 0)
    var soft_trail := TextureRect.new()
    soft_trail.name = "SoftTrail"
    soft_trail.texture = soft_texture
    soft_trail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    soft_trail.custom_minimum_size = Vector2(ORB_TRAIL_LENGTH, ORB_TRAIL_SOFT_HEIGHT)
    soft_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    soft_trail.modulate = Color(1, 1, 1, 0.9 if is_player else 0.55)
    root.add_child(soft_trail)

    # メイントレイル：細く鋭く、明端は白寄りに持ち上げてオーブ核と融合させる
    var trail_gradient := Gradient.new()
    trail_gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
    trail_gradient.colors = PackedColorArray([
        Color(glow_color.r, glow_color.g, glow_color.b, 0.0),
        Color(glow_color.r, glow_color.g, glow_color.b, 0.55),
        Color(1, 1, 1, 0.95),
    ])
    var trail_texture := GradientTexture2D.new()
    trail_texture.gradient = trail_gradient
    trail_texture.width = 192
    trail_texture.height = 8
    trail_texture.fill_from = Vector2(0, 0)
    trail_texture.fill_to = Vector2(1, 0)
    var trail := TextureRect.new()
    trail.name = "Trail"
    trail.texture = trail_texture
    trail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    trail.custom_minimum_size = Vector2(ORB_TRAIL_LENGTH, ORB_TRAIL_HEIGHT)
    trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    trail.modulate = Color(1, 1, 1, 0.92 if is_player else 0.65)
    root.add_child(trail)

    # コア：放射グラデーション（白中心 → glow → base → 外周で alpha 0 に落とす）
    # 参考: variant-b.jsx の borderRadius:50% 円形ターゲット。Godot の TextureRect は
    # 矩形なので、外周 (offset 0.9 以降) の alpha を 0 に落として円形に見せる。
    var core_gradient := Gradient.new()
    core_gradient.offsets = PackedFloat32Array([0.0, 0.35, 0.88, 1.0])
    core_gradient.colors = PackedColorArray([
        Color(1, 1, 1, 1),
        glow_color,
        Color(base_color.r, base_color.g, base_color.b, 0.95),
        Color(base_color.r, base_color.g, base_color.b, 0.0),
    ])
    var core_texture := GradientTexture2D.new()
    core_texture.gradient = core_gradient
    core_texture.width = int(size_px * 2)
    core_texture.height = int(size_px * 2)
    core_texture.fill = GradientTexture2D.FILL_RADIAL
    core_texture.fill_from = Vector2(0.5, 0.5)
    core_texture.fill_to = Vector2(1.0, 0.5)
    var core := TextureRect.new()
    core.name = "Core"
    core.texture = core_texture
    core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    core.stretch_mode = TextureRect.STRETCH_SCALE
    core.custom_minimum_size = Vector2(size_px, size_px)
    core.size = Vector2(size_px, size_px)
    core.set_anchors_preset(Control.PRESET_FULL_RECT)
    core.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(core)

    # グロー：Panel + shadow で外周発光
    var glow_panel := Panel.new()
    glow_panel.name = "Glow"
    glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glow_panel.custom_minimum_size = Vector2(size_px, size_px)
    glow_panel.size = Vector2(size_px, size_px)
    glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    glow_panel.show_behind_parent = true
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(glow_color.r, glow_color.g, glow_color.b, 0)  # 完全透明で影だけ
    sb.corner_radius_top_left = int(size_px)
    sb.corner_radius_top_right = int(size_px)
    sb.corner_radius_bottom_left = int(size_px)
    sb.corner_radius_bottom_right = int(size_px)
    sb.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.55 if is_player else 0.32)
    sb.shadow_size = 22 if is_player else 14
    glow_panel.add_theme_stylebox_override("panel", sb)
    root.add_child(glow_panel)
    root.move_child(glow_panel, 0)  # 最背面

    return root


func _position_orb(orb: Control, layer: Control, x: float, from_left: bool, dimmed: bool = false) -> void:
    if orb == null or layer == null:
        return
    # orb は layer(OrbLayer) の子として配置しているため、y 中心計算は「layer の
    # 実サイズ」を基準にする必要がある。親 PanelContainer(Lane) の outer size を
    # 使うと stylebox content margin の分だけオーブがレール線より下へずれる。
    var layer_size: Vector2 = layer.size if layer.size.y > 0 else Vector2(VIEWPORT_W, 170.0)
    var orb_size: Vector2 = orb.custom_minimum_size
    orb.position = Vector2(x - orb_size.x / 2.0, (layer_size.y - orb_size.y) / 2.0)
    orb.modulate = Color(1, 1, 1, 0.35 if dimmed else 1.0)


    # トレイル配置：進行方向と逆側に伸ばす。明端（白寄りの先端）をオーブ中心
    # に合わせることで、軌跡が「核から伸びている」ように見える。
    _layout_trail_layer(orb.get_node_or_null("Trail") as TextureRect, orb_size, from_left, ORB_TRAIL_HEIGHT)
    _layout_trail_layer(orb.get_node_or_null("SoftTrail") as TextureRect, orb_size, from_left, ORB_TRAIL_SOFT_HEIGHT)


func _layout_trail_layer(trail: TextureRect, orb_size: Vector2, from_left: bool, height: float) -> void:
    if trail == null:
        return
    trail.size = Vector2(ORB_TRAIL_LENGTH, height)
    var trail_y: float = (orb_size.y - height) / 2.0
    if from_left:
        # 左から来る → 進行方向は右。トレイルはオーブ左側に伸び、右端（明端）が
        # オーブ中心に届く。グラデは左=透明→右=明、flip 不要。
        trail.position = Vector2(orb_size.x / 2.0 - ORB_TRAIL_LENGTH, trail_y)
        trail.flip_h = false
    else:
        # 右から来る → 進行方向は左。トレイルはオーブ右側に伸び、左端（明端）が
        # オーブ中心に届く。明端を内側（左）に寄せるため flip_h = true。
        trail.position = Vector2(orb_size.x / 2.0, trail_y)
        trail.flip_h = true


# ---------------------------------------------------------------------------
# Announce / GhostStopMarker / TapFlash
# ---------------------------------------------------------------------------

func _show_announce_overlay(dir: String) -> void:
    _announce_overlay.visible = true
    var arrow := "←" if dir == "left" else "→"
    if dir == "left":
        _announce_overlay.text = "%s  左から来るぞ" % arrow
    else:
        _announce_overlay.text = "右から来るぞ  %s" % arrow

    _announce_overlay.pivot_offset = _announce_overlay.size / 2.0
    _announce_overlay.scale = Vector2(0.7, 0.7)
    _announce_overlay.modulate = Color(1, 1, 1, 0)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(_announce_overlay, "modulate:a", 1.0, 0.22)
    tween.tween_property(_announce_overlay, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_ghost_stop_marker(x: float) -> void:
    if _ghost_stop_marker != null and is_instance_valid(_ghost_stop_marker):
        _ghost_stop_marker.queue_free()

    var holder := Control.new()
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var lane_h: float = _ghost_lane.size.y

    var stripe := ColorRect.new()
    stripe.color = Color(ColorPaletteUtil.NEUTRAL_SLATE.r, ColorPaletteUtil.NEUTRAL_SLATE.g, ColorPaletteUtil.NEUTRAL_SLATE.b, 0.95)
    stripe.custom_minimum_size = Vector2(2, lane_h - 14)
    stripe.position = Vector2(x - 1.0, 6.0)
    stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(stripe)

    var cap := ColorRect.new()
    cap.color = ColorPaletteUtil.NEUTRAL_SLATE
    cap.custom_minimum_size = Vector2(12, 4)
    cap.position = Vector2(x - 6.0, 2.0)
    cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(cap)

    var dx_px: int = int(round(x - VIEWPORT_W / 2.0))
    var badge := PanelContainer.new()
    badge.theme_type_variation = &"g7_tile_lose"
    badge.position = Vector2(x + 6.0, lane_h - 28.0)
    badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var label := Label.new()
    label.theme_type_variation = &"caption_on_dark_slate"
    label.add_theme_font_size_override("font_size", 11)
    label.text = "GHOST 停止 · %s%dpx" % ["+" if dx_px >= 0 else "", dx_px]
    badge.add_child(label)
    holder.add_child(badge)

    _ghost_orb_layer.add_child(holder)
    _ghost_stop_marker = holder


func _spawn_tap_flash() -> void:
    # GHOST LINE 上に白の発光リングを描画してフェードアウト（rb-fire 相当）
    var ring := Panel.new()
    ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ring_size: float = 70.0
    var center_x: float = VIEWPORT_W / 2.0 - ring_size / 2.0
    var center_y: float = _you_lane.size.y / 2.0 - ring_size / 2.0
    ring.custom_minimum_size = Vector2(ring_size, ring_size)
    ring.size = Vector2(ring_size, ring_size)
    ring.position = Vector2(center_x, center_y)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(1, 1, 1, 0)
    sb.border_width_left = 2
    sb.border_width_top = 2
    sb.border_width_right = 2
    sb.border_width_bottom = 2
    sb.border_color = Color(0.718, 0.961, 0.784, 1)
    sb.corner_radius_top_left = int(ring_size)
    sb.corner_radius_top_right = int(ring_size)
    sb.corner_radius_bottom_left = int(ring_size)
    sb.corner_radius_bottom_right = int(ring_size)
    sb.shadow_color = Color(0.718, 0.961, 0.784, 0.5)
    sb.shadow_size = 18
    ring.add_theme_stylebox_override("panel", sb)
    ring.pivot_offset = Vector2(ring_size / 2.0, ring_size / 2.0)
    _you_orb_layer.add_child(ring)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.7)
    tween.tween_property(ring, "modulate:a", 0.0, 0.7)
    tween.chain().tween_callback(func():
        if is_instance_valid(ring):
            ring.queue_free()
    )


func _update_ghost_readout(fired: bool, ghost_delta_ms: int) -> void:
    if fired:
        _ghost_readout.text = "%d ms で 反応" % ghost_delta_ms
    else:
        _ghost_readout.text = "反応 %d ms" % ghost_delta_ms


func _render_result_card(result: Dictionary) -> void:
    var grade := String(result.get("grade", ""))
    match grade:
        "PERFECT":
            _result_grade.theme_type_variation = &"hero_on_dark_gold"
            _result_grade.text = "★ PERFECT"
        "GREAT":
            _result_grade.theme_type_variation = &"hero_on_dark"
            _result_grade.text = grade
        "GOOD":
            _result_grade.theme_type_variation = &"hero_on_dark"
            _result_grade.text = grade
        _:
            _result_grade.theme_type_variation = &"caption_on_dark_slate"
            _result_grade.text = grade

    if grade == "FLYING" or grade == "MISS":
        _result_you_delta.text = "ー"
    else:
        _result_you_delta.text = "%d ms" % int(result.get("delta", 0))
    _result_ghost_delta.text = "%d ms" % int(result.get("ghost", 0))

    if bool(result.get("win", false)):
        _result_verdict.theme_type_variation = &"caption_on_dark_green"
        _result_verdict.text = "○ プレイヤー勝利    TAP で 次"
    else:
        _result_verdict.theme_type_variation = &"caption_on_dark_slate"
        _result_verdict.text = "× ゴースト勝利    TAP で 次"


func _clear_round_artifacts() -> void:
    for child in _you_orb_layer.get_children():
        child.queue_free()
    for child in _ghost_orb_layer.get_children():
        child.queue_free()
    _player_orb = null
    _ghost_orb = null
    _ghost_stop_marker = null
    _announce_overlay.visible = false
    _ghost_readout.text = ""


# ---------------------------------------------------------------------------
# 背景フェーズ切替 + GHOST LINE パルス
# ---------------------------------------------------------------------------

func _background_state_for(result: Dictionary) -> String:
    var grade := String(result.get("grade", ""))
    if grade == "PERFECT":
        return "perfect"
    if bool(result.get("win", false)):
        return "win"
    return "lose"


func _set_background_state(state: String) -> void:
    # PageBackground の modulate を state ごとに色替え（軽量実装）。
    # 本格的な radial gradient 切替は v1.1 で。
    match state:
        "perfect":
            _page_background.modulate = Color(1.15, 1.05, 0.85)
        "win":
            _page_background.modulate = Color(1.0, 1.05, 1.2)
        "lose":
            _page_background.modulate = Color(0.55, 0.55, 0.65)
        _:
            _page_background.modulate = Color(1, 1, 1)


func _start_ghost_line_pulse() -> void:
    # GHOST LINE の StyleBoxFlat の shadow_size を 10 ↔ 20 で往復させてパルスを表現
    var sb: StyleBoxFlat = _ghost_line.get_theme_stylebox("panel") as StyleBoxFlat
    if sb == null:
        return
    # tscn で共有される StyleBox を編集すると他に波及するため、複製してからいじる
    var local := sb.duplicate() as StyleBoxFlat
    _ghost_line.add_theme_stylebox_override("panel", local)
    _line_pulse_tween = create_tween()
    _line_pulse_tween.set_loops()
    _line_pulse_tween.tween_property(local, "shadow_size", 22.0, LINE_PULSE_PERIOD_SEC / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _line_pulse_tween.tween_property(local, "shadow_size", 10.0, LINE_PULSE_PERIOD_SEC / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------------------
# GhostCharacter 連携
# ---------------------------------------------------------------------------

func _notify_ghost_character(mode: String, dialogue: String) -> void:
    # Ready 画面の吹き出しは直接 Label を更新する。mode は将来 GhostCharacter 共通
    # コンポーネントを他フェーズでも使うようになったとき用に受け取っておく。
    if _ready_bubble_text != null:
        _ready_bubble_text.text = dialogue
    var ghost: Node = _find_ghost_character()
    if ghost == null:
        return
    if ghost.has_method("set_mode"):
        ghost.set_mode(mode)
    if ghost.has_method("set_dialogue"):
        ghost.set_dialogue(dialogue)


func _notify_ghost_character_for_round(result: Dictionary) -> void:
    var ghost: Node = _find_ghost_character()
    if ghost == null:
        return
    if ghost.has_method("set_dialogue"):
        if bool(result.get("win", false)):
            ghost.set_dialogue("やられた〜！")
        else:
            ghost.set_dialogue("これは取らせてもらう")


func _notify_ghost_character_done(wins: int, ghost_wins: int) -> void:
    var dialogue: String
    if wins > ghost_wins:
        dialogue = "今日のきみ、鋭いね。完敗"
    elif wins == ghost_wins:
        dialogue = "互角だったね。いい勝負"
    else:
        dialogue = "惜しかった！また明日やろう"
    _notify_ghost_character("companion", dialogue)


func _find_ghost_character() -> Node:
    # Ready 画面の SD キャラは Control ベースで直接配置しており、
    # GhostCharacter コンポーネントは使っていない。以降のフェーズでキャラを
    # 再利用する拡張時に本メソッドを書き換える想定で placeholder のみ残す。
    return null


## Ready 画面の SD キャラに上下揺れ（bob）アニメーションを付ける。
## 参考: reference/mockup/variant-b.jsx の rb-bob (3.2s ease-in-out infinite, ±6px)。
func _start_ready_character_bob() -> void:
    if _ready_cat_portrait == null:
        return
    var base_pos: Vector2 = _ready_cat_portrait.position
    _ready_bob_tween = create_tween()
    _ready_bob_tween.set_loops()
    _ready_bob_tween.tween_property(_ready_cat_portrait, "position", base_pos + Vector2(0, -6), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _ready_bob_tween.tween_property(_ready_cat_portrait, "position", base_pos, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------------------
# ライフサイクル仕上げ
# ---------------------------------------------------------------------------

func _reset_for_replay() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_individual_result_replay"):
        gm.on_individual_result_replay()


func _on_game_finished(log: PlayLog) -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_game_finished_handler"):
        gm.on_game_finished_handler(log)
    else:
        push_warning("[Ghost7BanShobuView] GameManager not found; log dropped: score=%d" % log.score)


# ---------------------------------------------------------------------------
# 画面向き（横画面強制）
# ---------------------------------------------------------------------------

func _force_landscape() -> void:
    var ds := DisplayServer
    if ds.has_method("screen_get_orientation"):
        _saved_orientation = ds.screen_get_orientation()
    if ds.has_method("screen_set_orientation"):
        ds.screen_set_orientation(ds.SCREEN_LANDSCAPE)


func _restore_orientation() -> void:
    var ds := DisplayServer
    if ds.has_method("screen_set_orientation"):
        var target: int = _saved_orientation if _saved_orientation >= 0 else ds.SCREEN_PORTRAIT
        ds.screen_set_orientation(target)
