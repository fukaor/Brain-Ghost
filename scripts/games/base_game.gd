## BaseGame
##
## 全 6 種ミニゲームの基底クラス。
## 共通ライフサイクル（setup/start/on_user_input/on_finish）、タイマー管理、
## イベント記録、[code]game_finished[/code] シグナルの発火を担う。
##
## サブクラスは必ず以下を実装する:
## - [code]_on_setup(seed_value)[/code] 問題生成
## - [code]_on_start()[/code] ゲーム開始時の描画
## - [code]_on_user_input(input)[/code] ユーザー入力への応答
## - [code]_on_finish()[/code] 終了時のスコア計算と PlayLog 組み立て
class_name BaseGame
extends Node

signal game_started
signal game_finished(play_log: PlayLog)

## サブクラスで必ず上書きする（"flash_calc" など）
var game_type: String = ""

## タイム系ならプレイ中にゴーストバーを出す（サブクラスで設定）
var is_time_based: bool = false

## デイリー時はシード付き RNG、それ以外はランダム RNG
var rng: RandomNumberGenerator

## プレイ中の events（タイムスタンプ付き）
var events: Array[PlayEvent] = []

var _start_time_ms: int = 0
var _is_active: bool = false

## デイリー時はシード付き RNG でセットアップ
##
## [param seed_value] -1 ならランダム、それ以外はデイリーシード
func setup(seed_value: int = -1) -> void:
    rng = RandomNumberGenerator.new()
    if seed_value >= 0:
        rng.seed = seed_value
    else:
        rng.randomize()
    events = []
    _on_setup(seed_value)

## ゲームを開始する（カウントダウン後に呼ばれる想定）
func start() -> void:
    _start_time_ms = Time.get_ticks_msec()
    _is_active = true
    events = []
    game_started.emit()
    _on_start()

## サブクラスから呼ぶ: ユーザー入力を受け取る
func handle_input(input: Dictionary) -> void:
    if not _is_active:
        return
    _on_user_input(input)

## サブクラスから呼ぶ: イベントを記録する
func record_event(event_type: String, value: float = 0.0) -> void:
    var e := PlayEvent.new()
    e.time_ms = Time.get_ticks_msec() - _start_time_ms
    e.event_type = event_type
    e.value = value
    events.append(e)

## ゲームを終了し PlayLog を組み立てて通知する
func finish() -> void:
    if not _is_active:
        return
    _is_active = false
    var log: PlayLog = _on_finish()
    game_finished.emit(log)

func get_elapsed_ms() -> int:
    return Time.get_ticks_msec() - _start_time_ms

# --- サブクラスで上書きするフック（virtual methods） ---

func _on_setup(_seed_value: int) -> void:
    pass

func _on_start() -> void:
    pass

func _on_user_input(_input: Dictionary) -> void:
    pass

## サブクラスで上書き可能。基底実装は game_type / duration_ms / events を埋めた PlayLog を返す。
##
## [b]サブクラスでの完成責務:[/b]
## サブクラスはこの関数を override して、少なくとも以下を設定すること:
## - [code]log.id[/code]       — [code]UuidUtil.v4()[/code] で生成
## - [code]log.score[/code]    — ScoreSystem で算出
## - [code]log.mode[/code]     — "daily" / "free" / "onboarding"
## - [code]log.played_at[/code]   — ISO8601 形式のタイムスタンプ
## - [code]log.played_date[/code] — [code]DateUtil.today_jst()[/code]
## - [code]log.daily_seed[/code]  — daily モード時のみ、それ以外は -1
## - [code]log.is_new_best[/code] — GameBest との比較で決定
## - [code]log.ghost_result[/code] — GhostSystem の judge_result() 経由
func _on_finish() -> PlayLog:
    var log := PlayLog.new()
    log.game_type = game_type
    log.duration_ms = get_elapsed_ms()
    log.events = events
    return log
