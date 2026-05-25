## NumberSearchTierConfig
##
## 数字さがし (ghost-number-search) のティア定数集約。
## 仕様: docs/ideas/games/ghost-number-search-spec.md v1.1 §4-1。
##
## MVP は T3 (5×5 / 1〜25 / 60 秒 / 統一表示) のみ。
## T1, T2, T4-T6 は v1.1 で拡張する想定で定義しておく。
class_name NumberSearchTierConfig
extends Object


const TIER_LIST: Array[String] = ["T1", "T2", "T3", "T4", "T5", "T6"]

const DEFAULT_TIER: String = "T3"


## 各ティアの基本パラメータ。
## - rows / cols: グリッドサイズ
## - max_number: 1〜N の N
## - time_limit: 制限時間 (秒)
## - multiplier: スコアのティア倍率 (spec §4-1)
## - visual: "uniform" (T1-T3) / "size" (T4) / "size_color" (T5) / "size_color_rotation" (T6)
const TIER_CONFIGS: Dictionary = {
    "T1": {"rows": 3, "cols": 3, "max_number":  9, "time_limit": 30.0, "multiplier": 1.0, "visual": "uniform"},
    "T2": {"rows": 4, "cols": 4, "max_number": 16, "time_limit": 45.0, "multiplier": 1.0, "visual": "uniform"},
    "T3": {"rows": 5, "cols": 5, "max_number": 25, "time_limit": 60.0, "multiplier": 1.0, "visual": "uniform"},
    "T4": {"rows": 5, "cols": 5, "max_number": 25, "time_limit": 60.0, "multiplier": 1.3, "visual": "size"},
    "T5": {"rows": 5, "cols": 5, "max_number": 25, "time_limit": 60.0, "multiplier": 1.6, "visual": "size_color"},
    "T6": {"rows": 5, "cols": 5, "max_number": 25, "time_limit": 60.0, "multiplier": 2.0, "visual": "size_color_rotation"},
}


static func get_config(tier: String) -> Dictionary:
    return TIER_CONFIGS.get(tier, TIER_CONFIGS[DEFAULT_TIER])


static func get_max_number(tier: String) -> int:
    return int(get_config(tier).get("max_number", 25))


static func get_rows(tier: String) -> int:
    return int(get_config(tier).get("rows", 5))


static func get_cols(tier: String) -> int:
    return int(get_config(tier).get("cols", 5))


static func get_time_limit(tier: String) -> float:
    return float(get_config(tier).get("time_limit", 60.0))


static func get_multiplier(tier: String) -> float:
    return float(get_config(tier).get("multiplier", 1.0))
