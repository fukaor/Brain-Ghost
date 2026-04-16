## IndividualResultController
##
## 直近 1 回のミニゲームプレイ結果を表示する画面。
##
## Stitch v0.2 デザイン準拠 (2026-04-14):
## - 上部: ゴーストちびキャラ + 吹き出しセリフ
## - RESULTS ラベル
## - 大型タイム表示 (0.42s) + NEW BEST! バッジ + 「平均反応時間」
## - YOU vs GHOST 比較カード + VICTORY/DEFEAT バッジ
## - パーフェクト/ミス統計
## - CTA「もう一度プレイ」+ テキストリンク「ホームに戻る」
##
## [b]前提:[/b] GameManager._current_play_log と GameManager._previous_score を読む。
extends Control

# ゴーストのプレースホルダー反応時間（ms）— ゴーストシステム実装後に動的化
const GHOST_AVG_REACTION_MS: float = 450.0

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------

# ゴースト + 吹き出し
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/GhostRow/SpeechBubble/BubbleMargin/SpeechText

# スコアセクション
@onready var _score_value: Label = $SafeAreaMargin/MainColumn/ScoreSection/ScoreRow/ScoreValue
@onready var _new_best_badge: PanelContainer = $SafeAreaMargin/MainColumn/ScoreSection/ScoreRow/NewBestBadge

# YOU vs GHOST 比較
@onready var _you_value: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonHBox/YouSection/YouValue
@onready var _ghost_value: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonHBox/GhostSection/GhostValue
@onready var _victory_label: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonHBox/VictoryBadge/VictoryLabel

# 統計
@onready var _perfect_value: Label = $SafeAreaMargin/MainColumn/StatsCard/StatsMargin/StatsHBox/PerfectSection/PerfectValue
@onready var _miss_value: Label = $SafeAreaMargin/MainColumn/StatsCard/StatsMargin/StatsHBox/MissSection/MissValue

# ボタン
@onready var _replay_button: Button = $SafeAreaMargin/MainColumn/ReplayButton
@onready var _home_link: Button = $SafeAreaMargin/MainColumn/HomeLinkRow/HomeLink


func _ready() -> void:
    _wire_signals()
    _load_from_game_manager()


func _wire_signals() -> void:
    _replay_button.pressed.connect(_on_replay_pressed)
    _home_link.pressed.connect(_on_home_pressed)


func _load_from_game_manager() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm == null:
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
    # ダミーのイベント
    for i in range(18):
        var evt := PlayEvent.new()
        evt.event_type = "target_tapped"
        evt.value = 420
        dummy_log.events.append(evt)
    for i in range(2):
        var evt := PlayEvent.new()
        evt.event_type = "fake_tapped"
        evt.value = 0
        dummy_log.events.append(evt)
    set_result(dummy_log, 850)


## 結果を表示する
func set_result(log: PlayLog, _previous_score: int) -> void:
    # --- 平均反応時間 ---
    var avg_ms: float = _compute_avg_reaction_ms(log)
    var avg_sec: float = avg_ms / 1000.0 if avg_ms > 0.0 else 0.0
    _score_value.text = "%.2f" % avg_sec if avg_sec > 0.0 else "—"

    # --- NEW BEST ---
    _new_best_badge.visible = log.is_new_best

    # --- YOU vs GHOST ---
    var you_sec: float = avg_sec
    var ghost_sec: float = GHOST_AVG_REACTION_MS / 1000.0
    _you_value.text = "%.2fs" % you_sec if you_sec > 0.0 else "—"
    _ghost_value.text = "%.2fs" % ghost_sec

    # VICTORY/DEFEAT 判定（反応時間は短い方が勝ち）
    if you_sec > 0.0 and you_sec <= ghost_sec:
        _victory_label.text = "VICTORY"
    else:
        _victory_label.text = "DEFEAT"

    # --- パーフェクト / ミス ---
    var perfect_count: int = 0
    var miss_count: int = 0
    for evt in log.events:
        if evt != null:
            if evt.event_type == "target_tapped":
                perfect_count += 1
            elif evt.event_type == "fake_tapped":
                miss_count += 1
    _perfect_value.text = "%d回" % perfect_count
    _miss_value.text = "%d回" % miss_count

    # --- ゴーストセリフ ---
    _update_ghost_dialogue(log, you_sec, ghost_sec)


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


func _update_ghost_dialogue(log: PlayLog, you_sec: float, ghost_sec: float) -> void:
    if log.is_new_best:
        _speech_text.text = "すごい！昨日より反応が速くなってるよ！"
    elif you_sec > 0.0 and you_sec <= ghost_sec:
        _speech_text.text = "やったね！ゴーストに勝ったよ！\nこの調子で行こう！"
    elif you_sec > 0.0:
        _speech_text.text = "惜しい！\nでも確実に良くなってるよ。\nもう一度やってみる？"
    else:
        _speech_text.text = "お疲れさま！\nこれがきみの記録だよ。"


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
