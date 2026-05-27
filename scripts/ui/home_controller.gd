## HomeController (Sumi Ghost (墨絵調) v3)
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
# Sumi Ghost v4: home.tscn 再構築後のパス
@onready var _brain_age_value: Label = $SafeArea/MainColumn/TopRow/BrainAgeBlock/Margin/Content/Row/Value
@onready var _brain_age_accuracy: Label = $SafeArea/MainColumn/TopRow/BrainAgeBlock/Margin/Content/CaptionRow/AccuracyHint
@onready var _brain_age_progress: ProgressBar = $SafeArea/MainColumn/TopRow/BrainAgeBlock/Margin/Content/Progress
@onready var _settings_btn: Button = $SafeArea/MainColumn/TopRow/SettingsButton
@onready var _mascot: TextureRect = $SafeArea/MainColumn/HeroRow/MascotImage
@onready var _speech_text: Label = $SafeArea/MainColumn/HeroRow/SpeechWrap/SpeechBubble/Margin/SpeechText
@onready var _score_value: Label = $SafeArea/MainColumn/DailyScoreCard/Margin/Content/Row/Value
@onready var _score_delta: Label = $SafeArea/MainColumn/DailyScoreCard/Margin/Content/Row/Delta
@onready var _battle_caption: Label = $SafeArea/MainColumn/StatsAndStreakRow/StatsBlock/Margin/Content/Caption
@onready var _battle_wins: Label = $SafeArea/MainColumn/StatsAndStreakRow/StatsBlock/Margin/Content/Row/Wins
@onready var _battle_losses: Label = $SafeArea/MainColumn/StatsAndStreakRow/StatsBlock/Margin/Content/Row/Losses
@onready var _cta_button: Button = $SafeArea/MainColumn/DailyChallengeStrip/CTAWrap/CTAButton
@onready var _streak_ribbon: PanelContainer = $SafeArea/MainColumn/StatsAndStreakRow/StreakBlock
@onready var _streak_label: Label = $SafeArea/MainColumn/StatsAndStreakRow/StreakBlock/Margin/Content/Text
@onready var _radar: Control = $SafeArea/MainColumn/RadarCard/Margin/Radar
@onready var _all_games_link: Button = $SafeArea/MainColumn/AllGamesLink

var _anim_time: float = 0.0


func _ready() -> void:
	_wire_signals()
	_apply_data()
	set_process(true)
	_setup_mascot_controller()


## Sumi Ghost v4: MascotController を取得して精度連動グローを駆動する
func _setup_mascot_controller() -> void:
	var mc := get_node_or_null("SafeArea/MainColumn/HeroRow/MascotController")
	if mc == null:
		# シーンに未配置の場合は no-op
		return
	if mc.has_method("to_idle"):
		mc.to_idle()
	if mc.has_method("set_accuracy"):
		mc.set_accuracy(_compute_accuracy())


## 精度 = プレイ済み種目数 / 全種目数 (0.0 .. 1.0)
func _compute_accuracy() -> float:
	var ds := get_node_or_null("/root/DataStore")
	if ds == null:
		return 0.0
	var user_config = ds.load_dict(ds.StoreKey.USER_CONFIG) if ds.has_method("load_dict") else {}
	var played: Array = user_config.get("played_game_types", [])
	var total: int = ALL_GAME_TYPES.size()
	if total <= 0:
		return 0.0
	return clamp(float(played.size()) / float(total), 0.0, 1.0)


func _process(delta: float) -> void:
	_anim_time += delta
	_animate_mascot_float()
	_animate_cta_pulse()


func _wire_signals() -> void:
	_cta_button.pressed.connect(_on_cta_pressed)
	_all_games_link.pressed.connect(_on_all_games_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	# Sumi Ghost v4: レーダー「鍛える →」ボタン → 最弱軸の推奨ゲームを開始
	if _radar.has_signal("train_pressed"):
		_radar.train_pressed.connect(_on_train_pressed)


## レーダー「鍛える →」: 最弱軸に紐づくゲームを起動。
## ABILITY_KEYS の並びと RadarChart の軸インデックスは一致 (計算 / 記憶 / 注意 / 反射 / 観察 / 判断)。
func _on_train_pressed(weakest_axis: int) -> void:
	if weakest_axis < 0 or weakest_axis >= ABILITY_KEYS.size():
		_on_all_games_pressed()
		return
	var ability: String = ABILITY_KEYS[weakest_axis]
	var game_type: String = ABILITY_TO_GAME.get(ability, "")
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_game") and game_type != "":
		gm.start_game(game_type)
	else:
		_on_all_games_pressed()


# ---------------------------------------------------------------------------
# データ反映（すべて DataStore / GhostData の実データから算出）
# ---------------------------------------------------------------------------
func _apply_data() -> void:
	_brain_age_value.text = str(_compute_brain_age())
	_speech_text.text = SPEECH_RETURN

	# Sumi Ghost v4: 脳年齢カード内の精度ヒント + プログレスバー
	var accuracy: float = _compute_accuracy()
	_brain_age_accuracy.text = "精度 %d%%" % int(round(accuracy * 100.0))
	_brain_age_progress.value = accuracy

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

	# ストリーク (テキスト) + 直近 7 日のスタンプ点灯
	var streak_days: int = _compute_streak()
	_streak_ribbon.visible = true
	if streak_days > 0:
		_streak_label.text = "%d日連続！" % streak_days
	else:
		_streak_label.text = "今日からスタート"
	_apply_streak_stamps(_compute_recent_7_days_played())

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


## 直近 7 日のプレイ有無を [6日前, ..., 1日前, 今日] の順で返す。
## PlayLog.played_date ("YYYY-MM-DD" JST) を参照。
func _compute_recent_7_days_played() -> Array:
	var logs: Array[PlayLog] = DataStore.load_play_logs("", -1)
	var played_dates := {}
	for log in logs:
		if log.played_date != "":
			played_dates[log.played_date] = true
	var today := Time.get_date_dict_from_system()
	var today_unix: int = Time.get_unix_time_from_datetime_dict({
		"year": today.year, "month": today.month, "day": today.day,
		"hour": 0, "minute": 0, "second": 0
	})
	var result: Array = []
	for offset in range(6, -1, -1):
		var t := today_unix - offset * 86400
		var d := Time.get_datetime_dict_from_unix_time(t)
		var key := "%04d-%02d-%02d" % [d.year, d.month, d.day]
		result.append(played_dates.has(key))
	return result


## 7 個のスタンプ TextureRect に直近 7 日のプレイ状況を反映 (modulate.a で点灯/減衰)
func _apply_streak_stamps(played_flags: Array) -> void:
	var row := get_node_or_null("SafeArea/MainColumn/StatsAndStreakRow/StreakBlock/Margin/Content/Row")
	if row == null:
		return
	for i in 7:
		var stamp := row.get_node_or_null("Stamp%d" % i) as TextureRect
		if stamp == null:
			continue
		var played: bool = i < played_flags.size() and bool(played_flags[i])
		stamp.modulate = Color(1, 1, 1, 1.0 if played else 0.18)


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
