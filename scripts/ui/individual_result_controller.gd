## IndividualResultController
##
## 全ゲーム共通の個別結果画面コントローラ。
## game_type に応じた表示設定 Dictionary で動的にラベル・ロジックを切り替える。
##
## [b]対応ゲーム:[/b]
## reflex_tap, flash_calc, stroop, sequence_memory, card_match, number_search
##
## [b]前提:[/b] GameManager._current_play_log を読む。
extends Control

# ---------------------------------------------------------------------------
# ゲーム種別ごとの表示設定
# ---------------------------------------------------------------------------

## 各ゲームの結果画面表示設定を返す。新ゲーム追加時はここに1エントリ追加するだけ。
static func _get_display_config(game_type: String) -> Dictionary:
	match game_type:
		"reflex_tap":
			return {
				"score_unit": "s",
				"score_caption": "平均反応時間",
				"score_format": "time",       # time=秒表記, int=整数表記
				"stat1_caption": "パーフェクト",
				"stat1_event": "target_tapped",
				"stat2_caption": "ミス",
				"stat2_event": "fake_tapped",
				"stat2_is_error": true,
				"victory_rule": "lower_is_better",
				"ghost_score_placeholder": 450.0,  # ms
				"ghost_score_format": "time",
			}
		"flash_calc":
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "正解",
				"stat1_event": "correct",
				"stat2_caption": "誤答",
				"stat2_event": "wrong",
				"stat2_is_error": true,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 600.0,
				"ghost_score_format": "int",
			}
		"stroop":
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "正解",
				"stat1_event": "correct",
				"stat2_caption": "誤答",
				"stat2_event": "incorrect",
				"stat2_is_error": true,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 500.0,
				"ghost_score_format": "int",
			}
		"sequence_memory":
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "到達レベル",
				"stat1_event": "level_cleared",
				"stat2_caption": "ミス",
				"stat2_event": "level_failed",
				"stat2_is_error": true,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 450.0,
				"ghost_score_format": "int",
			}
		"card_match":
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "ペア数",
				"stat1_event": "pair_matched",
				"stat2_caption": "タップ数",
				"stat2_event": "card_flipped",
				"stat2_is_error": false,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 500.0,
				"ghost_score_format": "int",
			}
		"number_search":
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "クリア秒数",
				"stat1_event": "_clear_time",
				"stat2_caption": "ミス",
				"stat2_event": "miss_tap",
				"stat2_is_error": true,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 1500.0,
				"ghost_score_format": "int",
			}
		_:
			return {
				"score_unit": "点",
				"score_caption": "スコア",
				"score_format": "int",
				"stat1_caption": "正解",
				"stat1_event": "correct",
				"stat2_caption": "ミス",
				"stat2_event": "incorrect",
				"stat2_is_error": true,
				"victory_rule": "higher_is_better",
				"ghost_score_placeholder": 500.0,
				"ghost_score_format": "int",
			}

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------

# ゴースト + 吹き出し
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/GhostRow/SpeechBubble/BubbleMargin/SpeechText

# スコアカード
@onready var _score_value: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/ScoreValue
@onready var _score_unit: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/ScoreUnit
@onready var _score_caption: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreCaption
@onready var _new_best_badge: PanelContainer = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/NewBestBadge

# YOU vs GHOST 比較
@onready var _you_value: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/ScoreCompareRow/YouSection/YouValue
@onready var _ghost_value: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/ScoreCompareRow/GhostSection/GhostValue
@onready var _victory_badge: PanelContainer = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/ScoreCompareRow/VictoryBadge
@onready var _victory_label: Label = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/ScoreCompareRow/VictoryBadge/VictoryLabel
@onready var _player_bar: PanelContainer = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/CompareBarRow/PlayerBarSegment
@onready var _ghost_bar: PanelContainer = $SafeAreaMargin/MainColumn/ComparisonCard/ComparisonMargin/ComparisonVBox/CompareBarRow/GhostBarSegment

# 統計
@onready var _stat1_caption: Label = $SafeAreaMargin/MainColumn/StatsGrid/PerfectCard/PerfectVBox/PerfectCaption
@onready var _stat1_value: Label = $SafeAreaMargin/MainColumn/StatsGrid/PerfectCard/PerfectVBox/PerfectValue
@onready var _stat2_caption: Label = $SafeAreaMargin/MainColumn/StatsGrid/MissCard/MissVBox/MissCaption
@onready var _stat2_value: Label = $SafeAreaMargin/MainColumn/StatsGrid/MissCard/MissVBox/MissValue

# ボタン
@onready var _replay_button: Button = $SafeAreaMargin/MainColumn/ReplayButton
@onready var _home_link: Button = $SafeAreaMargin/MainColumn/HomeButton


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


# ---------------------------------------------------------------------------
# メイン表示ロジック（全ゲーム共通）
# ---------------------------------------------------------------------------

func set_result(log: PlayLog, _previous_score: int) -> void:
	var cfg := _get_display_config(log.game_type)

	# --- ラベル設定（ゲーム種に応じて動的に切替） ---
	_score_unit.text = cfg["score_unit"]
	_score_caption.text = cfg["score_caption"]
	_stat1_caption.text = cfg["stat1_caption"]
	_stat2_caption.text = cfg["stat2_caption"]

	# --- メインスコア表示 ---
	var you_display: float = _compute_display_score(log, cfg)
	if cfg["score_format"] == "time":
		_score_value.text = "%.2f" % you_display if you_display > 0.0 else "—"
	else:
		_score_value.text = "%d" % int(you_display) if you_display > 0.0 else "—"

	# --- NEW BEST ---
	_new_best_badge.visible = log.is_new_best

	# --- YOU vs GHOST ---
	var ghost_display: float = cfg["ghost_score_placeholder"]
	if cfg["ghost_score_format"] == "time":
		ghost_display = ghost_display / 1000.0  # ms → sec
	_display_comparison(you_display, ghost_display, cfg)

	# --- 統計 ---
	_display_stats(log, cfg)

	# --- ゴーストセリフ ---
	_update_ghost_dialogue(log, cfg)


## ゲーム種に応じた「表示用スコア値」を算出する
func _compute_display_score(log: PlayLog, cfg: Dictionary) -> float:
	if cfg["score_format"] == "time":
		# タイム系: イベントから平均反応時間を算出
		return _compute_avg_from_events(log, cfg.get("stat1_event", "")) / 1000.0
	else:
		# スコア系: PlayLog.scoreをそのまま使用
		return float(log.score)


## 指定イベント型の value 平均を算出
func _compute_avg_from_events(log: PlayLog, event_type: String) -> float:
	if log == null or log.events.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for evt in log.events:
		if evt != null and evt.event_type == event_type:
			total += float(evt.value)
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)


## YOU vs GHOST 比較セクション
func _display_comparison(you_val: float, ghost_val: float, cfg: Dictionary) -> void:
	# テキスト表示
	if cfg["score_format"] == "time":
		_you_value.text = "%.2fs" % you_val if you_val > 0.0 else "—"
		_ghost_value.text = "%.2fs" % ghost_val
	else:
		_you_value.text = "%d" % int(you_val) if you_val > 0.0 else "—"
		_ghost_value.text = "%d" % int(ghost_val)

	# VICTORY/DEFEAT 判定
	var is_victory: bool = _judge_victory(you_val, ghost_val, cfg["victory_rule"])
	if is_victory:
		_victory_label.text = "VICTORY"
		_victory_badge.theme_type_variation = "victory_badge"
		_victory_label.add_theme_color_override("font_color", Color(0, 0.353, 0.216, 1))
	else:
		_victory_label.text = "DEFEAT"
		_victory_badge.theme_type_variation = "defeat_badge"
		_victory_label.add_theme_color_override("font_color", Color(0.314, 0.353, 0.506, 1))

	# 比較バー比率
	if you_val > 0.0 and ghost_val > 0.0:
		var you_strength: float
		var ghost_strength: float
		if cfg["victory_rule"] == "lower_is_better":
			you_strength = 1.0 / you_val
			ghost_strength = 1.0 / ghost_val
		else:
			you_strength = you_val
			ghost_strength = ghost_val
		var total: float = you_strength + ghost_strength
		_player_bar.size_flags_stretch_ratio = you_strength / total * 100.0
		_ghost_bar.size_flags_stretch_ratio = ghost_strength / total * 100.0


## 勝敗判定
func _judge_victory(you_val: float, ghost_val: float, rule: String) -> bool:
	if you_val <= 0.0:
		return false
	match rule:
		"lower_is_better":
			return you_val <= ghost_val
		"higher_is_better":
			return you_val >= ghost_val
		_:
			return false


## 統計セクション
func _display_stats(log: PlayLog, cfg: Dictionary) -> void:
	var stat1_count: int = _count_events(log, cfg["stat1_event"])
	var stat2_count: int = _count_events(log, cfg["stat2_event"])
	_stat1_value.text = "%d" % stat1_count
	_stat2_value.text = "%d" % stat2_count


## イベントカウント
func _count_events(log: PlayLog, event_type: String) -> int:
	var count: int = 0
	for evt in log.events:
		if evt != null and evt.event_type == event_type:
			count += 1
	return count


## ゴーストセリフ（勝敗に応じたポジティブメッセージ）
func _update_ghost_dialogue(log: PlayLog, cfg: Dictionary) -> void:
	var you_val: float = _compute_display_score(log, cfg)
	var ghost_val: float = cfg["ghost_score_placeholder"]
	if cfg["ghost_score_format"] == "time":
		ghost_val = ghost_val / 1000.0
	var is_victory: bool = _judge_victory(you_val, ghost_val, cfg["victory_rule"])

	if log.is_new_best:
		_speech_text.text = "すごい！自己ベスト更新だよ！"
	elif is_victory:
		_speech_text.text = "やったね！ゴーストに勝ったよ！\nこの調子で行こう！"
	elif you_val > 0.0:
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
