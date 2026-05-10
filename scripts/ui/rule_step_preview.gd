## RuleStepPreview
##
## ルール説明画面のステップごとのプレビュー描画。
## docs/design/promotion/game_tap_rule.png の 3 ステップミニ図に相当。
##
## variants:
##   "ready"    — 第N戦/7 + 進捗ドット + 中央ゲート
##   "tap"      — TAP! + 中央発光
##   "compare"  — 87ms / 142ms 比較 + ゴースト猫
class_name RuleStepPreview
extends Control

const COLOR_RAIL := Color(0.49, 0.827, 0.988, 0.32)
const COLOR_GATE := Color(0.49, 0.827, 0.988, 0.85)
const COLOR_GLOW_GOLD := Color(1.0, 0.85, 0.4, 0.95)
const COLOR_GLOW_CYAN := Color(0.49, 0.827, 0.988, 0.95)
const COLOR_TEXT := Color(0.949, 0.957, 0.98, 1.0)
const COLOR_DIM := Color(0.42, 0.467, 0.561, 1.0)

const ICON_FONT_PATH: String = "res://assets/fonts/MaterialSymbolsRounded.ttf"
var _icon_font: Font

@export_enum("ready", "tap", "compare") var variant: String = "ready":
    set(v):
        variant = v
        queue_redraw()

@export var round_label: String = "第3戦/7":
    set(v):
        round_label = v
        queue_redraw()

@export var you_ms: String = "87ms"
@export var ghost_ms: String = "142ms"

func _ready() -> void:
    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = Vector2(280, 170)
    if ResourceLoader.exists(ICON_FONT_PATH):
        _icon_font = load(ICON_FONT_PATH)
    queue_redraw()

func _draw() -> void:
    var w := size.x
    var h := size.y
    var f: Font = get_theme_default_font()

    # round label top-left
    draw_string(f, Vector2(14, 26), round_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_DIM)

    # progress dots top-right (5 dots: 2 done, 1 current, 2 left)
    var dot_y := 22.0
    var dot_step := 16.0
    var dot_start_x := w - 14.0 - dot_step * 4.0
    for i in 5:
        var cx := dot_start_x + float(i) * dot_step
        var col: Color
        match i:
            0, 1: col = Color(0.49, 0.827, 0.988, 0.85)
            2: col = Color(1.0, 0.85, 0.4, 0.95)
            _: col = Color(0.42, 0.467, 0.561, 0.6)
        draw_circle(Vector2(cx, dot_y), 4.5, col)

    # central rail
    var rail_y := h * 0.58
    draw_line(Vector2(28, rail_y), Vector2(w - 28, rail_y), COLOR_RAIL, 2.0, true)

    # central gate
    var gate_x := w * 0.5
    draw_line(Vector2(gate_x, rail_y - 26), Vector2(gate_x, rail_y + 26), COLOR_GATE, 2.5, true)

    match variant:
        "ready":
            # YOU dot left, GHOST dot right
            _draw_glow(Vector2(w * 0.18, rail_y), 22.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            draw_circle(Vector2(w * 0.18, rail_y), 9.0, COLOR_GLOW_GOLD)
            _draw_glow(Vector2(w * 0.82, rail_y), 18.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.4))
            draw_circle(Vector2(w * 0.82, rail_y), 7.0, COLOR_GLOW_CYAN)
        "tap":
            # central burst with TAP! text + cross flare + multi-ring
            var center := Vector2(gate_x, rail_y)
            # multi-ring (3 layers)
            for i in 3:
                var rr: float = 18.0 + float(i) * 14.0
                var ra: float = 0.7 - float(i) * 0.18
                var ring := COLOR_GLOW_GOLD
                ring.a = ra
                _stroke_ring(center, rr, ring, 1.2)
            # cross flare (4 long rays)
            for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
                _draw_tapered_ray(center, d, 38.0, 5.0, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.85))
            # diagonal short rays
            var diag: Vector2 = Vector2(0.7071, 0.7071)
            for d2 in [Vector2(diag.x, -diag.y), Vector2(-diag.x, -diag.y), Vector2(diag.x, diag.y), Vector2(-diag.x, diag.y)]:
                _draw_tapered_ray(center, d2, 22.0, 3.5, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.55))
            # central glow + core
            _draw_glow(center, 44.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.65))
            draw_circle(center, 11.0, COLOR_GLOW_GOLD)
            draw_circle(center, 5.0, Color(1.0, 1.0, 1.0, 1.0))
            var tap_size_w: float = f.get_string_size("TAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
            draw_string(f, Vector2(gate_x - tap_size_w * 0.5, rail_y - 38.0), "TAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, COLOR_TEXT)
        "compare":
            # YOU near gate (gold), GHOST farther (cyan); icons under each
            var you_x := gate_x - 38.0
            var ghost_x := gate_x + 90.0
            _draw_glow(Vector2(you_x, rail_y), 28.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            draw_circle(Vector2(you_x, rail_y), 9.0, COLOR_GLOW_GOLD)
            _draw_glow(Vector2(ghost_x, rail_y), 22.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.4))
            draw_circle(Vector2(ghost_x, rail_y), 7.0, COLOR_GLOW_CYAN)
            _draw_centered(f, Vector2(you_x, rail_y - 22.0), you_ms, 18, COLOR_GLOW_GOLD)
            _draw_centered(f, Vector2(ghost_x, rail_y - 22.0), ghost_ms, 18, COLOR_GLOW_CYAN)
            if _icon_font != null:
                draw_string(_icon_font, Vector2(22.0, h - 16.0), "person", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COLOR_DIM)
                draw_string(_icon_font, Vector2(w - 50.0, h - 16.0), "pets", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COLOR_GLOW_CYAN)

func _draw_glow(pos: Vector2, radius: float, base: Color) -> void:
    for i in 6:
        var r := radius * (1.0 - float(i) * 0.14)
        var a := base.a * (0.3 - float(i) * 0.04)
        if a <= 0.0:
            break
        var c := base
        c.a = a
        draw_circle(pos, r, c)


func _draw_tapered_ray(origin: Vector2, dir: Vector2, length: float, base_width: float, color: Color) -> void:
    var tip: Vector2 = origin + dir * length
    var perp: Vector2 = Vector2(-dir.y, dir.x)
    var bl: Vector2 = origin + perp * (base_width * 0.5)
    var br: Vector2 = origin - perp * (base_width * 0.5)
    var pts := PackedVector2Array([bl, tip, br])
    var cols := PackedColorArray()
    var solid: Color = color
    var faded: Color = color
    faded.a = 0.0
    cols.append(solid)
    cols.append(faded)
    cols.append(solid)
    draw_polygon(pts, cols)


func _stroke_ring(center: Vector2, radius: float, color: Color, width: float) -> void:
    var prev: Vector2 = center + Vector2(radius, 0.0)
    var n: int = 36
    for i in range(1, n + 1):
        var ang: float = TAU * float(i) / float(n)
        var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, color, width, true)
        prev = p


func _draw_centered(f: Font, center: Vector2, text: String, size_px: int, color: Color) -> void:
    var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    draw_string(f, center - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
