## GameBest
##
## ゲーム別のベスト記録。docs/functional-design.md 「データモデル定義 > GameBest」準拠。
class_name GameBest
extends RefCounted

var game_type: String = ""
var best_score: int = 0
var best_play_log_id: String = ""
var achieved_at: String = ""
var total_play_count: int = 0

func to_dict() -> Dictionary:
    return {
        "gameType": game_type,
        "bestScore": best_score,
        "bestPlayLogId": best_play_log_id,
        "achievedAt": achieved_at,
        "totalPlayCount": total_play_count,
    }

static func from_dict(d: Dictionary) -> GameBest:
    var b := GameBest.new()
    b.game_type = String(d.get("gameType", ""))
    b.best_score = int(d.get("bestScore", 0))
    b.best_play_log_id = String(d.get("bestPlayLogId", ""))
    b.achieved_at = String(d.get("achievedAt", ""))
    b.total_play_count = int(d.get("totalPlayCount", 0))
    return b
