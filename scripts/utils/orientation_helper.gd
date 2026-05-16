## OrientationHelper
##
## 端末向き + content_scale_size をシーンに合わせて切り替えるヘルパー。
##
## project.godot は viewport_width=720, viewport_height=1280 (縦) で固定されているため、
## 横画面シーン (1280x720 ベース) を表示する時に content_scale_size も切り替えないと
## 画面中央 56% しか見えなくなる。enter_landscape / enter_portrait で
## DisplayServer の向きと get_window().content_scale_size の両方を切替する。
##
## project.godot は `window/handheld/orientation=1` (PORTRAIT) で固定。
## アプリ全体は縦画面を既定とし、landscape にしたいゲームシーンだけが
## 明示的に enter_landscape() を呼ぶ。シーン離脱時は _exit_tree() で
## enter_portrait() を呼んで縦画面に戻すこと。
##
## 使い方:
##   func _ready() -> void:
##       if scene_file_path.ends_with("_landscape.tscn"):
##           OrientationHelper.enter_landscape()
##       # portrait の場合は呼ばなくてもよい（プロジェクト既定）
##
##   func _exit_tree() -> void:
##       OrientationHelper.enter_portrait()
class_name OrientationHelper
extends Object


const PORTRAIT_SIZE := Vector2i(720, 1280)
const LANDSCAPE_SIZE := Vector2i(1280, 720)


## 画面を横向き (landscape) に切り替える。
## - 実機: DisplayServer.screen_set_orientation(LANDSCAPE)
## - 全環境: get_window().content_scale_size を 1280x720 に
static func enter_landscape() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	_apply_content_scale(LANDSCAPE_SIZE)


## 画面を縦向き (portrait) に切り替える。
static func enter_portrait() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_apply_content_scale(PORTRAIT_SIZE)


static func _apply_content_scale(size: Vector2i) -> void:
	# シーンツリーがまだ整っていない初期化フェーズではスキップ
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not main_loop is SceneTree:
		return
	var window := (main_loop as SceneTree).root
	if window == null:
		return
	window.content_scale_size = size
