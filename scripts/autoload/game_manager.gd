## GameManager
##
## アプリ全体のライフサイクル管理、プレイモード（daily/free/onboarding）の保持、
## シーン遷移の調停を担う Autoload（最上位のコーディネーター）。
##
## Week 1 段階: free モードでのミニゲーム単体プレイをサポート (反射タップ / フラッシュ暗算)。
## デイリーチャレンジ・オンボーディング・他ゲームは Week 2 以降。
##
## [b]ゲーム種別の追加方法:[/b]
## 1. `GAME_SCENES` Dictionary に game_type → tscn パスを追加
## 2. `_build_play_data_for(log)` に game_type ごとの ScoreSystem 入力構築を追加
extends Node

## game_type → シーンパスのマッピング。新ゲーム追加時はここに 1 行追加するだけ。
const GAME_SCENES: Dictionary = {
    "reflex_tap": "res://scenes/games/reflex_tap.tscn",
    "flash_calc": "res://scenes/games/flash_calc.tscn",
    "sequence_memory": "res://scenes/games/sequence_memory.tscn",
}

enum PlayMode { NONE, ONBOARDING, DAILY, FREE }

signal onboarding_started
signal onboarding_completed
signal daily_challenge_started(game_types: Array)
signal game_started(game_type: String)
signal game_finished(play_log)       # PlayLog
signal overall_result_ready(logs: Array)

var current_mode: int = PlayMode.NONE
var current_game_index: int = 0
var current_session_logs: Array = []  # 今回のセッションの PlayLog 配列

# --- 反射タップフロー用の状態 (Week 1 で追加) ---

## 現在進行中のゲームタイプ ("reflex_tap" など)
var _current_game_type: String = ""
## 直近の PlayLog (個別結果画面で参照)
var _current_play_log: PlayLog = null
## 直近の前回スコア (個別結果画面で前回比表示に使用)
var _previous_score: int = 0


# --- ライフサイクル ---

func start_onboarding() -> void:
    current_mode = PlayMode.ONBOARDING
    current_game_index = 0
    current_session_logs = []
    onboarding_started.emit()
    # TODO: scenes/main/onboarding.tscn に遷移

func start_daily_challenge() -> void:
    current_mode = PlayMode.DAILY
    current_game_index = 0
    current_session_logs = []
    # TODO: DailySeed 経由で 3 種決定、最初のゲーム開始

func start_free_game(game_type: String) -> void:
    current_mode = PlayMode.FREE
    current_game_index = 0
    current_session_logs = []
    game_started.emit(game_type)
    # TODO: scenes/games/{game_type}.tscn に遷移

# --- ゲーム完了時 ---

func on_game_finished(play_log) -> void:
    current_session_logs.append(play_log)
    game_finished.emit(play_log)
    # TODO: DataStore に保存、次のゲーム or 結果画面へ遷移

# --- 進捗 ---

func get_progress_percent() -> int:
    if current_session_logs.is_empty():
        return 0
    match current_mode:
        PlayMode.ONBOARDING:
            return int(current_session_logs.size() * 100 / 6)
        PlayMode.DAILY:
            return int(current_session_logs.size() * 100 / 3)
        _:
            return 0


# --- 反射タップフロー (Week 1 で追加) ---

## ジェネリックなゲーム単体プレイ開始。home → rule_explain へ遷移。
## 新ゲーム追加時は GAME_SCENES に登録すれば本メソッドだけでフローが組める。
func start_game(game_type: String) -> void:
    if not GAME_SCENES.has(game_type):
        push_error("[GameManager] start_game: unknown game_type %s" % game_type)
        _safe_change_scene("res://scenes/main/home.tscn")
        return
    _current_game_type = game_type
    current_mode = PlayMode.FREE
    _previous_score = DataStore.load_best(game_type).best_score
    _safe_change_scene("res://scenes/ui/rule_explain.tscn")


## 後方互換: 反射タップ専用ラッパ。新規呼び出しは start_game("reflex_tap") を推奨。
func start_reflex_tap(_mode: String = "free") -> void:
    start_game("reflex_tap")


## ルール説明画面の [スタート] / [スキップ] が押された
func on_rule_explain_confirmed() -> void:
    _safe_change_scene("res://scenes/ui/countdown.tscn")


## ルール説明画面の [← 戻る] が押された (やっぱり別のゲームをやりたい場合)
func on_rule_explain_cancelled() -> void:
    _current_game_type = ""
    _previous_score = 0
    _safe_change_scene("res://scenes/main/home.tscn")


## カウントダウン完了 → _current_game_type のシーンへ動的遷移
func on_countdown_finished() -> void:
    var scene_path: String = String(GAME_SCENES.get(_current_game_type, ""))
    if scene_path == "":
        push_error("[GameManager] on_countdown_finished: no scene for %s" % _current_game_type)
        _safe_change_scene("res://scenes/main/home.tscn")
        return
    _safe_change_scene(scene_path)


## 任意のゲーム終了時に呼ばれる汎用ハンドラ。<game>_view から呼ぶ。
## log.game_type を見て ScoreSystem 入力を構築 → 保存 → 個別結果画面へ。
func on_game_finished_handler(log) -> void:
    if log == null:
        push_warning("[GameManager] on_game_finished_handler received null log")
        _safe_change_scene("res://scenes/main/home.tscn")
        return

    # PlayLog のフィールドを完全に埋める
    log.id = UuidUtil.v4()
    log.played_at = Time.get_datetime_string_from_system(true)
    log.played_date = DateUtil.today_jst()
    log.mode = "free"

    # スコア計算: log.events 等から ScoreSystem 入力を構築
    var play_data: Dictionary = _build_play_data_for(log)
    var score_sys := ScoreSystem.new()
    log.score = score_sys.calculate_score(log.game_type, play_data)
    score_sys.queue_free()

    # ベスト判定 + 保存を DataStore.update_best_if_better に委譲
    log.is_new_best = DataStore.update_best_if_better(log)

    # PlayLog 自体の保存（履歴）
    DataStore.append_play_log(log)

    _current_play_log = log
    current_session_logs.append(log)

    _safe_change_scene("res://scenes/ui/individual_result.tscn")


## 後方互換: 反射タップ専用ハンドラ。新規呼び出しは on_game_finished_handler を推奨。
func on_reflex_tap_finished(log) -> void:
    on_game_finished_handler(log)


## 個別結果画面の [もう一度] が押された
func on_individual_result_replay() -> void:
    start_game(_current_game_type)


## 個別結果画面の [ホームへ] が押された
func on_individual_result_home() -> void:
    _safe_change_scene("res://scenes/main/home.tscn")


## game_type ごとの ScoreSystem 入力構築。新ゲーム追加時はここに分岐を追加する。
func _build_play_data_for(log) -> Dictionary:
    match log.game_type:
        "reflex_tap":
            var avg_ms: float = _compute_avg_reaction_ms(log)
            return {"average_reaction_ms": avg_ms}
        "flash_calc":
            var correct: int = _count_events_of_type(log, "correct")
            var remaining: int = _extract_remaining_sec(log)
            return {"correct_count": correct, "remaining_sec": remaining}
        "sequence_memory":
            var max_level: int = _extract_max_level(log)
            return {"max_reached_level": max_level}
        _:
            push_warning("[GameManager] _build_play_data_for: unknown game_type %s" % log.game_type)
            return {}


func _count_events_of_type(log, event_type: String) -> int:
    if log == null or log.events == null:
        return 0
    var count: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == event_type:
            count += 1
    return count


## flash_calc の終了時イベント "session_end" の value に remaining_sec を入れる契約
func _extract_remaining_sec(log) -> int:
    if log == null or log.events == null:
        return 0
    for evt in log.events:
        if evt != null and evt.event_type == "session_end":
            return int(evt.value)
    return 0


## sequence_memory の level_cleared イベントの最大値を取得
func _extract_max_level(log) -> int:
    if log == null or log.events == null:
        return 0
    var max_level: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == "level_cleared":
            max_level = max(max_level, int(evt.value))
    return max_level


# --- ヘルパー ---

func _safe_change_scene(path: String) -> void:
    var err: int = get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("[GameManager] change_scene failed: %s (err=%d)" % [path, err])
        get_tree().change_scene_to_file("res://scenes/main/home.tscn")


func _compute_avg_reaction_ms(log) -> float:
    if log == null or log.events == null or log.events.is_empty():
        return 0.0
    var total: float = 0.0
    var count: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == "target_tapped":
            total += float(evt.value)
            count += 1
    if count == 0:
        return 0.0
    return total / float(count)


## DEPRECATED: 残置のみ。新規呼び出しは DataStore.load_best を直接使うこと。
func _load_previous_score(game_type: String) -> int:
    return DataStore.load_best(game_type).best_score


## DEPRECATED: 残置のみ。新規呼び出しは DataStore.append_play_log を直接使うこと。
func _save_play_log(log) -> void:
    DataStore.append_play_log(log)
