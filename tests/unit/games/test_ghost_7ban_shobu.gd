## GUT test for Ghost7BanShobu
##
## ゴースト7番勝負のロジック検証。classify_delta / calculate_total_score /
## generate_rounds / notify_* / resolve_tap / resolve_miss の単体動作と
## 6 段階判定の境界値、中央 5 発平均スコア、デイリー生成の決定論性。
##
## docs/ideas/games/ghost-7ban-shobu-spec.md v1.0 準拠。
extends "res://addons/gut/test.gd"

var game: Ghost7BanShobu


func before_each() -> void:
    game = Ghost7BanShobu.new()
    # タイミングテストでは CFG_BASE の固定値に依存するため seed=-1 でジッター無効。
    # 乱数が関与するテストはケース内で別途 setup する。
    game.setup(-1)


func after_each() -> void:
    if is_instance_valid(game):
        game.queue_free()


# ---------------------------------------------------------------------------
# 初期化
# ---------------------------------------------------------------------------

func test_setup_initializes_state() -> void:
    assert_eq(game.game_type, "ghost_7ban_shobu")
    assert_false(game.is_time_based, "ゴースト7番勝負はクリア系扱い")
    assert_eq(game.get_total_rounds(), 7)
    assert_eq(game.get_rounds_config().size(), 7)
    assert_eq(game.get_ghost_deltas().size(), 7)


# ---------------------------------------------------------------------------
# classify_delta 6 段階判定（variant-b.jsx しきい値）
# ---------------------------------------------------------------------------

func test_classify_delta_flying() -> void:
    assert_eq(Ghost7BanShobu.classify_delta(0, true), "FLYING")
    assert_eq(Ghost7BanShobu.classify_delta(200, true), "FLYING")

func test_classify_delta_perfect_boundary() -> void:
    assert_eq(Ghost7BanShobu.classify_delta(0, false), "PERFECT")
    assert_eq(Ghost7BanShobu.classify_delta(50, false), "PERFECT")
    assert_eq(Ghost7BanShobu.classify_delta(51, false), "GREAT")

func test_classify_delta_great_boundary() -> void:
    assert_eq(Ghost7BanShobu.classify_delta(150, false), "GREAT")
    assert_eq(Ghost7BanShobu.classify_delta(151, false), "GOOD")

func test_classify_delta_good_boundary() -> void:
    assert_eq(Ghost7BanShobu.classify_delta(300, false), "GOOD")
    assert_eq(Ghost7BanShobu.classify_delta(301, false), "LATE")

func test_classify_delta_miss() -> void:
    assert_eq(Ghost7BanShobu.classify_delta(1000, false), "MISS")
    assert_eq(Ghost7BanShobu.classify_delta(1500, false), "MISS")


# ---------------------------------------------------------------------------
# calculate_total_score
# ---------------------------------------------------------------------------

func test_calculate_total_score_example_from_spec() -> void:
    # spec §5-1 の例: [87, 98, 132, 145, 175, 210, 250]
    # 最速・最遅を除外した中央 5 発 [98, 132, 145, 175, 210] の平均 = 152ms
    # スコア = 1000 / 152 × 300 ≈ 1973 pts + 0 wins
    var deltas: Array = [87, 98, 132, 145, 175, 210, 250]
    var score: int = Ghost7BanShobu.calculate_total_score(deltas, 0)
    assert_almost_eq(score, 1974, 2, "spec 例示値と誤差 ±2 以内")


func test_calculate_total_score_with_win_bonus() -> void:
    var deltas: Array = [100, 100, 100, 100, 100, 100, 100]
    # 中央 5 発平均 = 100ms → reaction score = 1000/100×300 = 3000
    # + wins=4 × 50 = 200 → 合計 3200
    assert_eq(Ghost7BanShobu.calculate_total_score(deltas, 4), 3200)


func test_calculate_total_score_empty() -> void:
    assert_eq(Ghost7BanShobu.calculate_total_score([], 5), 0)


func test_calculate_total_score_zero_avg_returns_zero() -> void:
    # 全ゼロは異常だが防御的に 0 返し
    assert_eq(Ghost7BanShobu.calculate_total_score([0, 0, 0, 0, 0, 0, 0], 0), 0)


# ---------------------------------------------------------------------------
# generate_rounds
# ---------------------------------------------------------------------------

func test_generate_rounds_seed_minus_1_returns_cfg_base() -> void:
    var rounds := Ghost7BanShobu.generate_rounds(-1)
    assert_eq(rounds.size(), 7)
    assert_eq(int(rounds[0].move), 2200, "CFG_BASE R0 move=2200ms")
    assert_eq(int(rounds[0].pre), 1500, "CFG_BASE R0 pre=1500ms")
    assert_eq(String(rounds[0].dir), "left")
    assert_eq(int(rounds[6].move), 900, "CFG_BASE R6 move=900ms")


func test_generate_rounds_deterministic_with_seed() -> void:
    var r1 := Ghost7BanShobu.generate_rounds(42)
    var r2 := Ghost7BanShobu.generate_rounds(42)
    for i in range(7):
        assert_eq(int(r1[i].move), int(r2[i].move), "move 一致 i=%d" % i)
        assert_eq(int(r1[i].pre), int(r2[i].pre), "pre 一致 i=%d" % i)
        assert_eq(String(r1[i].dir), String(r2[i].dir), "dir 一致 i=%d" % i)


func test_generate_rounds_dir_not_mutated() -> void:
    var rounds := Ghost7BanShobu.generate_rounds(999)
    # CFG_BASE の dir 並びが保持されている
    var expected: Array = ["left", "right", "left", "right", "left", "right", "left"]
    for i in range(7):
        assert_eq(String(rounds[i].dir), expected[i], "dir 並び不変 i=%d" % i)


# ---------------------------------------------------------------------------
# resolve_tap / resolve_miss
# ---------------------------------------------------------------------------

func test_resolve_tap_announce_phase_is_flying() -> void:
    game.notify_announce_started(0)
    var result: Dictionary = game.resolve_tap(100)
    assert_eq(String(result.grade), "FLYING")
    assert_eq(int(result.delta), Ghost7BanShobu.FLYING_RECORDED_MS)
    assert_false(bool(result.win))


func test_resolve_tap_moving_phase_before_line_flying() -> void:
    # moving 開始時点 now=1000, cfg R0 move=2200 → line_pass = 1000 + 1100 = 2100
    # now = 1900 → signed = -200, < -80 なので FLYING
    game.notify_moving_started(0, 1000)
    var result: Dictionary = game.resolve_tap(1900)
    assert_eq(String(result.grade), "FLYING")


func test_resolve_tap_moving_phase_perfect() -> void:
    # line_pass = 2100. now = 2120 → signed = +20, PERFECT
    game.notify_moving_started(0, 1000)
    var result: Dictionary = game.resolve_tap(2120)
    assert_eq(String(result.grade), "PERFECT")
    assert_eq(int(result.delta), 20)


func test_resolve_tap_moving_phase_late() -> void:
    # now = 2500 → signed = +400, LATE
    game.notify_moving_started(0, 1000)
    var result: Dictionary = game.resolve_tap(2500)
    assert_eq(String(result.grade), "LATE")
    assert_eq(int(result.delta), 400)


func test_resolve_miss_records_miss_grade() -> void:
    game.notify_moving_started(0, 1000)
    var result: Dictionary = game.resolve_miss()
    assert_eq(String(result.grade), "MISS")
    assert_eq(int(result.delta), Ghost7BanShobu.MISS_RECORDED_MS)
    assert_true(bool(result.is_miss))


# ---------------------------------------------------------------------------
# ウィン集計
# ---------------------------------------------------------------------------

func test_win_counter_increments_on_win() -> void:
    assert_eq(game.get_wins(), 0)
    # R0 ゴースト Δt = 273（フォールバック）。20ms タップは勝利
    game.notify_moving_started(0, 1000)
    game.resolve_tap(2120)  # delta=20, win=true
    assert_eq(game.get_wins(), 1)
    assert_eq(game.get_ghost_wins(), 0)


func test_ghost_wins_on_miss() -> void:
    game.notify_moving_started(0, 1000)
    game.resolve_miss()
    assert_eq(game.get_wins(), 0)
    assert_eq(game.get_ghost_wins(), 1)
