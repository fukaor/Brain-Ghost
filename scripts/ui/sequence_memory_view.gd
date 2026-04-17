## SequenceMemoryView
##
## 順番記憶シーンスクリプト。SequenceMemory ロジックを内包し、
## パネルの表示アニメーション・入力処理・ラウンド進行を管理する。
##
## Stitch デザイン準拠:
## - 上部: ROUND バッジ + 指示テキスト
## - 中央: 3x3 メモリーグリッド（白パネル、アクティブ=青+番号）
## - 右上: タイマー
## - クリア系のためプレイ中ゴーストバトルバー非表示 (GDD §5c)
extends Control

# アクティブパネルのスタイル色定数
const COLOR_ACTIVE_BG := Color(0, 0.484, 1, 1)
const COLOR_ACTIVE_BORDER := Color(0, 0.337, 0.702, 1)
const COLOR_NORMAL_TEXT := Color(0.137, 0.173, 0.318, 0)  # 透明（非表示）
const COLOR_ACTIVE_TEXT := Color(1, 1, 1, 1)
const COLOR_WRONG_BG := Color(0.702, 0.106, 0.145, 1)

@onready var _round_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/RoundBadgeCenter/RoundBadge/RoundLabel
@onready var _instruction_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/InstructionLabel
@onready var _timer_label: Label = $TimerRing/TimerLabel
@onready var _memory_grid: GridContainer = $SafeAreaMargin/MainColumn/GridCenter/MemoryGrid

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
		panel.theme_type_variation = "memory_panel"
		panel.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)


func _highlight_panel(index: int, order_number: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	panel.text = str(order_number)
	panel.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)
	panel.add_theme_font_size_override("font_size", 48)
	# アクティブスタイルを直接適用（StyleBoxFlat_memory_panel_active）
	var active_style := StyleBoxFlat.new()
	active_style.bg_color = COLOR_ACTIVE_BG
	active_style.border_width_bottom = 8
	active_style.border_color = COLOR_ACTIVE_BORDER
	active_style.corner_radius_top_left = 17
	active_style.corner_radius_top_right = 17
	active_style.corner_radius_bottom_right = 17
	active_style.corner_radius_bottom_left = 17
	active_style.shadow_color = Color(0, 0.484, 1, 0.5)
	active_style.shadow_size = 16
	active_style.shadow_offset = Vector2(0, 4)
	active_style.content_margin_left = 8
	active_style.content_margin_top = 8
	active_style.content_margin_right = 8
	active_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("normal", active_style)
	panel.add_theme_stylebox_override("disabled", active_style)


func _dim_panel(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	panel.text = " "
	panel.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
	panel.remove_theme_stylebox_override("normal")
	panel.remove_theme_stylebox_override("disabled")


func _flash_wrong(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return
	var panel: Button = _panels[index]
	var wrong_style := StyleBoxFlat.new()
	wrong_style.bg_color = COLOR_WRONG_BG
	wrong_style.border_width_bottom = 8
	wrong_style.border_color = Color(0.5, 0.08, 0.1, 1)
	wrong_style.corner_radius_top_left = 17
	wrong_style.corner_radius_top_right = 17
	wrong_style.corner_radius_bottom_right = 17
	wrong_style.corner_radius_bottom_left = 17
	wrong_style.content_margin_left = 8
	wrong_style.content_margin_top = 8
	wrong_style.content_margin_right = 8
	wrong_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("normal", wrong_style)


# --- 表示フェーズ ---

func _start_showing_phase() -> void:
	_showing_index = 0
	_show_timer = 0.0
	_show_phase_active = true
	_show_phase_pause = false
	_set_panels_disabled(true)
	_reset_all_panels()
	_update_round_display()
	_instruction_label.text = "覚えてください"


func _process_showing_phase(delta: float) -> void:
	var sequence: Array[int] = _game.get_sequence()
	if _showing_index >= sequence.size():
		# 表示フェーズ完了 → 入力フェーズへ
		_reset_all_panels()
		_game.begin_input_phase()
		_set_panels_disabled(false)
		_instruction_label.text = "順にタップしてください"
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
		return
	if _game.get_phase() != "input":
		return

	_game.handle_input({"type": "panel_tap", "index": index})

	var phase: String = _game.get_phase()
	if phase == "level_clear":
		# レベルクリア → 短い間を置いて次のラウンドへ
		_set_panels_disabled(true)
		_instruction_label.text = "正解！"
		var timer := get_tree().create_timer(0.8)
		timer.timeout.connect(_on_level_clear_delay)
	elif phase == "finished":
		# 失敗
		_flash_wrong(index)
		_set_panels_disabled(true)
		_instruction_label.text = "ゲーム終了"


func _on_level_clear_delay() -> void:
	if _game == null or not _game._is_active:
		return
	_game.advance_to_next_level()
	_start_showing_phase()


func _update_round_display() -> void:
	_round_label.text = "ROUND %02d" % _game.get_current_level()


func _on_game_finished(log: PlayLog) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("on_game_finished_handler"):
		gm.on_game_finished_handler(log)
	else:
		push_warning("[SequenceMemoryView] GameManager not found; log dropped: score=%d" % log.score)
