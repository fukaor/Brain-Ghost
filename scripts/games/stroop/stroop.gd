## Stroop
##
## 色文字ストループのゲームロジック (BaseGame サブクラス)。
## 仕様: docs/ideas/games/ghost-stroop-showdown-spec.md v1.1。
##
## ## 統一操作原則 (spec §2-2)
## 「画面中央の色を答える」— 刺激タイプ (Congruent / Incongruent / Shape) に関係なく
## 表示色 = display_color が常に正解。
##
## ## タイム系ゲーム
## is_time_based = true。プレイ中ゴーストバーは View 側で線形近似表示。
##
## ## スコア
## _on_finish() で `max(0, correct*100 - wrong*50) * tier_mult` を log.score に設定 (flash_calc パターン)。
## ScoreSystem は precomputed_score をパススルー。
##
## ## MVP 範囲
## T1〜T3 をコードでサポート。起動時はティア選択 UI が無いため T1 固定。
class_name Stroop
extends BaseGame

const _TierConfig = preload("res://scripts/games/stroop/tier_config.gd")
const _Generator = preload("res://scripts/games/stroop/stimulus_generator.gd")

const DEFAULT_TIER: String = "T1"
const GAME_DURATION_SEC: float = 30.0
const ANSWER_TIMEOUT_MS: int = 3000

# --- 状態 ---

var _tier: String = DEFAULT_TIER
var _stimuli: Array = []
var _current_index: int = 0
var _correct_count: int = 0
var _wrong_count: int = 0
var _stimulus_start_ms: int = 0
var _is_finished: bool = false
var _final_score: int = 0


# ---------------------------------------------------------------------------
# BaseGame オーバーライド
# ---------------------------------------------------------------------------

func _on_setup(seed_value: int) -> void:
    game_type = "stroop"
    is_time_based = true
    _tier = _resolve_tier()
    _current_index = 0
    _correct_count = 0
    _wrong_count = 0
    _is_finished = false
    _final_score = 0

    var generator := _Generator.new()
    # 2 段階生成: ティア非依存プール → ティア別比率フィルタリング
    var pool: Array = generator.generate_pool(seed_value)
    _stimuli = generator.select_for_tier(pool, _tier)


func _on_start() -> void:
    _stimulus_start_ms = Time.get_ticks_msec()
    record_event("session_start", 0.0)


func _on_user_input(input: Dictionary) -> void:
    var t := String(input.get("type", ""))
    match t:
        "answer":
            _handle_answer(String(input.get("color", "")))
        "answer_timeout":
            _handle_answer_timeout()
        "time_over":
            _handle_time_over()


# flash_calc.gd と同パターン: _on_finish() で log.score を完成する。
# GameManager は precomputed_score 方式でパススルー。
func _on_finish() -> PlayLog:
    _final_score = _compute_score()
    var log: PlayLog = super._on_finish()
    log.game_type = "stroop"
    log.score = _final_score
    return log


# ---------------------------------------------------------------------------
# 公開 API
# ---------------------------------------------------------------------------

func get_tier() -> String:
    return _tier


func get_current_index() -> int:
    return _current_index


func get_current_stimulus() -> Dictionary:
    if _current_index < _stimuli.size():
        return _stimuli[_current_index]
    return {}


func get_correct_count() -> int:
    return _correct_count


func get_wrong_count() -> int:
    return _wrong_count


func get_total_stimuli() -> int:
    return _stimuli.size()


func get_final_score() -> int:
    return _final_score


func notify_stimulus_presented() -> void:
    _stimulus_start_ms = Time.get_ticks_msec()


# ---------------------------------------------------------------------------
# 内部
# ---------------------------------------------------------------------------

func _resolve_tier() -> String:
    # GameManager._current_tier を優先 (v1.1 でティア選択 UI 追加時の互換性)。
    # MVP はティア選択 UI が無いため "" を返し、フォールバックで T1。
    var main_loop := Engine.get_main_loop()
    if main_loop == null:
        return DEFAULT_TIER
    var gm: Node = main_loop.root.get_node_or_null("GameManager")
    if gm != null:
        var t: String = String(gm._current_tier)
        if t == "T1" or t == "T2" or t == "T3":
            return t
    return DEFAULT_TIER


func _handle_answer(color: String) -> void:
    if _is_finished or _current_index >= _stimuli.size():
        return
    var stim: Dictionary = _stimuli[_current_index]
    var is_correct: bool = (color == String(stim.get("correct_answer", "")))
    var reaction_ms: int = Time.get_ticks_msec() - _stimulus_start_ms
    if is_correct:
        _correct_count += 1
        record_event("stroop_correct", float(reaction_ms))
    else:
        _wrong_count += 1
        record_event("stroop_wrong", float(reaction_ms))
    _advance_or_finish()


func _handle_answer_timeout() -> void:
    if _is_finished or _current_index >= _stimuli.size():
        return
    record_event("stroop_timeout", float(ANSWER_TIMEOUT_MS))
    _advance_or_finish()


func _handle_time_over() -> void:
    if _is_finished:
        return
    _is_finished = true
    record_event("session_end", float(_correct_count))
    finish()


func _advance_or_finish() -> void:
    _current_index += 1
    var elapsed_sec: float = float(get_elapsed_ms()) / 1000.0
    if elapsed_sec >= GAME_DURATION_SEC or _current_index >= _stimuli.size():
        _is_finished = true
        record_event("session_end", float(_correct_count))
        finish()


func _compute_score() -> int:
    var net: int = _correct_count * 100 - _wrong_count * 50
    if net <= 0:
        return 0
    var mult: float = _TierConfig.get_score_mult(_tier)
    return int(round(float(net) * mult))
