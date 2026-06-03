## snap_game_list_card.gd — GameListCard の4状態を1枚に並べてキャプチャする検証ツール。
##
## 使い方:
##   xvfb-run -a godot --rendering-driver opengl3 --path . \
##       --script tools/snap_game_list_card.gd -- <out_png>
##
## 通常 / NEW / ロック / 選択中 を横並びで描画し、card_states.png と目視比較する。
extends SceneTree

const CARD := preload("res://scenes/ui/components/game_list_card.tscn")

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "/tmp/game_list_card.png"

	var sv := SubViewport.new()
	sv.size = Vector2i(740, 260)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)

	var bg := ColorRect.new()
	bg.color = Color("E9E2D5")  # 一覧画面と同じ和紙地よりやや濃いめ
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sv.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	sv.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	row.add_child(_make("ghost_7ban_shobu", "ゴースト7番勝負", "反射力", "bolt", "ベスト 1,240", false, false, false))
	row.add_child(_make("number_search", "数字さがし", "観察力", "search", "", false, true, false))
	row.add_child(_make("card_match", "神経衰弱", "判断力", "style", "", true, false, false))
	row.add_child(_make("stroop", "色文字ストループ", "注意力", "palette", "ベスト 980", false, false, true))

	for i in range(60):
		await process_frame

	var img: Image = sv.get_texture().get_image()
	var err: int = img.save_png(out_path)
	if err == OK:
		print("[snap_game_list_card] saved -> %s" % out_path)
	else:
		printerr("[snap_game_list_card] save failed err=%d" % err)
	quit(0)


func _make(id: String, nm: String, ability: String, icon: String, best: String,
		locked: bool, is_new: bool, selected: bool) -> Control:
	var c := CARD.instantiate()
	c.game_id = id
	c.game_name = nm
	c.ability_label = ability
	c.icon_text = icon
	c.best_score = best
	c.is_locked = locked
	c.is_new = is_new
	c.is_selected = selected
	return c
