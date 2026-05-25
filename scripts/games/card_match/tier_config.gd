## CardMatchTierConfig
##
## 神経衰弱ライト (ghost-memory-match-lite) のティア定数。
## 仕様: docs/ideas/games/ghost-memory-match-lite-spec.md v1.1 §4-1。
##
## MVP は T1 (4×4 / 8 ペア / 単色図形 / 60 秒) のみ。
class_name CardMatchTierConfig
extends Object


const TIER_LIST: Array[String] = ["T1", "T2", "T3", "T4", "T5", "T6"]

const DEFAULT_TIER: String = "T1"


## 各ティアの基本パラメータ。
## - rows / cols: グリッドサイズ
## - pairs: ペア数 (= rows * cols / 2)
## - time_limit: 制限時間 (秒)
## - multiplier: スコアのティア倍率 (spec §4-1)
## - content: "shape" (T1, T4, T6) / "number" (T2) / "bi_attr" (T3, T5)
## - shuffle_on_match: T6 のみ true (シャッフルルール)
const TIER_CONFIGS: Dictionary = {
    "T1": {"rows": 4, "cols": 4, "pairs":  8, "time_limit": 60.0, "multiplier": 1.0, "content": "shape",   "shuffle_on_match": false},
    "T2": {"rows": 4, "cols": 4, "pairs":  8, "time_limit": 45.0, "multiplier": 1.2, "content": "number",  "shuffle_on_match": false},
    "T3": {"rows": 4, "cols": 4, "pairs":  8, "time_limit": 45.0, "multiplier": 1.5, "content": "bi_attr", "shuffle_on_match": false},
    "T4": {"rows": 5, "cols": 4, "pairs": 10, "time_limit": 60.0, "multiplier": 1.8, "content": "shape",   "shuffle_on_match": false},
    "T5": {"rows": 6, "cols": 4, "pairs": 12, "time_limit": 60.0, "multiplier": 2.2, "content": "bi_attr", "shuffle_on_match": false},
    "T6": {"rows": 4, "cols": 4, "pairs":  8, "time_limit": 60.0, "multiplier": 2.8, "content": "shape",   "shuffle_on_match": true},
}


## カードの図柄 (spec §2-2 T1)。Material Symbols Rounded のグリフ名 + 色。
const CARD_DATA_SHAPE: Array[Dictionary] = [
    {"icon": "circle",          "color": Color(0.898, 0.224, 0.208)},  # 赤
    {"icon": "square",          "color": Color(0.118, 0.533, 0.898)},  # 青
    {"icon": "change_history",  "color": Color(0.263, 0.627, 0.278)},  # 緑
    {"icon": "diamond",         "color": Color(0.992, 0.847, 0.208)},  # 黄
    {"icon": "star",            "color": Color(1.0,   0.420, 0.208)},  # オレンジ
    {"icon": "hexagon",         "color": Color(0.482, 0.122, 0.635)},  # 紫
    {"icon": "favorite",        "color": Color(0.925, 0.251, 0.478)},  # ピンク
    {"icon": "pentagon",        "color": Color(0.0,   0.737, 0.831)},  # シアン
]


static func get_config(tier: String) -> Dictionary:
    return TIER_CONFIGS.get(tier, TIER_CONFIGS[DEFAULT_TIER])


static func get_rows(tier: String) -> int:
    return int(get_config(tier).get("rows", 4))


static func get_cols(tier: String) -> int:
    return int(get_config(tier).get("cols", 4))


static func get_pairs(tier: String) -> int:
    return int(get_config(tier).get("pairs", 8))


static func get_time_limit(tier: String) -> float:
    return float(get_config(tier).get("time_limit", 60.0))


static func get_multiplier(tier: String) -> float:
    return float(get_config(tier).get("multiplier", 1.0))


static func get_card_visual(card_id: int) -> Dictionary:
    if card_id < 0 or card_id >= CARD_DATA_SHAPE.size():
        return CARD_DATA_SHAPE[0]
    return CARD_DATA_SHAPE[card_id]
