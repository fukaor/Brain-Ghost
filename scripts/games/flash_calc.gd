## FlashCalc
##
## フラッシュ暗算ゲームロジック (GDD §4-1)。
##
## [b]ルール:[/b]
## - 30 秒の制限時間内にできるだけ多くの 2 数演算を解く
## - 各問題: num1 (op) num2 = ? （例: "23 - 12 = ?"）
## - 演算子は ＋/− 混合（30% の確率で引き算）
## - テンキー入力で答えを送信、即次問題へ
## - 30 秒経過で終了
## - スコア: correct_count × 100 + remaining_sec × 10
##
## [b]決定論性:[/b]
## `BaseGame.rng` のみを使用（デイリーチャレンジ再現性保証）。
class_name FlashCalc
extends BaseGame

const TIME_LIMIT_SEC: int = 30
const NUM_MIN: int = 1
const NUM_MAX: int = 50
## 引き算が出現する確率 (0.0〜1.0)
const SUBTRACTION_CHANCE: float = 0.3

var _correct_count: int = 0
var _wrong_count: int = 0
var _current_problem: Dictionary = {}


func _on_setup(_seed_value: int) -> void:
	game_type = "flash_calc"
	is_time_based = true
	_correct_count = 0
	_wrong_count = 0
	_current_problem = {}


func _on_start() -> void:
	_current_problem = _generate_problem()


func _on_user_input(input: Dictionary) -> void:
	var input_type := String(input.get("type", ""))
	if input_type == "submit":
		var answer: int = int(input.get("answer", -99999))
		_handle_submit(answer)
	elif input_type == "timeout":
		_record_session_end()
		finish()


func _on_finish() -> PlayLog:
	var log := super._on_finish()
	log.game_type = "flash_calc"
	return log


# --- Public API ---

## 現在の問題を取得する {num1, num2, operator, answer}
func get_current_problem() -> Dictionary:
	return _current_problem


func get_correct_count() -> int:
	return _correct_count


func get_wrong_count() -> int:
	return _wrong_count


## 残り時間（秒、最低 0）
func get_remaining_sec() -> int:
	var elapsed_sec: int = int(get_elapsed_ms() / 1000)
	return max(0, TIME_LIMIT_SEC - elapsed_sec)


## タイムアップ判定
func is_time_up() -> bool:
	return get_elapsed_ms() >= TIME_LIMIT_SEC * 1000


# --- Private ---

func _generate_problem() -> Dictionary:
	var num1: int = rng.randi_range(NUM_MIN, NUM_MAX)
	var is_subtraction: bool = rng.randf() < SUBTRACTION_CHANCE

	var num2: int
	var operator: String
	var answer: int

	if is_subtraction:
		num2 = rng.randi_range(NUM_MIN, num1)
		operator = "-"
		answer = num1 - num2
	else:
		num2 = rng.randi_range(NUM_MIN, NUM_MAX)
		operator = "+"
		answer = num1 + num2

	return {"num1": num1, "num2": num2, "operator": operator, "answer": answer}


func _handle_submit(answer: int) -> void:
	if _current_problem.is_empty():
		return
	var expected: int = _current_problem["answer"]
	if answer == expected:
		_correct_count += 1
		record_event("correct", float(answer))
	else:
		_wrong_count += 1
		record_event("wrong", float(answer))
	# 次の問題
	_current_problem = _generate_problem()


func _record_session_end() -> void:
	record_event("session_end", float(get_remaining_sec()))
