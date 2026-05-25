## TierConfig
##
## フラッシュ暗算 (ゴースト一本勝負・計算編) のティア定数集約。
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md §4。
##
## ## ティア体系 (T1〜T8)
## - 数字枚数 / 桁数 / 速度倍率 / スコア倍率を各ティアで定義
## - 速度カーブ: ウォームアップ → 本番 → 追い込み の 3 フェーズ
class_name FlashCalcTierConfig
extends Object


## 全ティア順序 (T1=index 1, T8=index 8)
const TIER_LIST: Array[String] = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8"]


## 各ティアの基本パラメータ。
## - number_count: 表示する数字の枚数
## - digit_mode: "1digit" | "mixed" | "2digit"
## - flash_speed_class: 速度カーブの分類 ("slow" / "fast" / "mixed_slow" / "extreme")
## - score_mult: スコア倍率
## - max_answer_digits: 答えの最大桁数 (テンキー自動確定用)
const TIER_CONFIGS: Dictionary = {
    "T1": {"number_count": 10, "digit_mode": "1digit", "flash_speed_class": "slow",       "score_mult": 1.0,  "max_answer_digits": 2},
    "T2": {"number_count": 11, "digit_mode": "1digit", "flash_speed_class": "slow",       "score_mult": 1.1,  "max_answer_digits": 2},
    "T3": {"number_count": 12, "digit_mode": "1digit", "flash_speed_class": "slow",       "score_mult": 1.25, "max_answer_digits": 2},
    "T4": {"number_count": 12, "digit_mode": "1digit", "flash_speed_class": "fast",       "score_mult": 1.4,  "max_answer_digits": 2},
    "T5": {"number_count": 13, "digit_mode": "1digit", "flash_speed_class": "fast",       "score_mult": 1.6,  "max_answer_digits": 2},
    "T6": {"number_count": 12, "digit_mode": "mixed",  "flash_speed_class": "mixed_slow", "score_mult": 2.0,  "max_answer_digits": 3},
    "T7": {"number_count": 14, "digit_mode": "mixed",  "flash_speed_class": "mixed_slow", "score_mult": 2.5,  "max_answer_digits": 3},
    "T8": {"number_count": 15, "digit_mode": "2digit", "flash_speed_class": "extreme",    "score_mult": 3.0,  "max_answer_digits": 3},
}


## 速度カーブ (ms 単位)。線形補間方式 (v1.4 / 2026-05-17)。
## key: flash_speed_class, value: {start_ms, end_ms}
##
## 旧 (v1.3 まで) は warmup/normal/push の 3 段階離散カーブだったが、
## フェーズ境界で急加速して見える問題があり、各番号の間隔を start_ms から end_ms まで
## 線形補間する方式に変更。最初の数字は start_ms、最後の数字は end_ms で表示される。
##
## T1〜T3 (slow) のベースラインは初心者向けに緩めに再設定。
const FLASH_SPEED_CURVES: Dictionary = {
    "slow":       {"start_ms": 800, "end_ms": 500},
    "fast":       {"start_ms": 650, "end_ms": 400},
    "mixed_slow": {"start_ms": 700, "end_ms": 420},
    "extreme":    {"start_ms": 500, "end_ms": 280},
}


## 初期ゴースト Δt (ms)。各ティアの初回プレイで使用 (仕様 §6-3)。
const TIER_INITIAL_DELTAS: Dictionary = {
    "T1": 12000, "T2": 11000, "T3": 9000, "T4": 7000,
    "T5": 5500,  "T6": 4500,  "T7": 3500, "T8": 2500,
}


## 入力フェーズの最大時間 (ms)。ゴースト CD バーがゼロになるまでの猶予。
## ティア別に異なるが MVP では一律 TIER_INITIAL_DELTAS を上限として使う。


## ティア名 (T1〜T8) を 1-based index (1〜8) に変換。
static func tier_to_index(tier: String) -> int:
    var i: int = TIER_LIST.find(tier)
    return i + 1 if i >= 0 else 0


## 1-based index (1〜8) を ティア名 ("T1"〜"T8") に変換。
static func index_to_tier(index: int) -> String:
    var i: int = index - 1
    if i < 0 or i >= TIER_LIST.size():
        return ""
    return TIER_LIST[i]


## ティアの 1 つ上 (T1 → T2 等)。最上位の T8 は "" を返す。
static func next_tier(tier: String) -> String:
    var i: int = TIER_LIST.find(tier)
    if i < 0 or i + 1 >= TIER_LIST.size():
        return ""
    return TIER_LIST[i + 1]
