## CardMatchView
##
## 神経衰弱ライト (card_match) のシーンスクリプト。CardMatch ロジックを内包し、
## カード生成・タップ処理・ペア演出・タイマー・結果遷移を管理する。
##
## Sumi Ghost (墨絵調) デザイン:
## - 上部: タイトル + タイマー
## - 進捗: 「タップ: N  ペア: N/8」
## - 中央: 4×4 グリッド (CardComponent インスタンス)
## - 下部: ★ベスト pill
##
## クリア系のためプレイ中ゴーストバトルバー非表示 (GDD §5b)。
extends Control

const _Card = preload("res://scripts/ui/components/card.gd")

const MATCH_DISPLAY_SEC: float = 0.3
const MISMATCH_DISPLAY_SEC: float = 0.5

# 残り 10 秒で警告色へ
const COLOR_TIMER_NORMAL := Color(0.722, 0.878, 1, 1)
const COLOR_TIMER_WARN := Color(1.0, 0.914, 0.659, 1)


@onready var _title_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/TitleChip/TitleLabel
@onready var _timer_label: Label = $SafeAreaMargin/MainColumn/HeaderArea/TimerChip/TimerLabel
@onready var _progress_label: Label = $SafeAreaMargin/MainColumn/ProgressLabel
@onready var _card_grid: GridContainer = $SafeAreaMargin/MainColumn/GridCenter/CardGrid
@onready var _best_label: Label = $SafeAreaMargin/MainColumn/FooterArea/BestPill/BestLabel


var _game: CardMatch
var _seed_value: int = -1
var _cards: Array[CardComponent] = []
var _last_displayed_remaining: int = -1
var _pending_finish_log: PlayLog = null
## spec §2-5: _is_processing 中に 60 秒到達した場合は判定終了後に timeout を呼ぶ
var _pending_timeout: bool = false


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _game = CardMatch.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.pair_evaluated.connect(_on_pair_evaluated)
    _game.setup(_seed_value)

    _build_grid()
    _update_best_display()
    _update_progress()
    _update_timer_label()

    _game.start()


func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec: float = float(_game.get_elapsed_ms()) / 1000.0
    var remaining: float = max(0.0, _game.get_time_limit_sec() - elapsed_sec)
    _update_timer_label(remaining)
    if remaining <= 0.0 and not _pending_timeout:
        # 判定処理中なら保留 (spec §2-5)
        if _game.is_pair_processing():
            _pending_timeout = true
        else:
            _game.timeout()


func set_seed(seed_value: int) -> void:
    _seed_value = seed_value


# ---------------------------------------------------------------------------
# グリッド生成
# ---------------------------------------------------------------------------

func _build_grid() -> void:
    for child in _card_grid.get_children():
        child.queue_free()
    _cards = []

    var grid_data: Array[int] = _game.get_grid_data()
    var cols: int = CardMatchTierConfig.get_cols(_game.get_tier())
    _card_grid.columns = cols

    var cell_size: int = _compute_cell_size(grid_data.size())

    for i in range(grid_data.size()):
        var card: CardComponent = _Card.new()
        card.setup(i, grid_data[i])
        card.custom_minimum_size = Vector2(cell_size, cell_size)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.card_pressed.connect(_on_card_pressed)
        _card_grid.add_child(card)
        _cards.append(card)


func _compute_cell_size(count: int) -> int:
    # 16 枚 (4×4): 128px、20 枚 (5×4): 110px、24 枚 (6×4): 96px
    if count <= 16:
        return 128
    if count <= 20:
        return 110
    return 96


# ---------------------------------------------------------------------------
# 入力ハンドラ
# ---------------------------------------------------------------------------

func _on_card_pressed(cell_index: int) -> void:
    if _game == null or not _game._is_active:
        return
    if cell_index < 0 or cell_index >= _cards.size():
        return
    var card: CardComponent = _cards[cell_index]
    if card.is_face_up() or card.is_matched():
        return
    # spec §2-5: 2 枚目タップ時は判定 (pair_evaluated) より先に view 側で表向きにする
    # 必要があるため、handle_input より先に flip_to_front を呼ぶ。
    # CardMatch._handle_cell_tap が拒否したケース (_can_tap=false) では prev_taps で
    # 巻き戻して flip_to_back する。
    var prev_taps: int = _game.get_total_taps()
    card.flip_to_front()
    _game.handle_input({"type": "cell_tap", "cell_index": cell_index})
    if _game.get_total_taps() == prev_taps:
        # CardMatch が受理しなかった (処理中タップ等) → 巻き戻し
        card.flip_to_back()
        return
    _update_progress()


# ---------------------------------------------------------------------------
# ペア判定演出
# ---------------------------------------------------------------------------

func _on_pair_evaluated(first_idx: int, second_idx: int, is_match: bool) -> void:
    if is_match:
        _animate_match(first_idx, second_idx)
    else:
        _animate_mismatch(first_idx, second_idx)


func _animate_match(first_idx: int, second_idx: int) -> void:
    var a: CardComponent = _cards[first_idx]
    var b: CardComponent = _cards[second_idx]
    a.flash_match()
    b.flash_match()
    var timer := get_tree().create_timer(MATCH_DISPLAY_SEC)
    timer.timeout.connect(func() -> void:
        a.set_matched()
        b.set_matched()
        if _game != null and _game._is_active:
            _game.handle_input({"type": "match_resolved", "first": first_idx, "second": second_idx})
        _update_progress()
        _drain_pending_timeout()
    )


func _animate_mismatch(first_idx: int, second_idx: int) -> void:
    var a: CardComponent = _cards[first_idx]
    var b: CardComponent = _cards[second_idx]
    a.flash_mismatch()
    b.flash_mismatch()
    var timer := get_tree().create_timer(MISMATCH_DISPLAY_SEC)
    timer.timeout.connect(func() -> void:
        a.flip_to_back()
        b.flip_to_back()
        if _game != null and _game._is_active:
            _game.handle_input({"type": "mismatch_resolved", "first": first_idx, "second": second_idx})
        _update_progress()
        _drain_pending_timeout()
    )


func _drain_pending_timeout() -> void:
    if _pending_timeout and _game != null and _game._is_active:
        _pending_timeout = false
        _game.timeout()


# ---------------------------------------------------------------------------
# HUD 更新
# ---------------------------------------------------------------------------

func _update_progress() -> void:
    if _game == null:
        return
    _progress_label.text = "タップ: %d  ペア: %d/%d" % [
        _game.get_total_taps(),
        _game.get_pairs_found(),
        _game.get_total_pairs(),
    ]


func _update_timer_label(remaining: float = -1.0) -> void:
    var r: float = remaining
    if r < 0.0:
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
    var best = ds.load_best("card_match")
    var bs: int = int(best.best_score) if best != null and "best_score" in best else 0
    if bs <= 0:
        _best_label.text = "★ ベスト: — pts"
    else:
        _best_label.text = "★ ベスト: %d pts" % bs


# ---------------------------------------------------------------------------
# 終了処理
# ---------------------------------------------------------------------------

func _on_game_finished(log: PlayLog) -> void:
    # 最後のペアフラッシュを見せてから遷移
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
        push_warning("[CardMatchView] GameManager not found; log dropped: score=%d" % log.score)
