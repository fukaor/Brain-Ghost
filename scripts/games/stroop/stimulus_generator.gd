## StroopStimulusGenerator
##
## 色文字ストループの刺激プール生成。デイリーシード対応。
## 仕様: docs/ideas/games/ghost-stroop-showdown-spec.md v1.1 §8-1。
##
## ## 2 段階生成 (Wordle 公平性)
## - generate_pool(seed): ティア非依存のコア属性プール (40 問)
## - select_for_tier(pool, tier): ティア別比率で刺激タイプを決定
##
## 同じシードならどのティアでも同じプールから派生するため、
## 日替わりプレイの「今日の刺激」が全ユーザー共通になる。
extends Object

const _TierConfig = preload("res://scripts/games/stroop/tier_config.gd")

const POOL_SIZE: int = 40


## Step 1: ティア非依存のコア属性プールを生成。
## 各エントリ: {index, display_color, interfere_color, shape}
func generate_pool(seed_value: int) -> Array:
    var rng := RandomNumberGenerator.new()
    if seed_value < 0:
        rng.randomize()
    else:
        rng.seed = seed_value

    var pool: Array = []
    for i in range(POOL_SIZE):
        var display: String = _TierConfig.COLORS[rng.randi() % 4]
        var others: Array = _TierConfig.COLORS.filter(func(c): return c != display)
        var interfere: String = others[rng.randi() % others.size()]
        var shape: String = _TierConfig.COLORS[rng.randi() % 4]  # 形状色は表示色とは独立
        pool.append({
            "index": i,
            "display_color": display,
            "interfere_color": interfere,
            "shape_key": shape,  # Shape 刺激のときの図形種類を決める参考値
        })
    return pool


## Step 2: 共通プールからティア別比率で刺激タイプを決定し、組み立てる。
func select_for_tier(pool: Array, tier: String) -> Array:
    var ratios: Dictionary = _TierConfig.get_ratios(tier)
    # ティア別に決定論的な型シーケンスを作るため、type 決定用 RNG はティア名でシード
    var type_rng := RandomNumberGenerator.new()
    type_rng.seed = hash(tier)

    var stimuli: Array = []
    for item in pool:
        var stim_type: String = _pick_type(type_rng, ratios)
        var display_color: String = String(item["display_color"])
        var interfere: String = String(item["interfere_color"])
        # text 内容: congruent なら表示色の色名、それ以外なら干渉色の色名
        var text: String = _TierConfig.JP_NAMES[display_color] if stim_type == "congruent" else _TierConfig.JP_NAMES[interfere]
        stimuli.append({
            "type": stim_type,
            "display_color": display_color,    # 正解判定の基準
            "interfere_color": interfere,
            "correct_answer": display_color,    # 統一操作原則: 中央の色 = display_color
            "text": text,
        })
    return stimuli


func _pick_type(rng: RandomNumberGenerator, ratios: Dictionary) -> String:
    var r: float = rng.randf()
    var cumulative: float = 0.0
    for key in ["congruent", "incongruent", "shape"]:
        cumulative += float(ratios.get(key, 0.0))
        if r < cumulative:
            return key
    return "incongruent"
