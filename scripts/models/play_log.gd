## PlayLog
##
## 1 回のミニゲームプレイの詳細記録。ゴースト生成の元データ。
## docs/functional-design.md 「データモデル定義 > PlayLog」準拠。
class_name PlayLog
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1

var id: String = ""                    # UUID v4
var game_type: String = ""             # "flash_calc" | "ghost_7ban_shobu" | ...
var mode: String = "free"              # "daily" | "free" | "onboarding"
var played_at: String = ""             # ISO8601
var played_date: String = ""           # "YYYY-MM-DD"（JST）
var daily_seed: int = -1               # デイリー時は YYYYMMDD、それ以外は -1
var score: int = 0
var is_new_best: bool = false
var duration_ms: int = 0
var events: Array[PlayEvent] = []
var ghost_result: Dictionary = {}      # {"result": "win"|"lose"|"draw", "selfValue": float, "ghostValue": float, "diff": float}

func to_dict() -> Dictionary:
    var events_array: Array = []
    for e in events:
        events_array.append(e.to_dict())
    return {
        "id": id,
        "gameType": game_type,
        "mode": mode,
        "playedAt": played_at,
        "playedDate": played_date,
        "dailySeed": daily_seed,
        "score": score,
        "isNewBest": is_new_best,
        "durationMs": duration_ms,
        "events": events_array,
        "ghostResult": ghost_result,
    }

static func from_dict(d: Dictionary) -> PlayLog:
    var log := PlayLog.new()
    log.id = String(d.get("id", ""))
    log.game_type = String(d.get("gameType", ""))
    log.mode = String(d.get("mode", "free"))
    log.played_at = String(d.get("playedAt", ""))
    log.played_date = String(d.get("playedDate", ""))
    log.daily_seed = int(d.get("dailySeed", -1))
    log.score = int(d.get("score", 0))
    log.is_new_best = bool(d.get("isNewBest", false))
    log.duration_ms = int(d.get("durationMs", 0))
    var events_raw: Array = d.get("events", [])
    for item in events_raw:
        if item is Dictionary:
            log.events.append(PlayEvent.from_dict(item))
    log.ghost_result = d.get("ghostResult", {})
    return log
