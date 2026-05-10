## GlowOrb
##
## variant-b.jsx Orb 移植：white/ink core → aura → transparent radial
## + 進行方向逆向きに横ぼかし trail。
##
## 使い方:
##   var orb := GlowOrb.new()
##   orb.kind = GlowOrb.Kind.YOU
##   orb.size = Vector2(64, 32)  # trail 含む長辺
##   orb.position = ...
class_name GlowOrb
extends Control

enum Kind { YOU, GHOST }

@export var kind: Kind = Kind.YOU:
    set(v):
        kind = v
        queue_redraw()

@export var fired: bool = false:
    set(v):
        fired = v
        queue_redraw()

## trail を左→右に伸ばすか (true=YOUデフォルト)。GHOST は false で右→左
@export var trail_to_left: bool = false:
    set(v):
        trail_to_left = v
        queue_redraw()

@export var orb_radius: float = 16.0:
    set(v):
        orb_radius = v
        queue_redraw()

@export var trail_length: float = 64.0:
    set(v):
        trail_length = v
        queue_redraw()


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if size == Vector2.ZERO:
        custom_minimum_size = Vector2(orb_radius * 2.0 + trail_length, orb_radius * 2.0)


func _draw() -> void:
    var center: Vector2 = size * 0.5
    var core_color: Color
    var aura_color: Color
    var trail_color: Color
    match kind:
        Kind.YOU:
            core_color = Color(1.0, 1.0, 1.0, 1.0)               # ink100
            aura_color = Color(1.0, 0.914, 0.659, 1.0)            # gold300
            trail_color = Color(0.435, 0.706, 1.0, 0.55)          # cyanGlow
        Kind.GHOST:
            core_color = Color(0.780, 0.824, 0.910, 1.0)          # ink80
            aura_color = Color(0.722, 0.878, 1.0, 0.85)           # cyan300
            trail_color = Color(0.780, 0.824, 0.910, 0.5)
        _:
            core_color = Color.WHITE
            aura_color = Color(0.722, 0.878, 1.0, 0.85)
            trail_color = Color(0.435, 0.706, 1.0, 0.55)

    var alpha_mul: float = 0.3 if (fired and kind == Kind.GHOST) else 1.0

    # trail (16 sample fading)
    var samples: int = 16
    var dir: float = -1.0 if trail_to_left else 1.0
    for i in range(1, samples + 1):
        var f: float = float(i) / float(samples)
        var fall: float = (1.0 - f)
        var alpha: float = trail_color.a * fall * fall * 0.85 * alpha_mul
        if alpha <= 0.0:
            continue
        var p: Vector2 = center + Vector2(-dir * trail_length * f, 0.0)
        var r: float = lerpf(orb_radius * 0.55, 1.0, f)
        var c := trail_color
        c.a = alpha
        draw_circle(p, r, c)

    # halo (multilayer radial)
    for i in 8:
        var r: float = orb_radius * (1.0 - float(i) * 0.08)
        var a: float = aura_color.a * (0.30 - float(i) * 0.035) * alpha_mul
        if a <= 0.0 or r <= 0.5:
            continue
        var c := aura_color
        c.a = a
        draw_circle(center, r, c)

    # aura mid
    var aura_mid := aura_color
    aura_mid.a = 0.85 * alpha_mul
    draw_circle(center, orb_radius * 0.5, aura_mid)

    # core
    var core_c := core_color
    core_c.a = core_c.a * alpha_mul
    draw_circle(center, orb_radius * 0.28, core_c)
