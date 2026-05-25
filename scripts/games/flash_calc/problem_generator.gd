## FlashCalcProblemGenerator
##
## ティア + シードから問題 (数字列 + 答え + 表示インターバル配列) を生成。
##
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md §4 / §8
## - ティアの digit_mode に従って 1 桁 / 2 桁 / 混合の数字を生成
## - 累積和の絶対値が 999 を超えないよう 4 桁防止チェック
## - 速度カーブに従い各表示の interval_ms を計算
##
## ## 戻り値の形式
## ```
## {
##   "tier": "T3",
##   "numbers": [3, 7, 2, ...],          # 数字列 (number_count 個)
##   "intervals_ms": [600, 600, ...],    # 各数字の表示時間 (ms)
##   "answer": 47,                       # 数字列の合計
##   "max_answer_digits": 2,             # 答えの桁数 (テンキー自動確定用)
## }
## ```
class_name FlashCalcProblemGenerator
extends Object

const _Tier = preload("res://scripts/games/flash_calc/tier_config.gd")

const MAX_GENERATION_ATTEMPTS: int = 50
const MAX_ABSOLUTE_SUM: int = 999  ## 4 桁防止 (答えが 4 桁になることを禁止)


## ティアとシードから問題を生成。
## seed_value < 0 の場合はランダム (デイリーチャレンジ以外で使う)。
static func generate(tier: String, seed_value: int = -1) -> Dictionary:
    var cfg: Dictionary = _Tier.TIER_CONFIGS.get(tier, {})
    if cfg.is_empty():
        push_error("[FlashCalcProblem] unknown tier: %s" % tier)
        return {}

    var rng := RandomNumberGenerator.new()
    if seed_value >= 0:
        rng.seed = seed_value
    else:
        rng.randomize()

    var number_count: int = int(cfg["number_count"])
    var digit_mode: String = String(cfg["digit_mode"])
    var max_digits: int = int(cfg["max_answer_digits"])

    # 数字列を生成 (4 桁防止つき)
    var numbers: Array[int] = _generate_numbers(rng, number_count, digit_mode)
    var answer: int = _sum_array(numbers)
    var attempts: int = 0
    while answer > MAX_ABSOLUTE_SUM and attempts < MAX_GENERATION_ATTEMPTS:
        numbers = _generate_numbers(rng, number_count, digit_mode)
        answer = _sum_array(numbers)
        attempts += 1

    var intervals: Array[int] = _build_intervals(number_count, String(cfg["flash_speed_class"]))

    return {
        "tier": tier,
        "numbers": numbers,
        "intervals_ms": intervals,
        "answer": answer,
        "max_answer_digits": max_digits,
    }


## 数字列を生成。digit_mode に応じて 1 桁 / 2 桁 / 混合 を選択。
static func _generate_numbers(rng: RandomNumberGenerator, count: int, digit_mode: String) -> Array[int]:
    var out: Array[int] = []
    for i in count:
        var n: int = _gen_one(rng, digit_mode)
        out.append(n)
    return out


## 1 数字生成。混合の場合は 67% で 1 桁、33% で 2 桁。
static func _gen_one(rng: RandomNumberGenerator, mode: String) -> int:
    match mode:
        "1digit":
            return rng.randi_range(1, 9)
        "2digit":
            return rng.randi_range(10, 99)
        "mixed":
            return rng.randi_range(1, 9) if rng.randf() < 0.67 else rng.randi_range(10, 99)
        _:
            return rng.randi_range(1, 9)


## 表示インターバル配列 (各数字の表示時間) を構築。
## v1.4 (2026-05-17): 旧 3 段階離散カーブ (warmup/normal/push) は段差が大きく
## 「途中から急に早くなる」体感の原因となっていたため、start_ms → end_ms の
## 線形補間に変更。先頭が start_ms、末尾が end_ms、中間は等差で減少。
static func _build_intervals(count: int, speed_class: String) -> Array[int]:
    var curve: Dictionary = _Tier.FLASH_SPEED_CURVES.get(speed_class, {})
    if curve.is_empty():
        push_warning("[FlashCalcProblem] unknown speed_class: %s" % speed_class)
        return []
    var start_ms: float = float(curve["start_ms"])
    var end_ms: float = float(curve["end_ms"])
    var out: Array[int] = []
    for i in count:
        var t: float = 0.0 if count <= 1 else float(i) / float(count - 1)
        out.append(int(round(lerp(start_ms, end_ms, t))))
    return out


static func _sum_array(arr: Array[int]) -> int:
    var s: int = 0
    for n in arr:
        s += n
    return s
