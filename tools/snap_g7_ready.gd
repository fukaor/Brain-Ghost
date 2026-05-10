extends SceneTree

const OUTPUT_PATH := "res://.steering/20260502-MidnightCatリデザイン/captures/ghost_7ban_shobu_ready.png"
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
    _capture_after_frames(70)

func _capture_after_frames(frames: int) -> void:
    for i in range(frames):
        await process_frame
    var image: Image = _sub_viewport.get_texture().get_image()
    var err: int = image.save_png(OUTPUT_PATH)
    print("[snap] %s err=%d" % [OUTPUT_PATH, err])
    quit(0 if err == OK else 1)
