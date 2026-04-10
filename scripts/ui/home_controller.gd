## HomeController
##
## ホーム画面のコントローラ。
##
## FR-07（2回目以降の日常フロー）の UI 要素と、ユーザー入力（タップ）を仲介する。
## 本フェーズ（20260411-mobile-ui-foundation）ではダミーデータで見た目を固定し、
## 実際のデータ連動・シーン遷移は後続ステアリングで実装する。
##
## [b]設計原則:[/b]
## - 色・フォント・サイズに触れるコードを一切書かない（Theme に一任）
## - `modulate` や `add_theme_*_override` は禁止（manifest.md §9 参照）
## - Platform Autoload 経由でプラットフォーム分岐（OS.get_name() 直接呼び出し禁止）
##
## [b]ゴースト (生霊) 連携:[/b]
## GhostCharacter コンポーネントに精度とセリフを渡すことで、ユーザの状態が視覚化される。
## 詳細は `memory/project_ghost_character.md` および `scripts/ui/ghost_character.gd` を参照。
extends Control

@onready var _ghost: GhostCharacter = $SafeAreaMargin/MainColumn/GhostCharacter

@onready var _streak_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/StreakPill/StreakHBox/StreakLabel
@onready var _brain_age_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/BrainAgePill/BrainAgeHBox/BrainAgeLabel
@onready var _precision_label: Label = $SafeAreaMargin/MainColumn/TopHudRow/PrecisionPill/PrecisionHBox/PrecisionLabel

@onready var _start_button: Button = $SafeAreaMargin/MainColumn/HeroSection/HeroVBox/StartButton

@onready var _home_tab: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavHBox/HomeTabButton
@onready var _calendar_tab: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavHBox/CalendarTabButton
@onready var _settings_tab: Button = $SafeAreaMargin/MainColumn/BottomNavBar/NavHBox/SettingsTabButton

@onready var _ad_banner_area: MarginContainer = $AdBannerArea


func _ready() -> void:
    _apply_placeholder_data()
    _wire_signals()
    _configure_platform_visibility()
    print_debug("HomeController: ready")


## ダミーデータで UI を埋める。DataStore の実データ連動は後続タスク。
func _apply_placeholder_data() -> void:
    # HUD ピルのダミー値
    _streak_label.text = "5 日"
    _brain_age_label.text = "28 歳"
    _precision_label.text = "67 %"

    # ゴースト (生霊) への状態反映
    # 精度 67% → ゴーストの不透明度 ~0.75 (やや濃いめに現出)
    _ghost.set_accuracy(0.67)
    _ghost.set_brain_age(28)  # v1.0 no-op、v1.1 で見た目年齢反映
    _ghost.set_streak(5)       # v1.0 no-op、v1.1 でオーラ反映
    _ghost.set_dialogue("おかえり！5 日連続すごいね。\n前回スコアは 3200 点だったよ。\n今日もチャレンジする？")


## ボタンシグナルを接続する。遷移処理は次ステアリングで実装するので、現段階では print のみ。
func _wire_signals() -> void:
    _start_button.pressed.connect(_on_start_button_pressed)
    _home_tab.pressed.connect(func(): print("[Home] HomeTab pressed"))
    _calendar_tab.pressed.connect(func(): print("[Home] CalendarTab pressed"))
    _settings_tab.pressed.connect(func(): print("[Home] SettingsTab pressed"))


## プラットフォーム分岐。広告バナーは Android 版でのみ表示する。
## Platform Autoload が未登録の場合は安全側（非表示）に倒す。
func _configure_platform_visibility() -> void:
    var supports_ads := false
    if Engine.has_singleton("Platform"):
        var platform = Engine.get_singleton("Platform")
        if platform.has_method("supports_admob"):
            supports_ads = platform.supports_admob()
    _ad_banner_area.visible = supports_ads


func _on_start_button_pressed() -> void:
    # ゴーストのセリフを更新して体験の連続性を出す
    _ghost.set_dialogue("よーし！一緒にがんばろう！")
    # Week 1 では反射タップ単体起動。デイリーチャレンジ統合は次タスク
    var gm := get_node_or_null("/root/GameManager")
    if gm != null and gm.has_method("start_reflex_tap"):
        gm.start_reflex_tap("free")
    else:
        push_warning("[Home] GameManager.start_reflex_tap not found")
