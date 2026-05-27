## Ghost7BanShobu
##
## ゴースト7番勝負ゲームロジック（docs/ideas/games/ghost-7ban-shobu-spec.md v1.0）。
##
## [b]ルール:[/b]
## - 7 ラウンド連続。各ラウンドでターゲットが画面端から中央の GHOST LINE に向かって移動
## - プレイヤーはラインを通過した瞬間にタップ（Δt = タップ時刻 − ライン通過時刻）
## - 各ラウンドの Δt を GhostData.load_round_medians() と比較して勝敗判定
## - 7 ラウンド終了で game_finished を発火、GhostData.save_play に Δt 配列と勝利数を保存
##
## [b]判定段階（spec §2-2 / variant-b.jsx classifyDelta）:[/b]
## - FLYING:  ライン通過前 80ms より早いタップ or 予告中タップ (delta=999, ラウンド敗北)
## - MISS:    ライン通過後 1000ms 無反応 (delta=1000, ラウンド敗北)
## - PERFECT: |delta| ≤ 50ms
## - GREAT:   ≤ 150ms
## - GOOD:    ≤ 300ms
## - LATE:    > 300ms
##
## [b]勝敗:[/b] !is_fly && player_delta < ghost_delta → プレイヤー勝利
##
## [b]スコア:[/b] (1000 / 中央5発平均ms) × 300 + 勝利数 × 50
##
## [b]フェーズ:[/b]
## ready → countdown → announce → moving → result → (次ラウンド or done)
##
## [b]決定論性:[/b] rng と Time.get_ticks_msec() のみ使用。
## デイリーシード時は CFG_BASE にジッタを加えてラウンド設定を生成。
class_name Ghost7BanShobu
extends BaseGame

# ---------------------------------------------------------------------------
# 定数（variant-b.jsx から移植）
# ---------------------------------------------------------------------------

## 7 ラウンド固定
const TOTAL_ROUNDS: int = 7

## CFG_B — 基礎値。ラウンドごとの {move, pre, shape, dir}。
##
## 2026-05-02 仕様変更（Sumi Ghost (墨絵調) / 1 レーン正面衝突）:
## - YOU 左→右、GHOST 右→左 で固定。`dir` は互換のため残すが view 側では未使用
## - `shape` を追加: "line"/"s_curve"/"sine_wave"/"zigzag"/"arc" でラウンドごとローテ
##
## move: ターゲット移動時間 (ms)
## pre:  予告フェーズ長 (ms) = announce 時間
## shape: レーン形状（LaneShapes.SHAPES のいずれか）
## dir:   旧 2 レーン互換用（"left"/"right"）。新規ロジックは無視。
const CFG_BASE: Array[Dictionary] = [
    {"move": 2200, "pre": 1500, "shape": "line",       "dir": "left"},
    {"move": 2000, "pre": 1200, "shape": "s_curve",    "dir": "right"},
    {"move": 1500, "pre": 1000, "shape": "sine_wave",  "dir": "left"},
    {"move": 1200, "pre":  900, "shape": "zigzag",     "dir": "right"},
    {"move": 1000, "pre":  800, "shape": "arc",        "dir": "left"},
    {"move":  900, "pre":  700, "shape": "line",       "dir": "right"},
    {"move":  900, "pre": 1000, "shape": "s_curve",    "dir": "left"},
]

## classifyDelta しきい値 (ms) — variant-b.jsx からそのまま移植
const FLYING_EARLY_THRESHOLD_MS: int = 80  # signed < -80 → FLYING
const MISS_TIMEOUT_MS: int = 1000
const PERFECT_MAX_MS: int = 50
const GREAT_MAX_MS: int = 150
const GOOD_MAX_MS: int = 300

const FLYING_RECORDED_MS: int = 999
const MISS_RECORDED_MS: int = 1000

## スコア算出 (spec §5-3)
const WIN_BONUS_PER_ROUND: int = 50
const REACTION_SCORE_COEFFICIENT: float = 300.0

## ゴースト Δt 初期値（GhostData 側でも同値）
const FALLBACK_GHOST_DELTA_MS: int = 273

# ---------------------------------------------------------------------------
# 状態
# ---------------------------------------------------------------------------

var _rounds_config: Array[Dictionary] = []      # 今回プレイの 7 ラウンド設定
var _ghost_deltas_ms: Array[int] = []           # GhostData.load_round_medians の結果
var _round_index: int = 0
var _phase: String = "ready"                    # ready/countdown/announce/moving/result/done
var _round_results: Array[Dictionary] = []      # 各ラウンド結果 {delta, ghost, grade, win}
var _wins: int = 0
var _ghost_wins: int = 0

## ラウンド内タイミング（Time.get_ticks_msec ベース）
var _move_start_ms: int = 0
var _line_pass_ms: int = 0

# ---------------------------------------------------------------------------
# BaseGame ライフサイクル
# ---------------------------------------------------------------------------

func _on_setup(seed_value: int) -> void:
    game_type = "ghost_7ban_shobu"
    is_time_based = false  # クリア系扱い（プレイ中ゴーストバー非表示）
    _round_index = 0
    _phase = "ready"
    _round_results = []
    _wins = 0
    _ghost_wins = 0
    _move_start_ms = 0
    _line_pass_ms = 0

    # ラウンド設定の生成（デイリーシード対応）
    _rounds_config = generate_rounds(seed_value)

    # ゴースト Δt の取得（シーンツリーに入っている時のみ Autoload にアクセス）
    _ghost_deltas_ms = []
    var svc: Node = null
    if is_inside_tree():
        svc = get_node_or_null("/root/GhostData")
    if svc != null and svc.has_method("load_round_medians"):
        _ghost_deltas_ms = svc.load_round_medians(game_type)
    if _ghost_deltas_ms.size() != TOTAL_ROUNDS:
        _ghost_deltas_ms = []
        for _i in range(TOTAL_ROUNDS):
            _ghost_deltas_ms.append(FALLBACK_GHOST_DELTA_MS)


func _on_start() -> void:
    _phase = "ready"  # ビュー側が startRound(0) 起動までの演出を握る


# ---------------------------------------------------------------------------
# ラウンド制御（ビュー側から呼び出し）
# ---------------------------------------------------------------------------

## ビュー側が各ラウンドの移動フェーズ開始時にタイムスタンプを通知する。
## line_pass_ms は move_start_ms + cfg.move / 2 で計算される（variant-b.jsx 準拠）。
func notify_moving_started(round_index: int, now_ms: int) -> void:
    if round_index < 0 or round_index >= TOTAL_ROUNDS:
        return
    _round_index = round_index
    _phase = "moving"
    _move_start_ms = now_ms
    var cfg: Dictionary = _rounds_config[round_index]
    _line_pass_ms = now_ms + int(cfg.move) / 2
    record_event("moving_started", float(round_index))


## ビュー側が announce フェーズに入ったことを通知する。
func notify_announce_started(round_index: int) -> void:
    _round_index = round_index
    _phase = "announce"
    record_event("announce_started", float(round_index))


## ラウンド結果を通知する（ビュー側が result フェーズに入るときに呼ぶ）。
func notify_result_shown(round_index: int) -> void:
    _round_index = round_index
    _phase = "result"


## プレイヤーがタップしたとき。タップ時の now_ms と現在フェーズで判定する。
## 戻り値: そのラウンドの結果 Dictionary（grade, delta, ghost, win, signed_ms）
func resolve_tap(now_ms: int) -> Dictionary:
    if _round_index < 0 or _round_index >= TOTAL_ROUNDS:
        return {}
    var ghost_ms: int = _ghost_deltas_ms[_round_index] if _round_index < _ghost_deltas_ms.size() else FALLBACK_GHOST_DELTA_MS
    var result: Dictionary

    if _phase == "announce":
        result = _make_flying(ghost_ms)
    elif _phase == "moving":
        var signed_ms: int = now_ms - _line_pass_ms
        if signed_ms < -FLYING_EARLY_THRESHOLD_MS:
            result = _make_flying(ghost_ms)
        else:
            var delta_ms: int = int(abs(signed_ms))
            var grade: String = classify_delta(delta_ms, false)
            var is_win: bool = delta_ms < ghost_ms
            result = {
                "delta": delta_ms,
                "ghost": ghost_ms,
                "grade": grade,
                "win": is_win,
                "signed_ms": signed_ms,
                "is_fly": false,
                "is_miss": false,
            }
    else:
        return {}

    _commit_round_result(result)
    return result


## ラウンドがタイムアウトしたときに呼ぶ（ライン通過後 MISS_TIMEOUT_MS 無反応）。
func resolve_miss() -> Dictionary:
    if _round_index < 0 or _round_index >= TOTAL_ROUNDS:
        return {}
    var ghost_ms: int = _ghost_deltas_ms[_round_index] if _round_index < _ghost_deltas_ms.size() else FALLBACK_GHOST_DELTA_MS
    var result: Dictionary = {
        "delta": MISS_RECORDED_MS,
        "ghost": ghost_ms,
        "grade": "MISS",
        "win": false,
        "signed_ms": MISS_RECORDED_MS,
        "is_fly": false,
        "is_miss": true,
    }
    _commit_round_result(result)
    return result


## 全 7 ラウンド終了を宣言し、GhostData.save_play を呼んで finish() を発火する。
func finalize_game() -> void:
    if _round_results.size() < TOTAL_ROUNDS:
        push_warning("[Ghost7BanShobu] finalize_game: only %d/%d rounds recorded" % [_round_results.size(), TOTAL_ROUNDS])
    _phase = "done"

    var deltas: Array = []
    for r in _round_results:
        deltas.append(int(r.get("delta", MISS_RECORDED_MS)))

    if is_inside_tree():
        var svc: Node = get_node_or_null("/root/GhostData")
        if svc != null and svc.has_method("save_play"):
            svc.save_play(game_type, deltas, _wins)

    finish()


# ---------------------------------------------------------------------------
# スコア・判定ロジック（純粋関数・テスト対象）
# ---------------------------------------------------------------------------

## variant-b.jsx の classifyDelta をそのまま移植。
## delta_ms は絶対値、is_flying=true は早すぎフライング扱い。
static func classify_delta(delta_ms: int, is_flying: bool) -> String:
    if is_flying:
        return "FLYING"
    if delta_ms >= MISS_RECORDED_MS:
        return "MISS"
    if delta_ms <= PERFECT_MAX_MS:
        return "PERFECT"
    if delta_ms <= GREAT_MAX_MS:
        return "GREAT"
    if delta_ms <= GOOD_MAX_MS:
        return "GOOD"
    return "LATE"


## 中央 5 発平均 + 勝利ボーナスの総合スコア (spec §5)。
## deltas_ms が 7 要素未満でも動作するが、spec では常に 7 を前提。
static func calculate_total_score(deltas_ms: Array, wins: int) -> int:
    if deltas_ms.is_empty():
        return 0
    var sorted: Array = deltas_ms.duplicate()
    sorted.sort()
    var slice_from: int = 1 if sorted.size() > 2 else 0
    var slice_to: int = sorted.size() - 1 if sorted.size() > 2 else sorted.size()
    var middle: Array = sorted.slice(slice_from, slice_to)
    if middle.is_empty():
        return 0
    var total: float = 0.0
    for v in middle:
        total += float(v)
    var avg_ms: float = total / float(middle.size())
    if avg_ms <= 0.0:
        return 0
    var reaction_score: int = int(round((1000.0 / avg_ms) * REACTION_SCORE_COEFFICIENT))
    var duel_bonus: int = wins * WIN_BONUS_PER_ROUND
    return max(0, reaction_score + duel_bonus)


## デイリーシード対応のラウンド設定生成。
## seed_value = -1 なら CFG_BASE をそのまま返す（手順書: JSX 定数をそのまま移植）。
## seed_value >= 0 なら ±10% move / ±20% pre のジッタを加える（spec §8）。
## dir はジッタの対象外（方向はラウンドごとの設計通りに保つ）。
static func generate_rounds(seed_value: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if seed_value < 0:
        for cfg in CFG_BASE:
            result.append(cfg.duplicate(true))
        return result

    var local_rng := RandomNumberGenerator.new()
    local_rng.seed = seed_value
    for cfg in CFG_BASE:
        var move_base: int = int(cfg.move)
        var pre_base: int = int(cfg.pre)
        var move_jitter: float = local_rng.randf_range(-0.10, 0.10)
        var pre_jitter: float = local_rng.randf_range(-0.20, 0.20)
        result.append({
            "move":  max(400, int(round(move_base * (1.0 + move_jitter)))),
            "pre":   max(400, int(round(pre_base  * (1.0 + pre_jitter)))),
            "shape": String(cfg.get("shape", "line")),
            "dir":   String(cfg.get("dir", "left")),
        })
    return result


# ---------------------------------------------------------------------------
# getter
# ---------------------------------------------------------------------------

func get_rounds_config() -> Array[Dictionary]:
    return _rounds_config

func get_ghost_deltas() -> Array[int]:
    return _ghost_deltas_ms

func get_round_results() -> Array[Dictionary]:
    return _round_results

func get_wins() -> int:
    return _wins

func get_ghost_wins() -> int:
    return _ghost_wins

func get_current_round_index() -> int:
    return _round_index

func get_phase() -> String:
    return _phase

func get_line_pass_ms() -> int:
    return _line_pass_ms

func get_move_start_ms() -> int:
    return _move_start_ms

func get_total_rounds() -> int:
    return TOTAL_ROUNDS


# ---------------------------------------------------------------------------
# 内部
# ---------------------------------------------------------------------------

func _make_flying(ghost_ms: int) -> Dictionary:
    return {
        "delta": FLYING_RECORDED_MS,
        "ghost": ghost_ms,
        "grade": "FLYING",
        "win": false,
        "signed_ms": -FLYING_RECORDED_MS,
        "is_fly": true,
        "is_miss": false,
    }


func _commit_round_result(result: Dictionary) -> void:
    _round_results.append(result)
    if bool(result.get("win", false)):
        _wins += 1
    else:
        _ghost_wins += 1
    record_event("round_result", float(int(result.get("delta", MISS_RECORDED_MS))))
    record_event("round_win", 1.0 if bool(result.get("win", false)) else 0.0)
    _phase = "result"


func _on_finish() -> PlayLog:
    var log := super._on_finish()
    log.game_type = "ghost_7ban_shobu"
    return log
