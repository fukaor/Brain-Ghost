## Capture helper — Ghost 7 番勝負 Ready 画面
##
## ghost_7ban_shobu.tscn を起動し、Ready フェーズの画面を PNG に保存する。
## 変更後のUIがモックアップと視覚的に一致するか検証するために使う。
##
## 実行:
##   godot --path /workspace --script tools/capture_ghost_7ban_ready.gd
extends SceneTree

const OUTPUT_PATH := "res://.steering/20260422-ゴースト7番勝負実装/capture_ready.png"
const SCENE_PATH := "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn"
## 起動後キャプチャまでの待機フレーム数（Tween初期化等を待つ）
const WAIT_FRAMES := 60

var _sub_viewport: SubViewport

func _init() -> void:
    # project.godot は Portrait (720x1280) だが本ゲームは Landscape 1280x720 用なので
    # SubViewport を明示サイズで作ってそこにシーンを入れ、そこからキャプチャする。
    _sub_viewport = SubViewport.new()
    _sub_viewport.size = Vector2i(1280, 720)
    _sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _sub_viewport.transparent_bg = false
    _sub_viewport.handle_input_locally = true
    root.add_child(_sub_viewport)

    var scene_packed: PackedScene = load(SCENE_PATH)
    var scene: Node = scene_packed.instantiate()
    _sub_viewport.add_child(scene)

    _capture_after_frames(WAIT_FRAMES)

func _capture_after_frames(frames: int) -> void:
    for i in range(frames):
        await process_frame

    var image: Image = _sub_viewport.get_texture().get_image()
    var err: int = image.save_png(OUTPUT_PATH)
    if err == OK:
        print("[capture] saved -> %s" % OUTPUT_PATH)
    else:
        push_error("[capture] failed to save: %d" % err)
    quit(0 if err == OK else 1)
