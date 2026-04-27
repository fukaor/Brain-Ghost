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


# ============================================================
# --- 高レベル API: PlayLog 操作 ---
# ============================================================

## 1 件の PlayLog を PLAY_LOGS に追加保存する。
## 失敗時は false を返し、push_warning を出す。
func append_play_log(log: PlayLog) -> bool:
    if log == null:
        push_warning("[DataStore] append_play_log: null log")
        return false
    var dict: Dictionary = _load_play_logs_dict()
    var logs_array: Array = dict.get("logs", [])
    logs_array.append(log.to_dict())
    dict["logs"] = logs_array
    dict["schemaVersion"] = SCHEMA_VERSION
    return save(StoreKey.PLAY_LOGS, dict)


## PLAY_LOGS から PlayLog 配列を読み込む。
## [param game_type] 空文字なら全件、指定があれば該当ゲームのみフィルタ
## [param limit] -1 なら全件、正数なら末尾 N 件（直近 N 件の意味）
func load_play_logs(game_type: String = "", limit: int = -1) -> Array[PlayLog]:
    var result: Array[PlayLog] = []
    var dict: Dictionary = _load_play_logs_dict()
    var logs_array: Array = dict.get("logs", [])
    for item in logs_array:
        if item is Dictionary:
            var log: PlayLog = PlayLog.from_dict(item)
            if game_type == "" or log.game_type == game_type:
                result.append(log)
    if limit > 0 and result.size() > limit:
        result = result.slice(result.size() - limit, result.size())
    return result


## PLAY_LOGS の件数を返す。
## [param game_type] 空文字なら全件、指定があれば該当ゲームのみカウント
func count_play_logs(game_type: String = "") -> int:
    var dict: Dictionary = _load_play_logs_dict()
    var logs_array: Array = dict.get("logs", [])
    if game_type == "":
        return logs_array.size()
    var count: int = 0
    for item in logs_array:
        if item is Dictionary and String(item.get("gameType", "")) == game_type:
            count += 1
    return count


# ============================================================
# --- 高レベル API: GameBest 操作 ---
# ============================================================

## 指定ゲームのベスト記録を読み込む。未保存なら score=0 の空 GameBest を返す。
func load_best(game_type: String) -> GameBest:
    var dict: Dictionary = _load_bests_dict()
    var bests: Dictionary = dict.get("bests", {})
    if bests.has(game_type):
        var item = bests[game_type]
        if item is Dictionary:
            return GameBest.from_dict(item)
    var empty := GameBest.new()
    empty.game_type = game_type
    return empty


## 単一の GameBest を保存する（既存の他ゲーム分はマージで保持）。
func save_best(best: GameBest) -> bool:
    if best == null or best.game_type == "":
        push_warning("[DataStore] save_best: invalid best")
        return false
    var dict: Dictionary = _load_bests_dict()
    var bests: Dictionary = dict.get("bests", {})
    bests[best.game_type] = best.to_dict()
    dict["bests"] = bests
    dict["schemaVersion"] = SCHEMA_VERSION
    return save(StoreKey.GAME_BESTS, dict)


## PlayLog のスコアが既存ベストより高ければ更新して true を返す。
## 同スコア・低スコアでは false を返す（更新なし）。
## 副作用: total_play_count を必ず +1 する（ベスト更新の有無に関係なく）。
func update_best_if_better(log: PlayLog) -> bool:
    if log == null or log.game_type == "":
        return false
    var current: GameBest = load_best(log.game_type)
    var should_update: bool = log.score > current.best_score
    if should_update:
        current.best_score = log.score
        current.best_play_log_id = log.id
        current.achieved_at = log.played_at
    current.total_play_count += 1
    save_best(current)
    return should_update


# ============================================================
# --- 内部ヘルパー ---
# ============================================================

func _load_play_logs_dict() -> Dictionary:
    var dict: Dictionary = load_dict(StoreKey.PLAY_LOGS)
    if not dict.has("logs"):
        dict["logs"] = []
    return dict


func _load_bests_dict() -> Dictionary:
    var dict: Dictionary = load_dict(StoreKey.GAME_BESTS)
    if not dict.has("bests"):
        dict["bests"] = {}
    return dict
