## GUT test for DataStore high-level API
##
## Autoload インスタンスの DataStore を使い、
## append_play_log / load_play_logs / load_best / update_best_if_better の挙動を検証する。
##
## [b]注意:[/b] 各テストの前に DataStore.clear() で PLAY_LOGS と GAME_BESTS を初期化する。
## native ファイル (`user://*.json`) をテスト環境で消すため、テスト終了後の状態は不定。
extends "res://addons/gut/test.gd"


func before_each() -> void:
    DataStore.clear(DataStore.StoreKey.PLAY_LOGS)
    DataStore.clear(DataStore.StoreKey.GAME_BESTS)


func after_each() -> void:
    DataStore.clear(DataStore.StoreKey.PLAY_LOGS)
    DataStore.clear(DataStore.StoreKey.GAME_BESTS)


# --- save / load ラウンドトリップ ---

func test_save_load_roundtrip():
    var data: Dictionary = {"hello": "world", "n": 42}
    var ok: bool = DataStore.save(DataStore.StoreKey.USER_CONFIG, data)
    assert_true(ok, "save returns true")
    var loaded: Dictionary = DataStore.load_dict(DataStore.StoreKey.USER_CONFIG)
    assert_eq(loaded.get("hello"), "world")
    assert_eq(int(loaded.get("n")), 42)
    DataStore.clear(DataStore.StoreKey.USER_CONFIG)


# --- append_play_log ---

func test_append_play_log_empty_state():
    var log := _make_log("reflex_tap", 1000)
    var ok: bool = DataStore.append_play_log(log)
    assert_true(ok)
    var logs: Array = DataStore.load_play_logs()
    assert_eq(logs.size(), 1)
    assert_eq(logs[0].score, 1000)


func test_append_play_log_multiple():
    DataStore.append_play_log(_make_log("reflex_tap", 800))
    DataStore.append_play_log(_make_log("reflex_tap", 900))
    DataStore.append_play_log(_make_log("flash_calc", 1500))
    var logs: Array = DataStore.load_play_logs()
    assert_eq(logs.size(), 3, "全件保存")
    # 順序は append 順
    assert_eq(logs[0].score, 800)
    assert_eq(logs[1].score, 900)
    assert_eq(logs[2].score, 1500)


# --- load_play_logs ---

func test_load_play_logs_filter_by_game():
    DataStore.append_play_log(_make_log("reflex_tap", 800))
    DataStore.append_play_log(_make_log("flash_calc", 1500))
    DataStore.append_play_log(_make_log("reflex_tap", 900))
    var reflex_logs: Array = DataStore.load_play_logs("reflex_tap")
    assert_eq(reflex_logs.size(), 2)
    var flash_logs: Array = DataStore.load_play_logs("flash_calc")
    assert_eq(flash_logs.size(), 1)
    var unknown: Array = DataStore.load_play_logs("unknown")
    assert_eq(unknown.size(), 0)


func test_load_play_logs_with_limit():
    for i in range(5):
        DataStore.append_play_log(_make_log("reflex_tap", 100 + i))
    var limited: Array = DataStore.load_play_logs("reflex_tap", 3)
    assert_eq(limited.size(), 3)
    # limit は末尾 N 件を返す（直近 N 件の意味）
    assert_eq(limited[0].score, 102)
    assert_eq(limited[2].score, 104)


# --- count_play_logs ---

func test_count_play_logs():
    assert_eq(DataStore.count_play_logs(), 0, "初期は 0")
    DataStore.append_play_log(_make_log("reflex_tap", 100))
    DataStore.append_play_log(_make_log("flash_calc", 200))
    DataStore.append_play_log(_make_log("reflex_tap", 300))
    assert_eq(DataStore.count_play_logs(), 3)
    assert_eq(DataStore.count_play_logs("reflex_tap"), 2)
    assert_eq(DataStore.count_play_logs("flash_calc"), 1)


# --- load_best ---

func test_load_best_when_missing():
    var best: GameBest = DataStore.load_best("reflex_tap")
    assert_not_null(best)
    assert_eq(best.best_score, 0)
    assert_eq(best.game_type, "reflex_tap")


# --- update_best_if_better ---

func test_update_best_if_better_new_record():
    var log := _make_log("reflex_tap", 1000)
    log.id = "log-id-1"
    var updated: bool = DataStore.update_best_if_better(log)
    assert_true(updated)
    var best: GameBest = DataStore.load_best("reflex_tap")
    assert_eq(best.best_score, 1000)
    assert_eq(best.best_play_log_id, "log-id-1")


func test_update_best_if_better_same_score():
    var first := _make_log("reflex_tap", 500)
    DataStore.update_best_if_better(first)
    var second := _make_log("reflex_tap", 500)
    var updated: bool = DataStore.update_best_if_better(second)
    assert_false(updated, "同スコアでは false")


func test_update_best_if_better_lower_score():
    DataStore.update_best_if_better(_make_log("reflex_tap", 1000))
    var lower := _make_log("reflex_tap", 800)
    var updated: bool = DataStore.update_best_if_better(lower)
    assert_false(updated)
    assert_eq(DataStore.load_best("reflex_tap").best_score, 1000, "更新されない")


func test_load_best_after_update_per_game():
    DataStore.update_best_if_better(_make_log("reflex_tap", 1000))
    DataStore.update_best_if_better(_make_log("flash_calc", 2000))
    DataStore.update_best_if_better(_make_log("reflex_tap", 1500))
    assert_eq(DataStore.load_best("reflex_tap").best_score, 1500)
    assert_eq(DataStore.load_best("flash_calc").best_score, 2000)


# --- ヘルパー ---

func _make_log(game_type: String, score: int) -> PlayLog:
    var log := PlayLog.new()
    log.game_type = game_type
    log.score = score
    log.id = "test-id"
    log.played_at = "2026-04-12T10:00:00"
    log.played_date = "2026-04-12"
    log.mode = "free"
    return log
