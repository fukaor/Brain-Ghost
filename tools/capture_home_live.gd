## capture_home_live.gd — home.tscn を「通常起動」（autoload有効）で動かし、
## 実データ束縛＋ランタイムエラー有無を検証してスクリーンショットを保存する。
##
## 使い方（--script ではなくシーン起動。これで autoload が登録される）:
##   xvfb-run -a godot --rendering-driver opengl3 --path . \
##       res://tools/capture_home_live.tscn -- <out_png>
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "/tmp/home_live.png"

	var win := get_window()
	win.size = Vector2i(720, 1280)

	var ps: PackedScene = load("res://scenes/main/home.tscn")
	if ps == null:
		printerr("[capture_home_live] failed to load home.tscn")
		get_tree().quit(1)
		return
	var home := ps.instantiate()
	# _ready 中は root が children セットアップ中で add_child が弾かれるため遅延追加。
	get_tree().root.add_child.call_deferred(home)

	# autoload からの実データで _apply_data が走る。数フレーム待って安定させる。
	for i in range(90):
		await get_tree().process_frame

	var img: Image = get_viewport().get_texture().get_image()
	var err: int = img.save_png(out_path)
	if err == OK:
		print("[capture_home_live] saved -> %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	else:
		printerr("[capture_home_live] save failed err=%d" % err)
	get_tree().quit(0)
