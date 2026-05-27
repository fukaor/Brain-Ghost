# 設計書

## アーキテクチャ概要

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 3: 画面適用 (home / result / countdown / 神経衰弱)     │
│           ↑ 使う                                                │
├──────────────────────────────────────────────────────────────┤
│  Layer 2: 共通コンポーネント                                    │
│   - MascotController (Sumineko 状態制御)                       │
│   - JuicyBounce      (Button タップ即時バウンス + ハプティック)│
│   - SpeechBubble (拡張: set_text fade in/out)                  │
├──────────────────────────────────────────────────────────────┤
│  Layer 1: 既存基盤                                              │
│   - ColorPaletteUtil v4 (Sumi Ghost 13 色)                     │
│   - Platform Autoload (supports_haptics() を追加する必要あり)  │
│   - assets/characters/sumineko_*.png (6 ポーズ)                 │
└──────────────────────────────────────────────────────────────┘
```

## コンポーネント設計

### 1. Platform.supports_haptics()

**配置**: 既存 `scripts/autoload/platform.gd` に追加

```gdscript
## ハプティック振動がサポートされているか（Android のみ）
func supports_haptics() -> bool:
    return current() == Target.ANDROID
```

JuicyBounce および MascotController から経由。

### 2. JuicyBounce（composition 型）

**配置**: `scripts/ui/components/juicy_bounce.gd`

**責務**: 任意の Button にタップフィードバック（スケール spring + ハプティック）を後付けする

**実装方針**:
- `Node` を extend、Button の親または子として配置
- `@export var target_button: Button` で対象を明示 / 未設定時は `get_parent()` を試す
- pressed.connect で発火

```gdscript
class_name JuicyBounce
extends Node

const BOUNCE_DURATION: float = 0.24
const HAPTIC_MS: int = 20

@export var target_button: Button

func _ready() -> void:
    var btn: Button = target_button if target_button != null else (get_parent() as Button)
    if btn == null:
        push_warning("[JuicyBounce] target_button not set and parent is not Button. No-op.")
        return
    # pivot_offset はレイアウト確定後に設定する。
    # _ready() 時点では btn.size が Vector2.ZERO の場合があり、(0,0) を中心に拡縮すると歪む。
    btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
    # 既に size が確定している（再起動等の）ケースに備えて 1 回明示計算
    if btn.size != Vector2.ZERO:
        btn.pivot_offset = btn.size / 2.0
    btn.pressed.connect(_on_pressed.bind(btn))

func _on_pressed(btn: Button) -> void:
    var t := create_tween()
    t.tween_property(btn, "scale", Vector2(0.95, 0.95), BOUNCE_DURATION * 0.25).set_trans(Tween.TRANS_SINE)
    t.tween_property(btn, "scale", Vector2(1.05, 1.05), BOUNCE_DURATION * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    t.tween_property(btn, "scale", Vector2(1.0, 1.0), BOUNCE_DURATION * 0.35).set_trans(Tween.TRANS_SINE)
    var platform_node: Node = Engine.get_main_loop().root.get_node_or_null("Platform")
    if platform_node != null and platform_node.has_method("supports_haptics") and platform_node.supports_haptics():
        Input.vibrate_handheld(HAPTIC_MS)
```

**適用パターン**: 既存ボタンに Node 子を 1 つ足すだけ。tscn 改修は最小。

### 3. MascotController

**配置**: `scripts/ui/components/mascot_controller.gd`

**責務**:
- `Sprite2D`（または `TextureRect`）に Sumineko のポーズテクスチャを切替表示する
- 状態 API を提供
- アイドルタイマー・精度連動グローを管理

#### 既存 GhostCharacter との共存方針（方針 A: 段階的移行）

既存 `scripts/ui/ghost_character.gd`（`extends HBoxContainer`、TextureRect + 吹き出し HBox）は既に `set_accuracy()` / `set_dialogue()` を持ち、ghost_7ban_shobu / countdown / 一部画面で稼働中。

本ステアリングでは **段階的移行（方針 A）** を採用:
- GhostCharacter は本ステアリング中は手を付けず、既存利用箇所はそのまま動かす
- MascotController は **新規配置箇所**（home 右下の常駐マスコット / 個別結果画面のリアクション）にのみ導入
- 既存 ghost_character.tscn インスタンスは引き続き機能（精度連動グローも GhostCharacter 側はそのまま）
- 完全統合（MascotController が GhostCharacter を吸収）は **別ステアリング**で扱う

これにより、本ステアリングはアセット未着（不足ポーズ）でもデグレ無く完走できる。

**ポーズ → テクスチャマッピング** (`docs/ideas` ではなく `assets/characters/`):

| state | texture path |
|---|---|
| `idle` | `res://assets/characters/sumineko_normal.png` |
| `celebrate` | `res://assets/characters/sumineko_fight.png` |
| `sad` | `res://assets/characters/sumineko_double.png` |
| `shock` | `res://assets/characters/sumineko_fight.png` |
| `think` | `res://assets/characters/sumineko_normal.png` |
| `tap_react` | `res://assets/characters/sumineko_touch.png` |
| `run` | `res://assets/characters/sumineko_running.png` |
| `sleep` | `res://assets/characters/sumineko_sleep.png` |

**API スケッチ**:

```gdscript
class_name MascotController
extends Node

signal mascot_tapped

const TEX_IDLE      = preload("res://assets/characters/sumineko_normal.png")
const TEX_FIGHT     = preload("res://assets/characters/sumineko_fight.png")
const TEX_DOUBLE    = preload("res://assets/characters/sumineko_double.png")
const TEX_TOUCH     = preload("res://assets/characters/sumineko_touch.png")
const TEX_RUNNING   = preload("res://assets/characters/sumineko_running.png")
const TEX_SLEEP     = preload("res://assets/characters/sumineko_sleep.png")

@export var mascot_sprite: TextureRect           # or Sprite2D
@export var particles: GPUParticles2D            # 鬼火青パーティクル
@export var auto_idle_to_sleep: bool = true

var _idle_timer: float = 0.0
var _sleep_threshold: float = 30.0
var _acc_tween: Tween = null

func react_celebrate() -> void: _set_pose(TEX_FIGHT)
func react_sad() -> void: _set_pose(TEX_DOUBLE)
func react_shock() -> void: _set_pose(TEX_FIGHT)
func react_think() -> void: _set_pose(TEX_IDLE)   # 暫定流用
func react_tap() -> void: _set_pose(TEX_TOUCH); _idle_timer = 0.0; mascot_tapped.emit()
func react_sleep() -> void: _set_pose(TEX_SLEEP)
func react_run() -> void: _set_pose(TEX_RUNNING)
func to_idle() -> void: _set_pose(TEX_IDLE); _idle_timer = 0.0

func _set_pose(tex: Texture2D) -> void:
    if mascot_sprite is TextureRect:
        (mascot_sprite as TextureRect).texture = tex
    elif mascot_sprite is Sprite2D:
        (mascot_sprite as Sprite2D).texture = tex

func set_accuracy(value: float) -> void:
    var v: float = clamp(value, 0.0, 1.0)
    if _acc_tween != null and _acc_tween.is_running():
        _acc_tween.kill()
    _acc_tween = create_tween()
    # GhostCharacter (MIN_ACCURACY_ALPHA=0.25) より高めの最低不透明度 0.6 を採用。
    # 理由: Sumineko は大型スプライト + 黒主体のため低透明度だと和紙背景に溶けて見えなくなる。
    _acc_tween.tween_property(mascot_sprite, "modulate:a", 0.6 + 0.4 * v, 0.4)
    if particles != null:
        _acc_tween.parallel().tween_property(particles, "amount_ratio", v, 0.4)

func _process(delta: float) -> void:
    if not auto_idle_to_sleep: return
    _idle_timer += delta
    if _idle_timer > _sleep_threshold and mascot_sprite != null:
        var current_tex = (mascot_sprite as TextureRect).texture if mascot_sprite is TextureRect else null
        if current_tex == TEX_IDLE:
            react_sleep()
```

### 4. SpeechBubble 拡張

**配置**: 既存 `scripts/ui/speech_bubble.gd` に API 追加

既存 SpeechBubble の利用箇所では Label が様々なパスに置かれている（例: `BubbleVBox/BubbleText`、`BubbleMargin/SpeechText` など）。`find_child` 依存はパス変化に脆弱なので、**@export で Label を外部注入**する方式に統一する。

```gdscript
@export var bubble_label: Label    # シーン側で接続。未接続時は no-op + warning
var _bubble_tween: Tween = null

## 吹き出しテキストを設定し、fade in → dwell → fade out のアニメを再生
func set_text(text: String, dwell_sec: float = 2.0) -> void:
    if bubble_label == null:
        push_warning("[SpeechBubble] bubble_label が未接続のため set_text は no-op")
        return
    bubble_label.text = text
    if _bubble_tween != null and _bubble_tween.is_running():
        _bubble_tween.kill()
    modulate.a = 0.0
    visible = true
    _bubble_tween = create_tween()
    _bubble_tween.tween_property(self, "modulate:a", 1.0, 0.2)
    _bubble_tween.tween_interval(dwell_sec)
    _bubble_tween.tween_property(self, "modulate:a", 0.0, 0.3)
```

既存の `_draw()` ロジック（しっぽ描画）と `tail_direction` プロパティはそのまま維持。`bubble_label` は新規追加プロパティのため、既存利用箇所が `set_text` を呼ばなければ後方互換性は保たれる。

### 5. 神経衰弱カード裏面に肉球

**配置**: 既存 `scripts/ui/components/card.gd` の `_apply_back()` 修正

```gdscript
func _apply_back() -> void:
    _apply_style(COLOR_BACK_BG, COLOR_BACK_BORDER, 1)
    if _icon_label != null:
        _icon_label.text = "pets"  # Material Symbols 肉球グリフ
        _icon_label.add_theme_color_override("font_color", Color(0.478, 0.702, 0.878, 0.25))  # 薄 ONIBI_BLUE
        _icon_label.visible = true
```

表向き時の `_apply_front()` で上書きされる挙動を維持。

## データフロー

### ホーム表示時

```
1. HomeController._ready()
2. シーン内の MascotController を取得
3. ScoreSystem.calculate_accuracy(played_game_types) → 0.0〜1.0
4. mascot_controller.set_accuracy(value)
5. mascot_controller.to_idle()
6. 30s 放置 → sleep
7. タップ → react_tap → SpeechBubble.set_text("ニャ！")
```

### 結果画面リアクション

`_compute_grade_headline()` は `{"text": "NEW BEST", "font_size": ..., "color": ..., "deco": ...}` の Dictionary を返す。`text` を取り出して分岐する点に注意。

```
1. individual_result.tscn 表示
2. set_result(log, prev) でスコア確定
3. Timer 600ms 後:
   - var grade_dict := _compute_grade_headline(log, previous_score)
   - var grade_text: String = String(grade_dict.get("text", ""))
   - match grade_text:
     - "NEW BEST"        → mascot.react_celebrate() + particles.emitting=true + haptic ×3
     - "PERFECT WIN" / "GREAT WIN" / "WIN" → mascot.react_celebrate() + haptic ×2
     - "IMPROVED"        → mascot.react_think() + haptic ×1
     - "NICE START"      → mascot.react_celebrate() + haptic ×1
     - "NICE TRY"        → mascot.react_sad()  # haptic なし
4. SpeechBubble.set_text(grade_text に応じた文言、12 文字以内)
```

## エラーハンドリング戦略

- マスコット画像が未配置時: `preload` でロード失敗 → 起動時にエラー（フェーズ0 完了済みのため発生しない）
- Platform Autoload が未登録時: `Engine.get_main_loop().root.get_node_or_null("Platform")` で安全に判定
- AnimationPlayer 不在: 本ステアリングでは AnimationPlayer は使わず、テクスチャ差替えのみ（次ステアリングで導入予定）

## テスト戦略

### ユニットテスト

- `tests/unit/ui/test_mascot_controller.gd`
  - `set_accuracy()` の補間値が clamp 範囲内
  - アイドルタイマーの閾値遷移

### 統合テスト（手動）

- 実機（moto g66j 5G）で:
  - ホーム起動 → Sumineko 表示 + タップ反応
  - 6 ゲーム完走 + 結果画面 7 グレード分岐
  - 神経衰弱カード裏面に肉球表示

## 依存ライブラリ

新規ライブラリは追加しない。Godot 4.6.2 ネイティブのみ。

## ディレクトリ構造

```
scripts/
├── autoload/
│   └── platform.gd                  (supports_haptics() 追加)
└── ui/
    ├── speech_bubble.gd             (set_text API 追加、既存拡張)
    └── components/
        ├── mascot_controller.gd     (新設)
        ├── juicy_bounce.gd          (新設、composition 型)
        └── card.gd                  (裏面に肉球、既存修正)

scenes/
├── main/
│   └── home.tscn                    (MascotController 配置)
└── ui/
    └── individual_result.tscn       (MascotController 配置 + JuicyBounce CTA)
```

## 実装の順序

1. **フェーズ1: 共通基盤**
   - `platform.gd` に `supports_haptics()` 追加
   - `juicy_bounce.gd` 新設
   - `mascot_controller.gd` 新設
   - `speech_bubble.gd` に `set_text` API 追加
   - `card.gd` 裏面に肉球

2. **フェーズ2: 画面適用**
   - home.tscn にホーム常駐マスコット + JuicyBounce on CTAs
   - individual_result.tscn にリアクションマスコット + JuicyBounce
   - 各ボタンに JuicyBounce を attach（rule_explain / countdown 等）

3. **フェーズ3: 検証**
   - 実機ビルド + 6 ゲーム完走 + 7 グレード確認

4. **フェーズ4: ドキュメント**
   - MEMORY 更新
   - 次ステアリングの不足ポーズ依頼リスト最終化

## セキュリティ考慮事項

- `Input.vibrate_handheld` は Platform 経由でガード（Web 版クラッシュ防止）

## パフォーマンス考慮事項

- テクスチャ差替えは preload 済みのため軽い
- GPUParticles2D の amount_ratio Tween は実機で動作確認済み（前ステアリング Phase 7 で間接確認）
- Tween は短命（240ms / 400ms）、重複発火は kill() で防止

## 将来の拡張性

- AnimatedSprite2D 化 (SpriteFrames) は次ステアリングで検討
- 不足ポーズ追加で `MascotController.TEX_*` を拡張すればよい構造
- B-2 ゴースト猫対戦相手化、B-4 ワードローブは別ステアリング
