## RuleExplainController
##
## ゲーム開始前のルール説明画面を制御する。ゴーストキャラクタが吹き出しで
## ルールを喋るのが本画面の特徴。
##
## [b]データドリブン:[/b] RULES Dictionary に各ゲームの title + dialogue を登録しておき、
## [code]set_rule(game_type)[/code] で差し替え可能。将来他 5 ゲーム実装時にエントリを追加するだけ。
extends Control

## ゲームごとのルール定義。新ゲーム追加時はここにエントリを足す。
const RULES: Dictionary = {
    "reflex_tap": {
        "title": "反射タップ",
        "dialogue": "ランダムに出てくる丸をできるだけ速くタップしてね。\n20 回の平均時間でスコアが決まるよ。\n違う色の偽物はタップしちゃダメ！",
    },
    "flash_calc": {
        "title": "フラッシュ暗算",
        "dialogue": "計算式が次々出てくるよ。\n答えをテンキーで入力して OK を押してね。\n30 秒で何問解けるかな？",
    },
    # 将来: "number_search", "stroop", "sequence_memory", "card_match"
}

@onready var _title_label: Label = $SafeAreaMargin/MainColumn/TitleLabel
@onready var _ghost: GhostCharacter = $SafeAreaMargin/MainColumn/GhostCharacter
@onready var _skip_button: Button = $SafeAreaMargin/MainColumn/ButtonRow/SkipButton
@onready var _start_button: Button = $SafeAreaMargin/MainColumn/ButtonRow/StartButton


func _ready() -> void:
    _wire_signals()
    # GameManager から現在のゲームタイプを読む
    var game_type: String = "reflex_tap"  # デフォルト
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and "_current_game_type" in gm:
        var gt: String = String(gm._current_game_type)
        if gt != "":
            game_type = gt
    set_rule(game_type)
    _configure_skip_visibility()


## ルールを差し替える（他ゲームでも呼べる）
func set_rule(game_type: String) -> void:
    var rule: Dictionary = RULES.get(game_type, {})
    if rule.is_empty():
        push_warning("[RuleExplain] No rule found for game_type: %s" % game_type)
        _title_label.text = "ゲーム"
        _ghost.set_dialogue("ルール情報が見つからないよ。ごめんね。")
        return
    _title_label.text = String(rule.get("title", ""))
    _ghost.set_dialogue(String(rule.get("dialogue", "")))
    # 精度はホーム画面と同じ（実データ連動は後続タスク）
    _ghost.set_accuracy(0.67)


func _wire_signals() -> void:
    _start_button.pressed.connect(_on_start_pressed)
    _skip_button.pressed.connect(_on_skip_pressed)


func _configure_skip_visibility() -> void:
    # UserConfig.onboardingCompleted == true のときのみ Skip を表示
    # 現時点では UserConfig 実装が未完成なのでデフォルトで hide
    # TODO: DataStore.load_dict(UserConfig) を使って判定する
    _skip_button.visible = false


func _on_start_pressed() -> void:
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("on_rule_explain_confirmed"):
        gm.on_rule_explain_confirmed()
    else:
        push_warning("[RuleExplain] GameManager.on_rule_explain_confirmed not found")


func _on_skip_pressed() -> void:
    _on_start_pressed()
