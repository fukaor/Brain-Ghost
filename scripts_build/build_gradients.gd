## build_gradients.gd
##
## ブレインゴースト の UI グラデーションテクスチャを生成する。
## `assets/textures/gradients/` に PNG を保存し、Theme の StyleBoxTexture から参照する。
##
## ウマ娘のような "豪華さ" のベースはグラデーションとハイライト。Godot の StyleBoxFlat
## は単色しか扱えないため、事前生成 PNG + StyleBoxTexture の組み合わせで実現する。
##
## 実行方法:
##     godot --headless --script scripts_build/build_gradients.gd
extends SceneTree

const OUT_DIR := "res://assets/textures/gradients/"

# manifest §2 のカラートークンと同期
const POSITIVE_GOLD := Color(0.980, 0.800, 0.082)
const BG_LIGHT      := Color(0.973, 0.980, 0.988)
const BG_DARK       := Color(0.059, 0.090, 0.165)
const NEUTRAL_LIGHT_GRAY := Color(0.886, 0.910, 0.941)
const ACCENT_BLUE   := Color(0.231, 0.510, 0.965)
const POSITIVE_GREEN := Color(0.133, 0.773, 0.369)

# v2 Animated Intellectual パレット (DESIGN.md 準拠)
const PRIMARY_BLUE := Color(0.0, 0.345, 0.729)        # #0058ba
const PRIMARY_DIM := Color(0.0, 0.302, 0.643)         # #004da4
const PRIMARY_CONTAINER := Color(0.424, 0.624, 1.0)   # #6c9fff
const PRIMARY_FIXED_DIM := Color(0.314, 0.569, 1.0)   # #5091ff
const BACKGROUND_V2 := Color(0.969, 0.961, 1.0)       # #f7f5ff
const SURFACE_CONTAINER_V2 := Color(0.894, 0.906, 1.0)  # #e4e7ff


func _init() -> void:
    # CTA ゴールドグラデ（明るい上端 → 通常ゴールド下端、ハイライトあり）
    _save_vertical_gradient(
        "cta_gold.png",
        [_lighten(POSITIVE_GOLD, 0.12), POSITIVE_GOLD, _darken(POSITIVE_GOLD, 0.88)],
        [0.0, 0.40, 1.0],
        32, 120
    )
    # CTA ゴールド pressed 状態（全体的に暗め）
    _save_vertical_gradient(
        "cta_gold_pressed.png",
        [POSITIVE_GOLD, _darken(POSITIVE_GOLD, 0.85), _darken(POSITIVE_GOLD, 0.75)],
        [0.0, 0.40, 1.0],
        32, 120
    )
    # Hero カード背景グラデ（白 → 淡いクリーム、非常に微妙）
    _save_vertical_gradient(
        "hero_card_bg.png",
        [Color(1, 1, 1, 1), Color(0.998, 0.988, 0.920, 1)],
        [0.0, 1.0],
        32, 200
    )
    # Pill 背景（白背景に微妙な陰影）
    _save_vertical_gradient(
        "pill_neutral.png",
        [Color(1, 1, 1, 1), _darken(BG_LIGHT, 0.98)],
        [0.0, 1.0],
        16, 96
    )
    # Action card 背景（白 → 薄いグレー）
    _save_vertical_gradient(
        "action_card_bg.png",
        [Color(1, 1, 1, 1), Color(0.95, 0.96, 0.98, 1)],
        [0.0, 1.0],
        16, 140
    )
    # カテゴリ帯（アクションカード左端の色帯） — 各カテゴリ 1 枚
    _save_vertical_gradient("accent_gold.png",  [_lighten(POSITIVE_GOLD, 0.05), POSITIVE_GOLD],  [0.0, 1.0], 8, 140)
    _save_vertical_gradient("accent_green.png", [_lighten(POSITIVE_GREEN, 0.05), POSITIVE_GREEN], [0.0, 1.0], 8, 140)
    _save_vertical_gradient("accent_blue.png",  [_lighten(ACCENT_BLUE, 0.05), ACCENT_BLUE],  [0.0, 1.0], 8, 140)
    _save_vertical_gradient("accent_purple.png", [Color(0.58, 0.43, 0.92, 1), Color(0.45, 0.29, 0.79, 1)], [0.0, 1.0], 8, 140)
    # ページ背景（上: 淡いクリーム → 下: BG_LIGHT）
    _save_vertical_gradient(
        "page_bg.png",
        [Color(1.0, 0.988, 0.929, 1), BG_LIGHT, Color(0.945, 0.960, 0.980, 1)],
        [0.0, 0.5, 1.0],
        32, 512
    )

    # ============================================================
    # v2: Animated Intellectual パレット
    # ============================================================

    # Blue CTA (135° 対角グラデ): PRIMARY_BLUE → PRIMARY_CONTAINER
    _save_diagonal_gradient(
        "cta_blue.png",
        [PRIMARY_BLUE, PRIMARY_FIXED_DIM, PRIMARY_CONTAINER],
        [0.0, 0.5, 1.0],
        128, 96,
        135.0
    )
    # Blue CTA pressed (全体を暗く)
    _save_diagonal_gradient(
        "cta_blue_pressed.png",
        [_darken(PRIMARY_BLUE, 0.80), _darken(PRIMARY_FIXED_DIM, 0.85), _darken(PRIMARY_CONTAINER, 0.85)],
        [0.0, 0.5, 1.0],
        128, 96,
        135.0
    )

    # ページ背景 v2 (白〜淡い紫、Animated Intellectual)
    _save_vertical_gradient(
        "page_bg_v2.png",
        [Color(1, 1, 1), BACKGROUND_V2, SURFACE_CONTAINER_V2],
        [0.0, 0.5, 1.0],
        32, 512
    )

    # アビリティ円形アイコン背景 (radial: 明るい中心 → 濃い縁)
    _save_radial_gradient(
        "ability_circle_blue.png",
        PRIMARY_CONTAINER,  # 中心 (明るい)
        PRIMARY_BLUE,       # 縁 (濃い)
        96
    )

    # ガラスパネル用の薄いグラデ (純白 → 薄水色、ほぼ白)
    _save_vertical_gradient(
        "glass_surface.png",
        [Color(1, 1, 1, 0.92), Color(0.98, 0.98, 1.0, 0.88)],
        [0.0, 1.0],
        16, 96
    )

    print("[build_gradients] Done. v1(9) + v2(4) textures written to %s" % OUT_DIR)
    quit(0)


## 対角線方向のグラデーション (DESIGN.md の 135° CTA 用).
## angle_deg は CSS 互換で 0=上方向, 90=右方向, 135=右下方向, 180=下方向
func _save_diagonal_gradient(file_name: String, colors: Array, offsets: Array, width: int, height: int, angle_deg: float) -> void:
    assert(colors.size() == offsets.size())
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    # CSS 角度 → 数学角度 (y を反転)
    var rad: float = deg_to_rad(angle_deg - 90.0)
    var dir := Vector2(cos(rad), sin(rad))
    # 対角の対角線上の距離で正規化
    var max_proj: float = abs(dir.x) * float(width - 1) + abs(dir.y) * float(height - 1)
    for y in range(height):
        for x in range(width):
            # 左上起点で t を計算。負方向に進む成分はオフセットで補正
            var offset_x: float = float(width - 1) if dir.x < 0 else 0.0
            var offset_y: float = float(height - 1) if dir.y < 0 else 0.0
            var proj: float = (float(x) - offset_x) * dir.x + (float(y) - offset_y) * dir.y
            var t: float = clampf(proj / max_proj, 0.0, 1.0)
            img.set_pixel(x, y, _sample_gradient(colors, offsets, t))
    var abs_path := OUT_DIR + file_name
    var err := img.save_png(abs_path)
    if err != OK:
        push_error("[build_gradients] Failed to save %s: err=%d" % [abs_path, err])
    else:
        print("[build_gradients] Saved %s (%dx%d diagonal %.0f°)" % [abs_path, width, height, angle_deg])


## 放射状グラデーション (アビリティ円形アイコン用).
## circle_only=true で円の外側を透明にする (円形 bake)
func _save_radial_gradient(file_name: String, inner: Color, outer: Color, size: int, circle_only: bool = true) -> void:
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var center := Vector2(float(size) * 0.5, float(size) * 0.5)
    var max_dist: float = float(size) * 0.5
    for y in range(size):
        for x in range(size):
            var d: float = (Vector2(float(x), float(y)) - center).length()
            if circle_only and d > max_dist:
                img.set_pixel(x, y, Color(0, 0, 0, 0))
                continue
            var t: float = clampf(d / max_dist, 0.0, 1.0)
            var c: Color = inner.lerp(outer, t)
            img.set_pixel(x, y, c)
    var abs_path := OUT_DIR + file_name
    var err := img.save_png(abs_path)
    if err != OK:
        push_error("[build_gradients] Failed to save %s: err=%d" % [abs_path, err])
    else:
        print("[build_gradients] Saved %s (%dx%d radial)" % [abs_path, size, size])


## 縦方向グラデーション PNG を生成して保存する。
## colors と offsets は同じ長さの配列（0.0〜1.0 の stop 位置）。
func _save_vertical_gradient(file_name: String, colors: Array, offsets: Array, width: int, height: int) -> void:
    assert(colors.size() == offsets.size(), "colors と offsets は同じ長さである必要がある")
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for y in range(height):
        var t := float(y) / float(height - 1)
        var col := _sample_gradient(colors, offsets, t)
        for x in range(width):
            img.set_pixel(x, y, col)
    var abs_path := OUT_DIR + file_name
    var err := img.save_png(abs_path)
    if err != OK:
        push_error("[build_gradients] Failed to save %s: err=%d" % [abs_path, err])
    else:
        print("[build_gradients] Saved %s (%dx%d)" % [abs_path, width, height])


func _sample_gradient(colors: Array, offsets: Array, t: float) -> Color:
    if t <= offsets[0]:
        return colors[0]
    if t >= offsets[-1]:
        return colors[-1]
    for i in range(offsets.size() - 1):
        var a_off: float = offsets[i]
        var b_off: float = offsets[i + 1]
        if t >= a_off and t <= b_off:
            var sub_t := (t - a_off) / (b_off - a_off)
            return (colors[i] as Color).lerp(colors[i + 1] as Color, sub_t)
    return colors[-1]


func _darken(c: Color, factor: float) -> Color:
    var r := Color.from_hsv(c.h, c.s, c.v * factor)
    r.a = c.a
    return r


func _lighten(c: Color, amount: float) -> Color:
    var r := Color.from_hsv(c.h, max(0.0, c.s - amount * 0.5), min(1.0, c.v + amount))
    r.a = c.a
    return r
