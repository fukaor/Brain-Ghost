## SequenceMemory
##
## 順番記憶ゲームロジック (GDD §4-2)。
##
## [b]ルール:[/b]
## - 3x3 グリッド (9 パネル) のパネルが順番に光る
## - 同じパネルがシーケンス内で重複してもよい (Simon Says ライク)
##   ただし「直前と同じパネルが連続して光る」のは視覚的に混乱するため避ける
## - ユーザは同じ順番でタップ
## - 正解するとレベル+1（光るパネル数が増える）
## - 最大レベル = MAX_LEVEL (9)。Lv9 をクリアすると「全クリア」で終了
## - 1つでも間違えたらゲーム終了
## - スコア: max_reached_level × 150
##
## [b]フェーズ:[/b]
## "showing" → パネルが順番に光る（ビュー側がアニメ制御）
## "input"   → ユーザーがタップ入力
## "finished" → 終了（誤タップ or Lv9 全クリア）
##
## [b]クリア系ゲーム:[/b] プレイ中ゴーストバー非表示 (GDD §5c)
##
## [b]決定論性:[/b] rng のみを使用。
class_name SequenceMemory
extends BaseGame

const GRID_SIZE: int = 9
const INITIAL_LEVEL: int = 3
const MAX_LEVEL: int = 9
const SHOW_INTERVAL_SEC: float = 0.6
const SHOW_PAUSE_SEC: float = 0.3

var _current_level: int = INITIAL_LEVEL
var _max_reached_level: int = 0
var _sequence: Array[int] = []
var _user_input_index: int = 0
var _phase: String = "showing"
var _max_level_cleared: bool = false  # Lv9 全クリアフラグ（誤タップ終了と区別）


func _on_setup(_seed_value: int) -> void:
	game_type = "sequence_memory"
	is_time_based = false
	_current_level = INITIAL_LEVEL
	_max_reached_level = 0
	_sequence = []
	_user_input_index = 0
	_phase = "showing"
	_max_level_cleared = false


func _on_start() -> void:
	_generate_sequence()


func _on_user_input(input: Dictionary) -> void:
	var input_type := String(input.get("type", ""))
	if input_type == "panel_tap":
		var panel_index: int = int(input.get("index", -1))
		_handle_panel_tap(panel_index)


func _on_finish() -> PlayLog:
	_phase = "finished"
	var log := super._on_finish()
	log.game_type = "sequence_memory"
	return log


# --- Public API ---

func get_current_level() -> int:
	return _current_level


func get_max_reached_level() -> int:
	return _max_reached_level


func get_sequence() -> Array[int]:
	return _sequence


func get_phase() -> String:
	return _phase


func get_user_input_index() -> int:
	return _user_input_index


## 表示フェーズ完了後にビューから呼ぶ
func begin_input_phase() -> void:
	_phase = "input"
	_user_input_index = 0


## 次のラウンドへ進む（ビューがアニメ完了後に呼ぶ）。
## Lv MAX_LEVEL を超える場合はゲーム終了（全クリア状態）。
func advance_to_next_level() -> void:
	if _current_level >= MAX_LEVEL:
		_max_level_cleared = true
		record_event("max_level_cleared", float(MAX_LEVEL))
		finish()
		return
	_current_level += 1
	_generate_sequence()
	_phase = "showing"


## Lv MAX_LEVEL 全クリアによる終了かどうか（誤タップ終了との区別）。
func is_max_level_cleared() -> bool:
	return _max_level_cleared


# --- Private ---

func _generate_sequence() -> void:
	_sequence = []
	# Simon Says ライク: 各ステップで独立にランダム選択（重複 OK）
	# ただし直前と同じパネルは視覚的に混乱するため避ける
	var prev: int = -1
	for i in range(_current_level):
		var n: int = rng.randi_range(0, GRID_SIZE - 1)
		while n == prev and GRID_SIZE > 1:
			n = rng.randi_range(0, GRID_SIZE - 1)
		_sequence.append(n)
		prev = n
	_user_input_index = 0


func _handle_panel_tap(panel_index: int) -> void:
	if _phase != "input":
		return

	var expected: int = _sequence[_user_input_index]

	if panel_index == expected:
		_user_input_index += 1
		if _user_input_index >= _sequence.size():
			# レベルクリア
			_max_reached_level = _current_level
			record_event("level_cleared", float(_current_level))
			_phase = "level_clear"
	else:
		# 失敗
		_max_reached_level = max(_max_reached_level, _current_level - 1)
		record_event("level_failed", float(_current_level))
		finish()
