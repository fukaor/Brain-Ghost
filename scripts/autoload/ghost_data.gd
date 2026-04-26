## GhostData
##
## ゴースト対戦専用のデータサービス（Autoload）。ミニゲームのラウンド別 Δt を
## 直近 5 回分保持し、各ラウンドの中央値をゴースト基準値として返す。
##
## docs/ideas/games/ghost-7ban-shobu-spec.md §6 準拠。
## - save_play(game_type, round_deltas, wins) で 1 プレイぶんを保存
## - load_round_medians(game_type) で 7 要素のラウンド別中央値を返す
##   （初回はフォールバック 273ms × 7 = Human Benchmark 中央値相当）
##
## [b]純粋モデル:[/b] データ構造体は [code]scripts/models/ghost_data.gd[/code]
## （[code]GhostDataModel[/code]）。本サービスはモデルを使わず、DataStore の
## GHOST_CACHE キーに直接 JSON を読み書きする軽量設計。
##
## [b]スキーマ:[/b]
## ```json
## {
##   "schemaVersion": 1,
##   "games": {
##     "ghost_7ban_shobu": {
##       "plays": [
##         {"date": "2026-04-22", "round_deltas_ms": [120, 145, ...], "wins": 4},
##         ... (最大 5 件、古い順)
##       ]
##     }
##   }
## }
## ```
extends Node

## spec §6-2 採用案: 初回プレイ時は平均的な成人反応時間
const FALLBACK_DELTA_MS: int = 273

## spec §2-1 / §10-2: 1 プレイは 7 ラウンド固定
const ROUNDS_PER_PLAY: int = 7

## spec §6-1: 直近 5 回分のみ保持（古いものから破棄）
const RECENT_PLAY_WINDOW: int = 5


## 1 プレイぶんのラウンド別 Δt と勝利数を保存する。
## round_deltas のサイズが ROUNDS_PER_PLAY と異なる場合は警告を出して破棄する。
func save_play(game_type: String, round_deltas: Array, wins: int) -> bool:
    if game_type == "":
        push_warning("[GhostData] save_play: empty game_type")
        return false
    if round_deltas.size() != ROUNDS_PER_PLAY:
        push_warning("[GhostData] save_play: expected %d deltas, got %d" % [ROUNDS_PER_PLAY, round_deltas.size()])
        return false

    var dict: Dictionary = _load_cache_dict()
    var games: Dictionary = dict.get("games", {})
    var game_entry: Dictionary = games.get(game_type, {})
    var plays: Array = game_entry.get("plays", [])

    var deltas_int: Array = []
    for d in round_deltas:
        deltas_int.append(int(d))

    plays.append({
        "date": _today_iso_date(),
        "round_deltas_ms": deltas_int,
        "wins": int(wins),
    })

    # spec §6-1: 直近 5 件だけ保持
    if plays.size() > RECENT_PLAY_WINDOW:
        plays = plays.slice(plays.size() - RECENT_PLAY_WINDOW, plays.size())

    game_entry["plays"] = plays
    games[game_type] = game_entry
    dict["games"] = games
    dict["schemaVersion"] = DataStore.SCHEMA_VERSION

    return DataStore.save(DataStore.StoreKey.GHOST_CACHE, dict)


## 各ラウンドのゴースト Δt を返す。要素数は常に ROUNDS_PER_PLAY。
## プレイ履歴が無いラウンドは FALLBACK_DELTA_MS で埋める。
func load_round_medians(game_type: String) -> Array[int]:
    var result: Array[int] = []
    for _i in range(ROUNDS_PER_PLAY):
        result.append(FALLBACK_DELTA_MS)

    if game_type == "":
        return result

    var dict: Dictionary = _load_cache_dict()
    var games: Dictionary = dict.get("games", {})
    if not games.has(game_type):
        return result
    var game_entry: Dictionary = games.get(game_type, {})
    var plays: Array = game_entry.get("plays", [])
    if plays.is_empty():
        return result

    for round_index in range(ROUNDS_PER_PLAY):
        var round_values: Array[int] = []
        for play in plays:
            if play is Dictionary:
                var deltas: Array = play.get("round_deltas_ms", [])
                if deltas.size() > round_index:
                    round_values.append(int(deltas[round_index]))
        if round_values.is_empty():
            continue
        round_values.sort()
        result[round_index] = round_values[round_values.size() / 2]

    return result


## そのゲームの保存済みプレイ数を返す（0〜RECENT_PLAY_WINDOW）。
func get_play_count(game_type: String) -> int:
    if game_type == "":
        return 0
    var dict: Dictionary = _load_cache_dict()
    var games: Dictionary = dict.get("games", {})
    var game_entry: Dictionary = games.get(game_type, {})
    var plays: Array = game_entry.get("plays", [])
    return plays.size()


# --- 内部 ---

func _load_cache_dict() -> Dictionary:
    var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.GHOST_CACHE)
    if not dict.has("games"):
        dict["games"] = {}
    return dict


func _today_iso_date() -> String:
    return Time.get_date_string_from_system(true)
