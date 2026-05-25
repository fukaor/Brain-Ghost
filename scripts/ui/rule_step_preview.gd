## RuleStepPreview
##
## ルール説明画面のステップごとのプレビュー描画。
## docs/design/promotion/game_tap_rule.png の 3 ステップミニ図に相当。
##
## variants (ghost_7ban_shobu):
##   "ready"        — 第N戦/7 + 進捗ドット + 中央ゲート
##   "tap"          — TAP! + 中央発光
##   "compare"      — 87ms / 142ms 比較 + ゴースト猫
##
## variants (flash_calc):
##   "flash_number" — 数字が次々と光る (大字 "7" + 残像)
##   "calc_sum"     — Σ + 思考バブル (合計暗算)
##   "calc_input"   — テンキーグリッド + ENTER
##
## variants (sequence_memory):
##   "grid_show"    — 3×3 グリッドの一部が光って順番表示
##   "grid_tap"     — 3×3 グリッド + TAP! ハンド
##   "grid_grow"    — Lv1→Lv5 の段階表現 (光るパネルが増える)
##
## variants (stroop):
##   "stroop_show"   — 中央に色文字「青」(実色=赤) を表示
##   "stroop_answer" — 4 色ボタンの一覧 + タップ指
##   "stroop_combo"  — 30s タイマ + +100 / −50 バッジ
##
## variants (card_match):
##   "card_show"   — 4×4 裏向きカード、2 枚だけ表向き
##   "card_pair"   — ペア成立カード 2 枚を強調 + ロック
##   "card_timer"  — 時計 + "8 PAIRS" 表記
##
## variants (number_search):
##   "number_find"     — 5×5 数字グリッド + 「1」を強調
##   "number_sequence" — 同グリッド + 1→2→3 の矢印
##   "number_clear"    — 時計 + チェック + 25/25
class_name RuleStepPreview
extends Control

const COLOR_RAIL := Color(0.49, 0.827, 0.988, 0.32)
const COLOR_GATE := Color(0.49, 0.827, 0.988, 0.85)
const COLOR_GLOW_GOLD := Color(1.0, 0.85, 0.4, 0.95)
const COLOR_GLOW_CYAN := Color(0.49, 0.827, 0.988, 0.95)
const COLOR_TEXT := Color(0.949, 0.957, 0.98, 1.0)
const COLOR_DIM := Color(0.42, 0.467, 0.561, 1.0)
const COLOR_PANEL_OFF := Color(0.137, 0.169, 0.247, 0.85)
const COLOR_PANEL_ON := Color(1.0, 0.85, 0.4, 0.95)

# Stroop パレット (docs/ideas/games/ghost-stroop-showdown-spec.md §2-3)
const STROOP_RED    := Color(0.898, 0.224, 0.208)   # #E53935
const STROOP_BLUE   := Color(0.118, 0.533, 0.898)   # #1E88E5
const STROOP_GREEN  := Color(0.263, 0.627, 0.278)   # #43A047
const STROOP_YELLOW := Color(0.992, 0.847, 0.208)   # #FDD835

const ICON_FONT_PATH: String = "res://assets/fonts/MaterialSymbolsRounded.ttf"
var _icon_font: Font

@export_enum("ready", "tap", "compare", "flash_number", "calc_sum", "calc_input", "grid_show", "grid_tap", "grid_grow", "stroop_show", "stroop_answer", "stroop_combo", "card_show", "card_pair", "card_timer", "number_find", "number_sequence", "number_clear") var variant: String = "ready":
    set(v):
        variant = v
        queue_redraw()

@export var round_label: String = "第3戦/7":
    set(v):
        round_label = v
        queue_redraw()

@export var you_ms: String = "87ms"
@export var ghost_ms: String = "142ms"

func _ready() -> void:
    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = Vector2(280, 170)
    if ResourceLoader.exists(ICON_FONT_PATH):
        _icon_font = load(ICON_FONT_PATH)
    queue_redraw()

func _draw() -> void:
    var w := size.x
    var h := size.y
    var f: Font = get_theme_default_font()

    # round label top-left
    draw_string(f, Vector2(14, 26), round_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_DIM)

    # progress dots top-right (5 dots: 2 done, 1 current, 2 left)
    var dot_y := 22.0
    var dot_step := 16.0
    var dot_start_x := w - 14.0 - dot_step * 4.0
    for i in 5:
        var cx := dot_start_x + float(i) * dot_step
        var col: Color
        match i:
            0, 1: col = Color(0.49, 0.827, 0.988, 0.85)
            2: col = Color(1.0, 0.85, 0.4, 0.95)
            _: col = Color(0.42, 0.467, 0.561, 0.6)
        draw_circle(Vector2(cx, dot_y), 4.5, col)

    # ghost_7ban_shobu バリアントは中央レールとゲートを描画
    var has_rail: bool = variant in ["ready", "tap", "compare"]
    var rail_y := h * 0.58
    var gate_x := w * 0.5
    if has_rail:
        draw_line(Vector2(28, rail_y), Vector2(w - 28, rail_y), COLOR_RAIL, 2.0, true)
        draw_line(Vector2(gate_x, rail_y - 26), Vector2(gate_x, rail_y + 26), COLOR_GATE, 2.5, true)

    match variant:
        "ready":
            # YOU dot left, GHOST dot right
            _draw_glow(Vector2(w * 0.18, rail_y), 22.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            draw_circle(Vector2(w * 0.18, rail_y), 9.0, COLOR_GLOW_GOLD)
            _draw_glow(Vector2(w * 0.82, rail_y), 18.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.4))
            draw_circle(Vector2(w * 0.82, rail_y), 7.0, COLOR_GLOW_CYAN)
        "tap":
            # central burst with TAP! text + cross flare + multi-ring
            var center := Vector2(gate_x, rail_y)
            # multi-ring (3 layers)
            for i in 3:
                var rr: float = 18.0 + float(i) * 14.0
                var ra: float = 0.7 - float(i) * 0.18
                var ring := COLOR_GLOW_GOLD
                ring.a = ra
                _stroke_ring(center, rr, ring, 1.2)
            # cross flare (4 long rays)
            for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
                _draw_tapered_ray(center, d, 38.0, 5.0, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.85))
            # diagonal short rays
            var diag: Vector2 = Vector2(0.7071, 0.7071)
            for d2 in [Vector2(diag.x, -diag.y), Vector2(-diag.x, -diag.y), Vector2(diag.x, diag.y), Vector2(-diag.x, diag.y)]:
                _draw_tapered_ray(center, d2, 22.0, 3.5, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.55))
            # central glow + core
            _draw_glow(center, 44.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.65))
            draw_circle(center, 11.0, COLOR_GLOW_GOLD)
            draw_circle(center, 5.0, Color(1.0, 1.0, 1.0, 1.0))
            var tap_size_w: float = f.get_string_size("TAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
            draw_string(f, Vector2(gate_x - tap_size_w * 0.5, rail_y - 38.0), "TAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, COLOR_TEXT)
        "compare":
            # YOU near gate (gold), GHOST farther (cyan); icons under each
            var you_x := gate_x - 38.0
            var ghost_x := gate_x + 90.0
            _draw_glow(Vector2(you_x, rail_y), 28.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            draw_circle(Vector2(you_x, rail_y), 9.0, COLOR_GLOW_GOLD)
            _draw_glow(Vector2(ghost_x, rail_y), 22.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.4))
            draw_circle(Vector2(ghost_x, rail_y), 7.0, COLOR_GLOW_CYAN)
            _draw_centered(f, Vector2(you_x, rail_y - 22.0), you_ms, 18, COLOR_GLOW_GOLD)
            _draw_centered(f, Vector2(ghost_x, rail_y - 22.0), ghost_ms, 18, COLOR_GLOW_CYAN)
            if _icon_font != null:
                draw_string(_icon_font, Vector2(22.0, h - 16.0), "person", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COLOR_DIM)
                draw_string(_icon_font, Vector2(w - 50.0, h - 16.0), "pets", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COLOR_GLOW_CYAN)
        "flash_number":
            # 中央に大字 "7" + 残像 (左右に薄い "3" "5")
            var center := Vector2(w * 0.5, h * 0.62)
            _draw_glow(center, 50.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.5))
            _draw_centered(f, center + Vector2(-72.0, 4.0), "3", 38, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.18))
            _draw_centered(f, center + Vector2(72.0, 4.0), "5", 38, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.28))
            _draw_centered(f, center + Vector2(0.0, 8.0), "7", 64, COLOR_GLOW_GOLD)
            # 上端に "FLASH" eyebrow
            _draw_centered(f, Vector2(w * 0.5, 56.0), "FLASH", 14, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.7))
        "calc_sum":
            # 上に "3 + 5 + 7" の数字列、中央に "= ?" の問い
            var row_y := h * 0.42
            _draw_centered(f, Vector2(w * 0.32, row_y), "3", 26, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.5))
            _draw_centered(f, Vector2(w * 0.5, row_y), "+", 22, COLOR_DIM)
            _draw_centered(f, Vector2(w * 0.68, row_y), "5", 26, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.7))
            # = ? center bottom
            var center2 := Vector2(w * 0.5, h * 0.78)
            _draw_glow(center2, 36.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.4))
            _draw_centered(f, center2 + Vector2(-22.0, 4.0), "=", 36, COLOR_TEXT)
            _draw_centered(f, center2 + Vector2(22.0, 4.0), "?", 38, COLOR_GLOW_CYAN)
        "calc_input":
            # 3×3 のテンキーグリッド (右下 ENTER は cyan)
            var pad_size := Vector2(34.0, 30.0)
            var pad_gap := 6.0
            var grid_w := pad_size.x * 3.0 + pad_gap * 2.0
            var grid_h := pad_size.y * 3.0 + pad_gap * 2.0
            var grid_top_left := Vector2((w - grid_w) * 0.5, (h - grid_h) * 0.5 + 8.0)
            for row in 3:
                for col in 3:
                    var n := row * 3 + col + 1
                    var pos := grid_top_left + Vector2(float(col) * (pad_size.x + pad_gap), float(row) * (pad_size.y + pad_gap))
                    var rect := Rect2(pos, pad_size)
                    var fill := COLOR_PANEL_OFF
                    var stroke := Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.4)
                    if n == 7:
                        fill = Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.35)
                        stroke = COLOR_GLOW_GOLD
                    draw_rect(rect, fill, true)
                    draw_rect(rect, stroke, false, 1.2)
                    _draw_centered(f, pos + pad_size * 0.5 + Vector2(0, 4), str(n), 14, COLOR_TEXT)
            # ENTER pill on the right
            var enter_pos := Vector2(grid_top_left.x + grid_w + 10.0, grid_top_left.y + grid_h - pad_size.y)
            var enter_rect := Rect2(enter_pos, Vector2(48.0, pad_size.y))
            draw_rect(enter_rect, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.25), true)
            draw_rect(enter_rect, COLOR_GLOW_CYAN, false, 1.2)
            _draw_centered(f, enter_pos + enter_rect.size * 0.5 + Vector2(0, 4), "OK", 14, COLOR_GLOW_CYAN)
        "grid_show":
            # 3×3 グリッド + 順序の矢印 (1→2→3 が光って繋がる)
            _draw_simon_grid(w, h, [0, 4, 8], true)
        "grid_tap":
            # 3×3 グリッド + ハンド/TAP! 表記
            _draw_simon_grid(w, h, [4], false)
            var c2 := Vector2(w * 0.5, h * 0.62)
            _draw_glow(c2, 32.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            _draw_centered(f, c2 + Vector2(0.0, -32.0), "TAP!", 22, COLOR_TEXT)
        "grid_grow":
            # Lv1 / Lv5 の段階比較 (左に小さい点列, 右に大きい点列)
            var center_y := h * 0.58
            _draw_growth_step(Vector2(w * 0.28, center_y), 3, "Lv 1", f)
            _draw_centered(f, Vector2(w * 0.5, center_y + 4.0), "→", 22, COLOR_DIM)
            _draw_growth_step(Vector2(w * 0.72, center_y), 7, "Lv 5", f)
        "stroop_show":
            # 中央に大字の色文字「あお」(実色=あか)。ストループ干渉のひと目見本
            var center := Vector2(w * 0.5, h * 0.62)
            _draw_glow(center, 44.0, STROOP_RED * Color(1, 1, 1, 0.35))
            _draw_centered(f, center + Vector2(0.0, 6.0), "あお", 38, STROOP_RED)
            _draw_centered(f, Vector2(w * 0.5, 56.0), "色は？", 14, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.7))
        "stroop_answer":
            # 4 色ボタン (●▲■◆) を横一列。中央 2 つの上に TAP ハンド/ハイライト
            var btn_w := 38.0
            var btn_h := 30.0
            var btn_gap := 6.0
            var total_w := btn_w * 4.0 + btn_gap * 3.0
            var top_y := h * 0.52
            var left_x := (w - total_w) * 0.5
            var palette := [STROOP_RED, STROOP_BLUE, STROOP_GREEN, STROOP_YELLOW]
            var shapes := ["●", "▲", "■", "◆"]
            for i in 4:
                var bx := left_x + float(i) * (btn_w + btn_gap)
                var brect := Rect2(Vector2(bx, top_y), Vector2(btn_w, btn_h))
                var col: Color = palette[i]
                var fill: Color = col
                fill.a = 0.25
                draw_rect(brect, fill, true)
                draw_rect(brect, col, false, 1.4)
                _draw_centered(f, Vector2(bx + btn_w * 0.5, top_y + btn_h * 0.5 + 5.0), shapes[i], 16, col)
            # TAP! の指示 (2 番目のボタンを選んでいる風)
            var tap_x := left_x + btn_w + btn_gap + btn_w * 0.5
            _draw_glow(Vector2(tap_x, top_y + btn_h + 18.0), 22.0, COLOR_GLOW_GOLD * Color(1, 1, 1, 0.45))
            _draw_centered(f, Vector2(tap_x, top_y + btn_h + 22.0), "TAP!", 16, COLOR_GLOW_GOLD)
        "stroop_combo":
            # タイマアーク + +100 / -50 バッジ
            var arc_center := Vector2(w * 0.32, h * 0.62)
            _draw_glow(arc_center, 26.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.3))
            _stroke_ring(arc_center, 22.0, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.6), 1.6)
            _draw_centered(f, arc_center + Vector2(0.0, 4.0), "30s", 16, COLOR_GLOW_CYAN)
            # +100 バッジ (ゴールド)
            var plus_pos := Vector2(w * 0.6, h * 0.5)
            var plus_rect := Rect2(plus_pos, Vector2(50.0, 22.0))
            draw_rect(plus_rect, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.25), true)
            draw_rect(plus_rect, COLOR_GLOW_GOLD, false, 1.2)
            _draw_centered(f, plus_pos + Vector2(25.0, 16.0), "+100", 14, COLOR_GLOW_GOLD)
            # -50 バッジ (グレー)
            var minus_pos := Vector2(w * 0.6, h * 0.72)
            var minus_rect := Rect2(minus_pos, Vector2(50.0, 22.0))
            draw_rect(minus_rect, Color(COLOR_DIM.r, COLOR_DIM.g, COLOR_DIM.b, 0.3), true)
            draw_rect(minus_rect, COLOR_DIM, false, 1.2)
            _draw_centered(f, minus_pos + Vector2(25.0, 16.0), "-50", 14, COLOR_DIM)
        "card_show":
            # 4×4 裏向きカード、2 枚だけ表 (絵柄プレースホルダ ★ ▲)
            _draw_card_grid(w, h, [{"idx": 5, "icon": "★"}, {"idx": 6, "icon": "▲"}], [])
        "card_pair":
            # 4×4、ペア成立 2 枚を金縁強調 + ロックアイコン
            _draw_card_grid(w, h, [{"idx": 5, "icon": "★"}, {"idx": 10, "icon": "★"}], [5, 10])
        "card_timer":
            # 時計アイコン + 8 PAIRS テキスト
            var c2 := Vector2(w * 0.32, h * 0.6)
            _draw_glow(c2, 28.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.3))
            _stroke_ring(c2, 22.0, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.7), 1.6)
            # 時計の針 (12 時と 4 時方向)
            draw_line(c2, c2 + Vector2(0.0, -16.0), COLOR_GLOW_CYAN, 1.6, true)
            draw_line(c2, c2 + Vector2(12.0, 6.0), COLOR_GLOW_CYAN, 1.6, true)
            _draw_centered(f, c2 + Vector2(0.0, 36.0), "60s", 14, COLOR_DIM)
            # 8 PAIRS バッジ
            var bx := w * 0.6
            var brect := Rect2(Vector2(bx, h * 0.54), Vector2(72.0, 30.0))
            draw_rect(brect, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.25), true)
            draw_rect(brect, COLOR_GLOW_GOLD, false, 1.4)
            _draw_centered(f, Vector2(bx + 36.0, h * 0.54 + 20.0), "8 PAIRS", 14, COLOR_GLOW_GOLD)
        "number_find":
            # 5×5 数字グリッド (シャッフル配置) で「1」を金色強調
            _draw_number_grid(w, h, 1)
        "number_sequence":
            # 5×5 数字グリッド + 1→2→3 の矢印経路
            _draw_number_grid_with_arrows(w, h, [1, 2, 3])
        "number_clear":
            # 時計アイコン + チェック + 25/25 表示
            var c3 := Vector2(w * 0.32, h * 0.6)
            _draw_glow(c3, 28.0, COLOR_GLOW_CYAN * Color(1, 1, 1, 0.3))
            _stroke_ring(c3, 22.0, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.7), 1.6)
            draw_line(c3, c3 + Vector2(0.0, -16.0), COLOR_GLOW_CYAN, 1.6, true)
            draw_line(c3, c3 + Vector2(12.0, 6.0), COLOR_GLOW_CYAN, 1.6, true)
            _draw_centered(f, c3 + Vector2(0.0, 36.0), "60s", 14, COLOR_DIM)
            # 25/25 ゴールバッジ + チェック
            var gx := w * 0.6
            var grect := Rect2(Vector2(gx, h * 0.54), Vector2(78.0, 30.0))
            draw_rect(grect, Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.25), true)
            draw_rect(grect, COLOR_GLOW_GOLD, false, 1.4)
            _draw_centered(f, Vector2(gx + 16.0, h * 0.54 + 20.0), "✓", 16, COLOR_GLOW_GOLD)
            _draw_centered(f, Vector2(gx + 48.0, h * 0.54 + 20.0), "25/25", 14, COLOR_GLOW_GOLD)

func _draw_simon_grid(w: float, h: float, lit_indices: Array, with_arrows: bool) -> void:
    var cell_size := 28.0
    var gap := 6.0
    var grid_size := cell_size * 3.0 + gap * 2.0
    var top_left := Vector2((w - grid_size) * 0.5, (h - grid_size) * 0.5 + 6.0)
    var lit_centers: Array = []
    for row in 3:
        for col in 3:
            var idx := row * 3 + col
            var pos := top_left + Vector2(float(col) * (cell_size + gap), float(row) * (cell_size + gap))
            var rect := Rect2(pos, Vector2(cell_size, cell_size))
            var lit_pos: int = lit_indices.find(idx)
            var is_lit: bool = lit_pos >= 0
            if is_lit:
                _draw_glow(pos + rect.size * 0.5, cell_size * 0.7, COLOR_PANEL_ON * Color(1, 1, 1, 0.5))
                draw_rect(rect, Color(COLOR_PANEL_ON.r, COLOR_PANEL_ON.g, COLOR_PANEL_ON.b, 0.55), true)
                draw_rect(rect, COLOR_PANEL_ON, false, 1.4)
                if with_arrows:
                    var f: Font = get_theme_default_font()
                    _draw_centered(f, pos + rect.size * 0.5 + Vector2(0, 4), str(lit_pos + 1), 14, Color(0.0, 0.0, 0.0, 0.7))
            else:
                draw_rect(rect, COLOR_PANEL_OFF, true)
                draw_rect(rect, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.3), false, 1.0)
            lit_centers.append(pos + rect.size * 0.5)
    if with_arrows and lit_indices.size() >= 2:
        for i in range(lit_indices.size() - 1):
            var p0: Vector2 = lit_centers[lit_indices[i]]
            var p1: Vector2 = lit_centers[lit_indices[i + 1]]
            draw_line(p0, p1, Color(COLOR_PANEL_ON.r, COLOR_PANEL_ON.g, COLOR_PANEL_ON.b, 0.5), 1.6, true)


## 4×4 のカード一覧。`face_ups` は [{idx, icon}] のリスト、`locked_indices` はロック装飾を付けるインデックス
func _draw_card_grid(w: float, h: float, face_ups: Array, locked_indices: Array) -> void:
    var cell_size := 22.0
    var gap := 4.0
    var grid_size := cell_size * 4.0 + gap * 3.0
    var top_left := Vector2((w - grid_size) * 0.5, (h - grid_size) * 0.5 + 6.0)
    var f: Font = get_theme_default_font()
    for i in 16:
        var row: int = i / 4
        var col: int = i % 4
        var pos := top_left + Vector2(float(col) * (cell_size + gap), float(row) * (cell_size + gap))
        var rect := Rect2(pos, Vector2(cell_size, cell_size))
        var face_up_entry: Dictionary = {}
        for fu in face_ups:
            if int(fu.get("idx", -1)) == i:
                face_up_entry = fu
                break
        var is_locked: bool = i in locked_indices
        if not face_up_entry.is_empty():
            var border: Color = COLOR_GLOW_GOLD if is_locked else COLOR_GLOW_CYAN
            var fill: Color = Color(border.r, border.g, border.b, 0.3)
            draw_rect(rect, fill, true)
            draw_rect(rect, border, false, 1.4)
            _draw_centered(f, pos + rect.size * 0.5 + Vector2(0, 4), String(face_up_entry.get("icon", "")), 13, border)
        else:
            draw_rect(rect, COLOR_PANEL_OFF, true)
            draw_rect(rect, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.25), false, 1.0)


## 5×5 数字グリッド。`highlight_number` を金色強調。
func _draw_number_grid(w: float, h: float, highlight_number: int) -> void:
    # シャッフル済みの 1..25 (固定配置、視認性優先)
    var nums := [17, 4, 21, 9, 13,
                 2, 18, 7, 24, 11,
                 19, 14, 1, 6, 22,
                 8, 25, 16, 3, 20,
                 12, 5, 23, 10, 15]
    _draw_number_grid_cells(w, h, nums, highlight_number, [])


## 5×5 数字グリッド + 指定数字列の矢印経路 (1→2→3 等)。
func _draw_number_grid_with_arrows(w: float, h: float, sequence: Array) -> void:
    var nums := [17, 4, 21, 9, 13,
                 2, 18, 7, 24, 11,
                 19, 14, 1, 6, 22,
                 8, 25, 16, 3, 20,
                 12, 5, 23, 10, 15]
    _draw_number_grid_cells(w, h, nums, -1, sequence)


func _draw_number_grid_cells(w: float, h: float, nums: Array, highlight: int, arrow_seq: Array) -> void:
    var cell_size := 22.0
    var gap := 3.0
    var grid_size := cell_size * 5.0 + gap * 4.0
    var top_left := Vector2((w - grid_size) * 0.5, (h - grid_size) * 0.5 + 4.0)
    var f: Font = get_theme_default_font()
    var num_to_center: Dictionary = {}
    for i in 25:
        var row: int = i / 5
        var col: int = i % 5
        var pos := top_left + Vector2(float(col) * (cell_size + gap), float(row) * (cell_size + gap))
        var rect := Rect2(pos, Vector2(cell_size, cell_size))
        var n: int = int(nums[i])
        var in_seq: bool = n in arrow_seq
        var is_hi: bool = n == highlight
        if is_hi or in_seq:
            var border: Color = COLOR_GLOW_GOLD
            var fill := Color(border.r, border.g, border.b, 0.3)
            draw_rect(rect, fill, true)
            draw_rect(rect, border, false, 1.4)
            _draw_centered(f, pos + rect.size * 0.5 + Vector2(0, 4), str(n), 11, border)
        else:
            draw_rect(rect, COLOR_PANEL_OFF, true)
            draw_rect(rect, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.25), false, 1.0)
            _draw_centered(f, pos + rect.size * 0.5 + Vector2(0, 4), str(n), 11, COLOR_DIM)
        num_to_center[n] = pos + rect.size * 0.5
    if arrow_seq.size() >= 2:
        for i in range(arrow_seq.size() - 1):
            var a: int = int(arrow_seq[i])
            var b: int = int(arrow_seq[i + 1])
            if num_to_center.has(a) and num_to_center.has(b):
                draw_line(num_to_center[a], num_to_center[b], Color(COLOR_GLOW_GOLD.r, COLOR_GLOW_GOLD.g, COLOR_GLOW_GOLD.b, 0.7), 1.8, true)


func _draw_growth_step(center: Vector2, lit_count: int, label: String, f: Font) -> void:
    # 3×3 ミニグリッド (small) — lit_count 個だけ光る
    var cell_size := 14.0
    var gap := 3.0
    var grid_size := cell_size * 3.0 + gap * 2.0
    var top_left := center - Vector2(grid_size * 0.5, grid_size * 0.5)
    for i in 9:
        var row: int = i / 3
        var col: int = i % 3
        var pos := top_left + Vector2(float(col) * (cell_size + gap), float(row) * (cell_size + gap))
        var rect := Rect2(pos, Vector2(cell_size, cell_size))
        if i < lit_count:
            draw_rect(rect, Color(COLOR_PANEL_ON.r, COLOR_PANEL_ON.g, COLOR_PANEL_ON.b, 0.55), true)
            draw_rect(rect, COLOR_PANEL_ON, false, 1.0)
        else:
            draw_rect(rect, COLOR_PANEL_OFF, true)
            draw_rect(rect, Color(COLOR_GLOW_CYAN.r, COLOR_GLOW_CYAN.g, COLOR_GLOW_CYAN.b, 0.3), false, 0.8)
    _draw_centered(f, center + Vector2(0.0, grid_size * 0.5 + 14.0), label, 14, COLOR_GLOW_CYAN)


func _draw_glow(pos: Vector2, radius: float, base: Color) -> void:
    for i in 6:
        var r := radius * (1.0 - float(i) * 0.14)
        var a := base.a * (0.3 - float(i) * 0.04)
        if a <= 0.0:
            break
        var c := base
        c.a = a
        draw_circle(pos, r, c)


func _draw_tapered_ray(origin: Vector2, dir: Vector2, length: float, base_width: float, color: Color) -> void:
    var tip: Vector2 = origin + dir * length
    var perp: Vector2 = Vector2(-dir.y, dir.x)
    var bl: Vector2 = origin + perp * (base_width * 0.5)
    var br: Vector2 = origin - perp * (base_width * 0.5)
    var pts := PackedVector2Array([bl, tip, br])
    var cols := PackedColorArray()
    var solid: Color = color
    var faded: Color = color
    faded.a = 0.0
    cols.append(solid)
    cols.append(faded)
    cols.append(solid)
    draw_polygon(pts, cols)


func _stroke_ring(center: Vector2, radius: float, color: Color, width: float) -> void:
    var prev: Vector2 = center + Vector2(radius, 0.0)
    var n: int = 36
    for i in range(1, n + 1):
        var ang: float = TAU * float(i) / float(n)
        var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
        draw_line(prev, p, color, width, true)
        prev = p


func _draw_centered(f: Font, center: Vector2, text: String, size_px: int, color: Color) -> void:
    var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    draw_string(f, center - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
