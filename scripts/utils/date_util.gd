## DateUtil
##
## ブレインゴースト の日付計算ユーティリティ。すべて [b]JST (UTC+9) 固定[/b]で扱う。
## ストリーク判定・デイリーシード・ハンコの日付境界は深夜の境界問題を避けるため JST 基準。
##
## 使用例:
## [codeblock]
## var today: String = DateUtil.today_jst()  # "2026-04-10"
## var diff: int = DateUtil.days_between("2026-04-08", "2026-04-10")  # 2
## var seed: int = DateUtil.date_string_to_seed("2026-04-10")  # 20260410
## [/codeblock]
class_name DateUtil
extends RefCounted

const JST_OFFSET_SEC: int = 9 * 3600  # UTC+9

## 現在の JST 日付を "YYYY-MM-DD" 形式で返す
static func today_jst() -> String:
    var unix_now: int = int(Time.get_unix_time_from_system())
    return unix_to_jst_date_string(unix_now)

## Unix 時刻を JST の "YYYY-MM-DD" 文字列に変換
static func unix_to_jst_date_string(unix_sec: int) -> String:
    var jst_unix: int = unix_sec + JST_OFFSET_SEC
    var dict: Dictionary = Time.get_date_dict_from_unix_time(jst_unix)
    return "%04d-%02d-%02d" % [dict.year, dict.month, dict.day]

## "YYYY-MM-DD" 文字列を、その日の JST 00:00 に相当する Unix 時刻（UTC）に変換
static func jst_date_string_to_unix(date_str: String) -> int:
    var parts: PackedStringArray = date_str.split("-")
    if parts.size() != 3:
        push_error("DateUtil: invalid date string: %s" % date_str)
        return 0
    var dict := {
        "year": int(parts[0]),
        "month": int(parts[1]),
        "day": int(parts[2]),
        "hour": 0, "minute": 0, "second": 0,
    }
    var unix_jst: int = int(Time.get_unix_time_from_datetime_dict(dict))
    return unix_jst - JST_OFFSET_SEC

## 2 つの "YYYY-MM-DD" 間の日数差を返す（from < to なら正の値）
## 年またぎ・月またぎ・うるう年にも対応
static func days_between(from_date: String, to_date: String) -> int:
    if from_date.is_empty() or to_date.is_empty():
        return 0
    var from_unix: int = jst_date_string_to_unix(from_date)
    var to_unix: int = jst_date_string_to_unix(to_date)
    return int((to_unix - from_unix) / 86400)  # 86400 秒 = 1 日

## "YYYY-MM-DD" → 20260410 の整数シード（日付シードとして使用）
static func date_string_to_seed(date_str: String) -> int:
    var parts: PackedStringArray = date_str.split("-")
    if parts.size() != 3:
        return 0
    return int(parts[0]) * 10000 + int(parts[1]) * 100 + int(parts[2])
