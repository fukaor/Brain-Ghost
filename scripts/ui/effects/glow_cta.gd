## GlowCTA
##
## variant-b.jsx Ready の TAP で開始 ボタン / home の今日のチャレンジ。
## cyan-border 角丸ピル + 内外ボックスシャドウ + glow pulse アニメ。
##
## 既存の Button にこの Control を背景として重ねる、または Container として使う想定。
## 自前で描画するため、子要素として Label を含めて使うとシンプル。
class_name GlowCTA
extends Control

@export var border_color: Color = Color(0.435, 0.706, 1.0, 1.0)  # CYAN_400
@export var glow_color: Color = Color(0.435, 0.706, 1.0, 0.55)   # CYAN_GLOW
@export var fill_color: Color = Color(0.043, 0.071, 0.125, 0.4)  # BG_PANEL with alpha
@export var corner_radius: float = 999.0
@export var border_width: float = 2.0
@export var pulse: bool = true
@export var pulse_speed: float = 0.5  # Hz相当

var _time: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(pulse)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    if size.x <= 2 or size.y <= 2:
        return
    var rect: Rect2 = Rect2(Vector2.ZERO, size)
    var radius: float = min(corner_radius, min(size.x, size.y) * 0.5)
    var p: float = (sin(_time * TAU * pulse_speed) * 0.5 + 0.5) if pulse else 0.5

    # subtle fill (background)
    _draw_pill_fill(rect, radius, fill_color)

    # outer glow as multi-layer outline (no expansion, just thicker semi-transparent strokes)
    # variant-b box-shadow 0 0 14px cyanGlow を線幅で代替
    var glow_layers: int = 4
    for i in glow_layers:
        var w: float = 18.0 - float(i) * 4.0 + p * 4.0
        var a: float = (0.18 - float(i) * 0.04) + p * 0.05
        if a <= 0.0 or w <= 0.0:
            continue
        var c := glow_color
        c.a = a
        _draw_pill_outline(rect, radius, c, w)

    # main border
    var bd := border_color
    bd.a = 0.95
    _draw_pill_outline(rect, radius, bd, border_width)


# rounded-rect fill via 1 horizontal rect + 2 vertical rects + 4 corner circles
func _draw_pill_fill(rect: Rect2, radius: float, color: Color) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    var r: float = clampf(radius, 0.0, min(rect.size.x, rect.size.y) * 0.5)
    if r <= 0.0:
        draw_rect(rect, color, true)
        return
    # central horizontal strip (full width × interior height)
    var inner_y: Rect2 = Rect2(
        Vector2(rect.position.x, rect.position.y + r),
        Vector2(rect.size.x, rect.size.y - r * 2.0)
    )
    if inner_y.size.y > 0.0:
        draw_rect(inner_y, color, true)
    # top strip (between corner centers)
    var top: Rect2 = Rect2(
        Vector2(rect.position.x + r, rect.position.y),
        Vector2(rect.size.x - r * 2.0, r)
    )
    if top.size.x > 0.0:
        draw_rect(top, color, true)
    var bot: Rect2 = Rect2(
        Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
        Vector2(rect.size.x - r * 2.0, r)
    )
    if bot.size.x > 0.0:
        draw_rect(bot, color, true)
    # 4 corner circles
    draw_circle(rect.position + Vector2(r, r), r, color)
    draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
    draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
    draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)


# rounded-rect outline via 4 lines + 4 arcs
func _draw_pill_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    var r: float = clampf(radius, 0.0, min(rect.size.x, rect.size.y) * 0.5)
    var p: Vector2 = rect.position
    var s: Vector2 = rect.size
    # top
    draw_line(p + Vector2(r, 0.0), p + Vector2(s.x - r, 0.0), color, width, true)
    # bottom
    draw_line(p + Vector2(r, s.y), p + Vector2(s.x - r, s.y), color, width, true)
    # left
    draw_line(p + Vector2(0.0, r), p + Vector2(0.0, s.y - r), color, width, true)
    # right
    draw_line(p + Vector2(s.x, r), p + Vector2(s.x, s.y - r), color, width, true)
    # corners
    _arc(p + Vector2(r, r), r, PI, 1.5 * PI, color, width)
    _arc(p + Vector2(s.x - r, r), r, 1.5 * PI, 2.0 * PI, color, width)
    _arc(p + Vector2(r, s.y - r), r, 0.5 * PI, PI, color, width)
    _arc(p + Vector2(s.x - r, s.y - r), r, 0.0, 0.5 * PI, color, width)


func _arc(center: Vector2, radius: float, start_ang: float, end_ang: float, color: Color, width: float) -> void:
    var n: int = 16
    var prev: Vector2 = center + Vector2(cos(start_ang), sin(start_ang)) * radius
    for i in range(1, n + 1):
        var t: float = float(i) / float(n)
        var ang: float = lerpf(start_ang, end_ang, t)
        var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, color, width, true)
        prev = p
