## LaunchController
##
## 初期ルーター。アプリ起動時の最初のシーン [code]scenes/main/launch.tscn[/code] にアタッチされる。
## [code]UserConfig.onboarding_completed[/code] を読み、ホームまたはオンボーディングへ振り分ける。
##
## MVP スタブ: ホーム画面への遷移のみ実装（オンボーディング画面は未作成）。
extends Control

@onready var _label: Label = $VBoxContainer/TitleLabel if has_node("VBoxContainer/TitleLabel") else null

func _ready() -> void:
    print_debug("LaunchController: ready")

    # UserConfig の読込
    var config_dict: Dictionary = DataStore.load_dict(DataStore.StoreKey.USER_CONFIG)
    var config: UserConfig = UserConfig.from_dict(config_dict) if not config_dict.is_empty() else UserConfig.new()

    # 簡易スプラッシュ（2秒後に遷移）
    await get_tree().create_timer(2.0).timeout
    _route_to_next_scene(config)

func _route_to_next_scene(config: UserConfig) -> void:
    if not config.onboarding_completed:
        # TODO: Week 1-3 で scenes/main/onboarding.tscn 実装後に以下を有効化:
        #   var err := get_tree().change_scene_to_file("res://scenes/main/onboarding.tscn")
        #   if err != OK: push_error(...)
        #   return
        # 現状はオンボーディングシーンが未作成のため、暫定的にホームへ遷移する
        print_debug("LaunchController: onboarding scene not implemented yet. Falling back to home.")
        _go_to_home()
        return

    # onboarding_completed == true の通常パス
    _go_to_home()

func _go_to_home() -> void:
    var err: int = get_tree().change_scene_to_file("res://scenes/main/home.tscn")
    if err != OK:
        push_error("LaunchController: failed to change scene to home (err=%d)" % err)
