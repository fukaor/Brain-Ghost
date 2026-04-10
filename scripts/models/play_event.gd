## PlayEvent
##
## ミニゲーム中の個別イベント。PlayLog.events の要素。
## タイム系ゲームのプログレスバー再生・ゴースト平均化に使う。
class_name PlayEvent
extends RefCounted

var time_ms: int = 0                        # プレイ開始からの経過ミリ秒
var event_type: String = ""                 # "correct" | "incorrect" | "tap" | "clear" | "miss"
var value: float = 0.0                      # ゲーム固有の数値（例: 反応時間）

func to_dict() -> Dictionary:
    return {
        "timeMs": time_ms,
        "eventType": event_type,
        "value": value,
    }

static func from_dict(d: Dictionary) -> PlayEvent:
    var e := PlayEvent.new()
    e.time_ms = int(d.get("timeMs", 0))
    e.event_type = String(d.get("eventType", ""))
    e.value = float(d.get("value", 0.0))
    return e
