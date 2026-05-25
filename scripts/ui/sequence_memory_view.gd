## SequenceMemoryView
##
## 順番記憶シーンスクリプト。SequenceMemory ロジックを内包し、
## パネルの表示アニメーション・入力処理・ラウンド進行を管理する。
##
## Midnight Cat デザイン (2026-05-17):
## - 上部: ROUND ピル (CYAN_400 ボーダー) + 指示テキスト (mc_h2 serif, フェーズ別色)
## - 中央: 3x3 メモリーグリッド (rule_explain 側のプレビューと整合)
##   - showing 中（光中）: CYAN_400 発光 + 番号
##   - showing 中（未光）: 暗グラスでほぼ透明
##   - input 中（タップ待ち）: NEUTRAL_SLATE グレー塗りで「タップ可能」と明示
##   - 正解タップ瞬間: GOLD_400 で 200ms フラッシュ
##   - 誤タップ: NEUTRAL_GRAY 飽和（赤は GDD §6 で禁止）
## - 右上: タイマー (CYAN_300 28px on 暗グラスチップ)
## - クリア系のためプレイ中ゴーストバトルバー非表示 (GDD §5c)
extends Control

# Midnight Cat パレット (color_palette.gd と同期)
const COLOR_ACTIVE_BG := Color(0.435, 0.706, 1, 0.85)        # CYAN_400 α=0.85
const COLOR_ACTIVE_BORDER := Color(0.722, 0.878, 1, 1)        # CYAN_300
const COLOR_ACTIVE_TEXT := Color(0.957, 0.969, 1, 1)          # INK_100
const COLOR_NORMAL_TEXT := Color(0.957, 0.969, 1, 0)          # 透明（非表示時）
const COLOR_ACTIVE_GLOW := Color(0.435, 0.706, 1, 0.7)        # CYAN_400 α=0.7 for shadow

# 入力フェーズの "タップ可能" 表示 (グレー)
const COLOR_TAPPABLE_BG := Color(0.58, 0.639, 0.722, 0.5)     # NEUTRAL_SLATE α=0.5
const COLOR_TAPPABLE_BORDER := Color(0.78, 0.824, 0.91, 0.7)  # INK_80 α=0.7

# 正解タップ瞬間のゴールドフラッシュ (200ms)
const COLOR_TAP_FLASH_BG := Color(0.961, 0.78, 0.416, 0.95)   # GOLD_400 α=0.95
const COLOR_TAP_FLASH_BORDER := Color(1.0, 0.914, 0.659, 1)   # GOLD_300
const COLOR_TAP_FLASH_GLOW := Color(0.961, 0.78, 0.416, 0.7)
const TAP_FLASH_DURATION_SEC: float = 0.2

# 誤タップ表示 (GDD §6: 赤系不使用、暗グレー + X アイコン + シェイクで視認性確保)
const COLOR_WRONG_BG := Color(0.18, 0.21, 0.27, 0.98)         # INK_20 寄りの暗グレー（タップ可能グレーより明らかに暗い）
const COLOR_WRONG_BORDER := Color(0.78, 0.824, 0.91, 0.85)    # INK_80 で輪郭を強調
const COLOR_WRONG_X := Color(0.957, 0.969, 1, 0.95)           # INK_100 で X を白く
const COLOR_WRONG_SHADOW := Color(0, 0, 0, 0.6)

# 正解パネルを誤タップ後にヒント表示する（学習効果）
const COLOR_CORRECT_HINT_BG := Color(0.435, 0.706, 1, 0.55)   # CYAN_400 dim
const COLOR_CORRECT_HINT_BORDER := Color(0.722, 0.878, 1, 0.9)  # CYAN_300

# 誤タップ後、結果画面へ遷移するまでの猶予（フィードバックを見せる時間）
const WRONG_FEEDBACK_DURATION_SEC: float = 1.6
const MAX_CLEAR_HOLD_DURATION_SEC: float = 1.2

# 指示テキストのフェーズ別色
const INSTRUCTION_COLOR_SHOWING := Color(0.78, 0.824, 0.91, 1)   # INK_80
const INSTRUCTION_COLOR_INPUT := Color(0.722, 0.878, 1, 1)        # CYAN_300
const INSTRUCTION_COLOR_CLEAR := Color(0.961, 0.78, 0.416, 1)     # GOLD_400
const INSTRUCTION_COLOR_FAILED := Color(0.533, 0.588, 0.69, 1)    # INK_60

const _MSYM_FONT = preload("res://assets/fonts/MaterialSymbolsRounded.ttf")

@onready var _round_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/RoundBadgeCenter/RoundBadge/RoundLabel
@onready var _instruction_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/InstructionLabel
@onready var _timer_label: Label = $TimerRing/TimerLabel
@onready var _memory_grid: GridContainer = $SafeAreaMargin/MainColumn/GridCenter/MemoryGrid

# 終了時のフィードバックを見せるため、game_finished シグナル受領後すぐに遷移せずタイマで遅延させる。
var _pending_finish_log: PlayLog = null

var _game: SequenceMemory
var _seed_value: int = -1
var _panels: Array[Button] = []
var _showing_index: int = 0
var _show_timer: float = 0.0
var _show_phase_active: bool = false  # パネルが光っている最中
var _show_phase_pause: bool = false   # パネル間の暗転中
var _elapsed_sec: int = 0


func _ready() -> void:
	_game = SequenceMemory.new()
	add_child(_game)
	_game.game_finished.connect(_on_game_finished)
	_game.setup(_seed_value)

	_collect_panels()
	_wire_panels()
	_set_panels_disabled(true)

	_game.start()
	_update_round_display()
	_start_showing_phase()


func set_seed(seed_value: int) -> void:
	_seed_value = seed_value


func _process(delta: float) -> void:
	if _game == null or not _game._is_active:
		return

	# タイマー表示
	_elapsed_sec = int(_game.get_elapsed_ms() / 1000)
	_timer_label.text = str(_elapsed_sec)

	# 表示フェーズアニメーション
	if _game.get_phase() == "showing":
		_process_showing_phase(delta)


func _collect_panels() -> void:
	_panels = []
	for i in range(SequenceMemory.GRID_SIZE):
		var panel: Button = _memory_grid.get_node("Panel%d" % i)
		_panels.append(panel)


func _wire_panels() -> void:
	for i in range(_panels.size()):
		_panels[i].pressed.connect(_on_panel_pressed.bind(i))


func _set_panels_disabled(disabled: bool) -> void:
	for panel in _panels:
		panel.disabled = disabled


func _reset_all_panels() -> void:
	for panel in _panels:
		panel.text = " "
		panel.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
		panel.remove_theme_stylebox_override("normal")
		panel.remove_theme_stylebox_override("hover")
		panel.remove_theme_stylebox_override("pressed")
		panel.remove_theme_stylebox_override("disabled")
		panel.remove_theme_stylebox_override("focus")


## input フェーズで全パネルを「グレー塗りでタップ可能」状態にする。
## ユーザがタップできることが視覚的に明確になる。
func _show_panels_tappable() -> void:
	var tappable := _build_tappable_style()
	for panel in _panels:
		panel.add_theme_stylebox_override("normal", tappable)
		panel.add_theme_stylebox_override("hover", tappable)
		panel.add_theme_stylebox_override("focus", tappable)


func _build_tappable_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_TAPPABLE_BG
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_TAPPABLE_BORDER
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 8
	sb.content_margin_top = 8
	sb.content_margin_right = 8
	sb.content_margin_bottom = 8
	return sb


## 正解タップ瞬間のゴールドフラッシュ。TAP_FLASH_DURATION_SEC 経過後にタップ可能状態へ戻す。
func _flash_correct(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	var flash := StyleBoxFlat.new()
	flash.bg_color = COLOR_TAP_FLASH_BG
	flash.border_width_left = 2
	flash.border_width_top = 2
	flash.border_width_right = 2
	flash.border_width_bottom = 2
	flash.border_color = COLOR_TAP_FLASH_BORDER
	flash.corner_radius_top_left = 18
	flash.corner_radius_top_right = 18
	flash.corner_radius_bottom_right = 18
	flash.corner_radius_bottom_left = 18
	flash.shadow_color = COLOR_TAP_FLASH_GLOW
	flash.shadow_size = 20
	flash.shadow_offset = Vector2(0, 0)
	flash.content_margin_left = 8
	flash.content_margin_top = 8
	flash.content_margin_right = 8
	flash.content_margin_bottom = 8
	panel.add_theme_stylebox_override("normal", flash)
	panel.add_theme_stylebox_override("hover", flash)
	panel.add_theme_stylebox_override("disabled", flash)
	# タイマで通常タップ可能状態へ戻す
	var timer := get_tree().create_timer(TAP_FLASH_DURATION_SEC)
	timer.timeout.connect(_revert_panel_to_tappable.bind(index))


func _revert_panel_to_tappable(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	# ゲームが進行中の場合のみタップ可能状態へ戻す（level_clear / finished フェーズなら触らない）
	if _game == null or _game.get_phase() != "input":
		return
	var panel: Button = _panels[index]
	var tappable := _build_tappable_style()
	panel.add_theme_stylebox_override("normal", tappable)
	panel.add_theme_stylebox_override("hover", tappable)
	panel.add_theme_stylebox_override("disabled", tappable)


func _highlight_panel(index: int, order_number: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	panel.text = str(order_number)
	panel.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)
	panel.add_theme_font_size_override("font_size", 56)
	# アクティブ（CYAN_400 発光）
	var active_style := StyleBoxFlat.new()
	active_style.bg_color = COLOR_ACTIVE_BG
	active_style.border_width_left = 2
	active_style.border_width_top = 2
	active_style.border_width_right = 2
	active_style.border_width_bottom = 2
	active_style.border_color = COLOR_ACTIVE_BORDER
	active_style.corner_radius_top_left = 18
	active_style.corner_radius_top_right = 18
	active_style.corner_radius_bottom_right = 18
	active_style.corner_radius_bottom_left = 18
	active_style.shadow_color = COLOR_ACTIVE_GLOW
	active_style.shadow_size = 24
	active_style.shadow_offset = Vector2(0, 0)
	active_style.content_margin_left = 8
	active_style.content_margin_top = 8
	active_style.content_margin_right = 8
	active_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("normal", active_style)
	panel.add_theme_stylebox_override("hover", active_style)
	panel.add_theme_stylebox_override("disabled", active_style)


func _dim_panel(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	panel.text = " "
	panel.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
	panel.remove_theme_stylebox_override("normal")
	panel.remove_theme_stylebox_override("hover")
	panel.remove_theme_stylebox_override("disabled")


## 誤タップ時のフィードバック。
## - wrong_index: ユーザが誤って押したパネル → 暗グレー塗り + X (Material `close`) アイコン + シェイク
## - correct_index: 本来押すべきだったパネル → シアン dim でヒント表示（学習効果）
## - 赤系は GDD §6 / 開発ガイドラインで禁止のため使わない。
func _flash_wrong(wrong_index: int, correct_index: int) -> void:
	if wrong_index < 0 or wrong_index >= _panels.size():
		return
	var wrong_panel: Button = _panels[wrong_index]
	# 暗グレー + 白枠 + X アイコン
	var wrong_style := StyleBoxFlat.new()
	wrong_style.bg_color = COLOR_WRONG_BG
	wrong_style.border_width_left = 3
	wrong_style.border_width_top = 3
	wrong_style.border_width_right = 3
	wrong_style.border_width_bottom = 3
	wrong_style.border_color = COLOR_WRONG_BORDER
	wrong_style.corner_radius_top_left = 18
	wrong_style.corner_radius_top_right = 18
	wrong_style.corner_radius_bottom_right = 18
	wrong_style.corner_radius_bottom_left = 18
	wrong_style.shadow_color = COLOR_WRONG_SHADOW
	wrong_style.shadow_size = 12
	wrong_style.shadow_offset = Vector2(0, 4)
	wrong_style.content_margin_left = 8
	wrong_style.content_margin_top = 8
	wrong_style.content_margin_right = 8
	wrong_style.content_margin_bottom = 8
	wrong_panel.add_theme_stylebox_override("normal", wrong_style)
	wrong_panel.add_theme_stylebox_override("hover", wrong_style)
	wrong_panel.add_theme_stylebox_override("disabled", wrong_style)
	# Material Symbol "close" (X 印)
	wrong_panel.text = "close"
	wrong_panel.add_theme_font_override("font", _MSYM_FONT)
	wrong_panel.add_theme_font_size_override("font_size", 96)
	wrong_panel.add_theme_color_override("font_color", COLOR_WRONG_X)

	# シェイク (短く 4 振り、合計 ~0.35s)
	_shake_panel(wrong_panel)

	# 正解パネルをシアン dim でヒント表示（同じ位置だった場合はスキップ）
	if correct_index >= 0 and correct_index < _panels.size() and correct_index != wrong_index:
		_hint_correct_panel(correct_index)


func _shake_panel(panel: Button) -> void:
	# pivot を中心に設定して回転シェイク
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(panel, "rotation", deg_to_rad(-4.0), 0.06)
	tween.tween_property(panel, "rotation", deg_to_rad(4.0), 0.10)
	tween.tween_property(panel, "rotation", deg_to_rad(-3.0), 0.09)
	tween.tween_property(panel, "rotation", 0.0, 0.08)


func _hint_correct_panel(index: int) -> void:
	var panel: Button = _panels[index]
	var hint := StyleBoxFlat.new()
	hint.bg_color = COLOR_CORRECT_HINT_BG
	hint.border_width_left = 2
	hint.border_width_top = 2
	hint.border_width_right = 2
	hint.border_width_bottom = 2
	hint.border_color = COLOR_CORRECT_HINT_BORDER
	hint.corner_radius_top_left = 18
	hint.corner_radius_top_right = 18
	hint.corner_radius_bottom_right = 18
	hint.corner_radius_bottom_left = 18
	hint.shadow_color = Color(0.435, 0.706, 1, 0.5)
	hint.shadow_size = 16
	hint.shadow_offset = Vector2(0, 0)
	hint.content_margin_left = 8
	hint.content_margin_top = 8
	hint.content_margin_right = 8
	hint.content_margin_bottom = 8
	panel.add_theme_stylebox_override("normal", hint)
	panel.add_theme_stylebox_override("hover", hint)
	panel.add_theme_stylebox_override("disabled", hint)


func _set_instruction(text: String, phase: String) -> void:
	_instruction_label.text = text
	var color := INSTRUCTION_COLOR_SHOWING
	match phase:
		"showing": color = INSTRUCTION_COLOR_SHOWING
		"input": color = INSTRUCTION_COLOR_INPUT
		"clear": color = INSTRUCTION_COLOR_CLEAR
		"failed": color = INSTRUCTION_COLOR_FAILED
	_instruction_label.add_theme_color_override("font_color", color)


# --- 表示フェーズ ---

func _start_showing_phase() -> void:
	_showing_index = 0
	_show_timer = 0.0
	_show_phase_active = true
	_show_phase_pause = false
	_set_panels_disabled(true)
	_reset_all_panels()
	_update_round_display()
	_set_instruction("覚えてください", "showing")


func _process_showing_phase(delta: float) -> void:
	var sequence: Array[int] = _game.get_sequence()
	if _showing_index >= sequence.size():
		# 表示フェーズ完了 → 入力フェーズへ
		_reset_all_panels()
		_show_panels_tappable()  # グレー塗りで「タップ可能」を明示
		_game.begin_input_phase()
		_set_panels_disabled(false)
		_set_instruction("順にタップしてください", "input")
		return

	_show_timer += delta

	if _show_phase_active:
		if _show_timer == delta:  # 初回フレーム: パネルを光らせる
			_highlight_panel(sequence[_showing_index], _showing_index + 1)
		if _show_timer >= SequenceMemory.SHOW_INTERVAL_SEC:
			# 暗転
			_dim_panel(sequence[_showing_index])
			_show_timer = 0.0
			_show_phase_active = false
			_show_phase_pause = true
	elif _show_phase_pause:
		if _show_timer >= SequenceMemory.SHOW_PAUSE_SEC:
			_showing_index += 1
			_show_timer = 0.0
			_show_phase_active = true
			_show_phase_pause = false


# --- 入力フェーズ ---

func _on_panel_pressed(index: int) -> void:
	if _game == null or not _game._is_active:
		# 既に finish 済みで結果遷移待ちの場合は無視（誤タップフィードバック表示中など）
		return
	if _game.get_phase() != "input":
		return

	# 直前の判定状態を保持してから handle_input を呼ぶ（呼び出し後にフェーズが遷移するため）
	var sequence: Array[int] = _game.get_sequence()
	var expected_index: int = _game.get_user_input_index()
	var correct_panel_index: int = sequence[expected_index] if expected_index < sequence.size() else -1
	var was_correct: bool = correct_panel_index == index

	_game.handle_input({"type": "panel_tap", "index": index})

	var phase: String = _game.get_phase()
	if phase == "level_clear":
		# 最後のタップが正解でクリア達成 → 最後のタップ位置もゴールドフラッシュさせる
		_flash_correct(index)
		_set_panels_disabled(true)
		_set_instruction("正解！", "clear")
		var timer := get_tree().create_timer(0.8)
		timer.timeout.connect(_on_level_clear_delay)
	elif phase == "finished":
		# 失敗: 暗グレー + X + シェイク + 正解パネルのヒント表示
		_flash_wrong(index, correct_panel_index)
		_set_panels_disabled(true)
		_set_instruction("ゲーム終了", "failed")
		# 結果画面への遷移は WRONG_FEEDBACK_DURATION_SEC 後に遅延（_on_game_finished で log は保留中）
		var timer := get_tree().create_timer(WRONG_FEEDBACK_DURATION_SEC)
		timer.timeout.connect(_trigger_pending_finish)
	elif was_correct:
		# 途中の正解タップ → ゴールドフラッシュ
		_flash_correct(index)


func _on_level_clear_delay() -> void:
	if _game == null or not _game._is_active:
		return
	_game.advance_to_next_level()
	# advance_to_next_level が Lv9 全クリアで finish() を呼ぶ可能性がある
	if not _game._is_active:
		# 全クリア → "全クリア！" 表示してから遅延遷移
		_set_panels_disabled(true)
		_set_instruction("全クリア！", "clear")
		var timer := get_tree().create_timer(MAX_CLEAR_HOLD_DURATION_SEC)
		timer.timeout.connect(_trigger_pending_finish)
		return
	_start_showing_phase()


func _update_round_display() -> void:
	_round_label.text = "ROUND %02d" % _game.get_current_level()


func _on_game_finished(log: PlayLog) -> void:
	# 即遷移しない。誤タップ or Lv9 全クリアのフィードバックを見せた後、
	# _on_panel_pressed / _on_level_clear_delay からタイマ経由で _trigger_pending_finish が呼ばれる。
	_pending_finish_log = log


func _trigger_pending_finish() -> void:
	if _pending_finish_log == null:
		return
	var log: PlayLog = _pending_finish_log
	_pending_finish_log = null
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("on_game_finished_handler"):
		gm.on_game_finished_handler(log)
	else:
		push_warning("[SequenceMemoryView] GameManager not found; log dropped: score=%d" % log.score)
