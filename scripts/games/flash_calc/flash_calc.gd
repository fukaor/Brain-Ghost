## FlashCalc
##
## ゴースト一本勝負・計算編 のゲームロジック (BaseGame サブクラス)。
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md v1.3。
##
## ## 役割分担
## - 本クラス: 問題状態 / 入力受付 / 判定 / スコア計算 / PlayLog event 記録
## - View (flash_calc_play_view.gd): UI 状態マシン (pre_announce → flash → input → result) と Timer/Tween 演出
##
## View は本クラスのインスタンスを child として保持し、各フェーズで以下を呼ぶ:
## - setup_with_tier(tier, seed) で問題生成
## - start() でセッション開始
## - notify_flash_started() / notify_flash_completed() / notify_input_started() で状態通知
## - submit_answer(value) で入力確定 → 判定 → スコア記録
## - timeout() で CD バーゼロ時の TIME_LOSE 判定
## - finish() で PlayLog 確定
class_name FlashCalc
extends BaseGame

const _Tier = preload("res://scripts/games/flash_calc/tier_config.gd")
const _Generator = preload("res://scripts/games/flash_calc/problem_generator.gd")

## 判定種別
enum Verdict {
    PERFECT,    # 正解 + ゴーストより 30% 以上早い
    GREAT,      # 正解 + ゴーストより 10% 以上早い
    WIN,        # 正解 + ゴーストより早い
    DRAW,       # 正解だが ±100ms 差
    TIME_LOSE,  # 正解だがゴーストより遅い / CD ゼロ
    WRONG,      # 不正解
}

## 状態
var _tier: String = ""
var _problem: Dictionary = {}
var _ghost_delta_ms: int = 0
var _current_input: String = ""
var _flash_completed_at_ms: int = -1   # フラッシュ終了の絶対時刻 (Time.get_ticks_msec)
var _response_time_ms: int = -1
var _verdict: int = Verdict.WRONG
var _is_won: bool = false
var _final_score: int = 0


# ---------------------------------------------------------------------------
# セットアップ / 開始
# ---------------------------------------------------------------------------

func _on_setup(seed_value: int) -> void:
    game_type = "flash_calc"
    is_time_based = false  # 入力中のゴースト CD バーは View 側で扱う
    _current_input = ""
    _flash_completed_at_ms = -1
    _response_time_ms = -1
    _verdict = Verdict.WRONG
    _is_won = false
    _final_score = 0


## View がティアを確定したら呼ぶ。問題生成 + ゴースト Δt 取得 + tier イベント記録。
func setup_with_tier(tier: String, seed_value: int) -> void:
    _tier = tier
    setup(seed_value)
    _problem = _Generator.generate(tier, seed_value)
    _ghost_delta_ms = FlashCalcGhostStore.get_delta_for_tier(tier)


# ---------------------------------------------------------------------------
# View からの状態通知 (event 記録用)
# ---------------------------------------------------------------------------

func notify_tier_started() -> void:
    record_event("tier", float(_Tier.tier_to_index(_tier)))


func notify_flash_completed() -> void:
    _flash_completed_at_ms = Time.get_ticks_msec()
    record_event("flash_completed", float(get_elapsed_ms()))


# ---------------------------------------------------------------------------
# 入力受付
# ---------------------------------------------------------------------------

func _on_user_input(input: Dictionary) -> void:
    var t: String = String(input.get("type", ""))
    match t:
        "digit":
            _append_digit(int(input.get("value", 0)))
        "backspace":
            _backspace()
        "submit":
            _submit()
        "timeout":
            _handle_timeout()


func _append_digit(d: int) -> void:
    var max_digits: int = int(_problem.get("max_answer_digits", 2))
    if _current_input.length() >= max_digits:
        return
    if _current_input == "" and d == 0:
        # 先頭 0 は許容しない (00 等を防ぐ)
        return
    _current_input += str(d)
    # 最大桁に達したら自動確定 (仕様 §3-3)
    if _current_input.length() >= max_digits:
        _submit()


func _backspace() -> void:
    if _current_input.length() > 0:
        _current_input = _current_input.substr(0, _current_input.length() - 1)


func _submit() -> void:
    if _current_input == "":
        return
    if _flash_completed_at_ms < 0:
        push_warning("[FlashCalc] _submit before flash completed")
        return
    var ans: int = int(_current_input)
    _response_time_ms = Time.get_ticks_msec() - _flash_completed_at_ms
    var correct: bool = (ans == int(_problem.get("answer", -1)))
    record_event("answer_submitted", float(_response_time_ms))
    _judge(correct)
    finish()


func _handle_timeout() -> void:
    # ゴースト CD バーがゼロになった時に View から呼ばれる
    _response_time_ms = _ghost_delta_ms
    record_event("answer_submitted", float(_response_time_ms))
    _verdict = Verdict.TIME_LOSE
    _is_won = false
    _record_match_result()
    finish()


# ---------------------------------------------------------------------------
# 判定 / スコア
# ---------------------------------------------------------------------------

func _judge(correct: bool) -> void:
    if not correct:
        _verdict = Verdict.WRONG
        _is_won = false
        _record_match_result()
        return
    # 正解時: ゴースト Δt との比較
    var diff_ms: int = _ghost_delta_ms - _response_time_ms
    var ratio: float = float(_response_time_ms) / float(max(_ghost_delta_ms, 1))
    if absi(diff_ms) <= 100:
        _verdict = Verdict.DRAW
        _is_won = true  # 同タイは引き分け勝ち扱い (ベスト更新可能)
    elif diff_ms > 0:
        # ゴーストより早い
        if ratio <= 0.7:
            _verdict = Verdict.PERFECT
        elif ratio <= 0.9:
            _verdict = Verdict.GREAT
        else:
            _verdict = Verdict.WIN
        _is_won = true
    else:
        _verdict = Verdict.TIME_LOSE
        _is_won = false
    _record_match_result()


func _record_match_result() -> void:
    record_event("match_result", 1.0 if _is_won else 0.0)
    _final_score = _compute_score()


## v1.3 スコア式:
##   勝利: max(0, ghost_delta_ms - response_time_ms) + WIN_BONUS = base
##   不正解 / TIME_LOSE: 0
##   最終: round(base * tier_score_mult)
func _compute_score() -> int:
    const WIN_BONUS: int = 500
    if not _is_won:
        return 0
    var cfg: Dictionary = _Tier.TIER_CONFIGS.get(_tier, {})
    var mult: float = float(cfg.get("score_mult", 1.0))
    var base: int = max(0, _ghost_delta_ms - _response_time_ms) + WIN_BONUS
    return int(round(float(base) * mult))


# ---------------------------------------------------------------------------
# 終了
# ---------------------------------------------------------------------------

func _on_finish() -> PlayLog:
    var log := PlayLog.new()
    log.game_type = game_type
    log.duration_ms = get_elapsed_ms()
    log.events = events
    log.score = _final_score
    return log


# ---------------------------------------------------------------------------
# View 用 getter
# ---------------------------------------------------------------------------

func get_tier() -> String:
    return _tier


func get_problem() -> Dictionary:
    return _problem


func get_ghost_delta_ms() -> int:
    return _ghost_delta_ms


func get_current_input() -> String:
    return _current_input


func get_verdict() -> int:
    return _verdict


func get_is_won() -> bool:
    return _is_won


func get_final_score() -> int:
    return _final_score


func get_response_time_ms() -> int:
    return _response_time_ms
