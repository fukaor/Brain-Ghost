## DailySeed
##
## 日付シード生成とデイリーチャレンジの 3 種選出を担うサービス。
## docs/functional-design.md 「コンポーネント設計 > core/DailySeed」および A-05 準拠。
##
## [b]重要:[/b] [code]Array.shuffle()[/code] は Godot 4 ではグローバル乱数を使用するため、
## シード決定性が壊れる。必ず [code]rng.randi()[/code] で Fisher-Yates を手動実装すること。
## この規則を破ると「全ユーザー共通問題」の前提が崩れる。
##
## [b]Autoload しない[/b]: サービスレイヤーはインスタンス化してテスト可能にする。
class_name DailySeed
extends Node

const ALL_GAMES: Array[String] = [
    "ghost_7ban_shobu",
    "flash_calc",
    "number_search",
    "stroop",
    "sequence_memory",
    "card_match",
]

const DAILY_GAME_COUNT: int = 3

## 日付（Dictionary）から整数シードを生成する
## 例: {year: 2026, month: 4, day: 15} -> 20260415
func get_daily_seed(date: Dictionary = {}) -> int:
    var d := date
    if d.is_empty():
        # デフォルト: JST の現在日付
        var today_str := DateUtil.today_jst()
        var parts := today_str.split("-")
        d = {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2])}
    return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)

## シードに基づく RNG を作成する
func create_rng(seed_value: int) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    return rng

## シードに基づいて ALL_GAMES から 3 種を決定論的に選出する
## 同じシードなら全ユーザーが同じ 3 種になる
func get_daily_games(seed_value: int) -> Array[String]:
    var rng := create_rng(seed_value)
    var pool: Array[String] = ALL_GAMES.duplicate()

    # Fisher-Yates シャッフルを rng で手動実装
    # Array.shuffle() はグローバル乱数を使うためシード決定性が壊れる
    for i in range(pool.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var tmp: String = pool[i]
        pool[i] = pool[j]
        pool[j] = tmp

    var result: Array[String] = []
    for k in range(DAILY_GAME_COUNT):
        result.append(pool[k])
    return result
