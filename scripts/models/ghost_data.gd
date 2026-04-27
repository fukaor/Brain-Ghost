## GhostDataModel
##
## 直近 5 回のプレイログから計算されたゴースト対戦用データ（純粋モデル）。
## docs/functional-design.md 「データモデル定義 > GhostData」準拠。
##
## タイム系ゲームでは [code]average_events[/code] を使ってプレイ中のプログレスバーを再生し、
## クリア系ゲームでは [code]average_duration_ms[/code] / [code]average_score[/code] を
## 結果画面でのタイム比較に使う。
##
## [b]NOTE:[/b] 2026-04-22 に [code]class_name GhostData[/code] から
## [code]GhostDataModel[/code] にリネーム。Autoload [code]GhostData[/code]
## （ゴースト対戦サービス）との名前衝突回避。
class_name GhostDataModel
extends RefCounted

var game_type: String = ""
var base_log_ids: Array[String] = []
var is_ready: bool = false
var average_events: Array[PlayEvent] = []   # 100ms 刻みのグリッド（タイム系のみ）
var average_score: float = 0.0
var average_duration_ms: float = 0.0
var average_tap_count: float = 0.0           # 神経衰弱のみ使用
var computed_at: String = ""

func to_dict() -> Dictionary:
    var events_array: Array = []
    for e in average_events:
        events_array.append(e.to_dict())
    var ids_array: Array = []
    for id in base_log_ids:
        ids_array.append(id)
    return {
        "gameType": game_type,
        "baseLogIds": ids_array,
        "isReady": is_ready,
        "averageEvents": events_array,
        "averageScore": average_score,
        "averageDurationMs": average_duration_ms,
        "averageTapCount": average_tap_count,
        "computedAt": computed_at,
    }

static func from_dict(d: Dictionary) -> GhostDataModel:
    var g := GhostDataModel.new()
    g.game_type = String(d.get("gameType", ""))
    g.is_ready = bool(d.get("isReady", false))
    g.average_score = float(d.get("averageScore", 0.0))
    g.average_duration_ms = float(d.get("averageDurationMs", 0.0))
    g.average_tap_count = float(d.get("averageTapCount", 0.0))
    g.computed_at = String(d.get("computedAt", ""))
    var ids_raw: Array = d.get("baseLogIds", [])
    for id in ids_raw:
        g.base_log_ids.append(String(id))
    var events_raw: Array = d.get("averageEvents", [])
    for item in events_raw:
        if item is Dictionary:
            g.average_events.append(PlayEvent.from_dict(item))
    return g

## 「あと○回で生まれます」に表示する残り回数。5 未満なら返し、それ以上なら 0
static func plays_until_ready(current_count: int) -> int:
    return max(0, 5 - current_count)
