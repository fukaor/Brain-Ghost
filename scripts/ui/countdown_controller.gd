## CountdownController
##
## ゲーム開始前の 3-2-1 カウントダウン演出。ゴーストキャラクタも段階的にセリフ更新。
## 各カウント表示時に CountLabel を Tween で 1.5 → 1.0 にスケールアップから戻す簡易演出。
## 完了後に GameManager.on_countdown_finished() を呼ぶ。
extends Control

const COUNT_INTERVAL_SEC: float = 1.0
const SCALE_TWEEN_SEC: float = 0.4

@onready var _count_label: Label = $CenterContainer/VBoxContainer/CountLabel
@onready var _ghost: GhostCharacter = $CenterContainer/VBoxContainer/GhostCharacter

var _step: int = 0  # 0: "3", 1: "2", 2: "1", 3: "いくよ！", 4: 完了


func _ready() -> void:
    _ghost.set_accuracy(0.67)
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
    var label_text: String = ""
    var ghost_text: String = ""
    match _step:
        0:
            label_text = "3"
            ghost_text = "3..."
        1:
            label_text = "2"
            ghost_text = "2..."
        2:
            label_text = "1"
            ghost_text = "1..."
        3:
            label_text = "いくよ！"
            ghost_text = "いくよ！\n一緒にがんばろう！"
        _:
            return
    _count_label.text = label_text
    _ghost.set_dialogue(ghost_text)
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
