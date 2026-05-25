## FlashCalcHome
##
## フラッシュ暗算 ホーム画面 (ティア選択) コントローラ。
## 仕様: docs/ideas/games/ghost-ippon-shobu-calc-spec.md §3-1。
##
## MVP: 8 ティアを全表示 (折りたたみ式は v1.1 以降)。
## 適正ティアにバッジを付与し、ロック済みティアは disable + 鍵アイコン。
extends Control

const _Tier = preload("res://scripts/games/flash_calc/tier_config.gd")

@onready var _appropriate_label: Label = $SafeArea/MainColumn/AppropriateLabel
@onready var _tier_grid: GridContainer = $SafeArea/MainColumn/TierGrid
@onready var _back_button: Button = $SafeArea/MainColumn/FooterRow/BackButton


func _ready() -> void:
    _back_button.pressed.connect(_on_back_pressed)
    _build_tier_grid()
    _appropriate_label.text = "🎯 今日の適正ティア: %s" % FlashCalcGhostStore.get_appropriate_tier()


func _build_tier_grid() -> void:
    for child in _tier_grid.get_children():
        child.queue_free()
    var appropriate: String = FlashCalcGhostStore.get_appropriate_tier()
    for tier in _Tier.TIER_LIST:
        var btn := _build_tier_button(tier, appropriate)
        _tier_grid.add_child(btn)


func _build_tier_button(tier: String, appropriate: String) -> Button:
    var unlocked: bool = FlashCalcGhostStore.is_unlocked(tier)
    var plays: int = FlashCalcGhostStore.get_play_count(tier)
    var wins: int = FlashCalcGhostStore.get_recent_wins(tier)
    var best: int = FlashCalcGhostStore.get_best_score(tier)
    var is_appropriate: bool = (tier == appropriate)

    var btn := Button.new()
    btn.custom_minimum_size = Vector2(0, 110)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.size_flags_vertical = Control.SIZE_FILL
    btn.disabled = not unlocked
    btn.add_theme_font_size_override("font_size", 26)

    var lines: PackedStringArray = []
    if not unlocked:
        lines.append("🔒 " + tier)
    elif is_appropriate:
        lines.append("⭐ " + tier)
    else:
        lines.append(tier)
    if unlocked:
        if plays == 0:
            lines.append("未挑戦")
        else:
            lines.append("勝率 %d/%d  Best %d" % [wins, plays, best])
    btn.text = "\n".join(lines)
    btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
    btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65, 0.6))
    if is_appropriate and unlocked:
        btn.add_theme_color_override("font_color", Color(1.0, 0.914, 0.659, 1))
    btn.pressed.connect(_on_tier_pressed.bind(tier))
    return btn


func _on_tier_pressed(tier: String) -> void:
    GameManager.on_tier_selected(tier)


func _on_back_pressed() -> void:
    GameManager.on_individual_result_home()
