## RuleExplainController
##
## ゲーム開始前のルール説明画面を制御する。
## Stitch v3「背景・透過修正版」デザイン準拠 (2026-04-14):
## - 上部: ゴーストちび(左) + 吹き出し(ルール説明テキスト)
## - 中央: 白カード内に タイトル + サブ説明 + TARGET/FAKE 2列
## - 下部: CTA「脳トレを開始する ▶」+ テキストリンク「ホームに戻る」
##
## [b]データドリブン:[/b] RULES Dictionary に各ゲームのデータを登録。
## set_rule(game_type) で差し替え可能。
extends Control

## ゲームごとのルール定義。新ゲーム追加時はここにエントリを足す。
const RULES: Dictionary = {
    "reflex_tap": {
        "title": "反射タップ",
        "speech": "「反射タップ」のルールを説明するね！画面に出てくるターゲットを、できるだけ早くタップして。フェイクには気をつけてね。",
        "subtitle_icon": "track_changes",
        "subtitle": "20回タップの平均反応時間を計測",
        "card1_title": "TARGET",
        "card1_icon": "flare",
        "card1_action": "タップして！",
        "card2_title": "FAKE",
        "card2_icon": "flare",
        "card2_action": "無視してね",
        "card2_style": "inactive",  # inactive=グレー(やらない), active=青(やる)
    },
    "flash_calc": {
        "title": "フラッシュ暗算",
        "speech": "「フラッシュ暗算」のルールを説明するね！画面に次々出てくる数字を計算して、足したり引いたりして、最後に合計を答えてね。",
        "subtitle_icon": "calculate",
        "subtitle": "制限時間：30秒",
        "card1_title": "入力",
        "card1_icon": "dialpad",
        "card1_action": "テンキーで回答",
        "card2_title": "制限",
        "card2_icon": "schedule",
        "card2_action": "30秒以内に！",
        "card2_style": "inactive",
    },
    "stroop": {
        "title": "ストループ",
        "speech": "「ストループ」のルールを説明するね！文字の「色」を答えてね。書いてある言葉ではなく、色に注目して！",
        "subtitle_icon": "palette",
        "subtitle": "30秒間で文字の色を正しく回答",
        "card1_title": "正解",
        "card1_icon": "check_circle",
        "card1_action": "色をタップ！",
        "card2_title": "注意",
        "card2_icon": "warning",
        "card2_action": "文字ではなく色",
        "card2_style": "inactive",
    },
    "sequence_memory": {
        "title": "順番記憶",
        "speech": "「順番記憶」のルールを説明するね！パネルが光る順番を覚えて、同じ順番でタップしてね。レベルが上がると数が増えるよ！",
        "subtitle_icon": "grid_view",
        "subtitle": "光る順番を覚えてタップ",
        "card1_title": "記憶",
        "card1_icon": "visibility",
        "card1_action": "順番を覚えて",
        "card2_title": "再現",
        "card2_icon": "touch_app",
        "card2_action": "同じ順でタップ",
        "card2_style": "active",
    },
    "card_match": {
        "title": "神経衰弱",
        "speech": "「神経衰弱」のルールを説明するね！カードをめくって同じ絵柄のペアを見つけてね。少ないタップ数でクリアを目指そう！",
        "subtitle_icon": "content_copy",
        "subtitle": "ペアを見つけてクリア",
        "card1_title": "めくる",
        "card1_icon": "flip",
        "card1_action": "カードをタップ",
        "card2_title": "目標",
        "card2_icon": "emoji_events",
        "card2_action": "少ないタップで",
        "card2_style": "active",
    },
    "number_search": {
        "title": "数字さがし",
        "speech": "「数字さがし」のルールを説明するね！画面に散らばった数字を、1から順番にタップしていってね。速くクリアするほど高得点！",
        "subtitle_icon": "search",
        "subtitle": "1から順番にタップ",
        "card1_title": "探す",
        "card1_icon": "pin",
        "card1_action": "1→2→3の順で",
        "card2_title": "スピード",
        "card2_icon": "bolt",
        "card2_action": "速いほど高得点",
        "card2_style": "active",
    },
    "ghost_7ban_shobu": {
        "title": "ゴースト7番勝負",
        "speech": "「ゴースト7番勝負」は 7 ラウンドの決闘だよ。ターゲットが GHOST LINE を通る瞬間にタップ。ゴーストより先に当てれば 1 勝！",
        "subtitle_icon": "bolt",
        "subtitle": "7 ラウンド / 約 30 秒",
        "card1_title": "TIMING",
        "card1_icon": "center_focus_strong",
        "card1_action": "ラインで TAP",
        "card2_title": "GHOST",
        "card2_icon": "swords",
        "card2_action": "先に当てる",
        "card2_style": "active",
    },
}

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/GhostRow/SpeechBubble/BubbleMargin/SpeechText
@onready var _title_label: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/TitleLabel
@onready var _subtitle_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/SubtitleContainer/SubtitleRow/SubtitleIcon
@onready var _subtitle_text: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/SubtitleContainer/SubtitleRow/SubtitleText
# ヒントカード1（左）
@onready var _card1_title: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/TargetCard/TargetColumn/TargetTitle
@onready var _card1_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/TargetCard/TargetColumn/TargetIconCenter/TargetIconBg/TargetIcon
@onready var _card1_action: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/TargetCard/TargetColumn/TargetActionCenter/TargetActionPill/TargetAction
# ヒントカード2（右）
@onready var _card2_panel: PanelContainer = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard
@onready var _card2_title: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeTitle
@onready var _card2_icon_bg: PanelContainer = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeIconCenter/FakeIconBg
@onready var _card2_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeIconCenter/FakeIconBg/FakeIcon
@onready var _card2_action_pill: PanelContainer = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeActionCenter/FakeActionPill
@onready var _card2_action: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeActionCenter/FakeActionPill/FakeAction
# ボタン
@onready var _start_button: Button = $SafeAreaMargin/MainColumn/StartButton
@onready var _home_link: Button = $SafeAreaMargin/MainColumn/HomeLinkButton


func _ready() -> void:
    _wire_signals()
    var game_type: String = "reflex_tap"
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and "_current_game_type" in gm:
        var gt: String = String(gm._current_game_type)
        if gt != "":
            game_type = gt
    set_rule(game_type)


## ルールを差し替える（他ゲームでも呼べる）
func set_rule(game_type: String) -> void:
    var rule: Dictionary = RULES.get(game_type, {})
    if rule.is_empty():
        push_warning("[RuleExplain] No rule found for game_type: %s" % game_type)
        _title_label.text = "ゲーム"
        _speech_text.text = "ルール情報が見つからないよ。ごめんね。"
        return

    _title_label.text = String(rule.get("title", ""))
    _speech_text.text = String(rule.get("speech", ""))
    _subtitle_icon.text = String(rule.get("subtitle_icon", "timer"))
    _subtitle_text.text = String(rule.get("subtitle", ""))
    _card1_title.text = String(rule.get("card1_title", "TARGET"))
    _card1_icon.text = String(rule.get("card1_icon", "stars"))
    _card1_action.text = String(rule.get("card1_action", ""))
    _card2_title.text = String(rule.get("card2_title", "FAKE"))
    _card2_icon.text = String(rule.get("card2_icon", "close"))
    _card2_action.text = String(rule.get("card2_action", ""))

    # カード2: 枠・タイトル・ピルは全ゲーム青系で統一。アイコンのみゲームごとに切替。
    # card2_style: "active"=アイコン青(やる), "inactive"=アイコングレー(注意/やらない)
    _card2_panel.theme_type_variation = "hint_card_target"
    _card2_title.add_theme_color_override("font_color", Color(0, 0.484, 1, 1))
    _card2_action_pill.theme_type_variation = "pill_action_blue"
    _card2_action.add_theme_color_override("font_color", Color(1, 1, 1, 1))

    var card2_style: String = String(rule.get("card2_style", "inactive"))
    if card2_style == "active":
        _card2_icon_bg.theme_type_variation = "icon_circle_blue"
        _card2_icon.add_theme_color_override("font_color", Color(0, 0.484, 1, 1))
    else:
        _card2_icon_bg.theme_type_variation = "icon_circle_grey"
        _card2_icon.add_theme_color_override("font_color", Color(0.424, 0.459, 0.62, 0.4))


func _wire_signals() -> void:
    _start_button.pressed.connect(_on_start_pressed)
    _home_link.pressed.connect(_on_back_pressed)


func _on_start_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_confirmed"):
        gm.on_rule_explain_confirmed()
    else:
        push_warning("[RuleExplain] GameManager.on_rule_explain_confirmed not found")


func _on_back_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_cancelled"):
        gm.on_rule_explain_cancelled()
    else:
        push_warning("[RuleExplain] GameManager.on_rule_explain_cancelled not found")
