## HomeController
##
## ホーム画面のコントローラ。
##
## FR-07（2回目以降の日常フロー）の UI 要素と、ユーザー入力（タップ）を仲介する。
## Stitch v0.1 デザインに基づくレイアウト (2026-04-13 再構築):
## - 上部: 脳年齢カード + ゴーストバトル勝敗バー
## - ストリークバッジ（Docs追加）
## - 中央上: ゴーストからの吹き出しメッセージ
## - 条件付きバナー（年代設定 / 復帰演出）
## - 中央下: 6 能力グリッド (人魂アイコンで得意/苦手を視覚化)
## - 底部: 大型 CTA + ボトムナビ 5 タブ
##
## [b]設計原則:[/b]
## - 色・フォント・サイズへの GDScript アクセスは禁止 (Theme 一任)
## - `modulate` の例外: GhostMascotBg の alpha は精度 % に連動
## - Platform Autoload 経由のプラットフォーム分岐
## - アセットパスは定数で集約し、差し替え容易にする
extends Control

# ---------------------------------------------------------------------------
# アセットパス定数 — バージョンアップ時はここを変更するだけで差し替え可能
# ---------------------------------------------------------------------------
const GHOST_TEXTURE := "res://assets/characters/ghost_seirei.png"
const BG_TEXTURE := "res://assets/textures/gradients/page_bg_v2.png"
const HITODAMA_TEXTURES: Array[String] = [
	"res://assets/icons/hitodama_lv1.png",
	"res://assets/icons/hitodama_lv2.png",
	"res://assets/icons/hitodama_lv3.png",
	"res://assets/icons/hitodama_lv4.png",
	"res://assets/icons/hitodama_lv5.png",
]

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------
const FLOAT_AMPLITUDE_PX: float = 4.0
const FLOAT_SPEED: float = 2.0

const PULSE_PERIOD_SEC: float = 2.0
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.03

## 能力軸 → ゲーム種別のマッピング
const ABILITY_TO_GAME: Dictionary = {
	"calculation": "flash_calc",
	"memory": "sequence_memory",
	"attention": "stroop",
	"reflex": "reflex_tap",
	"observation": "number_search",
	"judgment": "card_match",
}

## 能力軸の表示順（GridContainer の列順と一致させる）
const ABILITY_KEYS: Array[String] = [
	"calculation", "memory", "attention", "reflex", "observation", "judgment",
]

## 実装済みゲーム (GameManager.GAME_SCENES と同期)
const IMPLEMENTED_GAMES := ["reflex_tap", "flash_calc", "sequence_memory"]

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------
# ヘッダー
@onready var _brain_age_value: Label = $SafeAreaMargin/MainColumn/HeaderRow/BrainAgePanel/BrainAgeVBox/BrainAgeRow/BrainAgeValue
@onready var _win_label: Label = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/WinSide/WinLabel
@onready var _loss_label: Label = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/LossSide/LossLabel
@onready var _win_side: PanelContainer = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/WinSide
@onready var _loss_side: PanelContainer = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/LossSide

# ストリーク（Docs追加）
@onready var _streak_badge: HBoxContainer = $SafeAreaMargin/MainColumn/StreakBadge

# 吹き出し
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/SpeechBubblePanel/BubbleMargin/SpeechText

# 能力グリッド
@onready var _cell_calculation: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellCalculation
@onready var _cell_memory: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellMemory
@onready var _cell_attention: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellAttention
@onready var _cell_reflex: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellReflex
@onready var _cell_observation: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellObservation
@onready var _cell_judgment: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellJudgment

# CTA
@onready var _start_button: Button = $SafeAreaMargin/MainColumn/StartButton

# ボトムナビ 5 タブ
@onready var _nav_train: Button = $BottomNavPanel/BottomNavBar/NavTrainButton
@onready var _nav_analytics: Button = $BottomNavPanel/BottomNavBar/NavAnalyticsButton
@onready var _nav_home: Button = $BottomNavPanel/BottomNavBar/NavHomeActive/NavHomeButton
@onready var _nav_award: Button = $BottomNavPanel/BottomNavBar/NavAwardButton
@onready var _nav_settings: Button = $BottomNavPanel/BottomNavBar/NavSettingsButton

# 広告エリア
@onready var _ad_banner_area: MarginContainer = $AdBannerArea

# 人魂テクスチャキャッシュ（起動時にプリロード）
var _hitodama_cache: Array[Texture2D] = []

var _anim_time: float = 0.0


func _ready() -> void:
	_preload_hitodama()
	_apply_data()
	_check_welcome_back()
	_wire_signals()
	_configure_platform_visibility()
	print_debug("HomeController: ready")


func _process(delta: float) -> void:
	_anim_time += delta
	_animate_cta_pulse()


# ---------------------------------------------------------------------------
# 初期化
# ---------------------------------------------------------------------------

## 人魂テクスチャをプリロードしてキャッシュ
func _preload_hitodama() -> void:
	for path in HITODAMA_TEXTURES:
		# importキャッシュが壊れている環境では load() が失敗するため
		# Image.load_from_file で直接PNGを読み込む
		var abs_path: String = ProjectSettings.globalize_path(path)
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var itex := ImageTexture.create_from_image(img)
			_hitodama_cache.append(itex)
		else:
			# fallback: load() を試す
			var tex = load(path)
			if tex is Texture2D:
				_hitodama_cache.append(tex)
			else:
				push_warning("[Home] Failed to load hitodama: %s" % path)
				_hitodama_cache.append(null)


## DataStore からデータを読み込んで UI に反映する
func _apply_data() -> void:
	var ds := _get_data_store()

	# --- 脳年齢 ---
	var brain_age := 24  # TODO: ScoreSystem から算出
	_brain_age_value.text = str(brain_age)

	# --- ゴーストバトル戦績 ---
	var win := 15   # TODO: GhostSystem から取得
	var loss := 8   # TODO: GhostSystem から取得
	_set_battle_stats(win, loss)

	# --- ストリーク ---
	_apply_streak(ds)

	# --- ゴースト吹き出し ---
	_speech_text.text = "おかえり！今日もトレーニングしよう！"

	# --- 能力グリッドの人魂レベル ---
	_apply_ability_levels(ds)


## プレイ済みゲーム種別数 / 全 6 種 で精度を算出
func _calc_accuracy(ds: Node) -> float:
	if ds == null:
		return 0.0
	var played_count := 0
	for ability_key in ABILITY_KEYS:
		var game_type: String = ABILITY_TO_GAME.get(ability_key, "")
		if game_type != "" and ds.has_method("count_play_logs"):
			if ds.count_play_logs(game_type) > 0:
				played_count += 1
	return float(played_count) / float(ABILITY_KEYS.size())


## ストリーク日数を反映
func _apply_streak(ds: Node) -> void:
	if _streak_badge == null:
		return
	var streak_days := 0
	if ds != null and ds.has_method("load_dict"):
		var state: Dictionary = ds.load_dict(3)  # StoreKey.STREAK_STATE = 3
		streak_days = state.get("current_streak", 0)
	if streak_days > 0:
		_streak_badge.visible = true
		var streak_label: Label = _streak_badge.get_node_or_null("StreakLabel")
		if streak_label != null:
			streak_label.text = "%d日連続！" % streak_days
	else:
		_streak_badge.visible = false


## ゴーストバトルの勝敗バーを更新する。
func _set_battle_stats(win: int, loss: int) -> void:
	_win_label.text = "%d勝" % win
	_loss_label.text = "%d敗" % loss
	_win_side.size_flags_stretch_ratio = maxf(0.5, float(win))
	_loss_side.size_flags_stretch_ratio = maxf(0.5, float(loss))


## デモ用の固定レベル（全5段階が確認できるよう各能力に異なるレベルを割り当て）
const DEMO_LEVELS: Array[int] = [4, 2, 3, 1, 2, 5]

## 各能力の人魂レベル（1〜5）を算出して IconRect テクスチャを設定
func _apply_ability_levels(ds: Node) -> void:
	var cells := _get_ability_cells()
	# 実データがあるか判定: 1つでもプレイ済みゲームがあれば実データ使用
	var has_real_data := false
	if ds != null and ds.has_method("load_best"):
		for key in ABILITY_KEYS:
			var gt: String = ABILITY_TO_GAME.get(key, "")
			if gt != "":
				var best = ds.load_best(gt)
				if best != null and best.best_score > 0:
					has_real_data = true
					break
	# 実データのスコアが低い（全てLv1相当）場合はデモ表示にフォールバック
	if has_real_data:
		var all_lv1 := true
		for key in ABILITY_KEYS:
			if _calc_ability_level(ds, key) > 1:
				all_lv1 = false
				break
		if all_lv1:
			has_real_data = false
	for i in range(ABILITY_KEYS.size()):
		var level: int
		if not has_real_data:
			level = DEMO_LEVELS[i]
		else:
			level = _calc_ability_level(ds, ABILITY_KEYS[i])
		var cell: Button = cells[i]
		var icon_rect: TextureRect = cell.get_node_or_null("CellVBox/IconRect")
		if icon_rect != null and level >= 1 and level <= _hitodama_cache.size():
			icon_rect.texture = _hitodama_cache[level - 1]


## 能力レベルを算出（1〜5）。未プレイ = Lv1、スコアに応じて段階的に上昇。
func _calc_ability_level(ds: Node, ability_key: String) -> int:
	if ds == null:
		return 1
	var game_type: String = ABILITY_TO_GAME.get(ability_key, "")
	if game_type == "":
		return 1
	if not ds.has_method("load_best"):
		return 1
	var best: GameBest = ds.load_best(game_type)
	if best == null:
		return 1
	var score: int = best.best_score
	if score <= 0:
		return 1
	if score >= 2500:
		return 5
	elif score >= 1800:
		return 4
	elif score >= 1000:
		return 3
	elif score >= 400:
		return 2
	else:
		return 1


# ---------------------------------------------------------------------------
# 条件付き表示（Docs準拠）
# ---------------------------------------------------------------------------

## 復帰演出チェック（Docs A-06）
func _check_welcome_back() -> void:
	var ds := _get_data_store()
	if ds == null or not ds.has_method("load_dict"):
		return
	var state: Dictionary = ds.load_dict(3)  # StoreKey.STREAK_STATE
	if state.is_empty():
		return
	if not state.get("welcome_back_shown", true):
		var streak: int = state.get("current_streak", 0)
		if streak > 0:
			_speech_text.text = "おかえりなさい！%d日連続すごいね。\n今日もやる？" % streak
		state["welcome_back_shown"] = true
		if ds.has_method("save"):
			ds.save(3, state)  # StoreKey.STREAK_STATE


# ---------------------------------------------------------------------------
# シグナル接続
# ---------------------------------------------------------------------------

func _wire_signals() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)

	# 能力グリッド
	_cell_calculation.pressed.connect(_on_ability_pressed.bind("calculation"))
	_cell_memory.pressed.connect(_on_ability_pressed.bind("memory"))
	_cell_attention.pressed.connect(_on_ability_pressed.bind("attention"))
	_cell_reflex.pressed.connect(_on_ability_pressed.bind("reflex"))
	_cell_observation.pressed.connect(_on_ability_pressed.bind("observation"))
	_cell_judgment.pressed.connect(_on_ability_pressed.bind("judgment"))

	# ボトムナビ 5 タブ
	_nav_train.pressed.connect(_on_nav_train_pressed)
	_nav_analytics.pressed.connect(func(): print("[Home] NavAnalytics pressed (TODO)"))
	_nav_home.pressed.connect(func(): print("[Home] NavHome pressed (already on home)"))
	_nav_award.pressed.connect(func(): print("[Home] NavAward pressed (TODO)"))
	_nav_settings.pressed.connect(func(): print("[Home] NavSettings pressed (TODO)"))


## プラットフォーム分岐。広告バナーは Android 版でのみ表示する。
func _configure_platform_visibility() -> void:
	var supports_ads := false
	if Engine.has_singleton("Platform"):
		var platform = Engine.get_singleton("Platform")
		if platform.has_method("supports_admob"):
			supports_ads = platform.supports_admob()
	_ad_banner_area.visible = supports_ads


# ---------------------------------------------------------------------------
# ボタンハンドラ
# ---------------------------------------------------------------------------

func _on_nav_train_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("navigate_to_game_list"):
		gm.navigate_to_game_list()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/game_list.tscn")


func _on_start_button_pressed() -> void:
	_speech_text.text = "よーし！一緒にがんばろう！"
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_game"):
		gm.start_game("reflex_tap")
	else:
		push_warning("[Home] GameManager.start_game not found")


func _on_ability_pressed(ability_key: String) -> void:
	var game_type: String = String(ABILITY_TO_GAME.get(ability_key, ""))
	if game_type == "":
		push_warning("[Home] Unknown ability: %s" % ability_key)
		return
	if game_type in IMPLEMENTED_GAMES:
		_speech_text.text = "%s のトレーニングだね、いくよ！" % _ability_name(ability_key)
		var gm := get_node_or_null("/root/GameManager")
		if gm != null and gm.has_method("start_game"):
			gm.start_game(game_type)
	else:
		_speech_text.text = "%s はまだ準備中だよ。\nもう少し待ってね！" % _ability_name(ability_key)


# ---------------------------------------------------------------------------
# アニメーション
# ---------------------------------------------------------------------------

func _animate_ability_cells() -> void:
	var cells := _get_ability_cells()
	for i in range(cells.size()):
		var cell: Button = cells[i]
		if cell == null:
			continue
		var vbox: Control = cell.get_node_or_null("CellVBox")
		if vbox == null:
			continue
		var phase: float = float(i) * 0.45
		var offset: float = sin(_anim_time * FLOAT_SPEED + phase) * FLOAT_AMPLITUDE_PX
		vbox.position.y = offset


func _animate_cta_pulse() -> void:
	if _start_button != null:
		_start_button.pivot_offset = _start_button.size * 0.5
		var pulse_t: float = (sin(_anim_time * TAU / PULSE_PERIOD_SEC) + 1.0) * 0.5
		var scale_value: float = lerpf(PULSE_SCALE_MIN, PULSE_SCALE_MAX, pulse_t)
		_start_button.scale = Vector2(scale_value, scale_value)


# ---------------------------------------------------------------------------
# ユーティリティ
# ---------------------------------------------------------------------------

func _get_ability_cells() -> Array[Button]:
	return [_cell_calculation, _cell_memory, _cell_attention,
			_cell_reflex, _cell_observation, _cell_judgment]


func _get_data_store() -> Node:
	return get_node_or_null("/root/DataStore")


func _ability_name(key: String) -> String:
	match key:
		"calculation": return "計算"
		"memory": return "記憶"
		"attention": return "注意"
		"reflex": return "反射"
		"observation": return "観察"
		"judgment": return "判断"
		_: return key
