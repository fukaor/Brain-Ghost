## JuicyBounce
##
## 任意の Button にタップ即時バウンス + ハプティック振動を後付けする composition 型コンポーネント。
##
## 使い方:
##   既存 Button の子として JuicyBounce ノードを 1 つ配置。`target_button` 未設定なら親 Button を自動取得。
##
## 設計判断:
##   `extends Button` 継承型は採用しない。既存 `CardComponent extends Button` 等と多重継承不可のため。
extends Node

const BOUNCE_DURATION: float = 0.24
const HAPTIC_MS: int = 20

@export var target_button: Button


func _ready() -> void:
    var btn: Button = target_button if target_button != null else (get_parent() as Button)
    if btn == null:
        push_warning("[JuicyBounce] target_button not set and parent is not Button. No-op.")
        return
    # pivot_offset はレイアウト確定後に設定する。
    # _ready() 時点では btn.size が Vector2.ZERO の場合があり、(0,0) を中心に拡縮すると歪む。
    btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
    if btn.size != Vector2.ZERO:
        btn.pivot_offset = btn.size / 2.0
    btn.pressed.connect(_on_pressed.bind(btn))


func _on_pressed(btn: Button) -> void:
    var t := create_tween()
    t.tween_property(btn, "scale", Vector2(0.95, 0.95), BOUNCE_DURATION * 0.25).set_trans(Tween.TRANS_SINE)
    t.tween_property(btn, "scale", Vector2(1.05, 1.05), BOUNCE_DURATION * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    t.tween_property(btn, "scale", Vector2(1.0, 1.0), BOUNCE_DURATION * 0.35).set_trans(Tween.TRANS_SINE)
    var platform_node: Node = Engine.get_main_loop().root.get_node_or_null("Platform")
    if platform_node != null and platform_node.has_method("supports_haptics") and platform_node.supports_haptics():
        Input.vibrate_handheld(HAPTIC_MS)
