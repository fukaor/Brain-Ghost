## NavLinkButton
##
## ナビゲーション用リンクボタンの共通コンポーネント。
## rule_explain / game_list / home 等で散在していた「mc_back_btn + Material Symbol オーバーレイ + 矢印付きテキスト」
## のパターンを単一クラスに集約する。
##
## [b]使い方:[/b]
## シーンに `scenes/ui/components/nav_link_button.tscn` をインスタンスし、
## インスペクタで以下のプロパティを設定する:
## - [code]icon_name[/code]: Material Symbol 名（例: "home" / "psychology"）。空文字でアイコン非表示
## - [code]label_text[/code]: 表示文言（例: "ホーム" / "全ゲーム一覧"）
## - [code]direction[/code]: "back"（‹ 矢印を text の前に、アイコンは左端）/ "forward"（› 矢印を text の後、アイコンは右端）
##
## スタイルは `theme_type_variation = &"btn_secondary"` 固定 (Sumi Ghost v4)。
## サイズ・font_size はシーン側で override 可能。
class_name NavLinkButton
extends Button

## Material Symbol 名。空文字でアイコン非表示。
@export var icon_name: String = "":
	set(value):
		icon_name = value
		_refresh()

## ボタンに表示するラベル文字列。
@export var label_text: String = "ホーム":
	set(value):
		label_text = value
		_refresh()

## ナビゲーション方向。"back"=‹ 戻る / "forward"=› 進む。
@export_enum("back", "forward") var direction: String = "back":
	set(value):
		direction = value
		_refresh()

const _ICON_PAD: String = "           "  # アイコン領域分のスペース（offset_left=24, offset_right=64 と整合）

@onready var _icon_label: Label = $HeaderIcon


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if _icon_label == null:
		return
	var has_icon: bool = not icon_name.is_empty()
	_icon_label.visible = has_icon
	if has_icon:
		_icon_label.text = icon_name
	var pad: String = _ICON_PAD if has_icon else ""
	if direction == "back":
		text = "%s‹  %s" % [pad, label_text]
		_icon_label.anchor_left = 0.0
		_icon_label.anchor_right = 0.0
		_icon_label.offset_left = 24.0
		_icon_label.offset_right = 64.0
	else:
		text = "%s  ›%s" % [label_text, pad]
		_icon_label.anchor_left = 1.0
		_icon_label.anchor_right = 1.0
		_icon_label.offset_left = -64.0
		_icon_label.offset_right = -24.0
