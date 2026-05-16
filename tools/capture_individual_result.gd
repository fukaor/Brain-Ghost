## Capture helper — individual_result.tscn (リザルトイメージ準拠リデザイン後)
##
## 実行例:
##   CAPTURE_CASE=perfect_win godot --path /workspace --script tools/capture_individual_result.gd
##   CAPTURE_CASE=nice_try    godot --path /workspace --script tools/capture_individual_result.gd
##   CAPTURE_CASE=new_best    godot --path /workspace --script tools/capture_individual_result.gd
##   CAPTURE_CASE=improved    godot --path /workspace --script tools/capture_individual_result.gd
##
## 環境変数 CAPTURE_CASE で 4 ケースを切替。デフォルトは perfect_win。
extends SceneTree

const SCENE_PATH := "res://scenes/ui/individual_result.tscn"
const OUTPUT_DIR := "res://.steering/20260516-リザルト画面YOUGHOSTラベルとボタン統一/captures"
const WAIT_FRAMES := 30

var _sub_viewport: SubViewport

func _init() -> void:
	var case_name := OS.get_environment("CAPTURE_CASE")
	if case_name == "":
		case_name = "perfect_win"

	# 出力先ディレクトリを作成
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(720, 1280)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.handle_input_locally = true
	root.add_child(_sub_viewport)

	var scene_packed: PackedScene = load(SCENE_PATH)
	var scene: Node = scene_packed.instantiate()
	_sub_viewport.add_child(scene)

	_capture_after_frames(WAIT_FRAMES, case_name)


func _capture_after_frames(frames: int, case_name: String) -> void:
	for i in range(frames):
		await process_frame
	var image: Image = _sub_viewport.get_texture().get_image()
	var output_path := "%s/individual_%s.png" % [OUTPUT_DIR, case_name]
	var err: int = image.save_png(output_path)
	if err == OK:
		print("[capture] saved -> %s" % output_path)
	else:
		push_error("[capture] failed: %d" % err)
	quit(0 if err == OK else 1)
