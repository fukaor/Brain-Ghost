## HomeController (Midnight Cat v3)
##
## ホーム画面のコントローラ。docs/design/promotion/home.png 準拠。
##
## レイアウト:
## - 上部: 脳年齢 + ⚙設定 + 黒猫マスコット + 吹き出し
## - 中部: ポイント / 通算戦績ピル + 「今日のチャレンジ」CTA + 5日連続バッジ
## - 下部: 6軸レーダーチャート + 全ゲーム一覧リンク
##
## 「今日のチャレンジ」→ GameManager.start_game("ghost_7ban_shobu")。
##
## 表示データはすべて永続化されたものを集計（脳年齢 / ポイント / 戦績 / ストリーク / レーダー）。
extends Control

const ABILITY_KEYS: Array[String] = [
	"calculation", "memory", "attention", "reflex", "observation", "judgment",
]

const ABILITY_TO_GAME: Dictionary = {
	"calculation": "flash_calc",
	"memory": "sequence_memory",
	"attention": "stroop",
	"reflex": "ghost_7ban_shobu",
	"observation": "number_search",
	"judgment": "card_match",
}

## 年代 → 基準年齢 (GDD §脳年齢チューニング)
const AGE_GROUP_TO_AGE: Dictionary = {
	"10s": 15, "20s": 25, "30s": 30, "40s": 45, "50s+": 55,
}
const DEFAULT_BASE_AGE: int = 30

## 全ゲーム種別（ポイント合計 / 通算戦績集計に使用）
const ALL_GAME_TYPES: Array[String] = [
	"ghost_7ban_shobu", "flash_calc", "sequence_memory",
	"stroop", "card_match", "number_search",
]

const FLOAT_AMPLITUDE_PX: float = 4.0
const FLOAT_SPEED: float = 1.6
const PULSE_PERIOD_SEC: float = 2.4
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.025

const SPEECH_RETURN := "おかえり！\n今日もやる？"
const SPEECH_GO := "よし、いっしょに行こう。"

# ノード参照 -----------------------------------------------------------------
@onready var _brain_age_value: Label = $SafeArea/MainColumn/TopRow/BrainAgeBlock/Row/Value
@onready var _settings_btn: Button = $SafeArea/MainColumn/TopRow/SettingsButton
@onready var _mascot: TextureRect = $SafeArea/MainColumn/HeroRow/MascotImage
@onready var _speech_text: Label = $SafeArea/MainColumn/HeroRow/SpeechWrap/SpeechBubble/Margin/SpeechText
@onready var _score_value: Label = $SafeArea/MainColumn/ScoreRow/ScorePill/Row/Value
@onready var _score_delta: Label = $SafeArea/MainColumn/ScoreRow/ScorePill/Row/Delta
@onready var _battle_caption: Label = $SafeArea/MainColumn/ScoreRow/BattlePill/Row/Caption
@onready var _battle_wins: Label = $SafeArea/MainColumn/ScoreRow/BattlePill/Row/Wins
@onready var _battle_losses: Label = $SafeArea/MainColumn/ScoreRow/BattlePill/Row/Losses
@onready var _cta_button: Button = $SafeArea/MainColumn/CTAWrap/CTAButton
@onready var _streak_ribbon: PanelContainer = $SafeArea/MainColumn/StreakRow/StreakRibbon
@onready var _streak_label: Label = $SafeArea/MainColumn/StreakRow/StreakRibbon/Row/Text
@onready var _radar: Control = $SafeArea/MainColumn/RadarCard/Radar
@onready var _all_games_link: Button = $SafeArea/MainColumn/AllGamesLink

var _anim_time: float = 0.0


func _ready() -> void:
	_wire_signals()
	_apply_data()
	set_process(true)


func _process(delta: float) -> void:
	_anim_time += delta
	_animate_mascot_float()
	_animate_cta_pulse()


func _wire_signals() -> void:
	_cta_button.pressed.connect(_on_cta_pressed)
	_all_games_link.pressed.connect(_on_all_games_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)


# ---------------------------------------------------------------------------
# データ反映（すべて DataStore / GhostData の実データから算出）
# ---------------------------------------------------------------------------
func _apply_data() -> void:
	_brain_age_value.text = str(_compute_brain_age())
	_speech_text.text = SPEECH_RETURN

	# ポイント = 全 PlayLog の score 累積（生涯獲得ポイント。今日のデルタは部分集合）
	var total_pts: int = _compute_total_score()
	_score_value.text = _format_thousands(total_pts) if total_pts > 0 else "0"

	# デルタ = 今日プレイしたぶんのスコア合計（モチベーション指標）
	var today_delta: int = _compute_today_score_delta()
	if today_delta > 0:
		_score_delta.text = "+%s" % _format_thousands(today_delta)
		_score_delta.visible = true
	else:
		_score_delta.visible = false

	# 通算戦績 = ghost_7ban_shobu の round_win イベントから集計
	var wl: Dictionary = _compute_battle_wins_losses()
	_battle_caption.text = "通算"
	_battle_wins.text = "%d勝" % int(wl.get("wins", 0))
	_battle_losses.text = "%d敗" % int(wl.get("losses", 0))

	# ストリーク
	var streak_days: int = _compute_streak()
	_streak_ribbon.visible = streak_days > 0
	_streak_label.text = "%d日連続！" % streak_days

	# レーダー値
	var radar_values := _compute_radar_values()
	if _radar.has_method("set_values"):
		_radar.set_values(radar_values)


# ---------------------------------------------------------------------------
# データ算出ヘルパ
# ---------------------------------------------------------------------------

func _load_user_config() -> UserConfig:
	var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.USER_CONFIG)
	if dict.is_empty():
		return UserConfig.new()
	return UserConfig.from_dict(dict)


## 脳年齢: 年代から基準年齢を引いて、プレイ実績で若返り補正（GDD §脳年齢チューニング）。
## - 0 プレイ: 基準年齢
## - 1+ プレイ: 基準年齢 - (3 + plays / 5)、ただし base-15 〜 base+10 でクランプ
func _compute_brain_age() -> int:
	var cfg := _load_user_config()
	var base: int = DEFAULT_BASE_AGE
	if cfg != null and cfg.age_group != "":
		base = int(AGE_GROUP_TO_AGE.get(cfg.age_group, DEFAULT_BASE_AGE))
	var total_plays: int = DataStore.count_play_logs("")
	var bonus: int = 0
	if total_plays > 0:
		bonus = clampi(3 + total_plays / 5, 3, 15)
	return clampi(base - bonus, base - 15, base + 10)


## ポイント = 全 PlayLog の score 累積（生涯獲得ポイント）。
## 「今日のデルタ」と同じ集計軸（PlayLog.score）にすることで、
## delta は必ず total の部分集合になる（delta > total という矛盾を防ぐ）。
func _compute_total_score() -> int:
	var total: int = 0
	var logs: Array[PlayLog] = DataStore.load_play_logs("", -1)
	for log in logs:
		if log != null:
			total += log.score
	return total


## デルタ = 今日プレイした PlayLog の score 合計（total の部分集合）。
func _compute_today_score_delta() -> int:
	var today := DateUtil.today_jst()
	var logs: Array[PlayLog] = DataStore.load_play_logs("", -1)
	var total: int = 0
	for log in logs:
		if log != null and log.played_date == today:
			total += log.score
	return total


## ghost_7ban_shobu の通算勝敗 **セッション単位** で集計。
## 1 試合 = 7 ラウンド。試合内のラウンド勝ち数が 4 以上なら「勝ち越し」(1 勝)、
## 3 以下なら「負け越し」(1 敗) として通算カウント。
## (個別結果画面 _compute_verdict_title の wins >= 4 判定と同じ閾値)
func _compute_battle_wins_losses() -> Dictionary:
	var w: int = 0
	var l: int = 0
	var logs: Array[PlayLog] = DataStore.load_play_logs("ghost_7ban_shobu", -1)
	for log in logs:
		if log == null:
			continue
		var session_round_wins: int = 0
		for evt in log.events:
			if evt != null and evt.event_type == "round_win" and int(evt.value) == 1:
				session_round_wins += 1
		if session_round_wins >= 4:
			w += 1
		else:
			l += 1
	return {"wins": w, "losses": l}


## ストリーク日数を STREAK_STATE から読み込む。未保存なら 0。
func _compute_streak() -> int:
	var dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.STREAK_STATE)
	if dict.is_empty():
		return 0
	var state := StreakState.from_dict(dict)
	return state.current_streak


func _compute_radar_values() -> Array:
	# 各能力軸の best_score を 5000pts 基準で正規化（暫定）。データ無しは 0.05 で底上げ。
	var arr: Array = [0.05, 0.05, 0.05, 0.05, 0.05, 0.05]
	for i in ABILITY_KEYS.size():
		var key: String = ABILITY_KEYS[i]
		var game: String = String(ABILITY_TO_GAME.get(key, ""))
		if game == "":
			continue
		var best: GameBest = DataStore.load_best(game)
		if best != null and best.best_score > 0:
			arr[i] = clampf(float(best.best_score) / 5000.0, 0.05, 1.0)
	return arr


## 3 桁区切りフォーマット ("1280" -> "1,280")
static func _format_thousands(n: int) -> String:
	var negative := n < 0
	var s := str(absi(n))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" if negative else "") + result


# ---------------------------------------------------------------------------
# ボタン
# ---------------------------------------------------------------------------
func _on_cta_pressed() -> void:
	_speech_text.text = SPEECH_GO
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_game"):
		gm.start_game("ghost_7ban_shobu")
	else:
		push_warning("[Home] GameManager.start_game not found")


func _on_all_games_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_list.tscn")


func _on_settings_pressed() -> void:
	print("[Home] settings pressed (TODO)")


# ---------------------------------------------------------------------------
# アニメーション
# ---------------------------------------------------------------------------
func _animate_mascot_float() -> void:
	if _mascot == null:
		return
	var offset: float = sin(_anim_time * FLOAT_SPEED) * FLOAT_AMPLITUDE_PX
	_mascot.position.y = offset


func _animate_cta_pulse() -> void:
	if _cta_button == null:
		return
	_cta_button.pivot_offset = _cta_button.size * 0.5
	var pulse_t: float = (sin(_anim_time * TAU / PULSE_PERIOD_SEC) + 1.0) * 0.5
	var s: float = lerpf(PULSE_SCALE_MIN, PULSE_SCALE_MAX, pulse_t)
	_cta_button.scale = Vector2(s, s)
