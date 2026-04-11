## FlashCalc
##
## フラッシュ暗算ゲームロジック (GDD §4-1)。
##
## [b]ルール:[/b]
## - 30 秒の制限時間内にできるだけ多くの計算問題を解く
## - 各問題: 4 つの数字 (1-9) の合計 (例: "3 + 5 + 2 + 7 = ?")
## - テンキー入力で答えを送信、即次問題へ
## - 30 秒経過 or TOTAL_PROBLEMS 問完了で終了
## - スコア: correct_count × 100 + remaining_sec × 10
##
## [b]決定論性:[/b]
## setup 時に全問題を事前生成する。これにより rng の進行が完全に固定される。
class_name FlashCalc
extends BaseGame

const TOTAL_PROBLEMS: int = 15
const NUMBER_MIN: int = 1
const NUMBER_MAX: int = 9
const TIME_LIMIT_SEC: int = 30

## フェーズ分け難易度: 序盤 4 数字 → 中盤 5 数字 → 終盤 6 数字
const PHASE_1_END: int = 8     # 問題 0..7 は 4 個 (8 問)
const PHASE_2_END: int = 12    # 問題 8..11 は 5 個 (4 問)
# 問題 12..14 は 6 個 (3 問)
const NUMBERS_PHASE_1: int = 4
const NUMBERS_PHASE_2: int = 5
const NUMBERS_PHASE_3: int = 6

## 後方互換 / テスト向け: 平均的な数字個数 (フェーズ 1 のデフォルト値を返す)
const NUMBERS_PER_PROBLEM: int = NUMBERS_PHASE_1


var _problems: Array[Array] = []  # 各要素は [int, int, int, int]
var _expected_sums: Array[int] = []
var _current_index: int = 0
var _correct_count: int = 0


func _on_setup(_seed_value: int) -> void:
    game_type = "flash_calc"
    is_time_based = true
    _problems = []
    _expected_sums = []
    _current_index = 0
    _correct_count = 0
    # 全問題を事前生成 (決定論的)。フェーズに応じて数字の個数が変わる。
    for i in range(TOTAL_PROBLEMS):
        var count: int = _numbers_for_problem(i)
        var nums: Array[int] = []
        var sum: int = 0
        for j in range(count):
            var n: int = rng.randi_range(NUMBER_MIN, NUMBER_MAX)
            nums.append(n)
            sum += n
        _problems.append(nums)
        _expected_sums.append(sum)


## 問題インデックスからその問題で使う数字の個数を返す (フェーズ分け難易度)
func _numbers_for_problem(index: int) -> int:
    if index < PHASE_1_END:
        return NUMBERS_PHASE_1
    elif index < PHASE_2_END:
        return NUMBERS_PHASE_2
    else:
        return NUMBERS_PHASE_3


func _on_user_input(input: Dictionary) -> void:
    var input_type := String(input.get("type", ""))
    if input_type == "submit":
        var answer: int = int(input.get("answer", -1))
        _handle_submit(answer)
    elif input_type == "timeout":
        # 時間切れによる強制終了
        _record_session_end()
        finish()


func _on_finish() -> PlayLog:
    var log := super._on_finish()
    log.game_type = "flash_calc"
    return log


# --- Public API ---

## 現在の問題のテキスト表現を返す (例: "3 + 5 + 2 + 7")
func get_current_problem_text() -> String:
    if _current_index >= _problems.size():
        return ""
    var nums: Array = _problems[_current_index]
    var parts: Array[String] = []
    for n in nums:
        parts.append(str(n))
    return " + ".join(parts)


## 現在の問題の期待される答え (内部状態のテスト用)
func get_current_expected() -> int:
    if _current_index >= _expected_sums.size():
        return 0
    return _expected_sums[_current_index]


func get_correct_count() -> int:
    return _correct_count


func get_current_index() -> int:
    return _current_index


func get_total_problems() -> int:
    return TOTAL_PROBLEMS


## 残り時間 (秒、最低 0)
func get_remaining_sec() -> int:
    var elapsed_sec: int = int(get_elapsed_ms() / 1000)
    return max(0, TIME_LIMIT_SEC - elapsed_sec)


# --- Private ---

func _handle_submit(answer: int) -> void:
    if _current_index >= _problems.size():
        return
    var expected: int = _expected_sums[_current_index]
    if answer == expected:
        _correct_count += 1
        record_event("correct", float(answer))
    else:
        record_event("wrong", float(answer))
    _current_index += 1
    if _current_index >= TOTAL_PROBLEMS:
        # 全問完了 → セッション終了
        _record_session_end()
        finish()


func _record_session_end() -> void:
    record_event("session_end", float(get_remaining_sec()))
