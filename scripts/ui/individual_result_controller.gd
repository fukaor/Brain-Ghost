## IndividualResultController
##
## 全ゲーム共通の個別結果画面コントローラ。リザルトイメージ
## (docs/design/promotion/game_tap_result.png) 準拠の Midnight Cat 暗色レイアウト:
## GradeHeadline (PERFECT WIN 等) + Subtitle + RoundDots (ghost_7ban_shobu のみ) +
## VerdictTitle (勝ち越し！等) + ScoreBlock (score + delta + BEST pill) +
## CompareCards (YOU vs GHOST or YOU vs 自己ベスト) + SpeechBubble + ボタン。
##
## [b]対応ゲーム:[/b] reflex_tap, flash_calc, stroop, sequence_memory,
## card_match, number_search, ghost_7ban_shobu
##
## [b]前提:[/b] GameManager._current_play_log + _previous_score を読む。
extends Control

# ---------------------------------------------------------------------------
# 定数 (ゲーム種別ラベルとデザイントークン)
# ---------------------------------------------------------------------------

## ゲーム種別ラベル (subtitle に表示)
const GAME_SUBTITLE: Dictionary = {
    "ghost_7ban_shobu": "7ラウンド対決",
    "reflex_tap": "反射タップ",
    "flash_calc": "フラッシュ暗算",
    "stroop": "ストループ",
    "sequence_memory": "順番記憶",
    "card_match": "神経衰弱",
    "number_search": "数字さがし",
}

## Midnight Cat デザイントークン (rule_explain / countdown と統一)
const COLOR_GOLD := Color(1.0, 0.914, 0.659)
const COLOR_CYAN300 := Color(0.435, 0.706, 1.0)
const COLOR_CYAN100 := Color(0.7, 0.93, 1.0)
const COLOR_INK95 := Color(0.95, 0.97, 1.0)
const COLOR_INK80 := Color(0.78, 0.824, 0.91)
const COLOR_INK60 := Color(0.78, 0.824, 0.91, 0.7)
const COLOR_GRAY_DIM := Color(0.6, 0.65, 0.75)

## ghost_7ban_shobu の MISS 判定閾値 (delta_ms)
const MISS_THRESHOLD_MS: int = 1000

## 全ラウンド数
const TOTAL_ROUNDS: int = 7


# ---------------------------------------------------------------------------
# ゲーム種別ごとの表示設定
# ---------------------------------------------------------------------------

## 各ゲームの結果画面表示設定を返す。新ゲーム追加時はここに1エントリ追加するだけ。
##
## キー:
## - score_unit: スコア横の単位 ("pts" / "s" 等)
## - score_format: "time"=秒表記 / "int"=整数表記
## - compare_mode: "ghost"=YOU vs GHOST / "self_best"=YOU vs 自己ベスト
## - compare_caption_you / compare_caption_opponent: 比較カードのキャプション
## - ghost_score_placeholder: compare_mode==ghost のときのゴースト基準値 (ms or score)
## - ghost_score_format: ghost_score_placeholder のフォーマット ("time" / "int")
static func _get_display_config(game_type: String) -> Dictionary:
    match game_type:
        "reflex_tap":
            return {
                "score_unit": "s",
                "score_format": "time",
                "compare_mode": "ghost",
                "compare_caption_you": "平均",
                "compare_caption_opponent": "平均",
                "compare_value_format": "time_ms",  # 表示: "112ms"
                "you_event_for_avg": "target_tapped",
                "ghost_score_placeholder": 450.0,
                "ghost_score_format": "time_ms",
            }
        "ghost_7ban_shobu":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "ghost",
                "compare_caption_you": "平均",
                "compare_caption_opponent": "平均",
                "compare_value_format": "time_ms",  # 表示: "112ms"
                "you_event_for_avg": "round_result",
                "ghost_score_placeholder": 273.0,  # GhostData.FALLBACK_DELTA_MS
                "ghost_score_format": "time_ms",
            }
        "flash_calc":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }
        "stroop":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }
        "sequence_memory":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }
        "card_match":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }
        "number_search":
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }
        _:
            return {
                "score_unit": "pts",
                "score_format": "int",
                "compare_mode": "self_best",
                "compare_caption_you": "スコア",
                "compare_caption_opponent": "自己ベスト",
                "compare_value_format": "int",
            }


# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------

# ヘッダ
@onready var _grade_headline: Label = $SafeAreaMargin/MainColumn/HeaderBlock/GradeRow/GradeHeadline
@onready var _star_left: Label = $SafeAreaMargin/MainColumn/HeaderBlock/GradeRow/StarLeft
@onready var _star_right: Label = $SafeAreaMargin/MainColumn/HeaderBlock/GradeRow/StarRight
@onready var _subtitle: Label = $SafeAreaMargin/MainColumn/HeaderBlock/Subtitle
@onready var _round_dots: HBoxContainer = $SafeAreaMargin/MainColumn/HeaderBlock/RoundDots

# 判定タイトル
@onready var _verdict_title: Label = $SafeAreaMargin/MainColumn/VerdictTitle

# スコアブロック
@onready var _score_caption: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreCaption
@onready var _score_value: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/ScoreValue
@onready var _score_unit: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/ScoreUnit
@onready var _delta_badge: PanelContainer = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/DeltaBadge
@onready var _delta_text: Label = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/ScoreRow/DeltaBadge/DeltaText
@onready var _best_pill: PanelContainer = $SafeAreaMargin/MainColumn/ScoreCard/ScoreCardVBox/BestPill

# YOU/GHOST 比較カード
@onready var _you_card: PanelContainer = $SafeAreaMargin/MainColumn/CompareCards/YouCard
@onready var _you_header: Label = $SafeAreaMargin/MainColumn/CompareCards/YouCard/YouVBox/YouHeader
@onready var _you_caption: Label = $SafeAreaMargin/MainColumn/CompareCards/YouCard/YouVBox/YouCaption
@onready var _you_value: Label = $SafeAreaMargin/MainColumn/CompareCards/YouCard/YouVBox/YouValue
@onready var _opponent_card: PanelContainer = $SafeAreaMargin/MainColumn/CompareCards/OpponentCard
@onready var _opponent_header: Label = $SafeAreaMargin/MainColumn/CompareCards/OpponentCard/OpponentVBox/OpponentHeader
@onready var _opponent_caption: Label = $SafeAreaMargin/MainColumn/CompareCards/OpponentCard/OpponentVBox/OpponentCaption
@onready var _opponent_value: Label = $SafeAreaMargin/MainColumn/CompareCards/OpponentCard/OpponentVBox/OpponentValue

# マスコット
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/GhostRow/SpeechBubble/BubbleMargin/SpeechText

# ボタン
@onready var _replay_button: Button = $SafeAreaMargin/MainColumn/ReplayCTAWrap/ReplayButton
@onready var _home_button: Button = $SafeAreaMargin/MainColumn/HomeButton


# ---------------------------------------------------------------------------
# ライフサイクル
# ---------------------------------------------------------------------------

func _ready() -> void:
    _wire_signals()
    _load_from_game_manager()


func _wire_signals() -> void:
    _replay_button.pressed.connect(_on_replay_pressed)
    _home_button.pressed.connect(_on_home_pressed)


func _load_from_game_manager() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm == null:
        _show_dummy_result()
        return
    var log = gm._current_play_log if "_current_play_log" in gm else null
    var prev_score: int = int(gm._previous_score) if "_previous_score" in gm else 0
    if log == null:
        _show_dummy_result()
        return
    set_result(log, prev_score)


## キャプチャモード / GameManager 不在時のダミー結果。
## OS 環境変数 CAPTURE_CASE で 4 ケースを切替 (perfect_win / nice_try / new_best / improved)
func _show_dummy_result() -> void:
    var case_name := OS.get_environment("CAPTURE_CASE")
    if case_name == "":
        case_name = "perfect_win"  # default
    var pair := _build_dummy_log(case_name)
    set_result(pair["log"], int(pair["prev"]))


func _build_dummy_log(case_name: String) -> Dictionary:
    var log := PlayLog.new()
    var prev_score: int = 0

    match case_name:
        "perfect_win":
            log.game_type = "ghost_7ban_shobu"
            log.score = 1750
            log.is_new_best = true
            var wins_pattern := [1, 1, 1, 1, 1, 1, 1]
            var deltas_pattern := [42, 38, 51, 30, 45, 35, 40]
            _append_round_events(log, deltas_pattern, wins_pattern)
            prev_score = 1400
        "nice_try":
            log.game_type = "ghost_7ban_shobu"
            log.score = 820
            log.is_new_best = false
            var wins_pattern := [0, 1, 0, 0, 1, 0, 0]
            var deltas_pattern := [220, 110, 1000, 280, 130, 350, 240]
            _append_round_events(log, deltas_pattern, wins_pattern)
            prev_score = 950
        "new_best":
            log.game_type = "reflex_tap"
            log.score = 875
            log.is_new_best = true
            for d in [320, 350, 305, 380, 340]:
                var e := PlayEvent.new()
                e.event_type = "target_tapped"
                e.value = float(d)
                log.events.append(e)
            prev_score = 720
        "improved":
            log.game_type = "flash_calc"
            log.score = 1020
            log.is_new_best = false
            for i in 6:
                var e := PlayEvent.new()
                e.event_type = "correct"
                e.value = 100.0
                log.events.append(e)
            prev_score = 900
        _:
            log.game_type = "ghost_7ban_shobu"
            log.score = 1280
            log.is_new_best = true
            var wins_pattern := [1, 1, 0, 1, 1, 1, 0]
            var deltas_pattern := [110, 95, 240, 130, 120, 80, 220]
            _append_round_events(log, deltas_pattern, wins_pattern)
            prev_score = 1100
    return {"log": log, "prev": prev_score}


func _append_round_events(log: PlayLog, deltas: Array, wins: Array) -> void:
    for i in deltas.size():
        var evt_d := PlayEvent.new()
        evt_d.event_type = "round_result"
        evt_d.value = float(deltas[i])
        log.events.append(evt_d)
        var evt_w := PlayEvent.new()
        evt_w.event_type = "round_win"
        evt_w.value = float(wins[i])
        log.events.append(evt_w)


# ---------------------------------------------------------------------------
# メイン適用ロジック
# ---------------------------------------------------------------------------

func set_result(log: PlayLog, previous_score: int) -> void:
    var cfg := _get_display_config(log.game_type)
    _apply_grade_headline(log, previous_score)
    _apply_subtitle(log)
    _apply_round_dots(log)
    _apply_verdict_title(log, previous_score)
    _apply_score_block(log, cfg, previous_score)
    _apply_compare_cards(log, cfg)
    _apply_speech(log, previous_score)


# ---------------------------------------------------------------------------
# 算出メソッド
# ---------------------------------------------------------------------------

## ghost_7ban_shobu のラウンド勝数 (round_win イベントの合計)
func _compute_wins(log: PlayLog) -> int:
    var w: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == "round_win":
            w += int(evt.value)
    return w


## grade headline (PERFECT WIN / GREAT WIN / WIN / NICE TRY / NEW BEST / IMPROVED / NICE START)
func _compute_grade_headline(log: PlayLog, previous_score: int) -> Dictionary:
    if log.game_type == "ghost_7ban_shobu":
        var wins := _compute_wins(log)
        if wins >= 7:
            return {"text": "PERFECT WIN", "font_size": 72, "color": COLOR_GOLD, "deco": true}
        if wins >= 5:
            return {"text": "GREAT WIN", "font_size": 64, "color": COLOR_GOLD, "deco": true}
        if wins >= 4:
            return {"text": "WIN", "font_size": 56, "color": COLOR_GOLD, "deco": true}
        return {"text": "NICE TRY", "font_size": 56, "color": COLOR_INK80, "deco": false}
    if log.is_new_best:
        return {"text": "NEW BEST", "font_size": 64, "color": COLOR_GOLD, "deco": true}
    if previous_score <= 0:
        return {"text": "NICE START", "font_size": 56, "color": COLOR_GOLD, "deco": true}
    if log.score > previous_score:
        return {"text": "IMPROVED", "font_size": 56, "color": COLOR_GOLD, "deco": true}
    return {"text": "NICE TRY", "font_size": 56, "color": COLOR_INK80, "deco": false}


## 判定タイトル (✧ 勝ち越し！✧ など)
func _compute_verdict_title(log: PlayLog, previous_score: int) -> Dictionary:
    if log.game_type == "ghost_7ban_shobu":
        var wins := _compute_wins(log)
        if wins >= 4:
            return {"text": "✧ 勝ち越し！ ✧", "color": COLOR_GOLD}
        return {"text": "✧ あと一歩！ ✧", "color": COLOR_INK80}
    if log.is_new_best:
        return {"text": "✧ 自己最高記録！ ✧", "color": COLOR_GOLD}
    if previous_score <= 0:
        return {"text": "✧ 良いスタート！ ✧", "color": COLOR_GOLD}
    if log.score > previous_score:
        return {"text": "✧ 成長してる！ ✧", "color": COLOR_GOLD}
    return {"text": "✧ ナイスプレイ！ ✧", "color": COLOR_INK80}


## ghost_7ban_shobu の各ラウンド結果 ("win" / "loss" / "miss") を 7 要素配列で返す
func _compute_round_outcomes(log: PlayLog) -> Array:
    if log.game_type != "ghost_7ban_shobu":
        return []
    var deltas: Array = []
    var wins: Array = []
    for evt in log.events:
        if evt == null:
            continue
        if evt.event_type == "round_result":
            deltas.append(int(evt.value))
        elif evt.event_type == "round_win":
            wins.append(int(evt.value))
    var out: Array = []
    for i in deltas.size():
        if deltas[i] >= MISS_THRESHOLD_MS:
            out.append("miss")
        elif i < wins.size() and wins[i] == 1:
            out.append("win")
        else:
            out.append("loss")
    while out.size() < TOTAL_ROUNDS:
        out.append("miss")
    return out


## delta badge (前回比 +N)。delta > 0 のときのみ visible
func _compute_delta(log: PlayLog, previous_score: int) -> Dictionary:
    if previous_score <= 0:
        return {"visible": false, "text": ""}
    var diff: int = log.score - previous_score
    if diff <= 0:
        return {"visible": false, "text": ""}
    return {"visible": true, "text": "+%s" % _format_thousands(diff)}


## 3 桁区切りフォーマット ("1280" -> "1,280")
static func _format_thousands(n: int) -> String:
    var negative := n < 0
    var s := str(abs(n))
    var result := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        if count > 0 and count % 3 == 0:
            result = "," + result
        result = s[i] + result
        count += 1
    return ("-" if negative else "") + result


## 指定イベント型の value 平均 (タイム系平均算出)
func _compute_avg_value(log: PlayLog, event_type: String) -> float:
    if log == null or log.events.is_empty():
        return 0.0
    var total: float = 0.0
    var count: int = 0
    for evt in log.events:
        if evt != null and evt.event_type == event_type:
            total += float(evt.value)
            count += 1
    if count == 0:
        return 0.0
    return total / float(count)


# ---------------------------------------------------------------------------
# 適用メソッド
# ---------------------------------------------------------------------------

func _apply_grade_headline(log: PlayLog, previous_score: int) -> void:
    var g := _compute_grade_headline(log, previous_score)
    _grade_headline.text = String(g["text"])
    _grade_headline.add_theme_font_size_override("font_size", int(g["font_size"]))
    _grade_headline.add_theme_color_override("font_color", g["color"])
    var deco := bool(g["deco"])
    _star_left.visible = deco
    _star_right.visible = deco
    if deco:
        _star_left.add_theme_color_override("font_color", g["color"])
        _star_right.add_theme_color_override("font_color", g["color"])


func _apply_subtitle(log: PlayLog) -> void:
    _subtitle.text = String(GAME_SUBTITLE.get(log.game_type, log.game_type))


func _apply_round_dots(log: PlayLog) -> void:
    var outcomes := _compute_round_outcomes(log)
    if outcomes.is_empty():
        _round_dots.visible = false
        return
    _round_dots.visible = true
    var children := _round_dots.get_children()
    for i in TOTAL_ROUNDS:
        if i >= children.size():
            break
        var label: Label = children[i] as Label
        if label == null:
            continue
        # NotoSansJP で Unicode を直接描画 (Material Symbols は fill axis 設定が必要なので回避)
        match String(outcomes[i]):
            "win":
                label.text = "●"
                label.add_theme_color_override("font_color", COLOR_CYAN100)
            "loss":
                label.text = "✕"
                label.add_theme_color_override("font_color", COLOR_GRAY_DIM)
            "miss":
                label.text = "○"
                label.add_theme_color_override("font_color", Color(COLOR_GRAY_DIM.r, COLOR_GRAY_DIM.g, COLOR_GRAY_DIM.b, 0.5))


func _apply_verdict_title(log: PlayLog, previous_score: int) -> void:
    var v := _compute_verdict_title(log, previous_score)
    _verdict_title.text = String(v["text"])
    _verdict_title.add_theme_color_override("font_color", v["color"])


func _apply_score_block(log: PlayLog, cfg: Dictionary, previous_score: int) -> void:
    _score_caption.text = "スコア"
    if String(cfg.get("score_format", "int")) == "time":
        _score_value.text = "%.2f" % (float(log.score) / 1000.0) if log.score > 0 else "—"
    else:
        _score_value.text = _format_thousands(log.score) if log.score > 0 else "—"
    _score_unit.text = String(cfg.get("score_unit", "pts"))

    var delta := _compute_delta(log, previous_score)
    _delta_badge.visible = bool(delta["visible"])
    if bool(delta["visible"]):
        _delta_text.text = String(delta["text"])

    _best_pill.visible = log.is_new_best


func _apply_compare_cards(log: PlayLog, cfg: Dictionary) -> void:
    _you_caption.text = String(cfg.get("compare_caption_you", "スコア"))
    _opponent_caption.text = String(cfg.get("compare_caption_opponent", "自己ベスト"))

    var mode := String(cfg.get("compare_mode", "self_best"))
    var value_fmt := String(cfg.get("compare_value_format", "int"))

    var you_value: float = 0.0
    var opp_value: float = 0.0

    # YOU ヘッダは常に cyan
    _you_header.text = "YOU"
    _you_header.add_theme_color_override("font_color", COLOR_CYAN300)

    if mode == "ghost":
        var evt_name := String(cfg.get("you_event_for_avg", ""))
        you_value = _compute_avg_value(log, evt_name) if evt_name != "" else float(log.score)
        opp_value = float(cfg.get("ghost_score_placeholder", 0.0))
        _opponent_header.text = "GHOST"
        _opponent_header.add_theme_color_override("font_color", COLOR_GRAY_DIM)
        _opponent_card.add_theme_stylebox_override("panel", _build_card_style(COLOR_GRAY_DIM, 0.4))
        _opponent_value.add_theme_color_override("font_color", COLOR_INK80)
    else:  # self_best
        you_value = float(log.score)
        opp_value = _load_self_best(log.game_type)
        _opponent_header.text = "BEST"
        _opponent_header.add_theme_color_override("font_color", COLOR_GOLD)
        _opponent_card.add_theme_stylebox_override("panel", _build_card_style(COLOR_GOLD, 0.55))
        _opponent_value.add_theme_color_override("font_color", COLOR_GOLD)

    _you_value.text = _format_compare_value(you_value, value_fmt)
    _opponent_value.text = _format_compare_value(opp_value, value_fmt)


## OpponentCard のボーダー色を動的に切り替えるための StyleBoxFlat を生成。
## ghost モード=gray dim, self_best モード=gold で見分ける。
func _build_card_style(border: Color, alpha: float) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.04, 0.08, 0.16, 0.55)
    sb.content_margin_left = 14.0
    sb.content_margin_top = 14.0
    sb.content_margin_right = 14.0
    sb.content_margin_bottom = 14.0
    sb.border_width_left = 2
    sb.border_width_top = 2
    sb.border_width_right = 2
    sb.border_width_bottom = 2
    sb.border_color = Color(border.r, border.g, border.b, alpha)
    sb.corner_radius_top_left = 20
    sb.corner_radius_top_right = 20
    sb.corner_radius_bottom_right = 20
    sb.corner_radius_bottom_left = 20
    return sb


func _apply_speech(log: PlayLog, previous_score: int) -> void:
    var g := _compute_grade_headline(log, previous_score)
    var grade := String(g["text"])
    var msg: String
    match grade:
        "PERFECT WIN":
            msg = "完璧！\n今日のキミはヒーローだ！"
        "GREAT WIN":
            msg = "素晴らしい勝ち越しだよ！\nこの調子！"
        "WIN":
            msg = "やったね！\n今日は一歩近づいたよ"
        "NEW BEST":
            msg = "すごい！\n自己ベスト更新だよ！"
        "IMPROVED":
            msg = "成長してる！\nこの調子で行こう"
        "NICE START":
            msg = "良いスタート！\n基準値ができたよ"
        _:
            msg = "今日は惜しかった！\n次はきっと超えられるよ"
    _speech_text.text = msg


# ---------------------------------------------------------------------------
# ヘルパー
# ---------------------------------------------------------------------------

func _load_self_best(game_type: String) -> float:
    var ds := get_node_or_null("/root/DataStore")
    if ds == null or not ds.has_method("load_best"):
        return 0.0
    var best = ds.load_best(game_type)
    if best == null:
        return 0.0
    return float(best.best_score) if "best_score" in best else 0.0


func _format_compare_value(v: float, fmt: String) -> String:
    if v <= 0.0:
        return "—"
    match fmt:
        "time_ms":
            return "%dms" % int(v)
        "time_s":
            return "%.2fs" % (v / 1000.0)
        _:
            return _format_thousands(int(v))


# ---------------------------------------------------------------------------
# ボタンハンドラ
# ---------------------------------------------------------------------------

func _on_replay_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_individual_result_replay"):
        gm.on_individual_result_replay()
    else:
        push_warning("[IndividualResult] GameManager.on_individual_result_replay not found")


func _on_home_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_individual_result_home"):
        gm.on_individual_result_home()
    else:
        push_warning("[IndividualResult] GameManager.on_individual_result_home not found")
