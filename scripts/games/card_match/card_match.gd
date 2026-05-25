## CardMatch
##
## 神経衰弱ライトのゲームロジック (BaseGame サブクラス)。
## 仕様: docs/ideas/games/ghost-memory-match-lite-spec.md v1.1。
##
## ## カードの 3 状態 (spec §2-5)
## - face_down: 裏向き、タップ可能
## - face_up:   1 枚目として表向き中、再タップ無視
## - matched:   ペア成立済み、タップ無視
##
## ## View との連携シーケンス (pair_evaluated signal を経由する)
## 1. View が cell_tap を送る
## 2. ロジック: 1 枚目なら face_up 化、2 枚目なら判定 + pair_evaluated emit
## 3. View が一致/不一致の演出 (0.3 / 0.5 秒) を再生
## 4. View が match_resolved / mismatch_resolved 通知 → ロジックが状態更新
## 5. クリア達成なら finish()
##
## ## MVP 範囲
## T1 (4×4 / 8 ペア / 単色図形 / 60 秒) のみ。
class_name CardMatch
extends BaseGame

const _TierConfig = preload("res://scripts/games/card_match/tier_config.gd")
const _Generator = preload("res://scripts/games/card_match/card_generator.gd")

const DEFAULT_TIER: String = "T1"

# pair_evaluated は View 側のアニメ駆動用。is_match の真偽で 0.3s / 0.5s を分ける。
signal pair_evaluated(first_idx: int, second_idx: int, is_match: bool)

# --- 状態 ---

var _tier: String = DEFAULT_TIER
var _grid_data: Array[int] = []      # cell_index → card_id
var _is_face_up: Array = []           # cell_index → bool
var _is_matched: Array = []           # cell_index → bool
var _first_card_index: int = -1
var _total_taps: int = 0
var _pairs_found: int = 0
var _is_processing: bool = false      # pair_evaluated 発火後、match/mismatch_resolved 受領待ち
var _is_clear: bool = false


# ---------------------------------------------------------------------------
# BaseGame オーバーライド
# ---------------------------------------------------------------------------

func _on_setup(seed_value: int) -> void:
    game_type = "card_match"
    is_time_based = false
    _tier = DEFAULT_TIER  # MVP は T1 固定
    _first_card_index = -1
    _total_taps = 0
    _pairs_found = 0
    _is_processing = false
    _is_clear = false

    var generator := _Generator.new()
    _grid_data = generator.generate(_tier, seed_value)

    var n: int = _grid_data.size()
    _is_face_up = []
    _is_matched = []
    _is_face_up.resize(n)
    _is_matched.resize(n)
    for i in range(n):
        _is_face_up[i] = false
        _is_matched[i] = false


func _on_start() -> void:
    record_event("session_start", 0.0)


func _on_user_input(input: Dictionary) -> void:
    var t := String(input.get("type", ""))
    match t:
        "cell_tap":
            _handle_cell_tap(int(input.get("cell_index", -1)))
        "match_resolved":
            _resolve_match(int(input.get("first", -1)), int(input.get("second", -1)))
        "mismatch_resolved":
            _resolve_mismatch(int(input.get("first", -1)), int(input.get("second", -1)))


# NOTE: BaseGame 契約上、_on_finish() ではゲーム固有フィールド (events / duration_ms / game_type)
# のみ完成させる。log.id / log.score / log.mode / log.played_at / log.played_date / log.is_new_best
# は GameManager.on_game_finished_handler() が一括で埋める設計。
func _on_finish() -> PlayLog:
    var log: PlayLog = super._on_finish()
    log.game_type = "card_match"
    return log


# ---------------------------------------------------------------------------
# 公開 API
# ---------------------------------------------------------------------------

func get_tier() -> String:
    return _tier


func get_grid_data() -> Array[int]:
    return _grid_data


func get_total_pairs() -> int:
    return _TierConfig.get_pairs(_tier)


func get_total_cards() -> int:
    return _grid_data.size()


func get_total_taps() -> int:
    return _total_taps


func get_pairs_found() -> int:
    return _pairs_found


func get_time_limit_sec() -> float:
    return _TierConfig.get_time_limit(_tier)


func get_is_clear() -> bool:
    return _is_clear


func is_pair_processing() -> bool:
    return _is_processing


func get_clear_time_sec() -> float:
    return float(get_elapsed_ms()) / 1000.0


## 60 秒到達で View から呼ばれる。is_processing 中は View が _pending_timeout で保留。
func timeout() -> void:
    if not _is_active:
        return
    _is_clear = false
    record_event("timeout", float(_pairs_found))
    finish()


# ---------------------------------------------------------------------------
# 内部
# ---------------------------------------------------------------------------

func _can_tap(cell_index: int) -> bool:
    if _is_processing:
        return false
    if cell_index < 0 or cell_index >= _grid_data.size():
        return false
    if _is_face_up[cell_index] or _is_matched[cell_index]:
        return false
    return true


func _handle_cell_tap(cell_index: int) -> void:
    if not _can_tap(cell_index):
        return  # 再タップ / 処理中タップ / 範囲外は全て無視 (タップカウント加算なし)
    _total_taps += 1
    _is_face_up[cell_index] = true
    record_event("card_flipped", float(cell_index))
    if _first_card_index == -1:
        # 1 枚目
        _first_card_index = cell_index
        return
    # 2 枚目: ペア判定 → View へ通知 (View が演出後に resolved を返す)
    _is_processing = true
    var second: int = cell_index
    var is_match: bool = _grid_data[_first_card_index] == _grid_data[second]
    if is_match:
        record_event("pair_match", float(_grid_data[second]))
    else:
        record_event("pair_mismatch", float(_grid_data[second]))
    pair_evaluated.emit(_first_card_index, second, is_match)


func _resolve_match(a: int, b: int) -> void:
    if a < 0 or a >= _grid_data.size() or b < 0 or b >= _grid_data.size():
        _reset_selection()
        return
    _is_matched[a] = true
    _is_matched[b] = true
    _pairs_found += 1
    _reset_selection()
    if _pairs_found >= get_total_pairs():
        _is_clear = true
        record_event("clear", float(get_elapsed_ms()))
        finish()


func _resolve_mismatch(a: int, b: int) -> void:
    if 0 <= a and a < _grid_data.size():
        _is_face_up[a] = false
    if 0 <= b and b < _grid_data.size():
        _is_face_up[b] = false
    _reset_selection()


func _reset_selection() -> void:
    _first_card_index = -1
    _is_processing = false
