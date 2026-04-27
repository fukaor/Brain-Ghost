## GUT test for FlashCalc
##
## フラッシュ暗算ロジックの決定論性・問題生成範囲・正誤判定の検証。
extends "res://addons/gut/test.gd"

var game: FlashCalc


func before_each() -> void:
    game = FlashCalc.new()
    game.setup(54321)
    game.start()  # _is_active = true に必要 (handle_input が無視されないため)


func after_each() -> void:
    if is_instance_valid(game):
        game.queue_free()


# --- 初期化 ---

func test_setup_initializes_state():
    assert_eq(game.game_type, "flash_calc")
    assert_true(game.is_time_based)
    assert_eq(game.get_correct_count(), 0)
    assert_eq(game.get_current_index(), 0)


# --- 決定論性 ---

func test_deterministic_problems():
    var g1 := FlashCalc.new()
    var g2 := FlashCalc.new()
    g1.setup(54321)
    g2.setup(54321)
    for i in range(g1.TOTAL_PROBLEMS):
        assert_eq(g1.get_current_expected(), g2.get_current_expected(), "expected[%d] match" % i)
        assert_eq(g1.get_current_problem_text(), g2.get_current_problem_text(), "text[%d] match" % i)
        # 進める
        g1._handle_submit(g1.get_current_expected())
        g2._handle_submit(g2.get_current_expected())
    g1.queue_free()
    g2.queue_free()


# --- 問題生成範囲 ---

func test_problem_count_equals_total():
    assert_eq(game._problems.size(), game.TOTAL_PROBLEMS)
    assert_eq(game._expected_sums.size(), game.TOTAL_PROBLEMS)


func test_phase_1_problems_have_4_numbers():
    for i in range(FlashCalc.PHASE_1_END):
        assert_eq(game._problems[i].size(), FlashCalc.NUMBERS_PHASE_1, "phase1[%d]" % i)


func test_phase_2_problems_have_5_numbers():
    for i in range(FlashCalc.PHASE_1_END, FlashCalc.PHASE_2_END):
        assert_eq(game._problems[i].size(), FlashCalc.NUMBERS_PHASE_2, "phase2[%d]" % i)


func test_phase_3_problems_have_6_numbers():
    for i in range(FlashCalc.PHASE_2_END, FlashCalc.TOTAL_PROBLEMS):
        assert_eq(game._problems[i].size(), FlashCalc.NUMBERS_PHASE_3, "phase3[%d]" % i)


func test_each_number_in_range():
    for problem in game._problems:
        for n in problem:
            assert_true(n >= game.NUMBER_MIN, "n=%d >= MIN" % n)
            assert_true(n <= game.NUMBER_MAX, "n=%d <= MAX" % n)


func test_expected_sum_matches_numbers():
    for i in range(game._problems.size()):
        var sum: int = 0
        for n in game._problems[i]:
            sum += n
        assert_eq(game._expected_sums[i], sum, "sum mismatch at %d" % i)


# --- 正誤判定 ---

func test_correct_input_increments_count():
    var expected: int = game.get_current_expected()
    game.handle_input({"type": "submit", "answer": expected})
    assert_eq(game.get_correct_count(), 1)
    assert_eq(game.get_current_index(), 1, "次問題へ進む")


func test_wrong_input_no_increment_but_advances():
    var expected: int = game.get_current_expected()
    game.handle_input({"type": "submit", "answer": expected + 100})
    assert_eq(game.get_correct_count(), 0)
    assert_eq(game.get_current_index(), 1, "誤答でも次問題へ進む")


func test_complete_all_correct_finishes():
    # GDScript ラムダは値キャプチャなので Array でラップする
    var finished_flag := [false]
    game.game_finished.connect(func(_log): finished_flag[0] = true)
    for i in range(game.TOTAL_PROBLEMS):
        var expected: int = game.get_current_expected()
        game.handle_input({"type": "submit", "answer": expected})
    assert_true(finished_flag[0], "TOTAL_PROBLEMS 完了で finish")
    assert_eq(game.get_correct_count(), game.TOTAL_PROBLEMS)


# --- 問題テキスト ---

func test_problem_text_format_phase_1():
    # 初期状態は問題 0 = フェーズ 1 = 4 数字
    var text: String = game.get_current_problem_text()
    var parts: PackedStringArray = text.split(" + ")
    assert_eq(parts.size(), FlashCalc.NUMBERS_PHASE_1, "フェーズ 1 は 4 数字")
    for p in parts:
        var n: int = int(p)
        assert_true(n >= FlashCalc.NUMBER_MIN and n <= FlashCalc.NUMBER_MAX)


func test_problem_text_format_phase_3():
    # フェーズ 3 に進めて確認 (問題 12 以降)
    for i in range(FlashCalc.PHASE_2_END):
        game.handle_input({"type": "submit", "answer": game.get_current_expected()})
    var text: String = game.get_current_problem_text()
    var parts: PackedStringArray = text.split(" + ")
    assert_eq(parts.size(), FlashCalc.NUMBERS_PHASE_3, "フェーズ 3 は 6 数字")
