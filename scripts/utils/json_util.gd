## JsonUtil
##
## JSON 読書の共通エラーハンドリング。
## DataStore はこれを経由して JSON のパース/シリアライズを行う。
class_name JsonUtil
extends RefCounted

## 文字列を JSON としてパースし Dictionary を返す。失敗時は空 Dictionary + push_error
static func parse_dict(text: String, context_label: String = "") -> Dictionary:
    if text.is_empty():
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if parsed == null:
        push_error("JsonUtil.parse_dict: failed to parse JSON%s" % _ctx(context_label))
        return {}
    if not (parsed is Dictionary):
        push_error("JsonUtil.parse_dict: expected Dictionary, got %s%s" % [typeof(parsed), _ctx(context_label)])
        return {}
    return parsed as Dictionary

## 文字列を JSON としてパースし Array を返す。失敗時は空 Array + push_error
static func parse_array(text: String, context_label: String = "") -> Array:
    if text.is_empty():
        return []
    var parsed: Variant = JSON.parse_string(text)
    if parsed == null:
        push_error("JsonUtil.parse_array: failed to parse JSON%s" % _ctx(context_label))
        return []
    if not (parsed is Array):
        push_error("JsonUtil.parse_array: expected Array, got %s%s" % [typeof(parsed), _ctx(context_label)])
        return []
    return parsed as Array

## Dictionary を JSON 文字列にシリアライズ（インデント付きで読みやすく）
static func stringify(data: Variant, pretty: bool = false) -> String:
    if pretty:
        return JSON.stringify(data, "  ")
    return JSON.stringify(data)

static func _ctx(label: String) -> String:
    return " [%s]" % label if not label.is_empty() else ""
