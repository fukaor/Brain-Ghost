## DataStore
##
## JSON データの読み書きを担う永続化の唯一の窓口（Autoload）。
## プラットフォーム分岐は [code]Platform[/code] を経由する。
## docs/functional-design.md 「コンポーネント設計 > core/DataStore」準拠。
##
## [b]注意:[/b] MVP 段階ではスタブ実装。Week 1-2 で実装を肉付けする。
extends Node

enum StoreKey {
    USER_CONFIG,
    PLAY_LOGS,
    GAME_BESTS,
    STREAK_STATE,
    GHOST_CACHE,
}

const SCHEMA_VERSION: int = 1

# --- パス・キー ---

func _get_native_path(key: StoreKey) -> String:
    return "user://%s.json" % _key_name(key).to_lower()

func _get_web_key(key: StoreKey) -> String:
    return "brainghost_%s" % _key_name(key).to_lower()

func _key_name(key: StoreKey) -> String:
    return StoreKey.keys()[key]

# --- 存在確認 ---

func exists(key: StoreKey) -> bool:
    if Platform.is_web():
        return _exists_web(key)
    return FileAccess.file_exists(_get_native_path(key))

func _exists_web(key: StoreKey) -> bool:
    var js_key := _get_web_key(key)
    var result: Variant = JavaScriptBridge.eval("localStorage.getItem('%s') !== null" % js_key, true)
    return bool(result) if result != null else false

# --- 保存 ---

func save(key: StoreKey, data: Dictionary) -> bool:
    var json_text: String = JsonUtil.stringify(data)
    if Platform.is_web():
        return _save_web(key, json_text)
    return _save_native(key, json_text)

func _save_native(key: StoreKey, json_text: String) -> bool:
    var path: String = _get_native_path(key)
    var tmp_path: String = path + ".tmp"
    var file := FileAccess.open(tmp_path, FileAccess.WRITE)
    if file == null:
        push_error("DataStore._save_native: failed to open %s (err=%d)" % [tmp_path, FileAccess.get_open_error()])
        return false
    file.store_string(json_text)
    file.close()
    # 原子的リネーム: 一時ファイルから本ファイルへ
    var dir := DirAccess.open("user://")
    if dir == null:
        push_error("DataStore._save_native: failed to open user:// directory")
        return false
    if FileAccess.file_exists(path):
        dir.remove(path.replace("user://", ""))
    var rename_err: int = dir.rename(tmp_path.replace("user://", ""), path.replace("user://", ""))
    if rename_err != OK:
        push_error("DataStore._save_native: rename failed (err=%d)" % rename_err)
        return false
    return true

func _save_web(key: StoreKey, json_text: String) -> bool:
    # JSON.stringify の出力は JS リテラルとしても valid なため、eval で直接埋め込む。
    # MVP 時点ではユーザー自由入力フィールドが存在しないため安全。
    #
    # ⚠️ 将来の注意: ユーザーが自由入力できるフィールド（例: メモ、ニックネーム、
    # 年代以外のプロフィール情報）を追加する場合、この方式は XSS/インジェクション
    # リスクを抱える。そのときは以下のどちらかに切り替えること:
    #   1. btoa() による base64 エンコード経由で渡す
    #   2. JavaScriptBridge.create_object() を使って JS オブジェクト経由で setItem を呼ぶ
    # 詳細: docs/functional-design.md 「コンポーネント設計 > core/DataStore」の注意点
    var js_key: String = _get_web_key(key)
    var js: String = "try { localStorage.setItem('%s', JSON.stringify(%s)); 'ok'; } catch(e) { 'err:' + e.message; }" % [js_key, json_text]
    var result: Variant = JavaScriptBridge.eval(js, true)
    if result == null or str(result).begins_with("err:"):
        push_error("DataStore._save_web: %s" % str(result))
        return false
    return true

# --- 読込 ---

func load_dict(key: StoreKey) -> Dictionary:
    var text: String = ""
    if Platform.is_web():
        text = _load_web(key)
    else:
        text = _load_native(key)
    return JsonUtil.parse_dict(text, _key_name(key))

func _load_native(key: StoreKey) -> String:
    var path: String = _get_native_path(key)
    if not FileAccess.file_exists(path):
        return ""
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("DataStore._load_native: failed to open %s" % path)
        return ""
    var text := file.get_as_text()
    file.close()
    return text

func _load_web(key: StoreKey) -> String:
    var js_key: String = _get_web_key(key)
    var result: Variant = JavaScriptBridge.eval("localStorage.getItem('%s') || ''" % js_key, true)
    return str(result) if result != null else ""

# --- 削除 ---

func clear(key: StoreKey) -> void:
    if Platform.is_web():
        var js_key: String = _get_web_key(key)
        JavaScriptBridge.eval("localStorage.removeItem('%s')" % js_key, true)
    else:
        var path: String = _get_native_path(key)
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
