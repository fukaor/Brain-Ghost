## GUT test for ScoreSystem
##
## docs/functional-design.md A-01, A-02, A-04 のアルゴリズムを網羅する。
extends "res://addons/gut/test.gd"

var ss: ScoreSystem

func before_each() -> void:
    ss = ScoreSystem.new()

func after_each() -> void:
    if is_instance_valid(ss):
        ss.queue_free()

# --- A-01: スコア計算 ---

func test_score_flash_calc_precomputed():
    # スコアは flash_calc.gd 側で計算済み (precomputed_score をパススルー)
    assert_eq(ss.calculate_score("flash_calc", {"precomputed_score": 1234}), 1234)
    assert_eq(ss.calculate_score("flash_calc", {"precomputed_score": 0}), 0)
    assert_eq(ss.calculate_score("flash_calc", {}), 0)

func test_score_stroop_precomputed():
    # stroop.gd の _on_finish() でティア倍率込みで計算済み
    assert_eq(ss.calculate_score("stroop", {"precomputed_score": 1500}), 1500)
    assert_eq(ss.calculate_score("stroop", {"precomputed_score": -50}), 0, "負値は 0 にクランプ")

func test_score_number_search_clear():
    # 30s クリア / 60s 制限 / 倍率 1.0 → 1500 * 0.5 = 750
    var s := ss.calculate_score("number_search", {
        "is_clear": true,
        "clear_time_sec": 30.0,
        "time_limit_sec": 60.0,
        "tier_multiplier": 1.0,
    })
    assert_eq(s, 750)

func test_score_number_search_timeout():
    # is_clear=false なら 0
    assert_eq(ss.calculate_score("number_search", {
        "is_clear": false,
        "clear_time_sec": 60.0,
        "time_limit_sec": 60.0,
        "tier_multiplier": 1.0,
    }), 0)

func test_score_card_match_perfect():
    # 8 ペア / 16 タップ / 30 秒: 効率 1.0 (1000) + 時間ボーナス (250) = 1250
    var s := ss.calculate_score("card_match", {
        "pair_count": 8,
        "total_tap_count": 16,
        "clear_time_sec": 30.0,
        "time_limit_sec": 60.0,
        "tier_multiplier": 1.0,
    })
    assert_eq(s, 1250)

func test_score_card_match_zero_taps_guard():
    assert_eq(ss.calculate_score("card_match", {
        "pair_count": 0,
        "total_tap_count": 0,
        "clear_time_sec": 60.0,
        "time_limit_sec": 60.0,
        "tier_multiplier": 1.0,
    }), 0)

func test_score_unknown_game_returns_zero():
    assert_eq(ss.calculate_score("unknown", {}), 0)

# --- A-02: 脳年齢算出 ---

func test_brain_age_30s_zero_score():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # center=30, normalized=0, raw=40, no first_play compensation → 40
    assert_eq(ss.calculate_brain_age(0, "30s", false, rng), 40)

func test_brain_age_30s_max_score():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # center=30, normalized=1.0, raw=20 → 20
    assert_eq(ss.calculate_brain_age(17000, "30s", false, rng), 20)

func test_brain_age_30s_half_score():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # center=30, normalized=0.5, raw=30 → 30
    assert_eq(ss.calculate_brain_age(8500, "30s", false, rng), 30)

func test_brain_age_negative_score_clamped():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # normalized=0 扱い → raw=40 → 上限クランプで 40
    assert_eq(ss.calculate_brain_age(-1000, "30s", false, rng), 40)

func test_brain_age_overflow_score_clamped():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # normalized=1.0 扱い → raw=20 → 20
    assert_eq(ss.calculate_brain_age(999999, "30s", false, rng), 20)

func test_brain_age_10s_minimum_10():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # center=15, 高スコア + 初回補正 で 0 歳近くになっても絶対下限 10 歳
    var result := ss.calculate_brain_age(17000, "10s", true, rng)
    assert_true(result >= 10, "絶対下限 10 歳")

func test_brain_age_null_age_group_defaults_to_30():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var result_null := ss.calculate_brain_age(8500, "", false, rng)
    rng.seed = 12345
    var result_30s := ss.calculate_brain_age(8500, "30s", false, rng)
    assert_eq(result_null, result_30s, "空文字は 30s と同じ結果")

func test_brain_age_50plus_center():
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # center=55, normalized=0.5 → 55
    assert_eq(ss.calculate_brain_age(8500, "50s+", false, rng), 55)

func test_brain_age_first_play_is_younger():
    # 同じスコア/年代で is_first_play=true の方が低い値になる
    var rng1 := RandomNumberGenerator.new()
    rng1.seed = 12345
    var normal := ss.calculate_brain_age(8500, "30s", false, rng1)

    var rng2 := RandomNumberGenerator.new()
    rng2.seed = 12345
    var first := ss.calculate_brain_age(8500, "30s", true, rng2)

    assert_true(first <= normal, "初回補正で甘めになる")
    assert_true(normal - first <= 5 and normal - first >= 3, "補正幅は 3〜5 歳")

# --- A-04: 精度計算 ---

func test_accuracy_empty():
    assert_eq(ss.calculate_accuracy([]), 0.0)

func test_accuracy_half():
    # ALL_GAMES = 6 なので 3/6 = 0.5
    assert_almost_eq(ss.calculate_accuracy(["flash_calc", "stroop", "card_match"]), 3.0 / 6.0, 0.001)

func test_accuracy_full():
    assert_eq(ss.calculate_accuracy([
        "flash_calc", "number_search",
        "stroop", "sequence_memory", "card_match", "ghost_7ban_shobu"
    ]), 1.0)

func test_accuracy_dedups():
    # ALL_GAMES = 6 なので 2 種（重複除外後）/ 6
    assert_almost_eq(ss.calculate_accuracy(["flash_calc", "flash_calc", "stroop"]), 2.0 / 6.0, 0.001)

# --- 能力軸 ---

func test_ability_mapping():
    assert_eq(ss.get_ability("flash_calc"), "calculation")
    assert_eq(ss.get_ability("sequence_memory"), "memory")
    assert_eq(ss.get_ability("stroop"), "attention")
    assert_eq(ss.get_ability("ghost_7ban_shobu"), "reflex")
    assert_eq(ss.get_ability("number_search"), "observation")
    assert_eq(ss.get_ability("card_match"), "judgment")

func test_ability_unknown_empty():
    assert_eq(ss.get_ability("unknown"), "")
