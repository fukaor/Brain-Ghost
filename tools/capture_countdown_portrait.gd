## Capture helper — countdown.tscn (縦版リデザイン後)
##
## 実行: godot --path /workspace --script tools/capture_countdown_portrait.gd
extends SceneTree

const OUTPUT_PATH := "res://.steering/20260512-ゴースト7番勝負カウントダウン統一/capture_countdown_portrait.png"
const SCENE_PATH := "res://scenes/ui/countdown.tscn"
const WAIT_FRAMES := 30

var _sub_viewport: SubViewport

func _init() -> void:
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(720, 1280)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.handle_input_locally = true
	root.add_child(_sub_viewport)
	var scene_packed: PackedScene = load(SCENE_PATH)
	var scene: Node = scene_packed.instantiate()
	_sub_viewport.add_child(scene)
	# Timer/Tween を凍結してシーン遷移を防ぐ (キャプチャ専用)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	_capture_after_frames(WAIT_FRAMES)

func _capture_after_frames(frames: int) -> void:
	for i in range(frames):
		await process_frame
	var image: Image = _sub_viewport.get_texture().get_image()
	var err: int = image.save_png(OUTPUT_PATH)
	if err == OK:
		print("[capture] saved -> %s" % OUTPUT_PATH)
	else:
		push_error("[capture] failed: %d" % err)
	quit(0 if err == OK else 1)
