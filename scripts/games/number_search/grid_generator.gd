## NumberSearchGridGenerator
##
## デイリーシード対応の数字配列生成。
## 仕様: docs/ideas/games/ghost-number-search-spec.md v1.1 §8-1
##       (ティアごとの独立シャッフル、シード + オフセット方式)。
##
## 設計原則: 各ティアの数字範囲 (T1:1〜9, T2:1〜16, T3:1〜25) を独立にシャッフル。
## 同じ日に同じティアでプレイすれば同じ配置になる (Wordle 公平性)。
extends Object

const _TierConfig = preload("res://scripts/games/number_search/tier_config.gd")

const TIER_OFFSETS: Dictionary = {
    "T1": 0,
    "T2": 100,
    "T3": 200,
    "T4": 200,
    "T5": 200,
    "T6": 200,
}


## 指定ティアの数字配列を返す。`Array[int]` 型を明示するため戻り値で .duplicate() ではなく
## 中で typed Array を構築する。
##
## [param tier] "T1"〜"T6"
## [param seed_value] -1 ならランダム (自由プレイ)、それ以外はデイリーシード
func generate(tier: String, seed_value: int) -> Array[int]:
    var rng := RandomNumberGenerator.new()
    if seed_value < 0:
        rng.randomize()
    else:
        rng.seed = seed_value + int(TIER_OFFSETS.get(tier, 200))

    var max_num: int = _TierConfig.get_max_number(tier)
    var nums: Array[int] = []
    for i in range(1, max_num + 1):
        nums.append(i)

    # Fisher-Yates シャッフル
    for i in range(nums.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var tmp: int = nums[i]
        nums[i] = nums[j]
        nums[j] = tmp

    return nums
