## GUT test for ReflexTap
##
## 反射タップゲームロジックの決定論性・境界・エッジケース検証。
## docs/ideas/brain_training_gdd.md §4-4 および
## .steering/20260412-reflex-tap-implementation/design.md のテスト戦略準拠。
extends "res://addons/gut/test.gd"

var game: ReflexTap


func before_each() -> void:
    game = ReflexTap.new()
    game.setup(12345)  # 決定論シード


func after_each() -> void:
    if is_instance_valid(game):
        game.queue_free()


# --- 初期化 ---

func test_setup_initializes_state():
    assert_eq(game.game_type, "reflex_tap")
    assert_true(game.is_time_based)


# --- 決定論性 ---

func test_deterministic_target_size():
    var g1 := ReflexTap.new()
    var g2 := ReflexTap.new()
    g1.setup(12345)
    g2.setup(12345)
    for i in range(20):
        assert_eq(g1.pick_target_size(), g2.pick_target_size(), "Same seed same size at i=%d" % i)
    g1.queue_free()
    g2.queue_free()


func test_deterministic_wait_ms():
    var g1 := ReflexTap.new()
    var g2 := ReflexTap.new()
    g1.setup(12345)
    g2.setup(12345)
    for i in range(20):
        assert_eq(g1.pick_wait_ms(), g2.pick_wait_ms(), "Same seed same wait at i=%d" % i)
    g1.queue_free()
    g2.queue_free()


func test_deterministic_position():
    var g1 := ReflexTap.new()
    var g2 := ReflexTap.new()
    g1.setup(12345)
    g2.setup(12345)
    var viewport := Vector2i(720, 1280)
    for i in range(20):
        assert_eq(g1.generate_target_position(viewport), g2.generate_target_position(viewport), "Same seed same position at i=%d" % i)
    g1.queue_free()
    g2.queue_free()


# --- 範囲チェック ---

func test_target_size_in_range():
    for i in range(100):
        var size := game.pick_target_size()
        assert_true(size >= ReflexTap.TARGET_SIZE_MIN, "size=%d >= MIN" % size)
        assert_true(size <= ReflexTap.TARGET_SIZE_MAX, "size=%d <= MAX" % size)


func test_wait_ms_in_range():
    for i in range(100):
        var wait := game.pick_wait_ms()
        assert_true(wait >= ReflexTap.WAIT_MS_MIN, "wait=%d >= MIN" % wait)
        assert_true(wait <= ReflexTap.WAIT_MS_MAX, "wait=%d <= MAX" % wait)


func test_target_position_within_margin():
    var viewport := Vector2i(720, 1280)
    for i in range(100):
        var pos := game.generate_target_position(viewport)
        assert_true(pos.x >= float(ReflexTap.SCREEN_MARGIN_PX), "x >= margin")
        assert_true(pos.y >= float(ReflexTap.SCREEN_MARGIN_PX), "y >= margin")
        # サイズ分の余裕を引いた右/下端までに収まっている
        assert_true(pos.x <= float(viewport.x - ReflexTap.SCREEN_MARGIN_PX), "x <= width - margin")
        assert_true(pos.y <= float(viewport.y - ReflexTap.SCREEN_MARGIN_PX), "y <= height - margin")


# --- 平均反応時間の算出 ---

func test_average_reaction_empty():
    assert_eq(game.calculate_average_reaction_ms(), 0.0)


func test_average_reaction_normal():
    game._reaction_times_ms = [300, 400, 500]
    assert_almost_eq(game.calculate_average_reaction_ms(), 400.0, 0.1)


func test_average_reaction_fake_penalty():
    # 平均 400ms + フェイクタップ 2 回 × 50ms ペナルティ = 500ms
    game._reaction_times_ms = [300, 400, 500]
    game._fake_tapped_count = 2
    assert_almost_eq(game.calculate_average_reaction_ms(), 500.0, 0.1)


# --- フェイクタップ境界判定 ---

func test_should_show_fake_boundary():
    game._next_fake_at = 4
    game._tapped_count = 2
    # _tapped_count + 1 = 3 < 4
    assert_false(game.should_show_fake(), "3 < 4 should be false")
    game._tapped_count = 3
    # _tapped_count + 1 = 4 >= 4
    assert_true(game.should_show_fake(), "4 >= 4 should be true")


# --- 後半ランプ (セッション内難易度上昇) ---

func test_late_ramp_not_applied_early():
    # 進行度 25% (24 中 6 タップ) → 閾値 66% 未満なのでランプなし
    game._tapped_count = 6
    assert_eq(game._scale_wait_for_progress(1000), 1000)
    assert_eq(game._scale_wait_for_progress(500), 500)


func test_late_ramp_applied_late():
    # 進行度 83% (24 中 20 タップ) → 閾値 66% 超えなのでランプ適用
    # 1000 * 0.85 = 850
    game._tapped_count = 20
    assert_eq(game._scale_wait_for_progress(1000), 850)


func test_late_ramp_boundary():
    # 進行度ちょうど 66% 以上で発動
    game._tapped_count = int(ReflexTap.TARGET_COUNT * ReflexTap.LATE_RAMP_THRESHOLD)
    # TARGET_COUNT=24、threshold=0.66 → 15.84 → int で 15
    # 15/24 = 0.625 < 0.66 でまだランプなし
    assert_eq(game._scale_wait_for_progress(1000), 1000, "境界直下ではランプなし")
    game._tapped_count += 1
    # 16/24 = 0.667 > 0.66 でランプ適用
    assert_eq(game._scale_wait_for_progress(1000), 850, "境界超えでランプ適用")
