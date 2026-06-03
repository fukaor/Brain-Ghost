## BrainAgeCard — 脳年齢カード（コンポーネント 2-1）
##
## 参照: docs/ideas/sumi-theme/references/ui_parts_home_nenrei.png
## 表示専用。データはコントローラから @export / setter 経由で注入する。
@tool
class_name BrainAgeCard
extends PanelContainer

@export var brain_age: int = 31:
	set(value):
		brain_age = value
		_refresh()
@export_range(0.0, 1.0, 0.01) var accuracy: float = 1.0:
	set(value):
		accuracy = value
		_refresh()

@onready var _value: Label = $Margin/Content/AgeRow/Value
@onready var _progress: ProgressBar = $Margin/Content/MeterRow/Progress
@onready var _accuracy_label: Label = $Margin/Content/MeterRow/Accuracy


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_value.text = str(brain_age)
	var pct: float = clampf(accuracy, 0.0, 1.0)
	_progress.value = pct
	_accuracy_label.text = "精度: %d%%" % int(round(pct * 100.0))
