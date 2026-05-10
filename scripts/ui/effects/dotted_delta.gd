## DottedDelta
##
## 2 点間の repeating dotted line + 中央に「-/+ Xms」ラベル。
## variant-b.jsx Result の超過/不足表示。
class_name DottedDelta
extends Control

@export var color: Color = Color(0.780, 0.824, 0.910, 0.7)   # ink80
@export var label_color: Color = Color(0.722, 0.878, 1.0, 0.95)  # cyan300
@export var label_text: String = "+0ms"
@export var label_font_size: int = 14
@export var dot_length: float = 3.0
@export var gap_length: float = 3.0

var _start: Vector2 = Vector2.ZERO
var _end: Vector2 = Vector2.ZERO


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_endpoints(p_start: Vector2, p_end: Vector2) -> void:
    _start = p_start
    _end = p_end
    queue_redraw()


func _draw() -> void:
    if _start == _end:
        return
    var dir: Vector2 = (_end - _start).normalized()
    var total: float = _start.distance_to(_end)
    var step: float = dot_length + gap_length
    var i: float = 0.0
    while i < total:
        var a: Vector2 = _start + dir * i
        var b: Vector2 = _start + dir * min(i + dot_length, total)
        draw_line(a, b, color, 1.0, true)
        i += step
    # label at midpoint, slightly above
    var mid: Vector2 = (_start + _end) * 0.5
    var f: Font = get_theme_default_font()
    if f != null:
        var w: float = f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size).x
        var pos: Vector2 = mid + Vector2(-w * 0.5, -8.0)
        draw_string(f, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_color)
