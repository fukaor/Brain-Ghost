## Brain Boost — Smoke Test Runner
##
## GUT が配置されていない状況でも、環境構築の健全性を即座に検証するためのスモークテスト。
##
## 実行方法:
##   godot --headless --path /workspace --script tools/smoke_test.gd --quit
##
## GUT プラグインを addons/gut/ に配置した後は、tests/unit/ 配下の GUT テストに移行する。
extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []

func _init() -> void:
    print("=== Brain Boost Smoke Test ===")
    _run_all()
    print("---")
    print("Passed: %d, Failed: %d" % [_passed, _failed])
    if _failed > 0:
        for msg in _failures:
            print("  FAIL: %s" % msg)
        quit(1)
    else:
        print("All smoke tests passed.")
        quit(0)

func _run_all() -> void:
    _test_date_util()
    _test_daily_seed()
    _test_streak_service()
    _test_score_system()
    _test_platform()
    _test_uuid()
    _test_models_roundtrip()

# --- DateUtil ---

func _test_date_util() -> void:
    _assert_eq(DateUtil.days_between("2026-04-03", "2026-04-10"), 7, "date_util: 7-day diff")
    _assert_eq(DateUtil.days_between("2026-04-09", "2026-04-10"), 1, "date_util: 1-day diff")
    _assert_eq(DateUtil.days_between("2026-04-10", "2026-04-10"), 0, "date_util: same day")
    _assert_eq(DateUtil.days_between("2026-04-02", "2026-04-10"), 8, "date_util: 8-day diff")
    _assert_eq(DateUtil.days_between("2025-12-31", "2026-01-01"), 1, "date_util: year boundary")
    _assert_eq(DateUtil.days_between("2024-02-28", "2024-03-01"), 2, "date_util: leap year boundary")
    _assert_eq(DateUtil.date_string_to_seed("2026-04-15"), 20260415, "date_util: seed")

# --- DailySeed ---

func _test_daily_seed() -> void:
    var ds := DailySeed.new()
    var games1: Array[String] = ds.get_daily_games(20260415)
    var games2: Array[String] = ds.get_daily_games(20260415)
    _assert_eq(games1.size(), 3, "daily_seed: 3 games selected")
    _assert(games1 == games2, "daily_seed: deterministic for same seed")

    var games_different: Array[String] = ds.get_daily_games(20260416)
    _assert(games1 != games_different or games_different.size() == 3, "daily_seed: different seeds may differ")

    # 全選出ゲームが ALL_GAMES に含まれているか
    for g in games1:
        _assert(DailySeed.ALL_GAMES.has(g), "daily_seed: selected game %s is in ALL_GAMES" % g)
    # 重複がないか
    _assert_eq(games1.size(), {games1[0]: 1, games1[1]: 1, games1[2]: 1}.size(), "daily_seed: no duplicates")

    ds.queue_free()

# --- StreakService ---

func _test_streak_service() -> void:
    var ss := StreakService.new()

    # 初回プレイ
    var s0 := StreakState.new()
    var s1: StreakState = ss.update_streak(s0, "2026-04-10")
    _assert_eq(s1.current_streak, 1, "streak: first play -> 1")
    _assert_eq(s1.welcome_back_shown, true, "streak: first play -> welcome_back_shown=true")

    # 翌日プレイ
    var s2: StreakState = ss.update_streak(s1, "2026-04-11")
    _assert_eq(s2.current_streak, 2, "streak: next day -> +1")
    _assert_eq(s2.welcome_back_shown, true, "streak: next day -> welcome_back_shown unchanged")

    # 同日再プレイ
    var s3: StreakState = ss.update_streak(s2, "2026-04-11")
    _assert_eq(s3.current_streak, 2, "streak: same day -> unchanged")

    # 7 日空き（維持）
    var s4 := StreakState.new()
    s4.current_streak = 5
    s4.last_played_date = "2026-04-03"
    s4.welcome_back_shown = true
    var s5: StreakState = ss.update_streak(s4, "2026-04-10")
    _assert_eq(s5.current_streak, 6, "streak: 7-day gap -> maintained (+1)")
    _assert_eq(s5.welcome_back_shown, false, "streak: 7-day gap -> trigger welcome back")

    # 8 日空き（リセット）
    var s6 := StreakState.new()
    s6.current_streak = 10
    s6.last_played_date = "2026-04-02"
    s6.welcome_back_shown = true
    var s7: StreakState = ss.update_streak(s6, "2026-04-10")
    _assert_eq(s7.current_streak, 1, "streak: 8-day gap -> reset to 1")
    _assert_eq(s7.welcome_back_shown, true, "streak: 8-day gap -> no welcome back")

    ss.queue_free()

# --- ScoreSystem ---

func _test_score_system() -> void:
    var ss := ScoreSystem.new()

    # フラッシュ暗算: 10 問正解 + 残り 5 秒 = 1050
    _assert_eq(ss.calculate_score("flash_calc", {"correct_count": 10, "remaining_sec": 5}), 1050, "score: flash_calc")

    # 反射タップ: 平均 300ms = (1000/300)*300 = 1000
    _assert_eq(ss.calculate_score("reflex_tap", {"average_reaction_ms": 300.0}), 1000, "score: reflex_tap normal")

    # 反射タップ: 上限
    _assert_eq(ss.calculate_score("reflex_tap", {"average_reaction_ms": 100.0}), 1500, "score: reflex_tap capped at 1500")

    # ストループ: 10 正解 - 2 誤答 = 900
    _assert_eq(ss.calculate_score("stroop", {"correct_count": 10, "incorrect_count": 2}), 900, "score: stroop")

    # 数字さがし: 20 秒でクリア = 3000 - 2000 = 1000
    _assert_eq(ss.calculate_score("number_search", {"clear_time_sec": 20}), 1000, "score: number_search")

    # 未知のゲーム
    _assert_eq(ss.calculate_score("unknown_game", {}), 0, "score: unknown game -> 0")

    # 脳年齢（決定論的テストのため RNG を固定）
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    # total_score=0, age_group="30s", first_play=false -> 40 歳
    _assert_eq(ss.calculate_brain_age(0, "30s", false, rng), 40, "brain_age: 0 score @ 30s")
    rng.seed = 12345
    # total_score=17000, age_group="30s", first_play=false -> 20 歳
    _assert_eq(ss.calculate_brain_age(17000, "30s", false, rng), 20, "brain_age: max score @ 30s")
    rng.seed = 12345
    # 負のスコアでもクランプ
    var brain_age_negative := ss.calculate_brain_age(-1000, "30s", false, rng)
    _assert_eq(brain_age_negative, 40, "brain_age: negative score clamped")

    # 10代で高スコア + 初回補正で最低 10 歳を保つか
    rng.seed = 12345
    var brain_age_10s := ss.calculate_brain_age(17000, "10s", true, rng)
    _assert(brain_age_10s >= 10, "brain_age: 10s with first_play >= 10")

    # 精度計算
    _assert_eq(ss.calculate_accuracy([]), 0.0, "accuracy: empty -> 0.0")
    _assert_eq(ss.calculate_accuracy(["reflex_tap", "flash_calc", "stroop"]), 0.5, "accuracy: 3/6 -> 0.5")
    _assert_eq(ss.calculate_accuracy(["reflex_tap", "flash_calc", "number_search", "stroop", "sequence_memory", "card_match"]), 1.0, "accuracy: 6/6 -> 1.0")
    _assert_eq(ss.calculate_accuracy(["reflex_tap", "reflex_tap", "flash_calc"]), float(2) / float(6), "accuracy: duplicates deduplicated")

    # 能力軸マッピング
    _assert_eq(ss.get_ability("flash_calc"), "calculation", "ability: flash_calc -> calculation")
    _assert_eq(ss.get_ability("card_match"), "judgment", "ability: card_match -> judgment")
    _assert_eq(ss.get_ability("unknown"), "", "ability: unknown -> empty")

    ss.queue_free()

# --- Platform ---

func _test_platform() -> void:
    # Autoload として読めるか（スモークテストでは SceneTree レベルのため Platform singleton は未初期化）
    # そのため直接インスタンス化して確認する
    var p_script: GDScript = load("res://scripts/autoload/platform.gd")
    var p: Node = p_script.new()
    var current: int = p.current()
    _assert(current >= 0 and current <= 2, "platform: current() returns valid enum")
    _assert_eq(p.storage_strategy() in ["localStorage", "user_dir"], true, "platform: storage_strategy returns valid value")
    p.queue_free()

# --- Uuid ---

func _test_uuid() -> void:
    var u1 := UuidUtil.v4()
    var u2 := UuidUtil.v4()
    _assert_eq(u1.length(), 36, "uuid: length == 36")
    _assert(u1.contains("-"), "uuid: contains dashes")
    _assert(u1 != u2, "uuid: two calls produce different values")
    # バージョン 4 マーカー
    _assert_eq(u1[14], "4", "uuid: version marker is 4")

# --- Model roundtrip ---

func _test_models_roundtrip() -> void:
    # UserConfig
    var uc := UserConfig.new()
    uc.age_group = "30s"
    uc.bgm_enabled = false
    uc.onboarding_completed = true
    var uc_dict: Dictionary = uc.to_dict()
    var uc2: UserConfig = UserConfig.from_dict(uc_dict)
    _assert_eq(uc2.age_group, "30s", "user_config: roundtrip age_group")
    _assert_eq(uc2.bgm_enabled, false, "user_config: roundtrip bgm_enabled")
    _assert_eq(uc2.onboarding_completed, true, "user_config: roundtrip onboarding_completed")

    # PlayLog with events
    var pl := PlayLog.new()
    pl.id = "abc-123"
    pl.game_type = "reflex_tap"
    pl.score = 1200
    var ev := PlayEvent.new()
    ev.time_ms = 2300
    ev.event_type = "correct"
    pl.events.append(ev)
    var pl_dict: Dictionary = pl.to_dict()
    var pl2: PlayLog = PlayLog.from_dict(pl_dict)
    _assert_eq(pl2.id, "abc-123", "play_log: roundtrip id")
    _assert_eq(pl2.events.size(), 1, "play_log: roundtrip events count")
    _assert_eq(pl2.events[0].event_type, "correct", "play_log: roundtrip event_type")

    # StreakState clone
    var ss := StreakState.new()
    ss.current_streak = 5
    ss.last_played_date = "2026-04-10"
    ss.stamped_dates = ["2026-04-08", "2026-04-09", "2026-04-10"]
    var clone: StreakState = ss.clone()
    _assert_eq(clone.current_streak, 5, "streak_state: clone current_streak")
    _assert_eq(clone.stamped_dates.size(), 3, "streak_state: clone stamped_dates count")

# --- Assertion helpers ---

func _assert(condition: bool, message: String) -> void:
    if condition:
        _passed += 1
        print("  [OK] %s" % message)
    else:
        _failed += 1
        _failures.append(message)
        print("  [FAIL] %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual == expected:
        _passed += 1
        print("  [OK] %s" % message)
    else:
        _failed += 1
        var detail := "%s (expected: %s, actual: %s)" % [message, str(expected), str(actual)]
        _failures.append(detail)
        print("  [FAIL] %s" % detail)
