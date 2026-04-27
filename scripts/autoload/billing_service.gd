## BillingService
##
## Google Play Billing の広告非表示買い切り課金を抽象化した Autoload。
## Web / Desktop では常に [code]false[/code] を返す no-op。
##
## [b]信頼源:[/b] ローカルキャッシュ（UserConfig.has_purchased_ad_free）ではなく、
## Play Billing の [code]queryPurchasesAsync()[/code] を信頼源とする。
## アプリ起動時・フォアグラウンド復帰時・広告表示直前に毎回照合する（docs/architecture.md）。
##
## MVP スタブ: インターフェースのみ。実 Play Billing 連携は Week 4 で実装。
extends Node

signal purchase_state_changed(is_ad_free: bool)

var _cached_is_ad_free: bool = false

func _ready() -> void:
    if Platform.supports_billing():
        _init_billing()

func _init_billing() -> void:
    # TODO: Week 4 で Google Play Billing を初期化し、queryPurchasesAsync() を呼ぶ
    print_debug("BillingService: Play Billing initialization pending (Week 4)")

# --- 公開 API ---

func is_ad_free() -> bool:
    if not Platform.supports_billing():
        return false
    return _cached_is_ad_free

func purchase_ad_free() -> void:
    if not Platform.supports_billing():
        push_warning("BillingService: purchase_ad_free called on unsupported platform")
        return
    # TODO: Week 4 で購入フロー起動

func restore_purchases() -> void:
    if not Platform.supports_billing():
        return
    # TODO: Week 4 で queryPurchasesAsync() を呼び、キャッシュを更新
