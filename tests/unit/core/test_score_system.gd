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

func test_score_flash_calc():
    assert_eq(ss.calculate_score("flash_calc", {"correct_count": 10, "remaining_sec": 5}), 1050)
    assert_eq(ss.calculate_score("flash_calc", {"correct_count": 0, "remaining_sec": 0}), 0)

func test_score_reflex_tap_normal():
    # 平均 300ms → (1000/300)*300 = 1000
    assert_eq(ss.calculate_score("reflex_tap", {"average_reaction_ms": 300.0}), 1000)

func test_score_reflex_tap_capped():
    # 平均 100ms → (1000/100)*300 = 3000 だが上限 1500
    assert_eq(ss.calculate_score("reflex_tap", {"average_reaction_ms": 100.0}), 1500)

func test_score_reflex_tap_zero_guard():
    assert_eq(ss.calculate_score("reflex_tap", {"average_reaction_ms": 0.0}), 0)

func test_score_stroop():
    assert_eq(ss.calculate_score("stroop", {"correct_count": 10, "incorrect_count": 2}), 900)
    assert_eq(ss.calculate_score("stroop", {"correct_count": 1, "incorrect_count": 10}), 0, "下限 0")

func test_score_number_search():
    assert_eq(ss.calculate_score("number_search", {"clear_time_sec": 20}), 1000)
    assert_eq(ss.calculate_score("number_search", {"clear_time_sec": 30}), 0, "30 秒以降は 0")

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
    assert_eq(ss.calculate_accuracy(["reflex_tap", "flash_calc", "stroop"]), 0.5)

func test_accuracy_full():
    assert_eq(ss.calculate_accuracy([
        "reflex_tap", "flash_calc", "number_search",
        "stroop", "sequence_memory", "card_match"
    ]), 1.0)

func test_accuracy_dedups():
    assert_almost_eq(ss.calculate_accuracy(["reflex_tap", "reflex_tap", "flash_calc"]), 2.0 / 6.0, 0.001)

# --- 能力軸 ---

func test_ability_mapping():
    assert_eq(ss.get_ability("flash_calc"), "calculation")
    assert_eq(ss.get_ability("sequence_memory"), "memory")
    assert_eq(ss.get_ability("stroop"), "attention")
    assert_eq(ss.get_ability("reflex_tap"), "reflex")
    assert_eq(ss.get_ability("number_search"), "observation")
    assert_eq(ss.get_ability("card_match"), "judgment")

func test_ability_unknown_empty():
    assert_eq(ss.get_ability("unknown"), "")
