## AdService
##
## 広告表示を抽象化した Autoload。
## Android では [code]godot-admob-plugin[/code] を呼び出し、それ以外（Web / Desktop）では no-op。
## 広告非表示購入済みユーザーに対してはすべてのメソッドが no-op になる。
##
## MVP スタブ: インターフェースのみ。実 AdMob 連携は Week 4 で実装。
extends Node

func _ready() -> void:
    if Platform.supports_admob():
        _init_admob()

func _init_admob() -> void:
    # TODO: Week 4 で addons/admob を通じて初期化
    print_debug("AdService: AdMob initialization pending (Week 4)")

# --- 公開 API ---

func is_enabled() -> bool:
    return Platform.supports_admob() and not BillingService.is_ad_free()

func show_banner() -> void:
    if not is_enabled():
        return
    # TODO: addons/admob 経由でバナー表示

func hide_banner() -> void:
    if not Platform.supports_admob():
        return
    # TODO: addons/admob 経由でバナー非表示

func show_interstitial() -> void:
    if not is_enabled():
        return
    # TODO: addons/admob 経由でインタースティシャル表示

func show_rewarded(callback: Callable = Callable()) -> void:
    if not is_enabled():
        if callback.is_valid():
            callback.call(false)  # 広告無効時は failure として返す
        return
    # TODO: addons/admob 経由でリワード広告表示
    if callback.is_valid():
        callback.call(false)
