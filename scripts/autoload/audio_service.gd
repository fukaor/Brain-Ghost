## AudioService
##
## BGM と効果音の再生・管理を担う Autoload。
## [b]Web 版の音声自動再生制限の回避[/b]: 最初のタップ入力まで AudioServer をミュートしておき、
## 初回タップで解除する。
##
## MVP スタブ: 初期化枠組みのみ。実際の BGM/SE 再生は Week 2 以降で実装。
extends Node

var _initialized: bool = false
var _bgm_enabled: bool = true
var _se_enabled: bool = true

func _ready() -> void:
    # Web 版では初回タップまで音声を抑制する（自動再生制限回避）
    if Platform.is_web():
        var master_idx := AudioServer.get_bus_index("Master")
        if master_idx >= 0:
            AudioServer.set_bus_mute(master_idx, true)

func _unhandled_input(event: InputEvent) -> void:
    if _initialized:
        return
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        if event.is_pressed():
            _initialize()

func _initialize() -> void:
    _initialized = true
    var master_idx := AudioServer.get_bus_index("Master")
    if master_idx >= 0:
        AudioServer.set_bus_mute(master_idx, false)
    print_debug("AudioService: initialized on first user input")

# --- BGM / SE オンオフ（UserConfig から設定される想定） ---

func set_bgm_enabled(enabled: bool) -> void:
    _bgm_enabled = enabled

func set_se_enabled(enabled: bool) -> void:
    _se_enabled = enabled

func is_bgm_enabled() -> bool:
    return _bgm_enabled

func is_se_enabled() -> bool:
    return _se_enabled

# --- スタブ: 実再生は Week 2 以降 ---

func play_bgm(_bgm_name: String) -> void:
    if not _bgm_enabled:
        return
    # TODO: Week 2 で実装

func play_se(_se_name: String) -> void:
    if not _se_enabled:
        return
    # TODO: Week 2 で実装

func stop_bgm() -> void:
    pass
