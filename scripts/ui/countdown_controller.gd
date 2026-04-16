## CountdownController
##
## ゲーム開始前の 3-2-1 カウントダウン演出。
## Stitch準拠デザイン: 巨大カウント数字 + SDキャラ吹き出し + ローディングバー。
## 完了後に GameManager.on_countdown_finished() を呼ぶ。
extends Control

const COUNT_INTERVAL_SEC: float = 1.0
const SCALE_TWEEN_SEC: float = 0.4

@onready var _count_label: Label = $MainContent/CountCenter/CountLabel
@onready var _ready_label: Label = $MainContent/ReadyLabel
@onready var _bubble_text: Label = $MainContent/ChibiArea/ChibiColumn/SpeechBubble/BubbleMargin/BubbleText
@onready var _loading_fill: PanelContainer = $MainContent/FooterMargin/FooterVBox/LoadingBarBg/LoadingBarFill
@onready var _loading_text: Label = $MainContent/FooterMargin/FooterVBox/LoadingTextRow/LoadingLabel
@onready var _ready_pct: Label = $MainContent/FooterMargin/FooterVBox/LoadingTextRow/ReadyLabel

var _step: int = 0  # 0: "3", 1: "2", 2: "1", 3: "GO!", 4: 完了


func _ready() -> void:
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
	var progress: float = 0.0
	match _step:
		0:
			count_text = "3"
			bubble_msg = "集中して！(Focus!)"
			progress = 0.33
		1:
			count_text = "2"
			bubble_msg = "もうすぐだよ！"
			progress = 0.66
		2:
			count_text = "1"
			bubble_msg = "いくよ！"
			progress = 0.9
		3:
			count_text = "GO!"
			bubble_msg = "がんばれ！"
			progress = 1.0
		_:
			return
	_count_label.text = count_text
	_bubble_text.text = bubble_msg
	_update_loading_bar(progress)
	_animate_count_label()


func _update_loading_bar(progress: float) -> void:
	_loading_fill.size_flags_stretch_ratio = maxf(0.01, progress)
	var pct := int(progress * 100)
	_ready_pct.text = "%d%% READY" % pct
	if pct >= 100:
		_loading_text.text = "READY!"
	else:
		_loading_text.text = "LOADING ASSETS..."


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
