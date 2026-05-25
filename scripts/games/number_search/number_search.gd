## NumberSearch
##
## 数字さがしゲームロジック (BaseGame サブクラス)。
## 仕様: docs/ideas/games/ghost-number-search-spec.md v1.1。
##
## ## ルール
## - グリッドに 1〜N の数字がランダム配置される
## - プレイヤーは 1 から昇順にタップ
## - 正解: 緑ハイライト、次の対象に進む
## - 不正解: 何も起きない (miss_taps のみカウント)
## - クリア: N までタップ
## - タイムアウト: 制限時間到達でその時点の到達数字を記録
##
## ## クリア系ゲーム
## プレイ中ゴーストバー非表示 (GDD §5b)。
##
## ## MVP 範囲
## T3 (5×5 / 1〜25 / 60 秒 / 統一表示) のみ。
class_name NumberSearch
extends BaseGame

const _TierConfig = preload("res://scripts/games/number_search/tier_config.gd")
const _Generator = preload("res://scripts/games/number_search/grid_generator.gd")

const DEFAULT_TIER: String = "T3"

# --- 状態 ---

var _tier: String = DEFAULT_TIER
## cell_index (0..max-1) → 配置された数字 (1..max)
var _grid_numbers: Array[int] = []
var _current_target: int = 1
var _miss_taps: int = 0
var _is_clear: bool = false


# ---------------------------------------------------------------------------
# BaseGame オーバーライド
# ---------------------------------------------------------------------------

func _on_setup(seed_value: int) -> void:
    game_type = "number_search"
    is_time_based = false
    _tier = DEFAULT_TIER  # MVP は T3 固定 (v1.1 で TierManager 経由に変更予定)
    _current_target = 1
    _miss_taps = 0
    _is_clear = false
    var generator := _Generator.new()
    _grid_numbers = generator.generate(_tier, seed_value)


func _on_start() -> void:
    record_event("session_start", 0.0)


func _on_user_input(input: Dictionary) -> void:
    var t := String(input.get("type", ""))
    if t == "cell_tap":
        _handle_cell_tap(int(input.get("cell_index", -1)))


# NOTE: BaseGame 契約上、_on_finish() ではゲーム固有フィールド (events / duration_ms / game_type)
# のみ完成させる。log.id / log.score / log.mode / log.played_at / log.played_date / log.is_new_best
# は GameManager.on_game_finished_handler() が一括で埋める設計 (sequence_memory.gd と同パターン)。
func _on_finish() -> PlayLog:
    var log: PlayLog = super._on_finish()
    log.game_type = "number_search"
    return log


# ---------------------------------------------------------------------------
# 公開 API
# ---------------------------------------------------------------------------

## View 側 _process でタイムアウト検出時に呼ぶ。二重 finish はガード済み。
func timeout() -> void:
    if not _is_active:
        return
    _is_clear = false
    # NOTE: timeout イベントの value は到達数字 (= 正解タップした数)。秒ではない。
    # クリア時間は log.duration_ms / 1000 を使う。
    record_event("timeout", float(_current_target - 1))
    finish()


func get_tier() -> String:
    return _tier


func get_current_target() -> int:
    return _current_target


func get_grid_numbers() -> Array[int]:
    return _grid_numbers


func get_max_number() -> int:
    return _TierConfig.get_max_number(_tier)


func get_time_limit_sec() -> float:
    return _TierConfig.get_time_limit(_tier)


func get_miss_taps() -> int:
    return _miss_taps


func get_is_clear() -> bool:
    return _is_clear


func get_clear_time_sec() -> float:
    return float(get_elapsed_ms()) / 1000.0


# ---------------------------------------------------------------------------
# 内部
# ---------------------------------------------------------------------------

func _handle_cell_tap(cell_index: int) -> void:
    if cell_index < 0 or cell_index >= _grid_numbers.size():
        return
    var number: int = _grid_numbers[cell_index]
    if number != _current_target:
        _miss_taps += 1
        record_event("miss_tap", float(number))
        return
    record_event("correct_tap", float(number))
    _current_target += 1
    if _current_target > get_max_number():
        _is_clear = true
        record_event("clear", float(get_elapsed_ms()))
        finish()
