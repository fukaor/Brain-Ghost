## HeadlineSerif
##
## variant-b.jsx の rb-headline / rb-slam キーフレーム移植：
## scale 1.4 + letter-spacing 0.4em + opacity 0 → scale 1.0 letter-spacing 0.08em opacity 1
##
## 使い方:
##   var head := HeadlineSerif.new()
##   head.text = "PERFECT"
##   add_child(head)
##   head.play()
class_name HeadlineSerif
extends Control

const SERIF_FONT_PATH: String = "res://assets/fonts/NotoSerifJP-Bold.otf"
const ANIM_DURATION_MS: int = 480

@export var text: String = "PERFECT":
    set(v):
        text = v
        queue_redraw()

@export var font_size_px: int = 64:
    set(v):
        font_size_px = v
        queue_redraw()

@export var color: Color = Color(1.0, 0.914, 0.659, 1.0)  # gold300
@export var glow_color: Color = Color(0.961, 0.780, 0.416, 0.6)  # goldGlow
@export var auto_play: bool = false

var _serif: Font
var _start_ms: int = -1


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if ResourceLoader.exists(SERIF_FONT_PATH):
        _serif = load(SERIF_FONT_PATH)
    if auto_play:
        play()


func play() -> void:
    _start_ms = Time.get_ticks_msec()
    set_process(true)
    queue_redraw()


func _process(_delta: float) -> void:
    if _start_ms < 0:
        return
    var age: int = Time.get_ticks_msec() - _start_ms
    if age >= ANIM_DURATION_MS + 200:
        set_process(false)
    queue_redraw()


func _draw() -> void:
    if text.is_empty():
        return
    var f: Font = _serif if _serif != null else get_theme_default_font()
    if f == null:
        return
    var phase: float = 1.0
    if _start_ms >= 0:
        var age: int = Time.get_ticks_msec() - _start_ms
        phase = clampf(float(age) / float(ANIM_DURATION_MS), 0.0, 1.0)
    var ease: float = 1.0 - pow(1.0 - phase, 3.0)
    var scale: float = lerpf(1.4, 1.0, ease)
    var alpha: float
    if phase < 0.5:
        alpha = lerpf(0.0, 1.0, phase / 0.5)
    else:
        alpha = 1.0
    var spacing: float = lerpf(0.4, 0.08, ease)  # em equiv

    var size_px: int = int(float(font_size_px) * scale)
    var letter_extra: float = float(size_px) * spacing

    # measure total width with extra letter-spacing
    var total_w: float = 0.0
    var glyphs: Array = []
    for i in text.length():
        var ch: String = text.substr(i, 1)
        var w: float = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
        glyphs.append({"ch": ch, "w": w})
        total_w += w
        if i < text.length() - 1:
            total_w += letter_extra

    var center_x: float = size.x * 0.5
    var center_y: float = size.y * 0.5
    var x: float = center_x - total_w * 0.5
    var y: float = center_y + float(size_px) * 0.32

    var glow_alpha: float = alpha * 0.9
    for g in glyphs:
        var ch: String = g["ch"]
        var w: float = g["w"]
        # glow
        for k in 4:
            var pad: float = 1.0 + float(k) * 4.0
            var c := glow_color
            c.a = glow_color.a * glow_alpha * (0.5 - float(k) * 0.10)
            if c.a > 0.0:
                draw_string(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, c)
        # main
        var main_c := color
        main_c.a = alpha
        draw_string(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, main_c)
        x += w + letter_extra
