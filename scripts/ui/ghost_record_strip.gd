## GhostRecordStrip — 戦績 + ストリーク（コンポーネント 2-3）
##
## 参照: docs/ideas/sumi-theme/references/daily_challenge_strip.png（戦績）/ ui_parts_sheet.png（連勝）
## 左: 通算戦績（N勝=濃墨 / N敗=薄墨、番付風）。右: 朱印スタンプ7個 + 「N日連続！」。
## スタンプは確認済みクリーンパーツ stamp_shuin.png を使用（played=点灯 / 未=減衰）。
@tool
class_name GhostRecordStrip
extends HBoxContainer

const STAMP_ON_ALPHA := 1.0
const STAMP_OFF_ALPHA := 0.18

@export var total_wins: int = 15:
	set(value):
		total_wins = value
		_refresh()
@export var total_losses: int = 8:
	set(value):
		total_losses = value
		_refresh()
@export var streak_days: int = 5:
	set(value):
		streak_days = value
		_refresh()
## 直近7日のプレイ有無 [6日前..今日]。true=点灯。
@export var streak_stamps: Array[bool] = [true, true, true, true, true, false, false]:
	set(value):
		streak_stamps = value
		_refresh()

@onready var _wins: Label = $StatsBlock/Margin/Content/Row/Wins
@onready var _losses: Label = $StatsBlock/Margin/Content/Row/Losses
@onready var _streak_label: Label = $StreakBlock/Margin/Content/Text
@onready var _stamps_row: HBoxContainer = $StreakBlock/Margin/Content/Row


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_wins.text = "%d勝" % total_wins
	_losses.text = "%d敗" % total_losses
	if streak_days > 0:
		_streak_label.text = "%d日連続！" % streak_days
	else:
		_streak_label.text = "今日からスタート"
	_apply_stamps()


func _apply_stamps() -> void:
	var stamps := _stamps_row.get_children()
	for i in stamps.size():
		var s := stamps[i] as CanvasItem
		if s == null:
			continue
		var on: bool = i < streak_stamps.size() and streak_stamps[i]
		s.modulate = Color(1, 1, 1, STAMP_ON_ALPHA if on else STAMP_OFF_ALPHA)
