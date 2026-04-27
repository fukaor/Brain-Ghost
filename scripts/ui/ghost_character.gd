## GhostCharacter
##
## ブレインゴースト 独自要素: ユーザの生霊 (過去自分の人格化) を視覚化する再利用コンポーネント。
## GDD のゴースト対戦・精度システム・脳年齢を視覚統合する第 3 の独自要素。
##
## 全画面共通で `scenes/ui/ghost_character.tscn` をインスタンス化して使う。
## ホーム・オンボーディング・ゲーム開始前・個別結果・総合結果、それぞれでセリフと
## 表情を更新するだけで同じゴーストが場面に応じて喋る。
##
## [b]ビジュアル仕様:[/b]
## - ポートレート: assets/characters/ghost_placeholder.svg (ダミー、本番は 15 ポーズ予定)
## - 吹き出し: Theme の `speech_bubble` variation 参照 (白背景 + 下ボーダー + シャドウ)
##
## [b]ステート → ビジュアル対応 (v1.0 と v1.1):[/b]
## - 精度 % → 不透明度 (modulate.a)            [v1.0 ✅]
## - セリフ → 吹き出しテキスト                  [v1.0 ✅]
## - 脳年齢 → 見た目年齢 (体型・髪・顔付き)     [v1.1 TODO: カスタムアセット要]
## - ストリーク → オーラ・発光強度              [v1.1 TODO: シェーダ実装要]
## - ベスト更新 → 喜びモーション                [v1.1 TODO: AnimationPlayer 要]
## - 表情バリエーション → ポーズ SVG 差し替え   [v1.1 TODO: アセット要]
class_name GhostCharacter
extends HBoxContainer

## 最低透明度。精度 0% でも完全透明だと存在感が消えるため、25% 残す。
const MIN_ACCURACY_ALPHA := 0.25

## ゴースト7番勝負など決闘モード時の色味補正（わずかにクール寄りに倒す）
const MODE_DUELIST_TINT := Color(0.92, 0.94, 1.00)
const MODE_COMPANION_TINT := Color(1, 1, 1)

@onready var _portrait: TextureRect = $Portrait
@onready var _bubble_text: Label = $SpeechBubble/BubbleVBox/BubbleText

var _current_alpha: float = 1.0
var _current_tint: Color = MODE_COMPANION_TINT


func _ready() -> void:
    # デフォルトはフル不透明。set_accuracy() が呼ばれれば上書きされる。
    _portrait.modulate = Color(1, 1, 1, 1)


## ポートレートのテクスチャを差し替える。
## 画面ごとに違うポーズ／表情を使いたい場合に呼ぶ（例: Ready 画面では構えポーズ、
## 結果画面では勝敗に応じたポーズ、など）。
## 渡された Texture2D が null の場合は差し替えをスキップする。
func set_portrait(texture: Texture2D) -> void:
    if texture == null:
        return
    _portrait.texture = texture


## 精度 (0.0〜1.0) をゴーストの不透明度に反映する。
## 精度 0% → alpha 0.25 (ぼんやり見える)
## 精度 100% → alpha 1.0 (くっきり現出)
## GDD FR-05 の「精度 100% でゴースト対戦機能解放」を視覚的に表現する。
func set_accuracy(accuracy: float) -> void:
    var clamped: float = clampf(accuracy, 0.0, 1.0)
    _current_alpha = MIN_ACCURACY_ALPHA + clamped * (1.0 - MIN_ACCURACY_ALPHA)
    _apply_modulate()


## ゴーストのセリフを設定する。即時テキスト更新。
## 将来はタイプライタ演出 (1 文字ずつ表示) を追加予定 (v1.1)。
func set_dialogue(text: String) -> void:
    _bubble_text.text = text


## 脳年齢をゴーストの見た目年齢に反映する。
## v1.0 では no-op。v1.1 でカスタムアセット (子/中/老 × ポーズ) 発注後に実装。
func set_brain_age(_age: int) -> void:
    pass  # TODO(v1.1): 見た目年齢。アセット発注後に実装


## ストリーク日数をゴーストのオーラ・発光強度に反映する。
## v1.0 では no-op。v1.1 でシェーダ実装後に有効化。
func set_streak(_days: int) -> void:
    pass  # TODO(v1.1): オーラ強度。シェーダ実装後


## ムード (idle / happy / tired / surprised / celebrating) を設定する。
## v1.0 では no-op。v1.1 でポーズ SVG バリエーション発注後に実装。
func set_mood(_mood: String) -> void:
    pass  # TODO(v1.1): 表情変化。アセット発注後に実装


## 対戦モード切替 (docs/ideas/games/ghost-7ban-shobu-spec.md §7-1)。
## - "duelist":   ゲーム前〜プレイ中。わずかにクール寄りの色味で「本気モード」を示唆
## - "companion": 通常モード（ホーム・結果画面など）
## v1.1 で表情 SVG 差分に拡張予定。現状は modulate のティント成分のみ変更。
## 例外扱いの根拠は docs/design/patterns.md §7 に準拠（data-driven modulate、
## alpha と同列に mode もデータ駆動で色成分を振る）。
func set_mode(mode: String) -> void:
    match mode:
        "duelist":
            _current_tint = MODE_DUELIST_TINT
        "companion":
            _current_tint = MODE_COMPANION_TINT
        _:
            push_warning("[GhostCharacter] set_mode: unknown mode '%s'" % mode)
            _current_tint = MODE_COMPANION_TINT
    _apply_modulate()


func _apply_modulate() -> void:
    _portrait.modulate = Color(_current_tint.r, _current_tint.g, _current_tint.b, _current_alpha)
