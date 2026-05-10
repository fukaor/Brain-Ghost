## Snap helper — 全画面キャプチャ (Midnight Cat 改修後)
##
## 実行: xvfb-run -a godot --rendering-driver opengl3 --path . --script tools/snap_all.gd
extends SceneTree

const OUT_DIR := "res://.steering/20260502-MidnightCatリデザイン/captures"

# (label, path, viewport_size, wait_frames, taps)
const TARGETS: Array = [
    {"label": "home", "path": "res://scenes/main/home.tscn", "size": Vector2i(720, 1280), "frames": 90, "taps": []},
    {"label": "rule_explain_ghost_7ban_shobu", "path": "res://scenes/ui/rule_explain.tscn", "size": Vector2i(720, 1280), "frames": 90, "taps": []},
    {"label": "rule_explain_flash_calc", "path": "res://scenes/ui/rule_explain.tscn", "size": Vector2i(720, 1280), "frames": 90, "taps": [], "rule": "flash_calc"},
    {"label": "rule_explain_sequence_memory", "path": "res://scenes/ui/rule_explain.tscn", "size": Vector2i(720, 1280), "frames": 90, "taps": [], "rule": "sequence_memory"},
    {"label": "ghost_7ban_shobu_ready", "path": "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn", "size": Vector2i(1280, 720), "frames": 90, "taps": []},
    {"label": "ghost_7ban_shobu_play", "path": "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn", "size": Vector2i(1280, 720), "frames": 90, "taps": [{"after_sec": 0.4}], "play_wait_sec": 1.6},
    {"label": "ghost_7ban_shobu_result", "path": "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn", "size": Vector2i(1280, 720), "frames": 90, "taps": [{"after_sec": 0.4}, {"after_sec": 1.7 + 1.4}], "play_wait_sec": 0.5},
]

var _sub_viewport: SubViewport
var _idx: int = 0


func _init() -> void:
    _sub_viewport = SubViewport.new()
    _sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _sub_viewport.transparent_bg = false
    _sub_viewport.handle_input_locally = true
    root.add_child(_sub_viewport)
    _run_all()


func _run_all() -> void:
    for target in TARGETS:
        await _snap(target)
    quit(0)


func _snap(target: Dictionary) -> void:
    _sub_viewport.size = Vector2i(target["size"])

    # クリア前回のシーン
    for c in _sub_viewport.get_children():
        c.queue_free()
    await process_frame

    var ps: PackedScene = load(String(target["path"]))
    var scene: Node = ps.instantiate()
    _sub_viewport.add_child(scene)

    # rule_explain の場合は set_rule を呼ぶ
    if target.has("rule") and scene.has_method("set_rule"):
        await process_frame
        scene.set_rule(String(target["rule"]))

    var frames: int = int(target.get("frames", 60))
    for i in range(frames):
        await process_frame

    # タップ送信
    if target.has("taps"):
        for tap in target["taps"]:
            var sec: float = float(tap.get("after_sec", 0.0))
            if sec > 0.0:
                await _wait_sec(sec)
            _send_tap()
        if target.has("play_wait_sec"):
            await _wait_sec(float(target["play_wait_sec"]))

    var image: Image = _sub_viewport.get_texture().get_image()
    var out_path: String = "%s/%s.png" % [OUT_DIR, target["label"]]
    var err: int = image.save_png(out_path)
    if err == OK:
        print("[snap] saved -> %s" % out_path)
    else:
        printerr("[snap] failed: %s err=%d" % [out_path, err])


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
