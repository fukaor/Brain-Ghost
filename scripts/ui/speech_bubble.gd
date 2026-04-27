## SpeechBubble
##
## 吹き出しのしっぽ（三角矢印）を描画するカスタム PanelContainer。
## glass_bubble テーマに加え、指定方向にしっぽを追加描画する。
extends PanelContainer

enum TailDirection { DOWN, LEFT, RIGHT }

## しっぽの方向
@export var tail_direction: TailDirection = TailDirection.DOWN
## しっぽの幅（ピクセル）
@export var tail_width: float = 20.0
## しっぽの高さ（ピクセル）
@export var tail_height: float = 14.0
## しっぽのオフセット（DOWN=水平オフセット、LEFT/RIGHT=垂直オフセット）
@export var tail_offset_x: float = 0.0

func _draw() -> void:
	var panel_style := get_theme_stylebox("panel")
	if panel_style == null:
		return

	var bg_color := Color(1, 1, 1, 0.92)
	if panel_style is StyleBoxFlat:
		bg_color = (panel_style as StyleBoxFlat).bg_color

	var p1: Vector2
	var p2: Vector2
	var p3: Vector2

	match tail_direction:
		TailDirection.DOWN:
			var cx: float = size.x * 0.5 + tail_offset_x
			var bottom: float = size.y
			p1 = Vector2(cx - tail_width * 0.5, bottom)
			p2 = Vector2(cx + tail_width * 0.5, bottom)
			p3 = Vector2(cx, bottom + tail_height)
		TailDirection.LEFT:
			var cy: float = size.y * 0.5 + tail_offset_x
			p1 = Vector2(0, cy - tail_width * 0.5)
			p2 = Vector2(0, cy + tail_width * 0.5)
			p3 = Vector2(-tail_height, cy)
		TailDirection.RIGHT:
			var cy: float = size.y * 0.5 + tail_offset_x
			p1 = Vector2(size.x, cy - tail_width * 0.5)
			p2 = Vector2(size.x, cy + tail_width * 0.5)
			p3 = Vector2(size.x + tail_height, cy)

	draw_polygon([p1, p2, p3], [bg_color, bg_color, bg_color])
