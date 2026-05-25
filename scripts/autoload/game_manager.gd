## GameManager
##
## アプリ全体のライフサイクル管理、プレイモード（daily/free/onboarding）の保持、
## シーン遷移の調停を担う Autoload（最上位のコーディネーター）。
##
## Week 1 段階: free モードでのミニゲーム単体プレイをサポート (フラッシュ暗算 / ゴースト7番勝負ほか)。
## デイリーチャレンジ・オンボーディング・他ゲームは Week 2 以降。
##
## [b]ゲーム種別の追加方法:[/b]
## 1. `GAME_SCENES` Dictionary に game_type → tscn パスを追加
## 2. `_build_play_data_for(log)` に game_type ごとの ScoreSystem 入力構築を追加
extends Node

## game_type → シーンパスのマッピング。新ゲーム追加時はここに 1 行追加するだけ。
const GAME_SCENES: Dictionary = {
    "flash_calc": "res://scenes/games/flash_calc/flash_calc_play.tscn",
    "sequence_memory": "res://scenes/games/sequence_memory.tscn",
    "ghost_7ban_shobu": "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn",
    "number_search": "res://scenes/games/number_search/number_search.tscn",
    "card_match": "res://scenes/games/card_match/card_match.tscn",
    "stroop": "res://scenes/games/stroop/stroop.tscn",
}

## 横画面で動作するゲーム種別。ここに登録すると rule_explain / countdown も横版を使う。
## 現状はゴースト 7 番勝負のみ横画面。
const LANDSCAPE_GAMES: Array = ["ghost_7ban_shobu"]

## ティア選択フェーズを持つゲーム。rule_explain の前に挟まれる。
## flash_calc は 8 ティアからユーザがティアを選ぶフェーズが必要 (仕様 §3-1)。
const TIER_SELECT_SCENES: Dictionary = {
    "flash_calc": "res://scenes/games/flash_calc/flash_calc_home.tscn",
}

## game_type の向き → rule_explain シーンパスマップ
const RULE_EXPLAIN_SCENES: Dictionary = {
    "portrait": "res://scenes/ui/rule_explain.tscn",
    "landscape": "res://scenes/ui/rule_explain_landscape.tscn",
}

## game_type の向き → countdown シーンパスマップ
const COUNTDOWN_SCENES: Dictionary = {
    "portrait": "res://scenes/ui/countdown.tscn",
    "landscape": "res://scenes/ui/countdown_landscape.tscn",
}


func _is_landscape_game(game_type: String) -> bool:
    return game_type in LANDSCAPE_GAMES


func _orientation_key(game_type: String) -> String:
    return "landscape" if _is_landscape_game(game_type) else "portrait"

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

# --- ゲーム単体プレイ用の状態 (Week 1 で追加) ---

## 現在進行中のゲームタイプ ("flash_calc" など)
var _current_game_type: String = ""
## 現在選択中のティア ("T1"〜"T8" 等)。ティア対応ゲーム以外では "" のまま。
var _current_tier: String = ""
## 直近の PlayLog (個別結果画面で参照)
var _current_play_log: PlayLog = null
## 直近の前回スコア (個別結果画面で前回比表示に使用)
var _previous_score: int = 0
## ルール説明画面の [← 戻る] で戻る先のシーン
var _entry_scene: String = "res://scenes/main/home.tscn"


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


# --- ジェネリックなゲーム単体プレイフロー (Week 1 で追加) ---

## ジェネリックなゲーム単体プレイ開始。home → (tier_select?) → rule_explain へ遷移。
## 新ゲーム追加時は GAME_SCENES に登録すれば本メソッドだけでフローが組める。
## ティア選択を持つゲーム (TIER_SELECT_SCENES) は rule_explain の前に tier_select を挟む。
func start_game(game_type: String) -> void:
    if not GAME_SCENES.has(game_type):
        push_error("[GameManager] start_game: unknown game_type %s" % game_type)
        _safe_change_scene("res://scenes/main/home.tscn")
        return
    _current_game_type = game_type
    _current_tier = ""
    current_mode = PlayMode.FREE
    _previous_score = DataStore.load_best(game_type).best_score
    if TIER_SELECT_SCENES.has(game_type):
        _safe_change_scene(String(TIER_SELECT_SCENES[game_type]))
    else:
        _safe_change_scene(RULE_EXPLAIN_SCENES[_orientation_key(game_type)])


## ティア選択画面で選択が確定したら呼び出す。rule_explain へ遷移。
func on_tier_selected(tier: String) -> void:
    _current_tier = tier
    _safe_change_scene(RULE_EXPLAIN_SCENES[_orientation_key(_current_game_type)])


## 現在選択中のティア (試合シーンから読む)。"" の場合はティア未選択。
func get_current_tier() -> String:
    return _current_tier


## ルール説明画面の [スタート] / [スキップ] が押された
func on_rule_explain_confirmed() -> void:
    _safe_change_scene(COUNTDOWN_SCENES[_orientation_key(_current_game_type)])


## ルール説明画面の [← 戻る] が押された (やっぱり別のゲームをやりたい場合)
func on_rule_explain_cancelled() -> void:
    _current_game_type = ""
    _previous_score = 0
    _safe_change_scene(_entry_scene)


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

    # ストリーク更新（連続プレイ日数 - StreakService は状態を返すだけなのでここで永続化）
    _update_streak_state(log.played_date)

    _current_play_log = log
    current_session_logs.append(log)

    _safe_change_scene("res://scenes/ui/individual_result.tscn")


## ストリーク状態を読み込み → StreakService で更新 → STREAK_STATE に保存。
func _update_streak_state(today: String) -> void:
    if today == "":
        return
    var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.STREAK_STATE)
    var state: StreakState
    if dict.is_empty():
        state = StreakState.new()
    else:
        state = StreakState.from_dict(dict)
    var service := StreakService.new()
    var new_state: StreakState = service.update_streak(state, today)
    service.queue_free()
    DataStore.save(DataStore.StoreKey.STREAK_STATE, new_state.to_dict())


## 個別結果画面の [もう一度] が押された
func on_individual_result_replay() -> void:
    start_game(_current_game_type)


## 個別結果画面の [ホームへ] が押された
func on_individual_result_home() -> void:
    _safe_change_scene("res://scenes/main/home.tscn")


## game_type ごとの ScoreSystem 入力構築。新ゲーム追加時はここに分岐を追加する。
func _build_play_data_for(log) -> Dictionary:
    match log.game_type:
        "flash_calc":
            # v1.3: スコアは flash_calc.gd 側で算出済み (log.score)。
            # ScoreSystem はパススルーするため precomputed_score を渡す。
            return {"precomputed_score": int(log.score)}
        "sequence_memory":
            var max_level: int = _extract_max_level(log)
            return {"max_reached_level": max_level}
        "ghost_7ban_shobu":
            var deltas: Array = _extract_round_deltas(log)
            var wins: int = _count_wins_from_events(log)
            return {"round_deltas_ms": deltas, "wins": wins}
        "number_search":
            # docs/ideas/games/ghost-number-search-spec.md v1.1 §5-1
            var is_clear := _extract_number_search_is_clear(log)
            var clear_sec := _extract_number_search_clear_time_sec(log)
            return {
                "is_clear": is_clear,
                "clear_time_sec": clear_sec,
                "time_limit_sec": 60.0,    # MVP は T3 固定
                "tier_multiplier": 1.0,    # MVP は T3 (倍率 1.0)
            }
        "card_match":
            # docs/ideas/games/ghost-memory-match-lite-spec.md v1.1 §5-1
            return {
                "pair_count": _count_events_of_type(log, "pair_match"),
                "total_tap_count": _count_events_of_type(log, "card_flipped"),
                "clear_time_sec": float(log.duration_ms) / 1000.0 if log != null else 60.0,
                "time_limit_sec": 60.0,
                "tier_multiplier": 1.0,    # MVP は T1
            }
        "stroop":
            # docs/ideas/games/ghost-stroop-showdown-spec.md v1.1 §5-1:
            # スコアは stroop.gd の _on_finish() で計算済み。パススルー。
            return {"precomputed_score": int(log.score)}
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


## ghost_7ban_shobu の round_result イベント（value=delta_ms）を配列化
func _extract_round_deltas(log) -> Array:
    var result: Array = []
    if log == null or log.events == null:
        return result
    for evt in log.events:
        if evt != null and evt.event_type == "round_result":
            result.append(int(evt.value))
    return result


## ghost_7ban_shobu の勝利数は PlayLog から復元できないため GhostData から取得する
func _count_wins_from_events(log) -> int:
    if log == null:
        return 0
    # GhostData は直近のプレイを 1 件保存済み。その wins を参照。
    var svc := get_node_or_null("/root/GhostData")
    if svc == null:
        return 0
    var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.GHOST_CACHE)
    var games: Dictionary = dict.get("games", {})
    var entry: Dictionary = games.get(String(log.game_type), {})
    var plays: Array = entry.get("plays", [])
    if plays.is_empty():
        return 0
    var last: Dictionary = plays[plays.size() - 1]
    return int(last.get("wins", 0))


## number_search: clear イベントの有無で is_clear 判定
func _extract_number_search_is_clear(log) -> bool:
    if log == null or log.events == null:
        return false
    for evt in log.events:
        if evt != null and evt.event_type == "clear":
            return true
    return false


## number_search: クリアタイム (秒)。clear イベントの value はミリ秒、タイムアウト時は log.duration_ms。
func _extract_number_search_clear_time_sec(log) -> float:
    if log == null or log.events == null:
        return 60.0
    for evt in log.events:
        if evt != null and evt.event_type == "clear":
            return float(evt.value) / 1000.0
    return float(log.duration_ms) / 1000.0


## sequence_memory の level_cleared イベントの最大値を取得
func _extract_max_level(log) -> int:
    if log == null or log.events == null:
        return 0
    var max_level: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == "level_cleared":
            max_level = max(max_level, int(evt.value))
    return max_level


# --- ナビゲーション ---

const GAME_LIST_SCENE: String = "res://scenes/ui/game_list.tscn"
const HOME_SCENE: String = "res://scenes/main/home.tscn"


## 脳トレ一覧画面へ遷移
func navigate_to_game_list() -> void:
    _entry_scene = GAME_LIST_SCENE
    _safe_change_scene(GAME_LIST_SCENE)


## ホーム画面へ遷移
func navigate_to_home() -> void:
    _entry_scene = HOME_SCENE
    _safe_change_scene(HOME_SCENE)


# --- ヘルパー ---

func _safe_change_scene(path: String) -> void:
    var err: int = get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("[GameManager] change_scene failed: %s (err=%d)" % [path, err])
        get_tree().change_scene_to_file("res://scenes/main/home.tscn")


## DEPRECATED: 残置のみ。新規呼び出しは DataStore.load_best を直接使うこと。
func _load_previous_score(game_type: String) -> int:
    return DataStore.load_best(game_type).best_score


## DEPRECATED: 残置のみ。新規呼び出しは DataStore.append_play_log を直接使うこと。
func _save_play_log(log) -> void:
    DataStore.append_play_log(log)
