## RadarChart
##
## ホーム画面の 6 軸レーダーチャート。Sumi Ghost (墨絵調) v4 スタイル。
## 軸: 計算力(0,top) / 記憶力(1) / 注意力(2) / 反射速度(3,bottom) / 観察力(4) / 判断力(5)
##
## 値は 0.0 .. 1.0。set_values() で更新。
## 最弱軸ラベル直下に「鍛える →」ボタンを動的配置し、押下時に train_pressed を emit。
class_name RadarChart
extends Control

signal train_pressed(weakest_axis: int)

const AXIS_COUNT: int = 6
const RING_COUNT: int = 3

# Sumi Ghost トークン (SumiColors と同期)
const COLOR_GRID    := Color(0.549, 0.549, 0.549, 0.55)  # SUMI_LIGHT
const COLOR_AXIS    := Color(0.549, 0.549, 0.549, 0.70)
const COLOR_FILL    := Color(0.722, 0.847, 0.910, 0.30)  # HITODAMA_FILL (alpha up)
const COLOR_STROKE  := Color(0.722, 0.847, 0.910, 0.95)  # HITODAMA
const COLOR_VERTEX  := Color(0.173, 0.173, 0.173, 1.0)   # SUMI_DARK
const COLOR_VERTEX_BEST := Color(0.788, 0.659, 0.298, 1.0)  # KINDEI
const COLOR_LABEL   := Color(0.173, 0.173, 0.173, 1.0)   # SUMI_DARK

@export var values: PackedFloat32Array = PackedFloat32Array([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]):
	set(v):
		values = v
		queue_redraw()

@export var labels: PackedStringArray = PackedStringArray([
	"計算力", "記憶力", "注意力", "反射速度", "観察力", "判断力"
])

@export var radius_ratio: float = 0.65
@export var label_offset: float = 26.0
@export var label_font_size: int = 12

# 円相のかすれ表現用シード (毎フレーム同じ揺れ)
var _rng_seed: int = 31415

# 最弱軸ラベル直下に置く動的ボタン
var _train_button: Button
var _weakest_axis: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(280, 280)
	_train_button = Button.new()
	_train_button.flat = true
	_train_button.text = "鍛える →"
	_train_button.focus_mode = Control.FOCUS_NONE
	_train_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_train_button.add_theme_color_override("font_color", COLOR_VERTEX_BEST)
	_train_button.add_theme_font_size_override("font_size", label_font_size)
	_train_button.pressed.connect(_on_train_pressed)
	_train_button.visible = false
	add_child(_train_button)
	_update_weakest()
	_reposition_train_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reposition_train_button()

# 既存 API 互換維持: 旧 home_controller が呼ぶ
func set_values(v: Array) -> void:
	var arr := PackedFloat32Array()
	for x in v:
		arr.append(clampf(float(x), 0.0, 1.0))
	while arr.size() < AXIS_COUNT:
		arr.append(0.0)
	values = arr
	_update_weakest()
	_reposition_train_button()

func _update_weakest() -> void:
	var min_v: float = INF
	var min_i: int = -1
	for i in AXIS_COUNT:
		var v: float = 0.0
		if i < values.size():
			v = values[i]
		if v < min_v:
			min_v = v
			min_i = i
	_weakest_axis = min_i

func _reposition_train_button() -> void:
	if _train_button == null:
		return
	if _weakest_axis < 0 or size.x <= 0.0 or size.y <= 0.0:
		_train_button.visible = false
		return
	var center: Vector2 = size * 0.5
	var radius: float = min(size.x, size.y) * 0.5 * radius_ratio
	var ang: float = -PI * 0.5 + TAU * float(_weakest_axis) / float(AXIS_COUNT)
	var label_pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius + label_offset)
	# ラベル直下に配置 (ラベルの 1 行分 + 余白)
	var btn_min: Vector2 = _train_button.get_combined_minimum_size()
	if btn_min.x <= 0.0:
		btn_min = Vector2(56.0, 22.0)
	_train_button.position = Vector2(
		label_pos.x - btn_min.x * 0.5,
		label_pos.y + float(label_font_size) * 0.8 + 2.0
	)
	_train_button.size = btn_min
	_train_button.visible = true

func _on_train_pressed() -> void:
	train_pressed.emit(_weakest_axis)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = min(size.x, size.y) * 0.5 * radius_ratio
	var axis_pts: Array[Vector2] = []
	for i in AXIS_COUNT:
		var ang: float = -PI * 0.5 + TAU * float(i) / float(AXIS_COUNT)
		axis_pts.append(Vector2(cos(ang), sin(ang)))

	# --- 円相風の同心円: 多角形近似 + 隙間 + 線幅微変動 ---
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng_seed
	for r in range(1, RING_COUNT + 1):
		var ring_r := radius * (float(r) / float(RING_COUNT))
		# 多角形近似 (64 セグメント)
		var seg_count := 64
		var pts := PackedVector2Array()
		for s in seg_count + 1:
			var a := TAU * float(s) / float(seg_count)
			pts.append(center + Vector2(cos(a), sin(a)) * ring_r)
		# 6 等分位置 (= 軸方向) で隙間を作る: 各セグメントを描画する/しないを判定
		# 全周を 12 分割し、偶数番だけ描画 (= 6 軸方向に向かって隙間)
		var lw: float = 1.2 + rng.randf_range(-0.4, 0.4)
		for s in seg_count:
			# 当該セグメントの中点の角度を計算
			var mid_a := TAU * (float(s) + 0.5) / float(seg_count)
			# 12 分割で偶数番が描画区間
			var bucket := int(mid_a / (TAU / 12.0)) % 2
			if bucket == 0:
				draw_line(pts[s], pts[s + 1], COLOR_GRID, lw, true)

	# --- 6 本の軸: 太→細テーパー (8 セグメント分割) ---
	for i in AXIS_COUNT:
		var p0 := center
		var p1 := center + axis_pts[i] * radius
		var seg := 8
		for s in seg:
			var t0 := float(s) / float(seg)
			var t1 := float(s + 1) / float(seg)
			var w := lerpf(2.0, 0.5, t0)
			draw_line(p0.lerp(p1, t0), p0.lerp(p1, t1), COLOR_AXIS, w, true)
		# 軸先端の小丸
		draw_circle(p1, 2.5, COLOR_VERTEX)

	# --- データ多角形: 塗り + 輪郭 ---
	var max_v: float = 0.0
	var max_i: int = 0
	var fill_pts := PackedVector2Array()
	for i in AXIS_COUNT:
		var v := 0.0
		if i < values.size():
			v = clampf(values[i], 0.0, 1.0)
		if v > max_v:
			max_v = v
			max_i = i
		fill_pts.append(center + axis_pts[i] * radius * v)
	if fill_pts.size() >= 3:
		var col_arr := PackedColorArray()
		for _j in fill_pts.size():
			col_arr.append(COLOR_FILL)
		draw_polygon(fill_pts, col_arr)
		var loop_pts := fill_pts.duplicate()
		loop_pts.append(loop_pts[0])
		for j in range(loop_pts.size() - 1):
			draw_line(loop_pts[j], loop_pts[j + 1], COLOR_STROKE, 1.8, true)
		# 通常頂点
		for j in fill_pts.size():
			if j != max_i:
				draw_circle(fill_pts[j], 3.0, COLOR_VERTEX)
		# 最強軸 = 金泥
		if max_v > 0.0:
			draw_circle(fill_pts[max_i], 5.0, COLOR_VERTEX_BEST)

	# --- 軸ラベル ---
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
