## StreakState
##
## ストリーク（連続プレイ日数）の状態。docs/functional-design.md 「データモデル定義 > StreakState」準拠。
##
## [b]welcome_back_shown フラグの意味:[/b]
## [code]false[/code] → 次回ホーム画面描画時に復帰演出を 1 度だけ表示すべき状態
## [code]true[/code] → 表示済み / 復帰演出不要
class_name StreakState
extends RefCounted

var current_streak: int = 0
var last_played_date: String = ""           # "YYYY-MM-DD"（JST）
var longest_streak: int = 0
var stamped_dates: Array[String] = []       # カレンダー表示用
var welcome_back_shown: bool = true

func to_dict() -> Dictionary:
    var stamped_array: Array = []
    for d in stamped_dates:
        stamped_array.append(d)
    return {
        "currentStreak": current_streak,
        "lastPlayedDate": last_played_date,
        "longestStreak": longest_streak,
        "stampedDates": stamped_array,
        "welcomeBackShown": welcome_back_shown,
    }

static func from_dict(d: Dictionary) -> StreakState:
    var s := StreakState.new()
    s.current_streak = int(d.get("currentStreak", 0))
    s.last_played_date = String(d.get("lastPlayedDate", ""))
    s.longest_streak = int(d.get("longestStreak", 0))
    s.welcome_back_shown = bool(d.get("welcomeBackShown", true))
    var stamped_raw: Array = d.get("stampedDates", [])
    for item in stamped_raw:
        s.stamped_dates.append(String(item))
    return s

func clone() -> StreakState:
    return StreakState.from_dict(to_dict())
