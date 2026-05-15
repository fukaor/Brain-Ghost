## CountdownController
##
## ゲーム開始前の 3-2-1-GO! カウントダウン演出。
## 縦版 (countdown.tscn) と横版 (countdown_landscape.tscn) の両方で動作する。
## ノード参照は find_child でパス非依存に解決。
## 完了後に GameManager.on_countdown_finished() を呼ぶ。
extends Control

const COUNT_INTERVAL_SEC: float = 1.0
const SCALE_TWEEN_SEC: float = 0.4

@onready var _count_label: Label = find_child("CountLabel") as Label
@onready var _ready_label: Label = find_child("ReadyLabel") as Label
@onready var _bubble_text: Label = find_child("BubbleText") as Label

var _step: int = 0  # 0: "3", 1: "2", 2: "1", 3: "GO!", 4: 完了


func _ready() -> void:
	# キャプチャモード (godot --script ...) では Timer/シーン遷移を起動しない
	if "--script" in OS.get_cmdline_args():
		_step = 0
		_show_step()
		return

	# SENSOR orientation 副作用対策: 縦/横をシーン名で確定する
	if scene_file_path.ends_with("_landscape.tscn"):
		OrientationHelper.enter_landscape()
	else:
		OrientationHelper.enter_portrait()

	_step = 0
	_show_step()
	_start_timer()


func _start_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = COUNT_INTERVAL_SEC
	timer.one_shot = false
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()


func _on_tick() -> void:
	_step += 1
	if _step <= 3:
		_show_step()
	if _step == 4:
		_finish_countdown()


func _show_step() -> void:
	var count_text: String = ""
	var bubble_msg: String = ""
	match _step:
		0:
			count_text = "3"
			bubble_msg = "集中して！(Focus!)"
		1:
			count_text = "2"
			bubble_msg = "もうすぐだよ！"
		2:
			count_text = "1"
			bubble_msg = "いくよ！"
		3:
			count_text = "GO!"
			bubble_msg = "がんばれ！"
		_:
			return
	_count_label.text = count_text
	_bubble_text.text = bubble_msg
	_animate_count_label()


func _animate_count_label() -> void:
	_count_label.scale = Vector2(1.5, 1.5)
	_count_label.pivot_offset = _count_label.size * 0.5
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(_count_label, "scale", Vector2(1.0, 1.0), SCALE_TWEEN_SEC)


func _finish_countdown() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("on_countdown_finished"):
		gm.on_countdown_finished()
	else:
		push_warning("[Countdown] GameManager.on_countdown_finished not found")
