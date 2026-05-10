extends SceneTree

const OUTPUT_PATH := "res://.steering/20260502-MidnightCatリデザイン/captures/ghost_7ban_shobu_result.png"
const SCENE_PATH := "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn"

var _sub_viewport: SubViewport

func _init() -> void:
    _sub_viewport = SubViewport.new()
    _sub_viewport.size = Vector2i(1280, 720)
    _sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _sub_viewport.transparent_bg = false
    _sub_viewport.handle_input_locally = true
    root.add_child(_sub_viewport)

    var ps: PackedScene = load(SCENE_PATH)
    _sub_viewport.add_child(ps.instantiate())
    _run()

func _run() -> void:
    for i in range(60):
        await process_frame
    # Tap to start
    _send_tap()
    # Wait through READY/START to enter moving (about 900ms)
    await _wait_sec(0.95)
    # Tap when orb is near center (move 2200ms / 2 = 1100ms into moving)
    await _wait_sec(1.1)
    _send_tap()
    # Result phase — capture 0.55s in (rings + residue both well visible)
    await _wait_sec(0.55)

    var image: Image = _sub_viewport.get_texture().get_image()
    var err: int = image.save_png(OUTPUT_PATH)
    print("[snap] %s err=%d" % [OUTPUT_PATH, err])
    quit(0 if err == OK else 1)


func _wait_sec(sec: float) -> void:
    var until: int = Time.get_ticks_msec() + int(sec * 1000.0)
    while Time.get_ticks_msec() < until:
        await process_frame


func _send_tap() -> void:
    var ev := InputEventMouseButton.new()
    ev.button_index = MOUSE_BUTTON_LEFT
    ev.pressed = true
    ev.position = Vector2(_sub_viewport.size) * 0.5
    _sub_viewport.push_input(ev)
    var ev2 := InputEventMouseButton.new()
    ev2.button_index = MOUSE_BUTTON_LEFT
    ev2.pressed = false
    ev2.position = ev.position
    _sub_viewport.push_input(ev2)
