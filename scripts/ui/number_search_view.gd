## NumberSearchView
##
## 数字さがしシーンスクリプト。NumberSearch ロジックを内包し、
## グリッド生成・タップ処理・タイマー・結果遷移を管理する。
##
## Midnight Cat デザイン:
## - 上部: 「次: N」HUD (左) + タイマー pill (右)
## - 中央: 5×5 グリッド (NumberCell インスタンス)
## - 下部: ★ベスト pill
##
## クリア系のためプレイ中ゴーストバトルバー非表示 (GDD §5b)。
extends Control

const _NumberCell = preload("res://scripts/ui/components/number_cell.gd")

# 残り 10 秒で警告色へ
const COLOR_TIMER_NORMAL := Color(0.722, 0.878, 1, 1)        # CYAN_300
const COLOR_TIMER_WARN := Color(1.0, 0.914, 0.659, 1)        # GOLD_300


@onready var _next_number_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/NextNumberChip/NextNumberLabel
@onready var _timer_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/TimerChip/TimerLabel
@onready var _number_grid: GridContainer = $SafeAreaMargin/MainColumn/GridCenter/NumberGrid
@onready var _best_label: Label = $SafeAreaMargin/MainColumn/FooterArea/BestPill/BestLabel


var _game: NumberSearch
var _seed_value: int = -1
var _cells: Array[NumberCell] = []
var _last_displayed_remaining: int = -1
## game_finished 後すぐ遷移すると最後のフラッシュが見えないため遅延させるためのバッファ
var _pending_finish_log: PlayLog = null


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _resolve_seed_from_game_manager()
    _game = NumberSearch.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed_value)

    _build_grid()
    _update_best_display()
    _update_next_number()
    _update_timer_label()

    _game.start()


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec: float = float(_game.get_elapsed_ms()) / 1000.0
    var remaining: float = max(0.0, _game.get_time_limit_sec() - elapsed_sec)
    _update_timer_label(remaining)
    if remaining <= 0.0:
        _game.timeout()


func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


# ---------------------------------------------------------------------------
# グリッド生成
# ---------------------------------------------------------------------------

func _build_grid() -> void:
    # 既存子ノードのクリーンアップ (シーンが再利用された場合に備えて)
    for child in _number_grid.get_children():
        child.queue_free()
    _cells = []

    var numbers: Array[int] = _game.get_grid_numbers()
    var cols: int = NumberSearchTierConfig.get_cols(_game.get_tier())
    _number_grid.columns = cols

    var cell_size: int = _compute_cell_size(numbers.size())

    for i in range(numbers.size()):
        var cell: NumberCell = _NumberCell.new()
        cell.cell_index = i
        cell.set_number(numbers[i])
        cell.custom_minimum_size = Vector2(cell_size, cell_size)
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        cell.number_cell_pressed.connect(_on_cell_pressed)
        _number_grid.add_child(cell)
        _cells.append(cell)


## 5×5 で 96px、4×4 で 110px、3×3 で 130px 程度のセルサイズを返す。
## 縦画面 720×1280 の安全領域内に収まる範囲。
func _compute_cell_size(count: int) -> int:
    if count <= 9:
        return 130
    if count <= 16:
        return 110
    return 96


# ---------------------------------------------------------------------------
# 入力ハンドラ
# ---------------------------------------------------------------------------

func _on_cell_pressed(cell_index: int) -> void:
    if _game == null or not _game._is_active:
        return
    if cell_index < 0 or cell_index >= _cells.size():
        return
    var cell: NumberCell = _cells[cell_index]
    var prev_target: int = _game.get_current_target()
    _game.handle_input({"type": "cell_tap", "cell_index": cell_index})
    # 正解で current_target が進んだなら、該当セルを found 状態に
    if _game.get_current_target() > prev_target:
        cell.mark_found()
    _update_next_number()


# ---------------------------------------------------------------------------
# HUD 更新
# ---------------------------------------------------------------------------

func _update_next_number() -> void:
    if _game == null:
        return
    var target: int = _game.get_current_target()
    var max_n: int = _game.get_max_number()
    if target > max_n:
        _next_number_label.text = "クリア！"
    else:
        _next_number_label.text = "次: %d" % target


func _update_timer_label(remaining: float = -1.0) -> void:
    var r: float = remaining
    if r < 0.0:
        # 初期表示など
        r = _game.get_time_limit_sec() if _game != null else 60.0
    var rounded: int = int(ceil(r))
    if rounded == _last_displayed_remaining:
        return
    _last_displayed_remaining = rounded
    _timer_label.text = "%ds" % rounded
    if rounded <= 10:
        _timer_label.add_theme_color_override("font_color", COLOR_TIMER_WARN)
    else:
        _timer_label.add_theme_color_override("font_color", COLOR_TIMER_NORMAL)


func _update_best_display() -> void:
    var ds := get_node_or_null("/root/DataStore")
    if ds == null or not ds.has_method("load_best"):
        _best_label.text = "★ ベスト: — pts"
        return
    var best = ds.load_best("number_search")
    var bs: int = int(best.best_score) if best != null and "best_score" in best else 0
    if bs <= 0:
        _best_label.text = "★ ベスト: — pts"
    else:
        _best_label.text = "★ ベスト: %d pts" % bs


# ---------------------------------------------------------------------------
# 終了処理
# ---------------------------------------------------------------------------

func _on_game_finished(log: PlayLog) -> void:
    # 最後のセルが緑にフラッシュするのを 0.5 秒見せてから個別結果へ
    _pending_finish_log = log
    var timer := get_tree().create_timer(0.6)
    timer.timeout.connect(_trigger_pending_finish)


func _trigger_pending_finish() -> void:
    if _pending_finish_log == null:
        return
    var log: PlayLog = _pending_finish_log
    _pending_finish_log = null
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_game_finished_handler"):
        gm.on_game_finished_handler(log)
    else:
        push_warning("[NumberSearchView] GameManager not found; log dropped: score=%d" % log.score)


# ---------------------------------------------------------------------------
# シード取得
# ---------------------------------------------------------------------------

func _resolve_seed_from_game_manager() -> void:
    if _seed_value >= 0:
        return
    # MVP は free モードのためデイリーシードを使わない（ランダム）。
    # 将来 GameManager にデイリーシード状態が来たらここで読む。
    _seed_value = -1
