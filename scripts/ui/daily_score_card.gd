## DailyScoreCard — デイリースコアカード（コンポーネント 2-2）
##
## 参照: docs/ideas/sumi-theme/references/ui_parts_home_score.png
## 表示専用。勝敗マーク(○×)は wins/losses から動的生成する。
## 汚染パーツ frame_ink_border / arrow_up_brush は使わず、2px 墨枠 StyleBoxFlat と
## テキスト「↑」で代替（README 方針）。将来 texture_frame で枠を差し替え可能。
@tool
class_name DailyScoreCard
extends PanelContainer

const MAX_MARKS := 5

@export var score: int = 3230:
	set(value):
		score = value
		_refresh()
@export var score_diff: int = 285:
	set(value):
		score_diff = value
		_refresh()
@export var brain_age: int = 31:
	set(value):
		brain_age = value
		_refresh()
@export var wins: int = 2:
	set(value):
		wins = value
		_refresh()
@export var losses: int = 1:
	set(value):
		losses = value
		_refresh()
## 将来 frame_ink_border のクリーン版に差し替えるためのフック。
@export var texture_frame: Texture2D

@onready var _value: Label = $Margin/Content/ScoreRow/Value
@onready var _delta_arrow: Label = $Margin/Content/DeltaRow/Arrow
@onready var _delta: Label = $Margin/Content/DeltaRow/Delta
@onready var _meta: Label = $Margin/Content/Meta
@onready var _marks: HBoxContainer = $Margin/Content/Marks


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_value.text = _format_thousands(score)
	if score_diff > 0:
		_delta.text = "+%s" % _format_thousands(score_diff)
		_delta_arrow.visible = true
		_delta.visible = true
	else:
		_delta_arrow.visible = false
		_delta.visible = false
	_meta.text = "脳年齢: %d歳" % brain_age
	_rebuild_marks()


## ○(勝ち, 濃墨) を wins 個 → ×(負け, 薄墨) を losses 個。合計 MAX_MARKS で打ち切り。
func _rebuild_marks() -> void:
	for c in _marks.get_children():
		c.queue_free()
	var shown := 0
	for i in range(wins):
		if shown >= MAX_MARKS:
			break
		_marks.add_child(_make_mark("○", SumiColors.SUMI_DARK))
		shown += 1
	for i in range(losses):
		if shown >= MAX_MARKS:
			break
		_marks.add_child(_make_mark("×", SumiColors.SUMI_LIGHT))
		shown += 1


func _make_mark(glyph: String, col: Color) -> Label:
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", col)
	return l


static func _format_thousands(n: int) -> String:
	var negative := n < 0
	var s := str(absi(n))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" if negative else "") + result
