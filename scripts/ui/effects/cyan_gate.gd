## CyanGate
##
## variant-b.jsx CenterGate 移植：細い縦光柱 + halo + GATE ラベル。
## 主にゲーム中央の判定線として使用。
class_name CyanGate
extends Control

@export var color: Color = Color(1.0, 0.914, 0.659, 1.0)  # gold300
@export var glow: Color = Color(0.961, 0.780, 0.416, 0.6)  # goldGlow
@export var beam_width: float = 2.0
@export var halo_radius: float = 22.0
@export var show_label: bool = true
@export var label_text: String = "GATE"
@export var pulse: bool = true

var _time: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(pulse)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    if size.y <= 0:
        return
    var x: float = size.x * 0.5
    var top: Vector2 = Vector2(x, 0.0)
    var bot: Vector2 = Vector2(x, size.y)
    var p: float = (sin(_time * TAU * 2.0) * 0.5 + 0.5) if pulse else 0.5

    # outer halo (wide soft)
    var halo_wide := Color(glow.r, glow.g, glow.b, 0.18 + p * 0.10)
    draw_line(top, bot, halo_wide, 16.0 + p * 6.0, true)
    # mid halo
    var halo_mid := Color(glow.r, glow.g, glow.b, 0.45)
    draw_line(top, bot, halo_mid, 6.0, true)
    # core beam
    var core := color
    core.a = 0.95
    draw_line(top, bot, core, beam_width, true)

    # center halo (radial)
    var halo_center := Color(glow.r, glow.g, glow.b, 0.5 + p * 0.3)
    var center := Vector2(x, size.y * 0.5)
    for i in 6:
        var r: float = halo_radius * (1.0 - float(i) * 0.15)
        var a: float = halo_center.a * (0.18 - float(i) * 0.025)
        if a <= 0.0:
            break
        var c := halo_center
        c.a = a
        draw_circle(center, r, c)

    if show_label:
        var f: Font = get_theme_default_font()
        if f != null:
            var size_px: int = 11
            var w: float = f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
            var label_pos: Vector2 = Vector2(x - w * 0.5, 14.0)
            draw_string(f, label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
