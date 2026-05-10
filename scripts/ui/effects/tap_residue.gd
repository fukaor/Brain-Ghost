## TapResidue
##
## promotion `game_tap_touch.png` の余韻 — タップ位置に小粒のダストを散らし、
## ゆっくり放射状にドリフトさせながらフェード。1500ms かけて消える。
##
## 使い方:
##   var res := TapResidue.new()
##   res.size = effects_layer.size
##   res.position = Vector2.ZERO
##   add_child(res)
##   res.start(hit_pos)
class_name TapResidue
extends Control

const PARTICLE_COUNT: int = 80
const TOTAL_DURATION_MS: int = 1700

@export var hot_color: Color = Color(1.0, 0.914, 0.659, 1.0)
@export var mid_color: Color = Color(0.961, 0.780, 0.416, 1.0)

var _origin: Vector2 = Vector2.ZERO
var _start_ms: int = -1
var _running: bool = false
var _particles: Array = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## hit_pos: Control ローカル座標系 (size の左上 0,0 基準)
func start(hit_pos: Vector2) -> void:
    _origin = hit_pos
    _start_ms = Time.get_ticks_msec()
    _running = true
    _generate_particles()
    set_process(true)
    queue_redraw()


func _generate_particles() -> void:
    _particles.clear()
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in PARTICLE_COUNT:
        # 角度ジッタ（全方向に均等にばらつく）
        var ang: float = rng.randf() * TAU
        # 距離: 0 (中心付近) から RANGE_MAX。pow で外に偏らせる
        var dist_max: float = 130.0 + rng.randf() * 70.0
        var u: float = pow(rng.randf(), 0.55)
        var dist: float = dist_max * u
        # サイズと不透明度のクラス分け（少し明るめにシフト）
        var roll: float = rng.randf()
        var p_size: float
        var p_op: float
        if roll < 0.45:
            p_size = 1.2 + rng.randf() * 0.7
            p_op = 0.5 + rng.randf() * 0.25
        elif roll < 0.80:
            p_size = 1.9 + rng.randf() * 1.0
            p_op = 0.7 + rng.randf() * 0.2
        else:
            p_size = 2.8 + rng.randf() * 1.4
            p_op = 0.85 + rng.randf() * 0.15
        # ドリフト速度（さらに外側へ少し動く）
        var drift_speed: float = 10.0 + rng.randf() * 38.0
        # 寿命（個別に揺らぎ）
        var life_ms: int = 800 + int(rng.randf() * 900.0)
        # 出現遅延
        var delay_ms: int = int(rng.randf() * 220.0)
        # 揺れ位相（微小揺らぎで「漂い」感）
        var sway_phase: float = rng.randf() * TAU
        var sway_amp: float = 1.5 + rng.randf() * 3.0
        _particles.append({
            "ang": ang,
            "dist0": dist,
            "size": p_size,
            "op": p_op,
            "drift": drift_speed,
            "life": life_ms,
            "delay": delay_ms,
            "sway_phase": sway_phase,
            "sway_amp": sway_amp,
            "hot": roll >= 0.80,
        })


func _process(_delta: float) -> void:
    if not _running:
        return
    var age: int = Time.get_ticks_msec() - _start_ms
    if age >= TOTAL_DURATION_MS + 100:
        _running = false
        set_process(false)
    queue_redraw()


func _draw() -> void:
    if not _running or _start_ms < 0:
        return
    var now: int = Time.get_ticks_msec() - _start_ms
    for p in _particles:
        var local_age: int = now - int(p["delay"])
        if local_age < 0:
            continue
        var life: int = int(p["life"])
        if local_age > life:
            continue
        var phase: float = float(local_age) / float(life)
        # 出現は最初の 18%, 残りはフェードアウト
        var alpha_mul: float
        if phase < 0.18:
            alpha_mul = phase / 0.18
        else:
            alpha_mul = 1.0 - (phase - 0.18) / 0.82
        if alpha_mul <= 0.0:
            continue
        # 半径方向のドリフト
        var dist: float = float(p["dist0"]) + float(p["drift"]) * phase
        var ang: float = float(p["ang"])
        var dir: Vector2 = Vector2(cos(ang), sin(ang))
        # 微小な揺らぎ（垂直成分）
        var sway: float = sin(float(p["sway_phase"]) + phase * TAU * 0.7) * float(p["sway_amp"])
        var perp: Vector2 = Vector2(-dir.y, dir.x)
        var pos: Vector2 = _origin + dir * dist + perp * sway
        var s: float = float(p["size"])
        var col: Color = hot_color if bool(p["hot"]) else mid_color
        var a: float = float(p["op"]) * alpha_mul
        var draw_col := Color(col.r, col.g, col.b, a)
        draw_circle(pos, s, draw_col)
        # 大粒子にはふんわりハロー
        if s > 1.8:
            var halo := Color(col.r, col.g, col.b, a * 0.35)
            draw_circle(pos, s * 2.4, halo)
