## ProgressDots
##
## 7 戦のドット表示 (variant-b.jsx Dots 移植):
##   win=cyan円glow / lose=red× / 未戦=空丸枠 / 進行中=白枠
##
## 使い方:
##   var dots := ProgressDots.new()
##   dots.total = 7
##   add_child(dots)
##   dots.set_state(round_idx, results)  # results: Array of {win:bool}
class_name ProgressDots
extends Control

@export var total: int = 7:
    set(v):
        total = v
        queue_redraw()

@export var dot_size: float = 10.0:
    set(v):
        dot_size = v
        queue_redraw()

@export var spacing: float = 6.0:
    set(v):
        spacing = v
        queue_redraw()

var _current_index: int = 0
var _results: Array = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if size == Vector2.ZERO:
        custom_minimum_size = Vector2(total * (dot_size + spacing) - spacing, dot_size)


func set_state(current: int, results: Array) -> void:
    _current_index = current
    _results = results
    queue_redraw()


func _draw() -> void:
    var x: float = 0.0
    var y: float = size.y * 0.5
    for i in total:
        var center: Vector2 = Vector2(x + dot_size * 0.5, y)
        var has_result: bool = i < _results.size() and _results[i] != null
        if has_result:
            var r: Variant = _results[i]
            var win: bool = false
            if r is Dictionary:
                win = bool(r.get("win", false))
            if win:
                # cyan filled circle + glow
                var halo := Color(0.435, 0.706, 1.0, 0.55)
                for k in 4:
                    var rr: float = dot_size * 0.5 * (1.6 - float(k) * 0.18)
                    var aa: float = halo.a * (0.35 - float(k) * 0.08)
                    if aa <= 0.0:
                        continue
                    draw_circle(center, rr, Color(halo.r, halo.g, halo.b, aa))
                draw_circle(center, dot_size * 0.5, Color(0.435, 0.706, 1.0, 1.0))  # CYAN_400
            else:
                # red × (serif)
                var f: Font = get_theme_default_font()
                if f != null:
                    var col := Color(0.898, 0.353, 0.353, 1.0)  # RED_400
                    var size_px: int = int(dot_size * 1.4)
                    var ws: float = f.get_string_size("×", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
                    draw_string(f, center + Vector2(-ws * 0.5, size_px * 0.35), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, col)
        elif i == _current_index:
            # current: white outlined ring
            var col := Color(0.957, 0.969, 1.0, 0.85)
            _stroke_circle(center, dot_size * 0.5, col, 1.5)
            # subtle outer halo
            var halo2 := Color(1.0, 1.0, 1.0, 0.08)
            draw_circle(center, dot_size * 0.5 + 3.0, halo2)
        else:
            # empty: faint outlined ring
            var col := Color(0.290, 0.333, 0.439, 1.0)  # ink40
            _stroke_circle(center, dot_size * 0.5, col, 1.0)
        x += dot_size + spacing


func _stroke_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
    var prev: Vector2 = center + Vector2(radius, 0.0)
    var n: int = 24
    for i in range(1, n + 1):
        var ang: float = TAU * float(i) / float(n)
        var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, color, width, true)
        prev = p
