## GameManager
##
## アプリ全体のライフサイクル管理、プレイモード（daily/free/onboarding）の保持、
## シーン遷移の調停を担う Autoload（最上位のコーディネーター）。
##
## Week 1 段階: free モードで反射タップ単体プレイをサポート。
## デイリーチャレンジ・オンボーディング・他ゲームは Week 2 以降。
extends Node

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

## 反射タップ単体プレイを開始する。home → rule_explain へ遷移
func start_reflex_tap(_mode: String = "free") -> void:
    _current_game_type = "reflex_tap"
    current_mode = PlayMode.FREE
    _safe_change_scene("res://scenes/ui/rule_explain.tscn")


## ルール説明画面の [スタート] / [スキップ] が押された
func on_rule_explain_confirmed() -> void:
    _safe_change_scene("res://scenes/ui/countdown.tscn")


## カウントダウン完了
func on_countdown_finished() -> void:
    _safe_change_scene("res://scenes/games/reflex_tap.tscn")


## 反射タップゲーム終了 (reflex_tap_view から呼ばれる)
func on_reflex_tap_finished(log) -> void:
    if log == null:
        push_warning("[GameManager] on_reflex_tap_finished received null log")
        _safe_change_scene("res://scenes/main/home.tscn")
        return

    # PlayLog のフィールドを完全に埋める
    log.id = UuidUtil.v4()
    log.played_at = Time.get_datetime_string_from_system(true)
    log.played_date = DateUtil.today_jst()
    log.mode = "free"
    log.game_type = "reflex_tap"

    # スコア計算: events から平均反応時間を取得して ScoreSystem で算出
    var avg_ms: float = _compute_avg_reaction_ms(log)
    var score_sys := ScoreSystem.new()
    log.score = score_sys.calculate_score("reflex_tap", {"average_reaction_ms": avg_ms})
    score_sys.queue_free()

    # ベスト判定 (Week 1 はスタブ: 前回スコアは 0)
    _previous_score = _load_previous_score("reflex_tap")
    log.is_new_best = log.score > _previous_score

    # DataStore へ保存 (Week 1 はスタブ: 失敗しても warning のみ)
    _save_play_log(log)

    _current_play_log = log
    current_session_logs.append(log)

    _safe_change_scene("res://scenes/ui/individual_result.tscn")


## 個別結果画面の [もう一度] が押された
func on_individual_result_replay() -> void:
    start_reflex_tap(_current_game_type)


## 個別結果画面の [ホームへ] が押された
func on_individual_result_home() -> void:
    _safe_change_scene("res://scenes/main/home.tscn")


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


func _load_previous_score(_game_type: String) -> int:
    # TODO: DataStore.load_dict(GAME_BESTS) から取得する。Week 1 はスタブ
    return 0


func _save_play_log(_log) -> void:
    # TODO: DataStore.load_dict(PLAY_LOGS) → append → save する。Week 1 はスタブ
    # 現状はログ出力のみ
    print("[GameManager] PlayLog (stub save): score=%d, game_type=%s" % [_log.score, _log.game_type])
