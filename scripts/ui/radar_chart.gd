## RadarChart
##
## ホーム画面の 6 軸レーダーチャート。Midnight Cat (v3) スタイル。
## 軸: 計算力(0,top) / 記憶力(1) / 注意力(2) / 反射速度(3,bottom) / 観察力(4) / 判断力(5)
##
## 値は 0.0 .. 1.0。set_values() で更新。
class_name RadarChart
extends Control

const AXIS_COUNT: int = 6
const RING_COUNT: int = 4

const COLOR_GRID := Color(0.49, 0.827, 0.988, 0.18)
const COLOR_GRID_OUTER := Color(0.49, 0.827, 0.988, 0.45)
const COLOR_FILL := Color(0.49, 0.827, 0.988, 0.22)
const COLOR_STROKE := Color(0.729, 0.902, 0.992, 0.95)
const COLOR_VERTEX := Color(0.949, 0.957, 0.98, 1.0)
const COLOR_LABEL := Color(0.682, 0.722, 0.812, 1.0)

@export var values: PackedFloat32Array = PackedFloat32Array([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]):
    set(v):
        values = v
        queue_redraw()

@export var labels: PackedStringArray = PackedStringArray([
    "計算力", "記憶力", "注意力", "反射速度", "観察力", "判断力"
])

@export var radius_ratio: float = 0.7
@export var label_offset: float = 22.0
@export var label_font_size: int = 14

func _ready() -> void:
    custom_minimum_size = Vector2(320, 320)

func set_values(v: Array) -> void:
    var arr := PackedFloat32Array()
    for x in v:
        arr.append(clampf(float(x), 0.0, 1.0))
    while arr.size() < AXIS_COUNT:
        arr.append(0.0)
    values = arr

func _draw() -> void:
    var center: Vector2 = size * 0.5
    var radius: float = min(size.x, size.y) * 0.5 * radius_ratio
    var axis_pts: Array[Vector2] = []
    for i in AXIS_COUNT:
        var ang: float = -PI * 0.5 + TAU * float(i) / float(AXIS_COUNT)
        axis_pts.append(Vector2(cos(ang), sin(ang)))

    # rings
    for r in range(1, RING_COUNT + 1):
        var ring_r := radius * (float(r) / float(RING_COUNT))
        var ring_pts := PackedVector2Array()
        for i in AXIS_COUNT:
            ring_pts.append(center + axis_pts[i] * ring_r)
        ring_pts.append(ring_pts[0])
        var col: Color = COLOR_GRID_OUTER if r == RING_COUNT else COLOR_GRID
        for j in range(ring_pts.size() - 1):
            draw_line(ring_pts[j], ring_pts[j + 1], col, 1.0, true)

    # axes
    for i in AXIS_COUNT:
        draw_line(center, center + axis_pts[i] * radius, COLOR_GRID, 1.0, true)

    # fill polygon
    var fill_pts := PackedVector2Array()
    for i in AXIS_COUNT:
        var v := 0.0
        if i < values.size():
            v = clampf(values[i], 0.0, 1.0)
        fill_pts.append(center + axis_pts[i] * radius * v)
    if fill_pts.size() >= 3:
        var col_arr := PackedColorArray()
        for _i in fill_pts.size():
            col_arr.append(COLOR_FILL)
        draw_polygon(fill_pts, col_arr)
        # stroke
        var loop_pts := fill_pts.duplicate()
        loop_pts.append(loop_pts[0])
        for j in range(loop_pts.size() - 1):
            draw_line(loop_pts[j], loop_pts[j + 1], COLOR_STROKE, 2.0, true)
        # vertex dots
        for p in fill_pts:
            draw_circle(p, 4.0, COLOR_VERTEX)

    # labels
    var f: Font = get_theme_default_font()
    for i in AXIS_COUNT:
        if i >= labels.size():
            continue
        var label_pos: Vector2 = center + axis_pts[i] * (radius + label_offset)
        var text := labels[i]
        var text_size: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size)
        var draw_pos := label_pos - text_size * 0.5
        draw_pos.y += text_size.y * 0.4
        draw_string(f, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size, COLOR_LABEL)
