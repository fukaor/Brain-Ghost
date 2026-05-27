# 設計書

## アーキテクチャ概要

3 層に分けて捉える：

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: 画面別演出 (juicy_button / 結果リアクション / 神経衰弱裏面)│
│           ↑ 利用                                              │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: マスコット制御 (MascotController + AnimationTree)   │
│           ↑ 駆動                                              │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: アセット (assets/characters/ghostneko_*.png + Atlas)│
└─────────────────────────────────────────────────────────────┘
```

新しいキャラ ID（仮）`ghostneko` で進める。ユーザの新規画像が届き次第、命名は確定する。本 design では `ghostneko` をプレースホルダとし、最終命名は実装時に置換する。

## コンポーネント設計

### 1. assets/characters/ 再編

**責務**:
- 新キャラのスチル / 状態スプライトを集中管理
- 旧 catboy_* / ghost_seirei は当面残置（参照ゼロ化のみ）

**配置**:

```
assets/characters/
├── ghostneko_idle.png           # 常時用ベース
├── ghostneko_blink.png          # 瞬き 1〜2 コマ
├── ghostneko_yawn.png           # あくび
├── ghostneko_tail_flick.png     # しっぽフリック
├── ghostneko_celebrate.png      # 勝利・新記録
├── ghostneko_sad.png            # 敗北・しっぽ膨らみ
├── ghostneko_shock.png          # ミス・驚き
├── ghostneko_think.png          # 待機・考え中
├── ghostneko_sleep.png          # 長時間放置
├── ghostneko_zap.png            # 電撃エフェクト
├── ghostneko_eyes_only.png      # 起動演出用（暗闇に目だけ光る）
└── (旧 catboy_*.png は当面残置)
```

**実装の要点**:
- すべて透過 PNG（背景は scene 側のグラデで担当）
- サイズは長辺 512px を上限（モバイル向け、SD 等身を意識）
- ユーザ作成画像の解像度・色味によっては、SpriteFrames 化（AnimatedSprite2D 用）も検討

### 2. MascotController（新設）— 既存 GhostCharacter との関係

**配置**: `scripts/ui/components/mascot_controller.gd`

**責務**:
- マスコットスプライトと AnimationTree の橋渡し
- 状態遷移 API の提供（`celebrate()`, `sad()`, `react_to_tap()` 等）
- 精度連動グロー（`accuracy` 値を Modulate + Particles にバインド）
- アイドル時の自動状態遷移（30s → curl_up、120s → sleep）

#### MascotController vs GhostCharacter

既存 `scripts/ui/ghost_character.gd`（`extends HBoxContainer`）には既に `set_accuracy()` / `set_dialogue()` / `set_portrait()` が実装されており、`TextureRect` ベースの静止画ゴーストを担っている。

両者は次のように **並立** させ、段階的に MascotController へ移行する:

| 観点 | GhostCharacter（既存） | MascotController（新設） |
|---|---|---|
| 描画基盤 | TextureRect（静止画）+ 吹き出し HBox | AnimatedSprite2D + AnimationTree |
| 表現力 | ポーズ差し替えのみ | 状態遷移アニメ + パーティクル + Tween |
| 利用画面 | ghost_7ban_shobu の Ready/Done 画面、ホームの旧位置 | 新規常駐マスコット（home 右下）+ 個別結果 + launch |
| 移行戦略 | 当面残置。ghost_7ban_shobu はゲーム性の都合で GhostCharacter のまま | 新画面と段階移行対象画面に導入 |

**完全移行は別ステアリングで扱う**（次回以降スコープ）。本ステアリングでは MascotController を導入し、GhostCharacter と機能重複が出ても許容する。

**実装の要点**:
- `Node` を extend、`mascot_sprite: AnimatedSprite2D` と `anim_tree: AnimationTree` を `@export` で外部から差し込み可能に
- `set_accuracy(value: float)` で 0.0〜1.0 を受けて Modulate / Particles に補間（`Tween`）
- 各 `react_*()` メソッドは AnimationTree の StateMachine に `travel("...")`

```gdscript
class_name MascotController
extends Node

signal mascot_tapped

@export var mascot_sprite: AnimatedSprite2D
@export var anim_tree: AnimationTree
@export var electric_particles: GPUParticles2D

var _idle_timer: float = 0.0
var _curl_threshold: float = 30.0
var _sleep_threshold: float = 120.0
var _acc_tween: Tween = null   # 重複発火防止用

func react_celebrate() -> void:
    anim_tree.get("parameters/playback").travel("celebrate")

func react_sad() -> void:
    anim_tree.get("parameters/playback").travel("sad")

func react_shock() -> void:
    anim_tree.get("parameters/playback").travel("shock")

func set_accuracy(value: float) -> void:
    var v: float = clamp(value, 0.0, 1.0)
    # 連続呼び出しで Tween が積まれて最終値ズレを起こさないようにする
    if _acc_tween != null and _acc_tween.is_running():
        _acc_tween.kill()
    _acc_tween = create_tween()
    _acc_tween.tween_property(mascot_sprite, "self_modulate:a", 0.6 + 0.4 * v, 0.4)
    if electric_particles != null:
        _acc_tween.parallel().tween_property(electric_particles, "amount_ratio", v, 0.4)

func _process(delta: float) -> void:
    _idle_timer += delta
    if _idle_timer > _sleep_threshold:
        anim_tree.get("parameters/playback").travel("sleep")
    elif _idle_timer > _curl_threshold:
        anim_tree.get("parameters/playback").travel("curl_up")

func _on_tap() -> void:
    _idle_timer = 0.0
    anim_tree.get("parameters/playback").travel("celebrate")
    mascot_tapped.emit()
```

### 3. juicy_button.gd（新設 / composition 型に確定）

**配置**: `scripts/ui/components/juicy_button.gd`

**責務**:
- 任意の `Button` に **後付け** してスプリングバウンス（240ms）+ ハプティック発火

**実装方針（確定）**:
- **継承型は採用しない**。既存 `CardComponent extends Button`, `NavLinkButton extends Button` 等と多重継承できないため
- **Composition 型**：`Node` を extend し、`@export var target_button: Button` で対象ボタンを受け取る。または自身の親が Button ならそれを自動取得
- `Platform.is_android()` を経由してハプティック発火（後述の追加メソッドを使用）
- スプリング曲線は `TRANS_BACK + EASE_OUT` を中盤に挟んだ 3 段 Tween

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

> **適用パターン**: 既存ボタンの子に `Node`（JuicyBounce スクリプト attach）を 1 つ足すだけ。tscn 改修は最小限。
> **前提**: `platform.gd` に `supports_haptics()` を追加するタスクをフェーズ1先頭で行う（Critical）。

### 4. SpeechBubble — 既存実装の拡張（新設しない）

**配置**: 既存 `scripts/ui/speech_bubble.gd`（PanelContainer 派生、しっぽ描画担当）に API を追加

**現状**:
- すでに countdown / home / ghost_character.tscn 等で利用中
- しっぽ方向の制御は実装済み（`tail_direction`）
- 子に `BubbleVBox/BubbleText: Label` を持つ構造（ghost_character.tscn 参照）

**今回の拡張**:
- `set_text(s: String, dwell_sec: float = 2.0)` を追加
  - 内部の `BubbleText.text = s`
  - `modulate.a` を 0 → 1（0.2s）→ dwell → 1 → 0（0.3s）の Tween
  - 連続呼び出しは内部 Tween を `kill()` してから再生
- 1 行 12 文字以内の運用ルールは **コードでバリデートせず**、呼び出し側のレビューで担保
- 既存の参照箇所は `set_text` を使わないので **後方互換**を維持

### 5. AnimationTree 設計

**配置**: マスコットスプライト直下の子ノードとして `AnimationTree`（モード: `StateMachine`）

**状態 7 系統（先行）**:

```
                ┌─ blink ─┐
                │         ↓
   start ──→ idle ←─→ yawn / tail_flick / curl_up / sleep
                │
                ├─→ celebrate ─→ idle
                ├─→ sad        ─→ idle
                ├─→ shock      ─→ idle
                ├─→ think      ─→ idle
                └─→ zap        ─→ idle
```

**遷移ルール**:
- すべての状態は終了後 `idle` に自動遷移（Advance Condition + Auto Advance）
- `sleep` のみ手動 wake が必要（タップ or `react_*()` 呼び出し）
- 遷移時間は短め（0.1〜0.2s）

### 6. 精度連動グロー（連携先）

**読み取り元**:
- `DataStore.load_user_config()` で取得した user_config 内の `played_game_types` から `ScoreSystem.calculate_accuracy()` を呼ぶ

**書き込み先**:
- `MascotController.set_accuracy(value)`

**駆動タイミング**:
- ホーム画面 `_ready()` 時
- 結果画面 `_load_from_game_manager()` 後

### 7. 神経衰弱カード裏面 — 肉球シルエット

**変更箇所**: `scripts/ui/components/card.gd` の `_apply_back()`

**実装の要点**:
- 子 Label（既存 `_IconLabel`）を使い、裏面でも visible=true にする
- 裏面用テキスト = Material Symbols の `pets`（肉球 / 動物足跡）
- 色は `Color(0.435, 0.706, 1, 0.18)`（薄いシアン、目立たない透かし）
- 表向き時に既存挙動でアイコンが上書きされる

## データフロー

### ユースケース 1: ホーム表示時のマスコット起動

```
1. HomeController._ready()
2. MascotController を取得（scene 内子ノード）
3. DataStore.load_user_config() → user_config
4. ScoreSystem.calculate_accuracy(user_config.played_game_types) → 0.0〜1.0
5. mascot_controller.set_accuracy(accuracy)
6. mascot_controller は AnimationTree を idle 状態にして待機開始
7. ユーザがタップ → SpeechBubble.set_text("ニャ！") + mascot_tapped emit
```

### ユースケース 2: 結果画面のリアクション（既存 7 グレード対応）

`individual_result_controller._compute_grade_headline()` の戻り値（既存実装）に 1:1 で割り当てる:

```
1. individual_result.tscn 表示
2. set_result(log, prev_score) でスコア確定
3. 600ms 待機（Timer）
4. _compute_grade_headline(log, prev_score) → "NEW BEST" / "PERFECT WIN" / "GREAT WIN" /
                                              "WIN" / "IMPROVED" / "NICE START" / "NICE TRY"
5. 分岐:
   - "NEW BEST"                          → react_celebrate + パーティクル + ハプティック × 3
   - "PERFECT WIN" / "GREAT WIN" / "WIN" → react_celebrate + ハプティック × 2
   - "IMPROVED"                          → react_think  + ハプティック × 1
   - "NICE START"                        → react_celebrate（控えめ）+ ハプティック × 1
   - "NICE TRY"                          → react_sad（ハプティックなし）
6. SpeechBubble.set_text("やったニャ！" / "応援してるニャ" 等、グレードに応じた 12 文字以内)
```

### ユースケース 3: 神経衰弱カード裏面

```
1. card._ready() → _apply_back()
2. _IconLabel.text = "pets"
3. _IconLabel.font_color = Color(0.435, 0.706, 1, 0.18)
4. _IconLabel.visible = true（裏面でも表示）
5. flip_to_front() で _apply_front() → アイコンに上書き、色も visual.color に変わる
```

## エラーハンドリング戦略

### マスコット画像が見つからない場合

- 新規画像が未配置の段階では、旧 catboy_electric.png を fallback として参照
- 起動時にコンソールに `[Mascot] new asset not found, falling back to legacy catboy_electric`

### Platform 判定が無いプラットフォーム

- `Engine.has_singleton("Platform")` でガード
- Web 版でハプティック呼び出しがクラッシュしないよう no-op

### AnimationTree のステート未定義

- `state.travel("XXX")` で存在しない状態を指定した場合、Godot は warn を出して無視する
- スクリプト側で各 `react_*` メソッド名と AnimationTree のノード名を 1:1 で定義し、ドキュメントコメントに対応表を残す

## テスト戦略

### ユニットテスト

- `tests/unit/ui/test_mascot_controller.gd`
  - `set_accuracy()` の補間が clamp 範囲内で動くか
  - アイドルタイマーの閾値遷移
- `tests/unit/ui/test_juicy_button.gd`
  - bounce 後に scale が 1.0 に戻ること

### 統合テスト

- 実機（moto g66j 5G）でホームを開いてマスコットの動作確認
- 結果画面で NewBest / Win / Lose の 3 ケース手動確認

### キャプチャ確認

- ホーム / 結果画面で `CAPTURE_CASE=perfect_win/nice_try/new_best/improved` を流して、各リアクションが期待通りか

## 依存ライブラリ

新規ライブラリ・プラグインは追加しない。Godot 4.6.2 ネイティブ機能のみで実装する。

## ディレクトリ構造

```
assets/
└── characters/
    ├── ghostneko_*.png             (ユーザ作成中、複数枚)
    └── catboy_*.png                (既存、当面残置)

scenes/
├── ui/components/
│   └── speech_bubble.tscn          (新設)
├── main/
│   ├── home.tscn                   (マスコット差し替え + 配置調整)
│   └── launch.tscn                 (目だけ光る演出追加)
└── ui/
    ├── countdown.tscn              (マスコット差し替え)
    ├── countdown_landscape.tscn    (マスコット差し替え)
    └── individual_result.tscn      (マスコット差し替え + リアクション)

scripts/
├── autoload/
│   └── platform.gd                 (supports_haptics() 追加)
├── ui/
│   ├── speech_bubble.gd            (既存拡張: set_text + fade in/out)
│   └── components/
│       ├── mascot_controller.gd    (新設)
│       ├── juicy_button.gd         (新設 / composition 型)
│       └── card.gd                 (裏面に肉球追加)
```

## 実装の順序

1. **アセット準備フェーズ**
   - ユーザの画像作成完了を待つ
   - 命名・サイズ規約を確定し assets/characters/ に配置

2. **基盤フェーズ**
   - juicy_button.gd 作成（全 CTA に適用 = 即効性高い）
   - MascotController + AnimationTree 構築
   - SpeechBubble コンポーネント新設

3. **画面適用フェーズ**
   - home.tscn 常駐マスコット
   - individual_result.tscn リアクション 3 段階
   - 精度連動グロー連携
   - launch.tscn 起動演出
   - countdown.tscn / countdown_landscape.tscn の差し替え

4. **ゲーム内最小改修フェーズ**
   - 神経衰弱カード裏面に肉球シルエット

5. **検証フェーズ**
   - 実機ビルド・動作確認
   - キャプチャ 4 ケースでの結果画面確認

## セキュリティ考慮事項

- ハプティック呼び出しは Web 版でクラッシュしないようガード必須
- 画像アセットは透過 PNG 限定（SVG は重い）

## パフォーマンス考慮事項

- AnimationTree の状態数自体は CPU 負荷の問題にはならない。むしろ **AnimatedSprite2D の SpriteFrames アニメ数とフレーム解像度**がメモリ・GPU 帯域を圧迫しやすい。7 系統は十分実用的。
- パーティクルは GPUParticles2D（CPUParticles2D は遅い）
- スプライトの長辺は 512px までに抑える（モバイル GPU 帯域）
- Tween は短命（240ms 程度）で create_tween() ベース、複数同時実行を避ける（`_acc_tween` パターン参照）
- `GPUParticles2D.amount_ratio` の Tween は Godot 4.x で動作するが、初導入時にエディタで動作確認すること

## 将来の拡張性

- AnimationTree の状態は後から追加可能（GhostNeko 対戦相手化 / 衣装システムは別ステアリングで）
- MascotController は他画面でも再利用可能な構造に設計
- juicy_button.gd は他ボタン全般に拡張可能
- 旧 catboy_* アセットは将来的に物理削除（別ステアリング）
