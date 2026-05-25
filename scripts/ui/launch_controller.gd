## LaunchController
##
## 初期ルーター。アプリ起動時の最初のシーン [code]scenes/main/launch.tscn[/code] にアタッチされる。
## [code]UserConfig.onboarding_completed[/code] を読み、ホームまたはオンボーディングへ振り分ける。
##
## 表示は 2 段階のブランドリビール:
##   Phase 1: Reigal Labs パブリッシャーロゴ (フェードイン → ホールド → フェードアウト)
##   Phase 2: Brain Ghost ゲームロゴ (フェードイン → ホールド → ホーム遷移)
##
## SkipArea を tap すると残りの演出をスキップして即ホームへ遷移。
extends Control

const _REIGAL_FADE_IN_SEC: float = 0.5
const _REIGAL_HOLD_SEC: float = 0.9
const _REIGAL_FADE_OUT_SEC: float = 0.4
const _BG_FADE_IN_SEC: float = 0.6
const _BG_HOLD_SEC: float = 1.2

@onready var _reigal: TextureRect = $ReigalLogo if has_node("ReigalLogo") else null
@onready var _bg_logo: TextureRect = $BrainGhostLogo if has_node("BrainGhostLogo") else null
@onready var _skip_area: Control = $SkipArea if has_node("SkipArea") else null

var _config: UserConfig = null
var _skipped: bool = false


func _ready() -> void:
    print_debug("LaunchController: ready")

    var config_dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.USER_CONFIG)
    _config = UserConfig.from_dict(config_dict) if not config_dict.is_empty() else UserConfig.new()

    if _skip_area != null:
        _skip_area.gui_input.connect(_on_skip_input)

    _play_intro_sequence()


func _play_intro_sequence() -> void:
    # Phase 1: Reigal Labs
    if _reigal != null:
        await _fade_to(_reigal, 1.0, _REIGAL_FADE_IN_SEC)
        if _skipped: return
        await get_tree().create_timer(_REIGAL_HOLD_SEC).timeout
        if _skipped: return
        await _fade_to(_reigal, 0.0, _REIGAL_FADE_OUT_SEC)
        if _skipped: return

    # Phase 2: Brain Ghost
    if _bg_logo != null:
        await _fade_to(_bg_logo, 1.0, _BG_FADE_IN_SEC)
        if _skipped: return
        await get_tree().create_timer(_BG_HOLD_SEC).timeout
        if _skipped: return

    _go_to_next_scene()


func _fade_to(node: CanvasItem, target_alpha: float, duration: float) -> void:
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(node, "modulate:a", target_alpha, duration)
    await tween.finished


func _on_skip_input(event: InputEvent) -> void:
    if _skipped:
        return
    if event is InputEventScreenTouch and event.pressed:
        _skipped = true
        _go_to_next_scene()
    elif event is InputEventMouseButton and event.pressed:
        _skipped = true
        _go_to_next_scene()


func _go_to_next_scene() -> void:
    if _config != null and not _config.onboarding_completed:
        # TODO: オンボーディング画面実装後に切替
        print_debug("LaunchController: onboarding scene not implemented yet. Falling back to home.")
    _go_to_home()


func _go_to_home() -> void:
    var err: int = get_tree().change_scene_to_file("res://scenes/main/home.tscn")
    if err != OK:
        push_error("LaunchController: failed to change scene to home (err=%d)" % err)
