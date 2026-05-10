## LaneShapes
##
## ゴースト7番勝負 (1 レーン正面衝突) のレーン形状ヘルパ。
##
## 各 shape は進行度 t ∈ [0,1] を受け取り、Rect2 に正規化した位置 (x,y) を返す。
## - t=0 → 左端 (x=0, y=center に対する形状依存オフセット)
## - t=0.5 → 中央 GATE 位置
## - t=1 → 右端
##
## 5 種ローテ（chat1 末尾の確定仕様）:
## - "line"       直線
## - "s_curve"    緩い S 字
## - "sine_wave"  サインウェーブ（中央山）
## - "zigzag"     ジグザグ
## - "arc"        弧（上膨らみ）
class_name LaneShapes
extends RefCounted

const SHAPES: Array[String] = ["line", "s_curve", "sine_wave", "zigzag", "arc"]

## ラウンドインデックスから shape をローテーションで決定する。
static func shape_for_round(round_index: int) -> String:
    if SHAPES.is_empty():
        return "line"
    return SHAPES[round_index % SHAPES.size()]

## Rect2 (例: Playfield の rect) と進行度 t から、レーン上の絶対座標 Vector2 を返す。
## [param shape] LaneShapes.SHAPES のいずれか
## [param t] 0.0..1.0 (clamp される)
## [param rect] レーン全体の矩形（左上原点）
static func position_on_lane(shape: String, t: float, rect: Rect2) -> Vector2:
    var clamped_t := clampf(t, 0.0, 1.0)
    var x: float = rect.position.x + clamped_t * rect.size.x
    var center_y: float = rect.position.y + rect.size.y * 0.5
    var amp: float = rect.size.y * 0.32   # 振幅は矩形高さの 32%
    var y: float = center_y

    match shape:
        "line":
            # 直線：常に center
            y = center_y
        "s_curve":
            # 緩い S：t=0 で center-amp*0.6, t=0.5 で center, t=1 で center+amp*0.6
            y = center_y + sin((clamped_t - 0.5) * PI) * amp * 0.6
        "sine_wave":
            # サインウェーブ：t=0/1 で center、t=0.5 で center-amp（中央山）
            # ※ t=0.5 で center に戻る単峰にしないよう、TWO 山構造で GATE は中央 (t=0.5) を通る
            y = center_y - sin(clamped_t * TAU) * amp * 0.5
        "zigzag":
            # ジグザグ：4 セグメントで上下に往復。t=0/0.5/1 で center、間で ±amp*0.7
            var seg: float = clamped_t * 4.0
            var phase: int = clampi(int(seg), 0, 3)
            var f: float = seg - floor(seg)
            var levels := [0.0, -0.7, 0.0, 0.7, 0.0]
            y = center_y + lerpf(levels[phase], levels[phase + 1], f) * amp
        "arc":
            # 上方向の弧：t=0/1 で center、t=0.5 で center-amp*1.4（広い山）
            # GATE 通過点 (t=0.5) は弧の頂点になる
            y = center_y - sin(clamped_t * PI) * amp * 1.4

    return Vector2(x, y)

## レーン全体を polyline でサンプリングして返す。_draw 用。
static func sample_polyline(shape: String, rect: Rect2, samples: int = 64) -> PackedVector2Array:
    var pts := PackedVector2Array()
    if samples < 2:
        samples = 2
    for i in samples:
        var t: float = float(i) / float(samples - 1)
        pts.append(position_on_lane(shape, t, rect))
    return pts
