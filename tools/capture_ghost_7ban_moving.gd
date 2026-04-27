## Capture helper — Ghost 7 番勝負 Moving 画面
##
## シーンを起動しタップ→カウントダウン終了→Moving フェーズに遷移した瞬間を
## キャプチャする。ターゲットオーブの円形描画の検証に使う。
extends SceneTree

const OUTPUT_PATH := "res://.steering/20260422-ゴースト7番勝負実装/capture_moving.png"
const SCENE_PATH := "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn"

var _sub_viewport: SubViewport
var _scene_root: Node

func _init() -> void:
    _sub_viewport = SubViewport.new()
    _sub_viewport.size = Vector2i(1280, 720)
    _sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _sub_viewport.handle_input_locally = true
    root.add_child(_sub_viewport)

    var scene_packed: PackedScene = load(SCENE_PATH)
    _scene_root = scene_packed.instantiate()
    _sub_viewport.add_child(_scene_root)

    _run_capture()

func _run_capture() -> void:
    # 初期化完了まで数フレーム待つ
    for i in range(5):
        await process_frame

    # Ready -> Countdown (tap simulation)
    _send_tap()
    # Countdown は 3 カウント × 700ms + フェード 320ms ≒ 2.5秒
    await _wait_sec(2.7)
    # Announce phase に入った直後。Moving に入るまで cfg.pre (1500ms for round 0) 待つ
    await _wait_sec(1.6)
    # Moving phase の途中 (orb が画面中央付近に来る moment) までさらに待つ
    await _wait_sec(0.9)

    var image: Image = _sub_viewport.get_texture().get_image()
    var err: int = image.save_png(OUTPUT_PATH)
    if err == OK:
        print("[capture] saved -> %s" % OUTPUT_PATH)
    else:
        push_error("[capture] failed to save: %d" % err)
    quit(0 if err == OK else 1)

func _wait_sec(sec: float) -> void:
    var target_ms: int = Time.get_ticks_msec() + int(sec * 1000.0)
    while Time.get_ticks_msec() < target_ms:
        await process_frame

func _send_tap() -> void:
    var ev := InputEventMouseButton.new()
    ev.button_index = MOUSE_BUTTON_LEFT
    ev.pressed = true
    ev.position = Vector2(640, 360)
    _sub_viewport.push_input(ev)
