## HomeController
##
## ホーム画面のコントローラ。
##
## FR-07（2回目以降の日常フロー）の UI 要素と、ユーザー入力（タップ）を仲介する。
## Stitch モックアップに基づく新レイアウト (2026-04-12 更新):
## - 上部: 脳年齢カード + ゴーストバトル勝敗バー
## - 中央上: ゴーストからの吹き出しメッセージ
## - 中央下: 6 能力グリッド (計算/記憶/注意/反応/観察/判断)
## - 底部: 大型 CTA + ボトムナビ 5 タブ
##
## [b]設計原則:[/b]
## - 色・フォント・サイズへの GDScript アクセスは禁止 (Theme 一任)
## - `modulate` の例外: GhostMascotBg の alpha は精度 % に連動（manifest §7）
## - Platform Autoload 経由のプラットフォーム分岐
extends Control

const GHOST_MASCOT_MIN_ALPHA: float = 0.12
const GHOST_MASCOT_MAX_ALPHA: float = 0.38

## アビリティアイコンの浮遊アニメの振幅と速度
const FLOAT_AMPLITUDE_PX: float = 4.0
const FLOAT_SPEED: float = 2.0

## CTA ボタンのパルスアニメの周期と強度
const PULSE_PERIOD_SEC: float = 2.0
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.03

## 能力軸 → ゲーム種別のマッピング (ScoreSystem.GAME_TO_ABILITY の逆引き)
const ABILITY_TO_GAME: Dictionary = {
	"calculation": "flash_calc",
	"memory": "sequence_memory",
	"attention": "stroop",
	"reflex": "reflex_tap",
	"observation": "number_search",
	"judgment": "card_match",
}

## 実装済みゲーム (GameManager.GAME_SCENES と同期)
const IMPLEMENTED_GAMES := ["reflex_tap", "flash_calc"]

@onready var _ghost_mascot_bg: TextureRect = $GhostMascotBg

@onready var _brain_age_value: Label = $SafeAreaMargin/MainColumn/HeaderRow/BrainAgePanel/BrainAgeVBox/BrainAgeRow/BrainAgeValue
@onready var _win_label: Label = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/WinSide/WinLabel
@onready var _loss_label: Label = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/LossSide/LossLabel
@onready var _win_side: PanelContainer = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/WinSide
@onready var _loss_side: PanelContainer = $SafeAreaMargin/MainColumn/HeaderRow/GhostBattlePanel/BattleVBox/BattleBarRow/LossSide

@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/SpeechBubblePanel/SpeechText

@onready var _cell_calculation: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellCalculation
@onready var _cell_memory: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellMemory
@onready var _cell_attention: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellAttention
@onready var _cell_reflex: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellReflex
@onready var _cell_observation: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellObservation
@onready var _cell_judgment: Button = $SafeAreaMargin/MainColumn/AbilityCard/AbilityVBox/AbilityGrid/CellJudgment

@onready var _start_button: Button = $SafeAreaMargin/MainColumn/StartButton

# v2 (DESIGN.md) ナビは 4 タブ: 脳トレ / ホーム (active) / アワード / 設定
# ホームタブは NavHomeActive (PanelContainer 青ピル) 配下の Button
@onready var _nav_train: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavTrainButton
@onready var _nav_home: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavHomeActive/NavHomeButton
@onready var _nav_award: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavAwardButton
@onready var _nav_settings: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavSettingsButton

@onready var _ad_banner_area: MarginContainer = $AdBannerArea


var _anim_time: float = 0.0


func _ready() -> void:
	_apply_placeholder_data()
	_wire_signals()
	_configure_platform_visibility()
	# pivot_offset は _process で毎フレーム現在サイズから計算する
	print_debug("HomeController: ready")


## アビリティアイコンの浮遊 + CTA のパルスを _process で毎フレーム更新する。
## Tween のループより軽量で決定論的。
func _process(delta: float) -> void:
	_anim_time += delta
	# アビリティアイコンの浮遊 (位相を cell ごとにずらす)
	var cells := [_cell_calculation, _cell_memory, _cell_attention, _cell_reflex, _cell_observation, _cell_judgment]
	for i in range(cells.size()):
		var cell: Button = cells[i]
		if cell == null:
			continue
		var vbox: Control = cell.get_node_or_null("VBox")
		if vbox == null:
			continue
		var phase: float = float(i) * 0.45
		var offset: float = sin(_anim_time * FLOAT_SPEED + phase) * FLOAT_AMPLITUDE_PX
		vbox.position.y = offset
	# CTA ボタンのパルス (ゆっくり拡縮)
	if _start_button != null:
		_start_button.pivot_offset = _start_button.size * 0.5
		var pulse_t: float = (sin(_anim_time * TAU / PULSE_PERIOD_SEC) + 1.0) * 0.5
		var scale_value: float = lerpf(PULSE_SCALE_MIN, PULSE_SCALE_MAX, pulse_t)
		_start_button.scale = Vector2(scale_value, scale_value)


## ダミーデータで UI を埋める。DataStore の実データ連動は後続タスク。
func _apply_placeholder_data() -> void:
	# 脳年齢 (仮値、実装後に DataStore から取得)
	_brain_age_value.text = "28"

	# ゴーストバトル勝敗 (仮値、GhostSystem.judge_result が本実装されたら自動計算)
	_set_battle_stats(15, 8)

	# ゴーストのセリフ (動的更新の起点は後続タスクで実装)
	_speech_text.text = "おかえり！昨日のあなたより計算力が上がってるよ！"

	# 背景マスコットの不透明度を精度 % に連動
	# (精度 0% → 0.12、精度 100% → 0.38)
	_apply_accuracy(0.67)


## ゴーストバトルの勝敗バーを更新する。
## win と loss の比率で size_flags_stretch_ratio を設定することで左右の幅が自動的に決まる。
## どちらかが 0 の場合でも 0.5 で描画し、バーが消えない最低保証を入れる。
func _set_battle_stats(win: int, loss: int) -> void:
	_win_label.text = "%d勝" % win
	_loss_label.text = "%d敗" % loss
	_win_side.size_flags_stretch_ratio = maxf(0.5, float(win))
	_loss_side.size_flags_stretch_ratio = maxf(0.5, float(loss))


## 精度を背景マスコットの不透明度に反映する。
## 精度 = プレイ済みゲーム種別 / 全 6 種 × 100%
## ホーム背景では 0.12〜0.38 の範囲で控えめに出す (コンテンツの可読性優先)。
func _apply_accuracy(accuracy: float) -> void:
	var clamped: float = clampf(accuracy, 0.0, 1.0)
	var alpha: float = GHOST_MASCOT_MIN_ALPHA + clamped * (GHOST_MASCOT_MAX_ALPHA - GHOST_MASCOT_MIN_ALPHA)
	_ghost_mascot_bg.modulate = Color(1, 1, 1, alpha)


## ボタンシグナルを接続する。
func _wire_signals() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)

	# 能力グリッドのタップ → 各ゲーム起動 (実装済みなら直接遷移、未実装ならゴーストが "coming soon")
	_cell_calculation.pressed.connect(_on_ability_pressed.bind("calculation"))
	_cell_memory.pressed.connect(_on_ability_pressed.bind("memory"))
	_cell_attention.pressed.connect(_on_ability_pressed.bind("attention"))
	_cell_reflex.pressed.connect(_on_ability_pressed.bind("reflex"))
	_cell_observation.pressed.connect(_on_ability_pressed.bind("observation"))
	_cell_judgment.pressed.connect(_on_ability_pressed.bind("judgment"))

	# ボトムナビ 4 タブ (ホーム以外は現状 no-op)
	_nav_train.pressed.connect(func(): print("[Home] NavTrain pressed (TODO)"))
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


## メイン CTA: 当面は反射タップ単体起動。
## 将来的にはデイリーチャレンジ (3 種連続) を起動する想定。
func _on_start_button_pressed() -> void:
	_speech_text.text = "よーし！一緒にがんばろう！"
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_game"):
		gm.start_game("reflex_tap")
	else:
		push_warning("[Home] GameManager.start_game not found")


## 能力グリッドのセルタップ。
## 対応ゲームが実装済みなら起動、未実装ならゴーストが "coming soon" セリフを出す。
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


func _ability_name(key: String) -> String:
	match key:
		"calculation":
			return "計算"
		"memory":
			return "記憶"
		"attention":
			return "注意"
		"reflex":
			return "反射"
		"observation":
			return "観察"
		"judgment":
			return "判断"
		_:
			return key
