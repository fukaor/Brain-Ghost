## CardMatchGenerator
##
## デイリーシード対応の神経衰弱カード配置生成。
## 仕様: docs/ideas/games/ghost-memory-match-lite-spec.md v1.1 §8-1。
##
## 設計: 共通プール生成 → ティア別切り出し方式。MVP は T1 (16 枚) のみ。
extends Object

const _TierConfig = preload("res://scripts/games/card_match/tier_config.gd")


## 指定ティアのカード配列 (cell_index → card_id) を返す。
##
## [param tier] "T1"〜"T6"
## [param seed_value] -1 ならランダム、それ以外はデイリーシード
func generate(tier: String, seed_value: int) -> Array[int]:
    var rng := RandomNumberGenerator.new()
    if seed_value < 0:
        rng.randomize()
    else:
        rng.seed = seed_value

    var pairs: int = _TierConfig.get_pairs(tier)
    var ids: Array[int] = []
    for i in range(pairs):
        ids.append(i)
        ids.append(i)

    # Fisher-Yates シャッフル
    for i in range(ids.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var tmp: int = ids[i]
        ids[i] = ids[j]
        ids[j] = tmp

    return ids
