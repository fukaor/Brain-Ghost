## StarLayer
##
## 漆黒 void 背景の上に薄い星空をスタンプする Control。
## variant-b.jsx の StarLayer (8 個の radial-gradient) を Godot に移植。
##
## 使い方:
##   var stars := StarLayer.new()
##   stars.anchors_preset = Control.PRESET_FULL_RECT
##   add_child(stars)
class_name StarLayer
extends Control

const _STAR_COUNT: int = 64
const _SEED_DEFAULT: int = 0xCA771C  # cat-ish

@export var density: float = 1.0:
    set(v):
        density = v
        _ensure_points()
        queue_redraw()

@export var seed_value: int = _SEED_DEFAULT:
    set(v):
        seed_value = v
        _points.clear()
        _ensure_points()
        queue_redraw()

@export var twinkle: bool = true

var _points: PackedVector2Array = PackedVector2Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _colors: PackedColorArray = PackedColorArray()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ensure_points()
    set_process(twinkle)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _ensure_points()
        queue_redraw()


func _ensure_points() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    if _points.size() == int(_STAR_COUNT * density):
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    _points.clear()
    _sizes.clear()
    _colors.clear()
    _phases.clear()
    var n: int = int(_STAR_COUNT * density)
    for i in n:
        _points.append(Vector2(rng.randf(), rng.randf()))
        var roll: float = rng.randf()
        var size_px: float
        if roll < 0.7:
            size_px = 1.0
        elif roll < 0.92:
            size_px = 1.5
        else:
            size_px = 2.2
        _sizes.append(size_px)
        var color_roll: float = rng.randf()
        var c: Color
        if color_roll < 0.6:
            c = Color(1.0, 1.0, 1.0, 0.35 + rng.randf() * 0.15)
        elif color_roll < 0.85:
            c = Color(0.722, 0.878, 1.0, 0.35 + rng.randf() * 0.15)  # CYAN_300
        else:
            c = Color(0.435, 0.706, 1.0, 0.30 + rng.randf() * 0.20)  # CYAN_400
        _colors.append(c)
        _phases.append(rng.randf() * TAU)


func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    if _points.is_empty():
        return
    for i in _points.size():
        var p: Vector2 = _points[i]
        var pos: Vector2 = Vector2(p.x * size.x, p.y * size.y)
        var s: float = _sizes[i]
        var c: Color = _colors[i]
        if twinkle:
            var t: float = sin(_time * 0.7 + _phases[i]) * 0.25 + 0.75
            c.a = c.a * t
        # halo (large faint)
        if s >= 1.5:
            var halo := Color(c.r, c.g, c.b, c.a * 0.3)
            draw_circle(pos, s * 2.0, halo)
        # core
        draw_circle(pos, s, c)
