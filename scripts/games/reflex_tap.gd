## ReflexTap
##
## 反射タップゲームのロジック本体。
## GDD §4-4 / PRD FR-01 / functional-design A-01 準拠。
##
## [b]ルール:[/b]
## - 画面のランダム位置に円形ターゲットが出現する
## - ユーザはできるだけ速くタップする
## - 合計 20 回タップでゲーム終了
## - 3〜5 回に 1 回フェイクターゲット（別色）が混入する。タップするとペナルティ
## - 最終スコアは `ScoreSystem.calculate_score("reflex_tap", {"average_reaction_ms": X})` で算出
##
## [b]ビジュアル層との分離:[/b]
## 本クラスは純粋なロジッククラスで、位置計算・反応時間記録・ペナルティ適用を担う。
## 実際のターゲットノードの表示・タップ検知は [code]scripts/ui/reflex_tap_view.gd[/code] が行う。
##
## [b]決定論性:[/b]
## `BaseGame.rng` (setup 時にシード設定) のみを使用し、`Array.shuffle()` など
## グローバル乱数依存の API は使わない（全ユーザ共通のデイリーチャレンジで再現性を保証）。
class_name ReflexTap
extends BaseGame

# --- 定数 ---

const TARGET_COUNT: int = 20
const SCREEN_MARGIN_PX: int = 40
const TARGET_SIZE_MIN: int = 80
const TARGET_SIZE_MAX: int = 120
const WAIT_MS_MIN: int = 400
const WAIT_MS_MAX: int = 1200
const FAKE_INTERVAL_MIN: int = 3
const FAKE_INTERVAL_MAX: int = 5
const FAKE_PENALTY_MS: int = 50
## フェイクが自動消滅するまでの時間 (ms)。
## ユーザはこの時間を過ぎるまで何もしなければよい (タップ NG の仕様)。
const FAKE_VISIBLE_MS: int = 1500

# --- 状態 ---

var _tapped_count: int = 0
var _fake_tapped_count: int = 0
var _reaction_times_ms: Array[int] = []
var _current_target_shown_time: int = -1
var _current_is_fake: bool = false
var _next_fake_at: int = 3


# --- BaseGame ライフサイクルフック ---

func _on_setup(_seed_value: int) -> void:
    game_type = "reflex_tap"
    is_time_based = true
    _tapped_count = 0
    _fake_tapped_count = 0
    _reaction_times_ms = []
    _current_target_shown_time = -1
    _current_is_fake = false
    # setup 時点で rng がセットされているので、最初のフェイク境界を決める
    _next_fake_at = rng.randi_range(FAKE_INTERVAL_MIN, FAKE_INTERVAL_MAX)


func _on_start() -> void:
    # ゲーム開始時の追加処理なし。シーン側（reflex_tap_view）が最初のターゲットを出す。
    pass


func _on_user_input(input: Dictionary) -> void:
    var input_type := String(input.get("type", ""))
    if input_type == "target_tap":
        _handle_target_tap()
    elif input_type == "fake_tap":
        _handle_fake_tap()


func _on_finish() -> PlayLog:
    var log := super._on_finish()
    # score と id 等は GameManager 側で埋める
    log.game_type = "reflex_tap"
    return log


# --- Public API（シーン側から呼ぶ） ---

## ターゲット表示時に呼び、反応時間計測の基準点を記録する
func mark_target_shown(is_fake: bool) -> void:
    _current_target_shown_time = get_elapsed_ms()
    _current_is_fake = is_fake
    var evt_type: String = "fake_shown" if is_fake else "target_shown"
    record_event(evt_type, float(_current_target_shown_time))


## 次に出すターゲットのサイズを決定する（決定論）
func pick_target_size() -> int:
    return rng.randi_range(TARGET_SIZE_MIN, TARGET_SIZE_MAX)


## 次に出すターゲットまでの待機時間を決定する（決定論）
func pick_wait_ms() -> int:
    return rng.randi_range(WAIT_MS_MIN, WAIT_MS_MAX)


## 次の 1 手がフェイクであるべきか判定する
##
## 「次にタップされる予定の番号」 (= _tapped_count + 1) が _next_fake_at に到達したら true。
## フェイクを出したら [code]_advance_fake_schedule()[/code] を呼んで次の境界に進めること。
func should_show_fake() -> bool:
    return (_tapped_count + 1) >= _next_fake_at


## フェイクを 1 回使ったあとに次のフェイク境界を進める
func advance_fake_schedule() -> void:
    _next_fake_at = _tapped_count + 1 + rng.randi_range(FAKE_INTERVAL_MIN, FAKE_INTERVAL_MAX)


## ターゲットの配置位置を viewport 内のマージンを考慮して決定する（決定論）
##
## 返り値は Control ノードの position（top-left 基準）。実際のサイズは
## [code]pick_target_size()[/code] で別途決定される前提。本関数はマージン内に
## 完全に収まる top-left 座標を返す。
func generate_target_position(viewport_size: Vector2i) -> Vector2:
    var size := pick_target_size()
    var max_x: int = viewport_size.x - SCREEN_MARGIN_PX - size
    var max_y: int = viewport_size.y - SCREEN_MARGIN_PX - size
    # max_x/max_y が margin より小さくなるケース（極端に小さい viewport）は想定しない
    var x := rng.randi_range(SCREEN_MARGIN_PX, max_x)
    var y := rng.randi_range(SCREEN_MARGIN_PX, max_y)
    return Vector2(x, y)


## 平均反応時間を計算する（空時は 0.0、フェイクタップごとに +50ms ペナルティ）
func calculate_average_reaction_ms() -> float:
    if _reaction_times_ms.is_empty():
        return 0.0
    var total: int = 0
    for t in _reaction_times_ms:
        total += t
    var avg: float = float(total) / float(_reaction_times_ms.size())
    return avg + float(_fake_tapped_count * FAKE_PENALTY_MS)


## 現在のタップ数を取得する（HUD 表示用）
func get_tapped_count() -> int:
    return _tapped_count


## 総ターゲット数を取得する（HUD 表示用）
func get_total_count() -> int:
    return TARGET_COUNT


# --- Private ---

func _handle_target_tap() -> void:
    if _current_target_shown_time < 0:
        return  # ターゲット表示前の無効タップは無視
    var reaction: int = get_elapsed_ms() - _current_target_shown_time
    _reaction_times_ms.append(reaction)
    record_event("target_tapped", float(reaction))
    _tapped_count += 1
    _current_target_shown_time = -1
    if _tapped_count >= TARGET_COUNT:
        finish()


func _handle_fake_tap() -> void:
    _fake_tapped_count += 1
    record_event("fake_tapped", 1.0)
    _current_target_shown_time = -1
