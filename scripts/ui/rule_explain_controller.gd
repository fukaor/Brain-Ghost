## RuleExplainController (Sumi Ghost v4)
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
                "preview_variant": "flash_number",
            },
            {
                "index": "2.",
                "title": "計算する",
                "body": "すべての合計を\n暗算しよう",
                "preview_variant": "calc_sum",
            },
            {
                "index": "3.",
                "title": "打ち込む",
                "body": "ゴーストより速く\n答えを入力しよう",
                "preview_variant": "calc_input",
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
                "preview_variant": "grid_show",
            },
            {
                "index": "2.",
                "title": "同じ順でタップ",
                "body": "覚えた順番で\nパネルをタップ",
                "preview_variant": "grid_tap",
            },
            {
                "index": "3.",
                "title": "ステージを伸ばせ",
                "body": "ステージが進むほど\n光るパネルが増えるよ",
                "preview_variant": "grid_grow",
            },
        ],
    },
    "stroop": {
        "title": "色文字ストループ",
        "ability_label": "鍛える能力：注意力",
        "steps": [
            {
                "index": "1.",
                "title": "色を見る",
                "body": "画面中央に色文字や\n色付き図形が出るよ",
                "preview_variant": "stroop_show",
            },
            {
                "index": "2.",
                "title": "色を答える",
                "body": "文字の意味は無視して\n「色」のボタンをタップ",
                "preview_variant": "stroop_answer",
            },
            {
                "index": "3.",
                "title": "30 秒で連続正解",
                "body": "正解 +100、誤答 −50。\n速く正確に！",
                "preview_variant": "stroop_combo",
            },
        ],
    },
    "card_match": {
        "title": "神経衰弱ライト",
        "ability_label": "鍛える能力：判断力",
        "steps": [
            {
                "index": "1.",
                "title": "覚える",
                "body": "16 枚の裏向きカード。\n2 枚めくって絵柄を覚える",
                "preview_variant": "card_show",
            },
            {
                "index": "2.",
                "title": "ペアを揃える",
                "body": "同じ絵柄が出たら\nそのカードは固定される",
                "preview_variant": "card_pair",
            },
            {
                "index": "3.",
                "title": "60 秒で 8 ペア",
                "body": "タップが少ないほど\nスコアは高くなるよ",
                "preview_variant": "card_timer",
            },
        ],
    },
    "number_search": {
        "title": "数字さがし",
        "ability_label": "鍛える能力：観察力",
        "steps": [
            {
                "index": "1.",
                "title": "1 を探す",
                "body": "5×5 の中から\n1 を見つけよう",
                "preview_variant": "number_find",
            },
            {
                "index": "2.",
                "title": "順にタップ",
                "body": "1, 2, 3 …と\n昇順にタップしよう",
                "preview_variant": "number_sequence",
            },
            {
                "index": "3.",
                "title": "60 秒以内に",
                "body": "25 までクリアでタイムが\nスコアになるよ",
                "preview_variant": "number_clear",
            },
        ],
    },
}

# ノード参照 (縦/横シーン共通、find_child でパス非依存に解決) ------------------
@onready var _title_label: Label = find_child("TitleLabel") as Label
@onready var _ability_label: Label = find_child("AbilityLabel") as Label
# 各 Step は Step1/Step2/Step3 ノード起点で find_child することで Index/Title/Body/Preview の名前重複を解決
@onready var _step1_index: Label = find_child("Step1").find_child("Index") as Label
@onready var _step1_title: Label = find_child("Step1").find_child("Title") as Label
@onready var _step1_body: Label = find_child("Step1").find_child("Body") as Label
@onready var _step1_preview: Control = find_child("Step1").find_child("Preview") as Control
@onready var _step2_index: Label = find_child("Step2").find_child("Index") as Label
@onready var _step2_title: Label = find_child("Step2").find_child("Title") as Label
@onready var _step2_body: Label = find_child("Step2").find_child("Body") as Label
@onready var _step2_preview: Control = find_child("Step2").find_child("Preview") as Control
@onready var _step3_index: Label = find_child("Step3").find_child("Index") as Label
@onready var _step3_title: Label = find_child("Step3").find_child("Title") as Label
@onready var _step3_body: Label = find_child("Step3").find_child("Body") as Label
@onready var _step3_preview: Control = find_child("Step3").find_child("Preview") as Control
@onready var _start_button: Button = find_child("StartButton") as Button
@onready var _back_button: Button = find_child("BackButton") as Button


func _ready() -> void:
    # SENSOR orientation 副作用対策: 縦/横をシーン名で確定する
    if scene_file_path.ends_with("_landscape.tscn"):
        OrientationHelper.enter_landscape()
    else:
        OrientationHelper.enter_portrait()

    _wire_signals()
    var game_type: String = "ghost_7ban_shobu"
    var gm := get_node_or_null("/root/GameManager")
    if gm != null:
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
    # 戻り先 (game_list / home) は必ず portrait のため、landscape 版から戻った場合の向きを復元する。
    OrientationHelper.enter_portrait()
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_cancelled"):
        gm.on_rule_explain_cancelled()
    else:
        get_tree().change_scene_to_file("res://scenes/main/home.tscn")
