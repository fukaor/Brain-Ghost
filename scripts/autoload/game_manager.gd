## GameManager
##
## アプリ全体のライフサイクル管理、プレイモード（daily/free/onboarding）の保持、
## シーン遷移の調停を担う Autoload（最上位のコーディネーター）。
##
## MVP スタブ: シグナル定義とメソッドスケルトンのみ。
## 実装は Week 1-3 でインクリメンタルに肉付けする。
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
