## RuleExplainController (Midnight Cat v3)
##
## ゲーム開始前のルール説明画面。docs/design/promotion/game_tap_rule.png 準拠。
##
## レイアウト:
## - 上部: 「📖 ルール説明」ヘッダ + ホームに戻る
## - 中央: 明朝タイトル + サブタイトル「鍛える能力：◯◯」
## - 中央: 3 ステップカード (RuleStepPreview ミニ図 + テキスト)
## - 下部: スタート CTA
##
## データドリブン: RULES Dictionary に各ゲームの 3 ステップを登録。
## set_rule(game_type) で他ゲームでも再利用可能。
extends Control

const RULES: Dictionary = {
    "ghost_7ban_shobu": {
        "title": "ゴースト7番勝負",
        "ability_label": "鍛える能力：反射速度",
        "steps": [
            {
                "index": "1.",
                "title": "構える",
                "body": "予告を見て、\n構えよう",
                "preview_variant": "ready",
            },
            {
                "index": "2.",
                "title": "タップで迎撃",
                "body": "光が中心に来た瞬間、\nタップ！",
                "preview_variant": "tap",
            },
            {
                "index": "3.",
                "title": "ゴーストに勝て",
                "body": "中央に近い方が勝ち。\nゴーストより勝ち越せ",
                "preview_variant": "compare",
            },
        ],
    },
    "flash_calc": {
        "title": "フラッシュ暗算",
        "ability_label": "鍛える能力：計算力",
        "steps": [
            {
                "index": "1.",
                "title": "覚える",
                "body": "数字が次々と光る。\n覚えよう",
                "preview_variant": "ready",
            },
            {
                "index": "2.",
                "title": "計算する",
                "body": "すべての合計を\n暗算しよう",
                "preview_variant": "tap",
            },
            {
                "index": "3.",
                "title": "打ち込む",
                "body": "ゴーストより速く\n答えを入力しよう",
                "preview_variant": "compare",
            },
        ],
    },
    "sequence_memory": {
        "title": "順番記憶",
        "ability_label": "鍛える能力：記憶力",
        "steps": [
            {
                "index": "1.",
                "title": "光る順を覚える",
                "body": "パネルが順に光るので\n順番を覚えよう",
                "preview_variant": "ready",
            },
            {
                "index": "2.",
                "title": "同じ順でタップ",
                "body": "覚えた順番で\nパネルをタップ",
                "preview_variant": "tap",
            },
            {
                "index": "3.",
                "title": "ステージを伸ばせ",
                "body": "ステージが進むほど\n光るパネルが増えるよ",
                "preview_variant": "compare",
            },
        ],
    },
}

# ノード参照 -----------------------------------------------------------------
@onready var _title_label: Label = $SafeArea/MainColumn/TitleBlock/TitleLabel
@onready var _ability_label: Label = $SafeArea/MainColumn/TitleBlock/AbilityLabel
@onready var _step1_index: Label = $SafeArea/MainColumn/StepsColumn/Step1/Row/TextBlock/IndexRow/Index
@onready var _step1_title: Label = $SafeArea/MainColumn/StepsColumn/Step1/Row/TextBlock/IndexRow/Title
@onready var _step1_body: Label = $SafeArea/MainColumn/StepsColumn/Step1/Row/TextBlock/Body
@onready var _step1_preview: Control = $SafeArea/MainColumn/StepsColumn/Step1/Row/Preview
@onready var _step2_index: Label = $SafeArea/MainColumn/StepsColumn/Step2/Row/TextBlock/IndexRow/Index
@onready var _step2_title: Label = $SafeArea/MainColumn/StepsColumn/Step2/Row/TextBlock/IndexRow/Title
@onready var _step2_body: Label = $SafeArea/MainColumn/StepsColumn/Step2/Row/TextBlock/Body
@onready var _step2_preview: Control = $SafeArea/MainColumn/StepsColumn/Step2/Row/Preview
@onready var _step3_index: Label = $SafeArea/MainColumn/StepsColumn/Step3/Row/TextBlock/IndexRow/Index
@onready var _step3_title: Label = $SafeArea/MainColumn/StepsColumn/Step3/Row/TextBlock/IndexRow/Title
@onready var _step3_body: Label = $SafeArea/MainColumn/StepsColumn/Step3/Row/TextBlock/Body
@onready var _step3_preview: Control = $SafeArea/MainColumn/StepsColumn/Step3/Row/Preview
@onready var _start_button: Button = $SafeArea/MainColumn/StartCTAWrap/StartButton
@onready var _back_button: Button = $SafeArea/MainColumn/Header/BackButton


func _ready() -> void:
    _wire_signals()
    var game_type: String = "ghost_7ban_shobu"
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and "_current_game_type" in gm:
        var gt: String = String(gm._current_game_type)
        if gt != "":
            game_type = gt
    set_rule(game_type)


func set_rule(game_type: String) -> void:
    var rule: Dictionary = RULES.get(game_type, RULES.get("ghost_7ban_shobu"))
    _title_label.text = String(rule.get("title", ""))
    _ability_label.text = String(rule.get("ability_label", ""))
    var steps: Array = rule.get("steps", [])
    var groups := [
        [_step1_index, _step1_title, _step1_body, _step1_preview],
        [_step2_index, _step2_title, _step2_body, _step2_preview],
        [_step3_index, _step3_title, _step3_body, _step3_preview],
    ]
    for i in 3:
        if i >= steps.size():
            continue
        var s: Dictionary = steps[i]
        groups[i][0].text = String(s.get("index", ""))
        groups[i][1].text = String(s.get("title", ""))
        groups[i][2].text = String(s.get("body", ""))
        var preview: Control = groups[i][3]
        if preview != null and "variant" in preview:
            preview.variant = String(s.get("preview_variant", "ready"))


func _wire_signals() -> void:
    _start_button.pressed.connect(_on_start_pressed)
    _back_button.pressed.connect(_on_back_pressed)


func _on_start_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_confirmed"):
        gm.on_rule_explain_confirmed()


func _on_back_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_cancelled"):
        gm.on_rule_explain_cancelled()
    else:
        get_tree().change_scene_to_file("res://scenes/main/home.tscn")
