## SumiDivider — 墨セクション区切り線（コンポーネント 2-7）
##
## ベース: ColorRect。和紙地に薄墨の細線を敷く。
## 汚染パーツ divider_*.png は使わず、塗りで表現する（README 方針）。
## 将来クリーンな divider_thick.png 等が用意できたら texture_override で差し替え可能。
@tool
class_name SumiDivider
extends ColorRect

## 線の太さ(px)。custom_minimum_size.y に反映。
@export var thickness: float = 2.0:
	set(value):
		thickness = value
		_apply()
## 線の色（既定: 薄墨）。
@export var divider_color: Color = SumiColors.SUMI_LIGHT:
	set(value):
		divider_color = value
		_apply()
## 線の不透明度。
@export_range(0.0, 1.0, 0.01) var divider_alpha: float = 0.3:
	set(value):
		divider_alpha = value
		_apply()
## 将来 divider_thick.png 等に差し替えるためのフック（設定時は塗りに優先して表示）。
@export var texture_override: Texture2D:
	set(value):
		texture_override = value
		_apply()

var _tex_rect: TextureRect


func _ready() -> void:
	_apply()


func _apply() -> void:
	custom_minimum_size.y = thickness
	var use_tex: bool = texture_override != null
	# テクスチャ使用時は ColorRect の塗りを消し、TextureRect を重ねる
	color = Color(0, 0, 0, 0) if use_tex else Color(divider_color.r, divider_color.g, divider_color.b, divider_alpha)

	# ツリー外（シーンロード中のセッター発火）では子ノード操作をしない
	if not is_inside_tree():
		return
	if use_tex:
		_ensure_tex_rect()
		_tex_rect.texture = texture_override
		_tex_rect.visible = true
	elif _tex_rect != null:
		_tex_rect.visible = false


func _ensure_tex_rect() -> void:
	if _tex_rect != null:
		return
	_tex_rect = TextureRect.new()
	_tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex_rect)
