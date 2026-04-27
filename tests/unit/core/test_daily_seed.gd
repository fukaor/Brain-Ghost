## GUT test for DailySeed
##
## 実行方法: GUT プラグイン配置後に Godot Editor または CLI から実行
##   godot --headless -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/unit/core/test_daily_seed.gd
extends "res://addons/gut/test.gd"

var ds: DailySeed

func before_each() -> void:
    ds = DailySeed.new()

func after_each() -> void:
    if is_instance_valid(ds):
        ds.queue_free()

func test_get_daily_seed_from_dict():
    var seed_value: int = ds.get_daily_seed({"year": 2026, "month": 4, "day": 15})
    assert_eq(seed_value, 20260415)

func test_get_daily_games_returns_3_games():
    var games: Array[String] = ds.get_daily_games(20260415)
    assert_eq(games.size(), 3)

func test_get_daily_games_is_deterministic():
    var games1: Array[String] = ds.get_daily_games(20260415)
    var games2: Array[String] = ds.get_daily_games(20260415)
    assert_eq(games1, games2, "同じシードなら全く同じ結果を返すこと")

func test_get_daily_games_all_in_all_games():
    var games: Array[String] = ds.get_daily_games(20260415)
    for g in games:
        assert_true(DailySeed.ALL_GAMES.has(g), "選出されたゲームは ALL_GAMES に含まれる: " + g)

func test_get_daily_games_no_duplicates():
    var games: Array[String] = ds.get_daily_games(20260415)
    var unique: Dictionary = {}
    for g in games:
        unique[g] = true
    assert_eq(unique.size(), 3, "重複なし")

func test_get_daily_games_different_seeds_may_differ():
    # 決定的に「違う」とは限らないが、複数のシードで同じ結果になる確率は低い
    var games_a: Array[String] = ds.get_daily_games(20260415)
    var games_b: Array[String] = ds.get_daily_games(20260420)
    var games_c: Array[String] = ds.get_daily_games(20260501)
    # 3 つ全てが完全に一致することはほぼないと仮定
    var all_same := (games_a == games_b and games_b == games_c)
    assert_false(all_same, "異なるシードで結果が分散すること")
