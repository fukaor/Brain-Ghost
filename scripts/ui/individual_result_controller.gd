## IndividualResultController
##
## 直近 1 回のミニゲームプレイ結果を表示する画面。
## ScoreLabel に大型表示、前回比、平均反応時間、ベスト更新バッジ、ゴーストの結果反応セリフ。
##
## [b]前提:[/b] GameManager._current_play_log と GameManager._previous_score を読む。
## それぞれ存在しない場合はデフォルト値で表示する（テスト時の単独起動も可能にする）。
extends Control

@onready var _score_label: Label = $SafeAreaMargin/MainColumn/ResultCard/CardVBox/ScoreLabel
@onready var _diff_label: Label = $SafeAreaMargin/MainColumn/ResultCard/CardVBox/DiffLabel
@onready var _avg_reaction_label: Label = $SafeAreaMargin/MainColumn/ResultCard/CardVBox/AvgReactionLabel
@onready var _best_badge: HBoxContainer = $SafeAreaMargin/MainColumn/ResultCard/CardVBox/BestBadge
@onready var _ghost: GhostCharacter = $SafeAreaMargin/MainColumn/GhostCharacter
@onready var _replay_button: Button = $SafeAreaMargin/MainColumn/ButtonRow/ReplayButton
@onready var _home_button: Button = $SafeAreaMargin/MainColumn/ButtonRow/HomeButton


func _ready() -> void:
    _wire_signals()
    _load_from_game_manager()


func _wire_signals() -> void:
    _replay_button.pressed.connect(_on_replay_pressed)
    _home_button.pressed.connect(_on_home_pressed)


func _load_from_game_manager() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm == null:
        # スタンドアロンテスト用のダミーデータ
        _show_dummy_result()
        return
    var log = gm._current_play_log if "_current_play_log" in gm else null
    var prev_score: int = int(gm._previous_score) if "_previous_score" in gm else 0
    if log == null:
        _show_dummy_result()
        return
    set_result(log, prev_score)


func _show_dummy_result() -> void:
    var dummy_log := PlayLog.new()
    dummy_log.game_type = "reflex_tap"
    dummy_log.score = 1020
    dummy_log.is_new_best = true
    set_result(dummy_log, 850)


## 結果を表示する。外部 (GameManager) からも呼べる
func set_result(log: PlayLog, previous_score: int) -> void:
    _score_label.text = str(log.score)

    if previous_score > 0:
        var diff := log.score - previous_score
        _diff_label.text = "前回比 %+d" % diff
    else:
        _diff_label.text = "初プレイ"

    var avg_ms: float = _compute_avg_reaction_ms(log)
    if avg_ms > 0.0:
        _avg_reaction_label.text = "平均 %d ms" % int(round(avg_ms))
    else:
        _avg_reaction_label.text = "—"

    _best_badge.visible = log.is_new_best

    _update_ghost_dialogue(log, previous_score)
    _ghost.set_accuracy(0.67)


func _compute_avg_reaction_ms(log: PlayLog) -> float:
    if log == null or log.events.is_empty():
        return 0.0
    var total: float = 0.0
    var count: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == "target_tapped":
            total += float(evt.value)
            count += 1
    if count == 0:
        return 0.0
    return total / float(count)


func _update_ghost_dialogue(log: PlayLog, previous_score: int) -> void:
    if previous_score == 0:
        _ghost.set_dialogue("お疲れさま！\nこれがきみの初めての記録だよ。\n次はもっと挑戦しようね")
    elif log.is_new_best:
        _ghost.set_dialogue("ベスト更新！\n今日のきみはすごい！\nこの調子で行こう")
    elif log.score > previous_score:
        _ghost.set_dialogue("前より早くなってるよ！\nいい調子だね")
    else:
        _ghost.set_dialogue("惜しい！\nでも確実に良くなってるよ。\nもう一度やってみる？")


func _on_replay_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_individual_result_replay"):
        gm.on_individual_result_replay()
    else:
        push_warning("[IndividualResult] GameManager.on_individual_result_replay not found")


func _on_home_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_individual_result_home"):
        gm.on_individual_result_home()
    else:
        push_warning("[IndividualResult] GameManager.on_individual_result_home not found")
