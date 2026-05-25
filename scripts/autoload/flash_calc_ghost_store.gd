## FlashCalcGhostStore
##
## フラッシュ暗算 (ゴースト一本勝負・計算編) 専用のティア別データストア (Autoload)。
## 既存 [code]GhostData[/code] は 7 ラウンド固定の API なので、本ゲーム用に独立。
##
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md §6-1。
##
## ## 永続スキーマ (GHOST_CACHE キーの "flash_calc" 名前空間)
## ```json
## {
##   "schemaVersion": 1,
##   "games": {
##     "flash_calc": {
##       "tiers": {
##         "T1": {
##           "plays": [
##             {"date": "2026-05-16", "response_ms": 4200, "won": true, "score": 1450},
##             ... (最大 5 件、古い順)
##           ],
##           "best_score": 1500,
##           "unlocked": true
##         },
##         "T2": {...},
##       }
##     }
##   }
## }
## ```
##
## T1 は初期解放 (unlocked=true)、T2 以降は false。
extends Node

const _Tier = preload("res://scripts/games/flash_calc/tier_config.gd")

const GAME_TYPE: String = "flash_calc"
const RECENT_PLAY_WINDOW: int = 5
const UNLOCK_REQUIRED_WINS: int = 3   ## 直近 5 回中の必要勝利数 (仕様 §5-1)


# ---------------------------------------------------------------------------
# 書込
# ---------------------------------------------------------------------------

## 1 試合ぶんの結果を保存。直近 5 件を超えたら古いものから破棄。
func save_play(tier: String, response_ms: int, won: bool, score: int) -> bool:
    if tier == "":
        push_warning("[FlashCalcGhostStore] save_play: empty tier")
        return false
    var tier_entry: Dictionary = _get_tier_entry(tier)
    var plays: Array = tier_entry.get("plays", [])
    plays.append({
        "date": _today_iso_date(),
        "response_ms": int(response_ms),
        "won": bool(won),
        "score": int(score),
    })
    if plays.size() > RECENT_PLAY_WINDOW:
        plays = plays.slice(plays.size() - RECENT_PLAY_WINDOW, plays.size())
    tier_entry["plays"] = plays
    if int(score) > int(tier_entry.get("best_score", 0)):
        tier_entry["best_score"] = int(score)
    return _save_tier_entry(tier, tier_entry)


## ティアを解放状態にする。
func unlock(tier: String) -> bool:
    if tier == "":
        return false
    var tier_entry: Dictionary = _get_tier_entry(tier)
    tier_entry["unlocked"] = true
    return _save_tier_entry(tier, tier_entry)


# ---------------------------------------------------------------------------
# 読込
# ---------------------------------------------------------------------------

## ゴースト Δt を返す。プレイ履歴があれば response_ms の中央値、なければ初期値。
func get_delta_for_tier(tier: String) -> int:
    var initial: int = int(_Tier.TIER_INITIAL_DELTAS.get(tier, 5000))
    var tier_entry: Dictionary = _get_tier_entry(tier)
    var plays: Array = tier_entry.get("plays", [])
    if plays.is_empty():
        return initial
    var responses: Array[int] = []
    for p in plays:
        if p is Dictionary:
            responses.append(int(p.get("response_ms", initial)))
    if responses.is_empty():
        return initial
    responses.sort()
    return responses[responses.size() / 2]


## ティアのプレイ回数 (0〜RECENT_PLAY_WINDOW)。
func get_play_count(tier: String) -> int:
    return _get_tier_entry(tier).get("plays", []).size()


## 直近 5 回中の勝利数。次ティア解放判定 (>= UNLOCK_REQUIRED_WINS) に使用。
func get_recent_wins(tier: String) -> int:
    var plays: Array = _get_tier_entry(tier).get("plays", [])
    var wins: int = 0
    for p in plays:
        if p is Dictionary and bool(p.get("won", false)):
            wins += 1
    return wins


## 解放済みかどうか。T1 は常に true。
func is_unlocked(tier: String) -> bool:
    if tier == "T1":
        return true
    return bool(_get_tier_entry(tier).get("unlocked", false))


## ベストスコア (0 = 未プレイ)。
func get_best_score(tier: String) -> int:
    return int(_get_tier_entry(tier).get("best_score", 0))


## ホーム画面の「適正ティア」を返す。
## - 解放済み最高ティアで勝率 60% 未満なら 1 つ下を推奨
## - そうでなければ解放済み最高ティアを推奨
## - 初回 (T1 未プレイ) は "T1"
func get_appropriate_tier() -> String:
    var best_unlocked: String = "T1"
    for t in _Tier.TIER_LIST:
        if is_unlocked(t):
            best_unlocked = t
    var plays: int = get_play_count(best_unlocked)
    if plays < 3:
        return best_unlocked
    var wins: int = get_recent_wins(best_unlocked)
    var win_rate: float = float(wins) / float(plays)
    if win_rate < 0.6 and best_unlocked != "T1":
        # 1 つ下が「適正」 (現ティアは挑戦域)
        var prev_index: int = _Tier.TIER_LIST.find(best_unlocked) - 1
        return _Tier.TIER_LIST[prev_index]
    return best_unlocked


# ---------------------------------------------------------------------------
# 永続化 (内部)
# ---------------------------------------------------------------------------

func _get_tier_entry(tier: String) -> Dictionary:
    var dict: Dictionary = _load_cache_dict()
    var games: Dictionary = dict.get("games", {})
    var game_entry: Dictionary = games.get(GAME_TYPE, {})
    var tiers: Dictionary = game_entry.get("tiers", {})
    var tier_entry: Dictionary = tiers.get(tier, {})
    if tier_entry.is_empty():
        tier_entry = {
            "plays": [],
            "best_score": 0,
            "unlocked": (tier == "T1"),
        }
    return tier_entry


func _save_tier_entry(tier: String, tier_entry: Dictionary) -> bool:
    var dict: Dictionary = _load_cache_dict()
    var games: Dictionary = dict.get("games", {})
    var game_entry: Dictionary = games.get(GAME_TYPE, {})
    var tiers: Dictionary = game_entry.get("tiers", {})
    tiers[tier] = tier_entry
    game_entry["tiers"] = tiers
    games[GAME_TYPE] = game_entry
    dict["games"] = games
    dict["schemaVersion"] = DataStore.SCHEMA_VERSION
    return DataStore.save(DataStore.StoreKey.GHOST_CACHE, dict)


func _load_cache_dict() -> Dictionary:
    var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.GHOST_CACHE)
    if not dict.has("games"):
        dict["games"] = {}
    return dict


func _today_iso_date() -> String:
    return Time.get_date_string_from_system(true)
