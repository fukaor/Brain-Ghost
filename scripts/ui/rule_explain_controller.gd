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
        "target_icon": "flare",
        "target_action": "タップして！",
        "fake_icon": "flare",
        "fake_action": "無視してね",
    },
    "flash_calc": {
        "title": "フラッシュ暗算",
        "speech": "「フラッシュ暗算」のルールを説明するね！計算式が出てくるから、答えをテンキーで入力してね。30秒で何問解けるかな？",
        "subtitle_icon": "calculate",
        "subtitle": "30秒間で計算問題に挑戦",
        "target_icon": "dialpad",
        "target_action": "テンキーで入力",
        "fake_icon": "schedule",
        "fake_action": "30秒以内に！",
    },
}

# ---------------------------------------------------------------------------
# ノード参照
# ---------------------------------------------------------------------------
@onready var _speech_text: Label = $SafeAreaMargin/MainColumn/GhostRow/SpeechBubble/BubbleMargin/SpeechText
@onready var _title_label: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/TitleLabel
@onready var _subtitle_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/SubtitleContainer/SubtitleRow/SubtitleIcon
@onready var _subtitle_text: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/SubtitleContainer/SubtitleRow/SubtitleText
@onready var _target_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/TargetCard/TargetColumn/TargetIconCenter/TargetIconBg/TargetIcon
@onready var _target_action: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/TargetCard/TargetColumn/TargetActionCenter/TargetActionPill/TargetAction
@onready var _fake_icon: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeIconCenter/FakeIconBg/FakeIcon
@onready var _fake_action: Label = $SafeAreaMargin/MainColumn/MainCard/CardMargin/CardVBox/HintCardsRow/FakeCard/FakeColumn/FakeActionCenter/FakeActionPill/FakeAction
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
    _target_icon.text = String(rule.get("target_icon", "stars"))
    _target_action.text = String(rule.get("target_action", ""))
    _fake_icon.text = String(rule.get("fake_icon", "close"))
    _fake_action.text = String(rule.get("fake_action", ""))


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
