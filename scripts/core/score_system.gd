## ScoreSystem
##
## 各ミニゲームのスコア算出、脳年齢算出、能力軸マッピング、精度計算を担うサービス。
## docs/functional-design.md 「コンポーネント設計 > core/ScoreSystem」および A-01, A-02, A-04 準拠。
##
## [b]Autoload しない[/b]: インスタンス化してテスト可能にする。
class_name ScoreSystem
extends Node

# --- 定数 ---

const MAX_TOTAL_SCORE: int = 17000

const ALL_GAMES: Array[String] = [
    "flash_calc",
    "number_search",
    "stroop",
    "sequence_memory",
    "card_match",
    "ghost_7ban_shobu",
]

## ゲーム種別から能力軸へのマッピング（レーダーチャート用）
const GAME_TO_ABILITY: Dictionary = {
    "flash_calc": "calculation",
    "sequence_memory": "memory",
    "stroop": "attention",
    "ghost_7ban_shobu": "reflex",
    "number_search": "observation",
    "card_match": "judgment",
}

## 年代の中央年齢（PRD FR-04）
const AGE_GROUP_CENTER: Dictionary = {
    "10s": 15,
    "20s": 25,
    "30s": 30,  # デフォルト / 年代未設定時
    "40s": 45,
    "50s+": 55,
}

const DEFAULT_CENTER_AGE: int = 30

# --- スコア計算 ---

## 指定ゲームのスコアを算出する（docs/functional-design.md A-01）
##
## [param game_type] "flash_calc" / "ghost_7ban_shobu" など
## [param play_data] ゲーム固有のフィールド（correct_count, remaining_sec など）
## [return] 0 以上の整数スコア。不正な game_type なら 0
func calculate_score(game_type: String, play_data: Dictionary) -> int:
    match game_type:
        "flash_calc":
            # v1.3: スコアは flash_calc.gd 内で算出済み (response_time × tier_mult + bonus)。
            # GameManager から precomputed_score を渡してパススルーする。
            return max(0, int(play_data.get("precomputed_score", 0)))
        "sequence_memory":
            # TODO: Week 3 で実装
            var max_level := int(play_data.get("max_reached_level", 0))
            return max(0, max_level * 150)
        "stroop":
            # docs/ideas/games/ghost-stroop-showdown-spec.md v1.1 §5-1:
            # stroop.gd の _on_finish() でティア倍率込みのスコアを計算済み。
            # GameManager は precomputed_score を渡してパススルー (flash_calc と同パターン)。
            return max(0, int(play_data.get("precomputed_score", 0)))
        "card_match":
            # docs/ideas/games/ghost-memory-match-lite-spec.md v1.1 §5-1:
            #   タップ効率 (= ペア数 × 2 / 総タップ数) × 1000 + 時間ボーナス × ティア倍率
            var pair := int(play_data.get("pair_count", 0))
            var tap := int(play_data.get("total_tap_count", 0))
            var clear_sec := float(play_data.get("clear_time_sec", 60.0))
            var time_limit := float(play_data.get("time_limit_sec", 60.0))
            var tier_mult := float(play_data.get("tier_multiplier", 1.0))
            if tap <= 0 or time_limit <= 0.0:
                return 0
            var efficiency := float(pair * 2) / float(tap)
            var efficiency_score: int = int(efficiency * 1000.0)
            var time_remaining: float = max(0.0, time_limit - clear_sec)
            var time_bonus: int = int((time_remaining / time_limit) * 500.0)
            return max(0, int(round(float(efficiency_score + time_bonus) * tier_mult)))
        "number_search":
            # docs/ideas/games/ghost-number-search-spec.md v1.1 §5-1:
            #   未クリア = 0 pts、それ以外は BASE_SCORE × (制限時間 − クリアタイム) / 制限時間 × ティア倍率
            const NS_BASE_SCORE: int = 1500
            var is_clear := bool(play_data.get("is_clear", false))
            if not is_clear:
                return 0
            var clear_sec := float(play_data.get("clear_time_sec", 60.0))
            var time_limit := float(play_data.get("time_limit_sec", 60.0))
            var tier_mult := float(play_data.get("tier_multiplier", 1.0))
            if time_limit <= 0.0:
                return 0
            var remaining_ratio: float = max(0.0, (time_limit - clear_sec) / time_limit)
            return max(0, int(round(float(NS_BASE_SCORE) * remaining_ratio * tier_mult)))
        "ghost_7ban_shobu":
            # docs/ideas/games/ghost-7ban-shobu-spec.md §5:
            #   (1000 / 中央5発平均ms) × 300 + 勝利数 × 50
            var deltas: Array = play_data.get("round_deltas_ms", [])
            var wins := int(play_data.get("wins", 0))
            return Ghost7BanShobu.calculate_total_score(deltas, wins)
        _:
            push_warning("ScoreSystem.calculate_score: unknown game_type: %s" % game_type)
            return 0

# --- 脳年齢算出（A-02） ---

## 総合スコアから脳年齢を算出する
##
## [param total_score] 全ゲームの合計スコア
## [param age_group] "10s" / "20s" / "30s" / "40s" / "50s+" / "" (未設定)
## [param is_first_play] 初回プレイなら 3〜5 歳の甘め補正を入れる
## [param rng] テスト時にシード付き RNG を注入可能。省略時はランダム
func calculate_brain_age(
    total_score: int,
    age_group: String,
    is_first_play: bool,
    rng: RandomNumberGenerator = null
) -> int:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()

    var center: int = AGE_GROUP_CENTER.get(age_group, DEFAULT_CENTER_AGE)
    var normalized: float = clamp(float(total_score) / float(MAX_TOTAL_SCORE), 0.0, 1.0)
    var raw: float = float(center) + 10.0 - (normalized * 20.0)

    if is_first_play:
        raw -= float(rng.randi_range(3, 5))

    # 上限: center + 10（PRD FR-04 キャップ）
    # 下限: center - 15（上限との対称範囲、非現実的な値の抑止）
    var capped: int = int(clamp(raw, float(center - 15), float(center + 10)))

    # 絶対下限 10 歳（10代ユーザーの高スコア境界ケース保険）
    return max(capped, 10)

# --- 精度計算（A-04） ---

## プレイ済みゲーム種目の数を ALL_GAMES.size() で割ってパーセント（0.0〜1.0）を返す
func calculate_accuracy(played_game_types: Array) -> float:
    if played_game_types.is_empty():
        return 0.0
    var unique: Dictionary = {}
    for g in played_game_types:
        unique[String(g)] = true
    return float(unique.size()) / float(ALL_GAMES.size())

# --- 能力軸マッピング ---

## ゲーム種別から能力軸を返す。未定義なら空文字
func get_ability(game_type: String) -> String:
    return String(GAME_TO_ABILITY.get(game_type, ""))
