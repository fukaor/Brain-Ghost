## SideLaser
##
## variant-b.jsx SideLaser 移植：hit→端の coreグラデ + パーティクル散布。
## start(...) で開始。約 700ms で自動終了。
##
## 使い方:
##   var laser := SideLaser.new()
##   laser.position = Vector2.ZERO  # 親 Control 全体に展開
##   add_child(laser)
##   laser.start(hit_pos, "left", screen_width)
class_name SideLaser
extends Control

const TOTAL_DURATION_MS: int = 700

@export var hot_color: Color = Color(1.0, 0.914, 0.659, 1.0)   # gold300
@export var mid_color: Color = Color(0.961, 0.780, 0.416, 1.0) # gold400
@export var weak: bool = false

var _hit: Vector2 = Vector2.ZERO
var _side: String = "left"
var _len: float = 0.0
var _delay_ms: int = 0
var _start_ms: int = -1
var _running: bool = false
var _particles: Array = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## hit_pos: 中心点 (Control ローカル)
## side: "left" or "right"
## length: 中心から端までの距離
func start(hit_pos: Vector2, side: String, length: float, delay_ms: int = 0) -> void:
    _hit = hit_pos
    _side = side
    _len = length
    _delay_ms = delay_ms
    _start_ms = Time.get_ticks_msec()
    _running = true
    _generate_particles()
    set_process(true)
    queue_redraw()


func _process(_delta: float) -> void:
    if not _running:
        return
    var age: int = Time.get_ticks_msec() - _start_ms
    if age >= TOTAL_DURATION_MS + _delay_ms + 200:
        _running = false
        set_process(false)
    queue_redraw()


func _generate_particles() -> void:
    _particles.clear()
    var n: int = 70 if weak else 140
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in n:
        var u: float = pow(rng.randf(), 2.2)
        var x_local: float
        var proximity: float
        if _side == "left":
            x_local = _len - u * _len
            proximity = x_local / _len
        else:
            x_local = u * _len
            proximity = 1.0 - (x_local / _len)
        var spread: float = 2.0 + proximity * (8.0 if weak else 16.0)
        var y_local: float = (rng.randf() - 0.5) * 2.0 * spread
        var roll: float = rng.randf()
        var s: float
        if roll < 0.7:
            s = 1.0
        elif roll < 0.92:
            s = 1.5
        else:
            s = 2.2
        var base_op: float = (0.2 if weak else 0.35) + proximity * (0.4 if weak else 0.65)
        var op: float = base_op * (0.6 + rng.randf() * 0.4)
        _particles.append({"x": x_local, "y": y_local, "size": s, "op": op})


func _draw() -> void:
    if not _running:
        return
    var age: int = Time.get_ticks_msec() - _start_ms - _delay_ms
    if age < 0:
        return
    # rb-laser keyframes: scaleX 0 → 1, op 0 → 1 over 520ms
    var laser_dur: int = 520
    var p: float = clampf(float(age) / float(laser_dur), 0.0, 1.0)
    var ease: float = 1.0 - pow(1.0 - p, 3.0)
    var visible_len: float = _len * ease

    var core_origin: Vector2 = _hit
    var core_end: Vector2
    if _side == "left":
        core_end = _hit - Vector2(visible_len, 0.0)
    else:
        core_end = _hit + Vector2(visible_len, 0.0)

    # core line — gradient from white at hit to faded at end (weak版は0.6倍)
    var alpha_mul: float = 0.6 if weak else 1.0
    var n_layers: int = 5
    for i in n_layers:
        var ratio: float = float(i + 1) / float(n_layers)
        var thickness: float = lerpf(3.0, 0.5, ratio)
        var col := hot_color
        col.a = (0.85 - ratio * 0.6) * alpha_mul
        draw_line(core_origin, core_end, col, thickness, true)
    var bright := Color(1.0, 1.0, 1.0, 0.85 * alpha_mul)
    draw_line(core_origin, lerp(core_origin, core_end, 0.15), bright, 1.0, true)

    # particles
    var part_age: int = age - 80
    if part_age >= 0:
        var pop: float = clampf(float(part_age) / 600.0, 0.0, 1.0)
        var pop_alpha: float = 1.0 - pop
        for prt in _particles:
            var x_local: float = float(prt["x"])
            if x_local > visible_len:
                continue
            var local: Vector2
            if _side == "left":
                local = _hit - Vector2(x_local, -float(prt["y"]))
            else:
                local = _hit + Vector2(x_local, float(prt["y"]))
            var s: float = float(prt["size"])
            var col := hot_color
            col.a = float(prt["op"]) * pop_alpha
            draw_circle(local, s, col)
            if s > 1.5:
                var halo := col
                halo.a = col.a * 0.4
                draw_circle(local, s * 2.0, halo)
