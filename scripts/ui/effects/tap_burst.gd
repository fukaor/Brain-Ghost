## TapBurst
##
## variant-b.jsx Result 中央演出のうち「Ring×7 + Core + VerticalFlare」を 1 つにまとめた爆発。
## start_burst() で開始。約 1100ms で自動終了。完了後は何も描画しない。
##
## 使い方:
##   var burst := TapBurst.new()
##   burst.position = hit_position
##   add_child(burst)
##   burst.start()
class_name TapBurst
extends Control

const RING_DEFS: Array = [
    {"r": 24.0,  "w": 1.5, "op": 0.95, "delay_ms": 0,   "hot": true},
    {"r": 38.0,  "w": 1.2, "op": 0.85, "delay_ms": 40,  "hot": true},
    {"r": 56.0,  "w": 1.0, "op": 0.70, "delay_ms": 90,  "hot": false},
    {"r": 78.0,  "w": 1.0, "op": 0.55, "delay_ms": 150, "hot": false},
    {"r": 102.0, "w": 1.0, "op": 0.40, "delay_ms": 220, "hot": false},
    {"r": 130.0, "w": 1.0, "op": 0.28, "delay_ms": 300, "hot": false},
    {"r": 162.0, "w": 1.0, "op": 0.18, "delay_ms": 390, "hot": false},
]
const TOTAL_DURATION_MS: int = 1100

@export var hot_color: Color = Color(1.0, 0.914, 0.659, 1.0)   # gold300
@export var mid_color: Color = Color(0.961, 0.780, 0.416, 1.0) # gold400
@export var draw_vertical_flare: bool = true
@export var auto_start: bool = false

var _start_ms: int = -1
var _running: bool = false


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if auto_start:
        start()


func start() -> void:
    _start_ms = Time.get_ticks_msec()
    _running = true
    set_process(true)
    queue_redraw()


func _process(_delta: float) -> void:
    if not _running:
        return
    var age: int = Time.get_ticks_msec() - _start_ms
    if age >= TOTAL_DURATION_MS + 200:
        _running = false
        set_process(false)
    queue_redraw()


func _draw() -> void:
    if not _running or _start_ms < 0:
        return
    var age: int = Time.get_ticks_msec() - _start_ms
    var center: Vector2 = size * 0.5
    if size == Vector2.ZERO:
        center = Vector2.ZERO

    # Vertical flare (上下の縦光線)
    if draw_vertical_flare:
        _draw_vertical_flare(center, age)

    # Rings
    for d in RING_DEFS:
        _draw_ring(center, d, age)

    # Core (中央 10px 白点 + glow), 0..1100ms で 0.2 → 1.6 → 1.0 → 0.7 のスケール
    _draw_core(center, age)


func _draw_ring(center: Vector2, d: Dictionary, age: int) -> void:
    var delay_ms: int = int(d["delay_ms"])
    var local_age: int = age - delay_ms
    var dur: int = 1100
    if local_age < 0 or local_age > dur:
        return
    var phase: float = float(local_age) / float(dur)
    # rb-ring keyframes: scale 0.1 → (op at 25%) → 1.0, opacity 0 → op → 0
    var scale: float = lerpf(0.1, 1.0, phase)
    var op_peak: float = float(d["op"])
    var alpha: float
    if phase < 0.25:
        alpha = lerpf(0.0, op_peak, phase / 0.25)
    else:
        alpha = lerpf(op_peak, 0.0, (phase - 0.25) / 0.75)
    if alpha <= 0.0:
        return
    var radius: float = float(d["r"]) * scale
    var color: Color = hot_color if bool(d["hot"]) else mid_color
    color.a = alpha
    var width: float = float(d["w"])
    _stroke_circle(center, radius, color, width)


func _draw_core(center: Vector2, age: int) -> void:
    var dur: int = 1100
    if age < 0 or age > dur:
        return
    var phase: float = float(age) / float(dur)
    var scale: float
    var alpha: float
    # rb-core keyframes: 0% (0.2, 0) → 12% (1.6, 1) → 30% (1, 1) → 100% (0.7, 0.3)
    if phase < 0.12:
        scale = lerpf(0.2, 1.6, phase / 0.12)
        alpha = lerpf(0.0, 1.0, phase / 0.12)
    elif phase < 0.30:
        scale = lerpf(1.6, 1.0, (phase - 0.12) / 0.18)
        alpha = 1.0
    else:
        scale = lerpf(1.0, 0.7, (phase - 0.30) / 0.70)
        alpha = lerpf(1.0, 0.3, (phase - 0.30) / 0.70)
    var r: float = 5.0 * scale
    var glow_color := hot_color
    glow_color.a = alpha * 0.8
    for i in 4:
        draw_circle(center, r * (1.0 + float(i) * 0.6), Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * (0.3 - float(i) * 0.07)))
    var core := Color(1.0, 1.0, 1.0, alpha)
    draw_circle(center, r, core)


func _draw_vertical_flare(center: Vector2, age: int) -> void:
    # rb-laser-v 600ms cubic-bezier(.2,.8,.2,1) 120ms / 160ms both
    var dur: int = 600
    var height_local: float = max(size.y * 0.5, 200.0)
    # upward
    var up_local: int = age - 120
    if up_local >= 0 and up_local <= dur:
        var p: float = clampf(float(up_local) / float(dur), 0.0, 1.0)
        var ease: float = 1.0 - pow(1.0 - p, 3.0)
        var len: float = height_local * ease
        var col := Color(hot_color.r, hot_color.g, hot_color.b, 0.7 * (1.0 - p * 0.5))
        draw_line(center, center + Vector2(0.0, -len), col, 1.5, true)
        # softer halo
        var halo := Color(hot_color.r, hot_color.g, hot_color.b, 0.25 * (1.0 - p * 0.5))
        draw_line(center, center + Vector2(0.0, -len), halo, 5.0, true)
    # downward
    var down_local: int = age - 160
    if down_local >= 0 and down_local <= dur:
        var p2: float = clampf(float(down_local) / float(dur), 0.0, 1.0)
        var ease2: float = 1.0 - pow(1.0 - p2, 3.0)
        var len2: float = height_local * ease2
        var col2 := Color(hot_color.r, hot_color.g, hot_color.b, 0.7 * (1.0 - p2 * 0.5))
        draw_line(center, center + Vector2(0.0, len2), col2, 1.5, true)
        var halo2 := Color(hot_color.r, hot_color.g, hot_color.b, 0.25 * (1.0 - p2 * 0.5))
        draw_line(center, center + Vector2(0.0, len2), halo2, 5.0, true)


func _stroke_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
    var prev: Vector2 = center + Vector2(radius, 0.0)
    var n: int = 48
    for i in range(1, n + 1):
        var ang: float = TAU * float(i) / float(n)
        var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, color, width, true)
        prev = p
