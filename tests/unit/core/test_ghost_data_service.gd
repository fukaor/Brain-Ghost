## GUT test for GhostData autoload service
##
## save_play / load_round_medians / get_play_count の挙動を検証。
## DataStore の GHOST_CACHE キーを実際に読み書きするので、
## before_each で clear() してクリーンな状態から始める。
extends "res://addons/gut/test.gd"

const GAME_TYPE: String = "test_ghost_7ban_shobu_gut"


func before_each() -> void:
    DataStore.clear(DataStore.StoreKey.GHOST_CACHE)


func after_each() -> void:
    DataStore.clear(DataStore.StoreKey.GHOST_CACHE)


func test_load_round_medians_returns_fallback_when_empty() -> void:
    var medians: Array[int] = GhostData.load_round_medians(GAME_TYPE)
    assert_eq(medians.size(), 7, "常に 7 要素を返す")
    for v in medians:
        assert_eq(v, GhostData.FALLBACK_DELTA_MS, "初回は 273ms フォールバック")


func test_save_play_and_load_round_medians_single_play() -> void:
    var deltas: Array = [100, 110, 120, 130, 140, 150, 160]
    assert_true(GhostData.save_play(GAME_TYPE, deltas, 4))
    var medians: Array[int] = GhostData.load_round_medians(GAME_TYPE)
    # 1 プレイの場合、各ラウンドの中央値はその値そのもの
    for i in range(7):
        assert_eq(medians[i], deltas[i], "R%d median == single value" % i)


func test_load_round_medians_3_plays() -> void:
    GhostData.save_play(GAME_TYPE, [100, 100, 100, 100, 100, 100, 100], 7)
    GhostData.save_play(GAME_TYPE, [200, 200, 200, 200, 200, 200, 200], 7)
    GhostData.save_play(GAME_TYPE, [300, 300, 300, 300, 300, 300, 300], 7)
    var medians: Array[int] = GhostData.load_round_medians(GAME_TYPE)
    for i in range(7):
        assert_eq(medians[i], 200, "中央 3 個中の中央値は 200")


func test_save_play_rejects_wrong_round_count() -> void:
    assert_false(GhostData.save_play(GAME_TYPE, [100, 100, 100], 1), "7 件でなければ拒否")
    assert_eq(GhostData.get_play_count(GAME_TYPE), 0)


func test_save_play_keeps_only_last_5() -> void:
    for i in range(7):
        var delta_value: int = 100 + i * 10
        GhostData.save_play(GAME_TYPE, [delta_value, delta_value, delta_value, delta_value, delta_value, delta_value, delta_value], 3)
    assert_eq(GhostData.get_play_count(GAME_TYPE), GhostData.RECENT_PLAY_WINDOW, "5 件までしか保持しない")


func test_get_play_count_empty() -> void:
    assert_eq(GhostData.get_play_count(GAME_TYPE), 0)
    assert_eq(GhostData.get_play_count(""), 0)
