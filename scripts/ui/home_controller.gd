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
# データ反映
# ---------------------------------------------------------------------------
func _apply_data() -> void:
	var ds: Node = get_node_or_null("/root/DataStore")
	var cfg: Variant = null
	if ds != null and ds.has_method("load_config"):
		cfg = ds.load_config()
	var brain_age: int = 31
	if cfg != null and "base_age" in cfg:
		brain_age = int(cfg.base_age)
	_brain_age_value.text = str(brain_age)
	_speech_text.text = SPEECH_RETURN

	# ポイント・戦績はモック値（実装は別タスク）
	_score_value.text = "3,230"
	_score_delta.text = "+285"
	_battle_caption.text = "通算"
	_battle_wins.text = "15勝"
	_battle_losses.text = "8敗"

	# ストリーク (DataStore からだが MVP はモック)
	var streak_days := 5
	if ds != null and ds.has_method("load_streak"):
		var s = ds.load_streak()
		if s != null and "current_streak" in s:
			streak_days = int(s.current_streak)
	_streak_ribbon.visible = streak_days > 0
	_streak_label.text = "%d日連続！" % streak_days

	# レーダー値（MVP は固定モック。本番は DataStore.load_play_logs から平均化）
	var radar_values := _compute_radar_values(ds)
	if _radar.has_method("set_values"):
		_radar.set_values(radar_values)


func _compute_radar_values(ds: Node) -> Array:
	var arr: Array = [0.5, 0.6, 0.5, 0.7, 0.45, 0.55]
	if ds == null:
		return arr
	for i in ABILITY_KEYS.size():
		var key: String = ABILITY_KEYS[i]
		var game: String = String(ABILITY_TO_GAME.get(key, ""))
		if game == "":
			continue
		if ds.has_method("load_best"):
			var best = ds.load_best(game)
			if best != null and "best_score" in best and best.best_score > 0:
				arr[i] = clampf(float(best.best_score) / 5000.0, 0.05, 1.0)
	return arr


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
