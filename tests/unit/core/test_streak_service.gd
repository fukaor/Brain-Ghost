## GUT test for StreakService
##
## docs/functional-design.md A-06 の全分岐を網羅する。
extends "res://addons/gut/test.gd"

var svc: StreakService

func before_each() -> void:
    svc = StreakService.new()

func after_each() -> void:
    if is_instance_valid(svc):
        svc.queue_free()

func test_first_play_sets_streak_to_1():
    var s := StreakState.new()
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 1)
    assert_eq(result.last_played_date, "2026-04-10")
    assert_true(result.welcome_back_shown, "初回は復帰演出を出さない")

func test_next_day_increments():
    var s := StreakState.new()
    s.current_streak = 3
    s.last_played_date = "2026-04-09"
    s.welcome_back_shown = true
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 4)
    assert_true(result.welcome_back_shown, "翌日プレイでは復帰演出フラグは変更しない")

func test_same_day_no_change():
    var s := StreakState.new()
    s.current_streak = 5
    s.last_played_date = "2026-04-10"
    s.welcome_back_shown = true
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 5, "同日再プレイは変動なし")

func test_7_day_gap_maintains_streak():
    var s := StreakState.new()
    s.current_streak = 5
    s.last_played_date = "2026-04-03"
    s.welcome_back_shown = true
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 6, "7日空きはストリーク維持+1")
    assert_false(result.welcome_back_shown, "7日空きで復帰演出フラグが立つ")

func test_2_day_gap_maintains_streak():
    var s := StreakState.new()
    s.current_streak = 3
    s.last_played_date = "2026-04-08"
    s.welcome_back_shown = true
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 4, "2日空きもストリーク維持+1")
    assert_false(result.welcome_back_shown)

func test_8_day_gap_resets():
    var s := StreakState.new()
    s.current_streak = 10
    s.last_played_date = "2026-04-02"
    s.welcome_back_shown = true
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.current_streak, 1, "8日空きでリセット")
    assert_true(result.welcome_back_shown, "リセット時は復帰演出を出さない")

func test_longest_streak_is_updated():
    var s := StreakState.new()
    s.current_streak = 3
    s.longest_streak = 3
    s.last_played_date = "2026-04-09"
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.longest_streak, 4, "新しい最高値に更新される")

func test_stamped_dates_accumulated():
    var s := StreakState.new()
    s.stamped_dates = ["2026-04-09"]
    s.last_played_date = "2026-04-09"
    s.current_streak = 1
    var result: StreakState = svc.update_streak(s, "2026-04-10")
    assert_eq(result.stamped_dates.size(), 2)
    assert_true(result.stamped_dates.has("2026-04-10"))
