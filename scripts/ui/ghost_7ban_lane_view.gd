## Ghost7BanLaneView (Midnight Cat — promo `game_tap_touch.png` 準拠)
##
## レーン描画＆オーブアニメ Control。promo の星明かりトーンを Godot に落とし込む：
## - レーン: 細く繊細な水平光線（端で減衰）
## - GATE:  柔らかい白の縦光柱（多層グロー、ハードな塗りなし）
## - YOU:   白コア + 金の星形（4 長軸ray + 4 短対角 ray、全て先細りでフェード）
## - GHOST: 小さなシアンコア + 控えめなグロー
##
## ビュー側からは set_round() / start_moving() / record_tap() / enter_result() を呼ぶ。
extends Control

const LaneShapes := preload("res://scripts/games/ghost_7ban_shobu/lane_shapes.gd")

# 主要トーン
const COL_LIGHT := Color(0.95, 0.97, 1.0, 1.0)
const COL_GATE_CORE := Color(1.0, 0.98, 0.92, 0.95)        # ほぼ白、温度感わずか
const COL_GATE_HALO := Color(1.0, 0.95, 0.78, 0.6)         # 金ニュアンスを含むハロー
const COL_LANE := Color(0.7, 0.85, 1.0, 0.32)              # 寒色寄りの細い光線

const COL_YOU_CORE := Color(1.0, 1.0, 1.0, 1.0)
const COL_YOU_GLOW := Color(1.0, 0.92, 0.62, 1.0)
const COL_YOU_RAY := Color(1.0, 0.9, 0.55, 1.0)

const COL_GHOST_CORE := Color(0.85, 0.95, 1.0, 1.0)
const COL_GHOST_GLOW := Color(0.49, 0.827, 0.988, 1.0)

const COL_TEXT := Color(0.949, 0.957, 0.98, 1.0)
const COL_DIM := Color(0.42, 0.467, 0.561, 1.0)

# レーン rect マージン
const LANE_PADDING_TOP: float = 80.0
const LANE_PADDING_BOTTOM: float = 80.0
const LANE_PADDING_X: float = 60.0

# トレイル
const TRAIL_LENGTH_PX: float = 100.0
const TRAIL_SAMPLES: int = 18

# タップフラッシュ
const TAP_FLASH_DURATION_MS: int = 700

# 星形 (long axis + short diagonal)
const RAY_LONG_LENGTH: float = 78.0
const RAY_SHORT_LENGTH: float = 28.0

# 状態
var _shape: String = "line"
var _move_ms: int = 2200
var _move_start_ms: int = 0
var _ghost_offset_ms: int = 0
var _you_tap_t: float = -1.0
var _ghost_stop_t: float = 0.5
var _phase: String = "idle"
var _result_grade: String = ""
var _result_win: bool = false
var _result_enter_ms: int = 0


func _process(_delta: float) -> void:
    if _phase == "moving" or _phase == "result":
        queue_redraw()


# 公開 API ---------------------------------------------------------------
func set_round(shape: String, move_ms: int, ghost_offset_ms: int) -> void:
    _shape = shape
    _move_ms = max(400, move_ms)
    _ghost_offset_ms = ghost_offset_ms
    _ghost_stop_t = clampf(0.5 + float(ghost_offset_ms) / float(_move_ms), 0.0, 1.0)
    _you_tap_t = -1.0
    _phase = "idle"
    queue_redraw()


func start_moving(move_start_ms: int) -> void:
    _move_start_ms = move_start_ms
    _you_tap_t = -1.0
    _phase = "moving"
    queue_redraw()


func record_tap(tap_ms: int) -> void:
    var elapsed: int = tap_ms - _move_start_ms
    _you_tap_t = clampf(float(elapsed) / float(_move_ms), 0.0, 1.0)


func enter_result(grade: String, win: bool, you_tap_ms_offset: int = -999999) -> void:
    if you_tap_ms_offset != -999999:
        _you_tap_t = clampf((float(_move_ms) * 0.5 + float(you_tap_ms_offset)) / float(_move_ms), 0.0, 1.0)
    _result_grade = grade
    _result_win = win
    _phase = "result"
    _result_enter_ms = Time.get_ticks_msec()
    queue_redraw()


func clear_state() -> void:
    _phase = "idle"
    _you_tap_t = -1.0
    queue_redraw()


# 公開: Result phase で外部エフェクトの位置を取得するためのヘルパ
func get_you_tap_position(rect: Rect2) -> Vector2:
    var t: float = _you_tap_t if _you_tap_t >= 0.0 else 0.5
    return LaneShapes.position_on_lane(_shape, t, rect)


func get_ghost_stop_position(rect: Rect2) -> Vector2:
    return LaneShapes.position_on_lane(_shape, 1.0 - _ghost_stop_t, rect)


func get_lane_rect_for_external() -> Rect2:
    return _lane_rect()


# 描画 -------------------------------------------------------------------
func _draw() -> void:
    if _phase == "idle":
        return
    var rect: Rect2 = _lane_rect()

    _draw_lane(rect)
    _draw_gate(rect)

    match _phase:
        "moving":
            _draw_moving(rect)
        "result":
            _draw_result(rect)


# ─── レーン（薄い水平光線、端でフェード） ───
func _draw_lane(rect: Rect2) -> void:
    var y: float = rect.position.y + rect.size.y * 0.5
    var x_start: float = rect.position.x
    var x_end: float = rect.position.x + rect.size.x
    # 中心 80% を主区間、外側 10% は減衰
    var inner_l: float = lerpf(x_start, x_end, 0.08)
    var inner_r: float = lerpf(x_start, x_end, 0.92)
    # ハロー（薄い太線）
    draw_line(Vector2(inner_l, y), Vector2(inner_r, y), Color(COL_LANE.r, COL_LANE.g, COL_LANE.b, 0.18), 6.0, true)
    # コア（細い線）
    draw_line(Vector2(inner_l, y), Vector2(inner_r, y), Color(COL_LANE.r, COL_LANE.g, COL_LANE.b, 0.55), 1.2, true)
    # フェード端：細い外延
    draw_line(Vector2(x_start, y), Vector2(inner_l, y), Color(COL_LANE.r, COL_LANE.g, COL_LANE.b, 0.15), 1.0, true)
    draw_line(Vector2(inner_r, y), Vector2(x_end, y), Color(COL_LANE.r, COL_LANE.g, COL_LANE.b, 0.15), 1.0, true)


# ─── GATE：細い縦光柱（variant-b CenterGate 準拠 — gold thin beam + halo） ───
func _draw_gate(rect: Rect2) -> void:
    var x: float = rect.position.x + rect.size.x * 0.5
    var y_top: float = rect.position.y + rect.size.y * 0.20
    var y_bot: float = rect.position.y + rect.size.y * 0.80
    var top: Vector2 = Vector2(x, y_top)
    var bot: Vector2 = Vector2(x, y_bot)
    # halo wide soft (16px)
    var halo_wide := Color(COL_GATE_HALO.r, COL_GATE_HALO.g, COL_GATE_HALO.b, 0.18)
    draw_line(top, bot, halo_wide, 16.0, true)
    # halo mid
    var halo_mid := Color(COL_GATE_HALO.r, COL_GATE_HALO.g, COL_GATE_HALO.b, 0.40)
    draw_line(top, bot, halo_mid, 6.0, true)
    # core thin beam
    var core := COL_GATE_CORE
    core.a = 0.95
    draw_line(top, bot, core, 2.0, true)
    # center halo radial (subtle — promo はこの halo を強くしていない)
    var mid_y: float = rect.position.y + rect.size.y * 0.5
    _draw_orb_glow(Vector2(x, mid_y), COL_GATE_HALO, 14.0, 0.25)
    # GATE label
    var f: Font = get_theme_default_font()
    if f != null:
        var label: String = "GATE"
        var size_px: int = 10
        var w: float = f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
        draw_string(f, Vector2(x - w * 0.5, y_top - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, COL_GATE_CORE)


# ─── プレイ中：YOU/GHOST orb + 軌跡 ───
func _draw_moving(rect: Rect2) -> void:
    var now: int = Time.get_ticks_msec()
    var t: float = clampf(float(now - _move_start_ms) / float(_move_ms), 0.0, 1.0)

    # YOU 軌跡 + orb
    _draw_trail(_shape, t, rect, +1, COL_YOU_GLOW)
    _draw_you_orb(LaneShapes.position_on_lane(_shape, t, rect), 0.6)

    # GHOST 軌跡 + orb（停止位置を超えない）
    var t_ghost_world: float = clampf(t, 0.0, _ghost_stop_t)
    var s_ghost: float = 1.0 - t_ghost_world
    _draw_trail(_shape, s_ghost, rect, -1, COL_GHOST_GLOW)
    _draw_ghost_orb(LaneShapes.position_on_lane(_shape, s_ghost, rect))


# ─── Result：星形バースト + 比較 ───
func _draw_result(rect: Rect2) -> void:
    var age_ms: int = Time.get_ticks_msec() - _result_enter_ms

    var you_t: float = _you_tap_t if _you_tap_t >= 0.0 else 0.5
    var you_pos: Vector2 = LaneShapes.position_on_lane(_shape, you_t, rect)
    var ghost_pos: Vector2 = LaneShapes.position_on_lane(_shape, 1.0 - _ghost_stop_t, rect)

    # GHOST orb（停止位置の小さな光点）
    _draw_ghost_orb(ghost_pos)

    # YOU 星形バースト
    _draw_you_star(you_pos)

    # タップフラッシュ拡張リング（フェード付き）
    if age_ms < TAP_FLASH_DURATION_MS:
        var phase: float = clampf(float(age_ms) / float(TAP_FLASH_DURATION_MS), 0.0, 1.0)
        _draw_soft_ring(you_pos, COL_YOU_GLOW, 64.0, phase)
        _draw_soft_ring(ghost_pos, COL_GHOST_GLOW, 38.0, phase)

    # ms ラベル（orb 真下中央）
    var f: Font = get_theme_default_font()
    var you_ms_offset: int = int(round((you_t - 0.5) * float(_move_ms)))
    var you_label: String = "%dms" % abs(you_ms_offset)
    _draw_centered_text(f, you_pos + Vector2(0.0, 38.0), you_label, 22, COL_YOU_GLOW)
    var ghost_label: String = "%dms" % abs(_ghost_offset_ms)
    _draw_centered_text(f, ghost_pos + Vector2(0.0, 38.0), ghost_label, 22, COL_GHOST_GLOW)


# ─── orb / 星形 描画ヘルパ ───
func _draw_you_orb(pos: Vector2, intensity: float = 1.0) -> void:
    # プレイ中の小さい白コア + 黄金ハロー
    _draw_orb_glow(pos, COL_YOU_GLOW, 22.0 * intensity, 1.0)
    draw_circle(pos, 7.0 * intensity, COL_YOU_GLOW)
    draw_circle(pos, 3.5 * intensity, COL_YOU_CORE)


func _draw_ghost_orb(pos: Vector2) -> void:
    _draw_orb_glow(pos, COL_GHOST_GLOW, 16.0, 0.85)
    draw_circle(pos, 5.5, COL_GHOST_GLOW)
    draw_circle(pos, 2.2, COL_GHOST_CORE)


func _draw_you_star(pos: Vector2) -> void:
    # 1) 中央のグロー（大）
    _draw_orb_glow(pos, COL_YOU_GLOW, 56.0, 1.0)

    # 2) 4 本の主軸 ray（上下左右）— 一番長い、太い
    var dirs_main := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
    for d in dirs_main:
        _draw_tapered_ray(pos, d, RAY_LONG_LENGTH, 6.0, COL_YOU_RAY)

    # 3) 副軸 ray 群（promo の不揃いなスターバースト感）
    #   — 主軸の間に 5 本ずつ、計 20 本。角度・長さ・太さに決定論的ジッタ
    var ray_color_dim := Color(COL_YOU_RAY.r, COL_YOU_RAY.g, COL_YOU_RAY.b, 0.55)
    var ray_color_mid := Color(COL_YOU_RAY.r, COL_YOU_RAY.g, COL_YOU_RAY.b, 0.7)
    # 16 本の副 ray を 360° 等間隔の少し外側に配置（22.5° おき、主軸 4 本を避ける）
    var sub_count: int = 16
    for i in sub_count:
        var t: float = float(i) / float(sub_count)
        var ang: float = t * TAU + 0.0982  # 5.6° オフセットで主軸から離す
        # 長さは主軸の 35〜70% にジッタ（i に基づく決定論ハッシュ）
        var jitter: float = sin(float(i) * 7.91 + 1.7) * 0.5 + 0.5  # 0..1
        var length: float
        var width: float
        var color: Color
        # 8 本は中尺、8 本は短尺
        if i % 2 == 0:
            length = lerpf(RAY_LONG_LENGTH * 0.55, RAY_LONG_LENGTH * 0.85, jitter)
            width = 3.5 + jitter * 1.5
            color = ray_color_mid
        else:
            length = lerpf(RAY_SHORT_LENGTH * 0.7, RAY_SHORT_LENGTH * 1.4, jitter)
            width = 2.0 + jitter * 1.5
            color = ray_color_dim
        var dir := Vector2(cos(ang), sin(ang))
        _draw_tapered_ray(pos, dir, length, width, color)

    # 4) 中心の白核
    draw_circle(pos, 9.0, COL_YOU_GLOW)
    draw_circle(pos, 4.5, COL_YOU_CORE)


# 先細り ray = 中心から外側へ向かう三角形ポリゴン（base 太、tip 細＋透明）
func _draw_tapered_ray(origin: Vector2, dir: Vector2, length: float, base_width: float, color: Color) -> void:
    var tip: Vector2 = origin + dir * length
    var perp: Vector2 = Vector2(-dir.y, dir.x)
    var base_left: Vector2 = origin + perp * (base_width * 0.5)
    var base_right: Vector2 = origin - perp * (base_width * 0.5)
    var pts := PackedVector2Array([base_left, tip, base_right])
    var cols := PackedColorArray()
    var solid: Color = color
    var faded: Color = color
    faded.a = 0.0
    cols.append(solid)
    cols.append(faded)
    cols.append(solid)
    draw_polygon(pts, cols)


# ─── 移動 orb のトレイル（進行方向逆向きに減衰） ───
func _draw_trail(shape: String, t: float, rect: Rect2, direction: int, base: Color) -> void:
    if t <= 0.001 or t >= 0.999:
        return
    var px_per_t: float = rect.size.x
    var step: float = TRAIL_LENGTH_PX / px_per_t / float(TRAIL_SAMPLES)
    for i in TRAIL_SAMPLES:
        var t_back: float = t - float(direction) * step * float(i + 1)
        if t_back < 0.0 or t_back > 1.0:
            continue
        var pos: Vector2 = LaneShapes.position_on_lane(shape, t_back, rect)
        var falloff: float = 1.0 - float(i) / float(TRAIL_SAMPLES)
        var a: float = 0.45 * falloff * falloff
        var r: float = lerpf(5.0, 1.5, float(i) / float(TRAIL_SAMPLES))
        var c: Color = base
        c.a = a
        draw_circle(pos, r, c)


func _draw_orb_glow(pos: Vector2, color: Color, radius: float, intensity: float = 1.0) -> void:
    # 多層放射状グロー（疑似 radial gradient）
    for i in 9:
        var r: float = radius * (1.0 - float(i) * 0.10)
        var a: float = color.a * intensity * (0.28 - float(i) * 0.03)
        if a <= 0.0 or r <= 0.5:
            break
        var c: Color = color
        c.a = a
        draw_circle(pos, r, c)


# ソフトリング（rb-fire keyframes 模倣：scale 0.3→1.2→2.2、alpha フェード）
func _draw_soft_ring(pos: Vector2, color: Color, base_size: float, phase: float) -> void:
    var scale: float
    if phase < 0.3:
        scale = lerpf(0.3, 1.2, phase / 0.3)
    else:
        scale = lerpf(1.2, 2.2, (phase - 0.3) / 0.7)
    var radius: float = base_size * 0.5 * scale
    var alpha: float = 0.7 * (1.0 - phase)
    if alpha <= 0.0:
        return
    var ring: Color = color
    ring.a = alpha
    # 円周を 36 サンプルでアンチエイリアスライン描画
    var prev: Vector2 = pos + Vector2(radius, 0.0)
    for i in range(1, 37):
        var ang: float = TAU * float(i) / 36.0
        var p: Vector2 = pos + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, ring, 2.0, true)
        prev = p


func _lane_rect() -> Rect2:
    return Rect2(
        Vector2(LANE_PADDING_X, LANE_PADDING_TOP),
        Vector2(size.x - LANE_PADDING_X * 2.0, size.y - LANE_PADDING_TOP - LANE_PADDING_BOTTOM)
    )


func _draw_centered_text(f: Font, center: Vector2, text: String, size_px: int, color: Color) -> void:
    var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    draw_string(f, center - Vector2(w * 0.5, -float(size_px) * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
