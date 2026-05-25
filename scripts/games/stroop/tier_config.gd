## StroopTierConfig
##
## 色文字ストループ (ghost-stroop-showdown) のティア定数。
## 仕様: docs/ideas/games/ghost-stroop-showdown-spec.md v1.1 §4-1。
##
## MVP は T1〜T3 まで実装。MVP 起動時は T1 固定 (TierManager 経由でいずれ T1〜T3 を切替予定)。
class_name StroopTierConfig
extends Object


const TIER_LIST: Array[String] = ["T1", "T2", "T3", "T4", "T5", "T6"]

const DEFAULT_TIER: String = "T1"


## 各ティアの基本パラメータ。
## - ratios: {congruent, incongruent, shape} の出現比率 (合計 1.0)
## - score_mult: スコアのティア倍率
## - shuffle_buttons_every: 0=固定、N=N 問ごとシャッフル
## - initial_ghost: 初回ゴーストの想定 30 秒間正答数 (spec §6-3)
const TIER_CONFIGS: Dictionary = {
    "T1": {
        "score_mult": 1.0,
        "shuffle_buttons_every": 0,
        "ratios": {"congruent": 0.5, "incongruent": 0.5, "shape": 0.0},
        "initial_ghost": 10,
    },
    "T2": {
        "score_mult": 1.2,
        "shuffle_buttons_every": 0,
        "ratios": {"congruent": 0.3, "incongruent": 0.7, "shape": 0.0},
        "initial_ghost": 9,
    },
    "T3": {
        "score_mult": 1.5,
        "shuffle_buttons_every": 3,
        "ratios": {"congruent": 0.2, "incongruent": 0.5, "shape": 0.3},
        "initial_ghost": 8,
    },
}


## 色キー → ひらがな
const JP_NAMES: Dictionary = {
    "red":    "あか",
    "blue":   "あお",
    "green":  "みどり",
    "yellow": "きいろ",
}


## 色キー → Godot Color (spec §2-3)
const COLOR_RGB: Dictionary = {
    "red":    Color(0.898, 0.224, 0.208),  # #E53935
    "blue":   Color(0.118, 0.533, 0.898),  # #1E88E5
    "green":  Color(0.263, 0.627, 0.278),  # #43A047
    "yellow": Color(0.992, 0.847, 0.208),  # #FDD835
}


## 色キー → Material Symbols グリフ名 (形状アイコン)
const SHAPE_GLYPH: Dictionary = {
    "red":    "circle",
    "blue":   "change_history",  # ▲
    "green":  "square",
    "yellow": "diamond",
}


const COLORS: Array[String] = ["red", "blue", "green", "yellow"]


static func get_config(tier: String) -> Dictionary:
    return TIER_CONFIGS.get(tier, TIER_CONFIGS[DEFAULT_TIER])


static func get_ratios(tier: String) -> Dictionary:
    return get_config(tier).get("ratios", {"congruent": 0.5, "incongruent": 0.5, "shape": 0.0})


static func get_score_mult(tier: String) -> float:
    return float(get_config(tier).get("score_mult", 1.0))


static func get_shuffle_every(tier: String) -> int:
    return int(get_config(tier).get("shuffle_buttons_every", 0))


static func get_initial_ghost(tier: String) -> int:
    return int(get_config(tier).get("initial_ghost", 10))
