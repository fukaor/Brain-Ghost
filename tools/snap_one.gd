## snap_one.gd — 任意シーンを1枚キャプチャする汎用ツール（視覚検証ループ用）
##
## 使い方:
##   xvfb-run -a godot --rendering-driver opengl3 --path . \
##       --script tools/snap_one.gd -- <scene_path> <out_png> [width] [height] [frames] [bg_hex]
##
## 例:
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script tools/snap_one.gd -- \
##       res://scenes/ui/components/brain_age_card.tscn /tmp/brain_age_card.png 360 200 60 F5F0E8
##
## bg_hex を渡すと、その色（例: 和紙色 F5F0E8）の背景を最背面に敷いてから撮影する。
## コンポーネント単体を和紙地の上で確認したい場合に使う。
##
## 注意:
## - `--script` 実行では autoload（DataStore 等）が登録されないため、
##   autoload に依存するコントローラはコンパイルできない。
##   コンポーネントは autoload 非依存に設計してあるため単体キャプチャ可能。
## - 画面（autoload 依存）の忠実キャプチャは static レイアウト確認に留まる。
extends SceneTree

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("[snap_one] usage: -- <scene_path> <out_png> [width] [height] [frames]")
		quit(1)
		return

	var scene_path: String = args[0]
	var out_path: String = args[1]
	var width: int = int(args[2]) if args.size() > 2 else 360
	var height: int = int(args[3]) if args.size() > 3 else 640
	var frames: int = int(args[4]) if args.size() > 4 else 60

	var sv := SubViewport.new()
	sv.size = Vector2i(width, height)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false
	root.add_child(sv)

	var bg_hex: String = String(args[5]) if args.size() > 5 else ""
	var component_mode: bool = bg_hex != ""

	# 任意の背景色（和紙地など）を最背面に敷く
	if component_mode:
		var bg := ColorRect.new()
		bg.color = Color(bg_hex)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sv.add_child(bg)

	var ps: PackedScene = load(scene_path)
	if ps == null:
		printerr("[snap_one] failed to load scene: %s" % scene_path)
		quit(1)
		return
	var instance: Node = ps.instantiate()

	if component_mode:
		# コンポーネントプレビュー: ホームと同じ「余白 + 縦並び（横stretch・上寄せ）」文脈で配置。
		# Container 駆動でサイズが決まるため、区切り線=細線・カード=横いっぱい、と正しく見える。
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "top", "right", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 16)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)
		vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		margin.add_child(vbox)
		if instance is Control:
			(instance as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(instance)
		sv.add_child(margin)
	else:
		# 全画面モード: シーンをそのまま配置（home 等の Control ルートは自前で full_rect）
		sv.add_child(instance)

	for i in range(frames):
		await process_frame

	var img: Image = sv.get_texture().get_image()
	var err: int = img.save_png(out_path)
	if err == OK:
		print("[snap_one] saved -> %s (%dx%d)" % [out_path, width, height])
	else:
		printerr("[snap_one] save failed err=%d -> %s" % [err, out_path])
	quit(0)
