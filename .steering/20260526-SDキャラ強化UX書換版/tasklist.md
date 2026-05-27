# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- 全てのタスクを `[x]` にすること
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### スキップ許可ケース
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は理由明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的理由）
```

---

## フェーズ1: 共通基盤

- [x] `scripts/autoload/platform.gd` に `supports_haptics()` を追加（Android のみ true）
- [x] `scripts/ui/components/juicy_bounce.gd` 新設（composition 型）
  - [x] `extends Node` + `@export var target_button: Button`
  - [x] 親 Button 自動取得フォールバック
  - [x] 3 段スプリング（0.95 → 1.05 → 1.0、240ms）
  - [x] `Platform.supports_haptics()` 経由で `Input.vibrate_handheld(20)`
- [x] `scripts/ui/components/mascot_controller.gd` 新設
  - [x] 6 ポーズの preload 定数
  - [x] `react_celebrate / sad / shock / think / sleep / run / tap / to_idle` API
  - [x] `set_accuracy(value)` の Tween 補間（重複発火を `_acc_tween.kill()` で防止）
  - [x] アイドル 30s で sleep 自動遷移（`auto_idle_to_sleep` フラグで制御可能）
- [x] `scripts/ui/speech_bubble.gd` に `set_text(text, dwell_sec)` API 追加
  - [x] `@export var bubble_label: Label` を追加（外部注入方式）
  - [x] fade in 0.2s / dwell / fade out 0.3s の Tween
  - [x] 連続呼び出しで `_bubble_tween.kill()`
  - [x] bubble_label 未接続時は push_warning + no-op
- [x] 既存 SpeechBubble 利用箇所のノード構造確認 + bubble_label を必要箇所のみ接続
  - [x] home.tscn / individual_result.tscn / countdown.tscn / countdown_landscape.tscn / ghost_character.tscn の SpeechBubble インスタンスを特定
  - [x] set_text を呼ぶ箇所（新規: home の常駐マスコット / 結果画面リアクション）のみ bubble_label を接続
- [x] `scripts/ui/components/card.gd` の `_apply_back()` に肉球表示追加
  - [x] `_IconLabel.text = "pets"`
  - [x] 薄 ONIBI_BLUE 透過（α 0.25）
  - [x] 表向き遷移時の `_apply_front()` でアイコン上書きが効くか目視確認

## フェーズ2: 画面適用

- [x] `scenes/main/home.tscn` を更新
  - [x] MascotController + TextureRect（Sumineko）配置
  - [x] CTA ボタン群に JuicyBounce 子 Node を追加
- [x] `scenes/ui/individual_result.tscn` を更新
  - [x] MascotController + TextureRect 配置
  - [x] CTA（リプレイ / ホーム）に JuicyBounce
- [x] `scenes/ui/rule_explain.tscn` の Start ボタンに JuicyBounce
- [x] `scenes/ui/rule_explain_landscape.tscn` の Start ボタンに JuicyBounce（ゴースト 7 番勝負専用）
- [x] `scenes/ui/countdown.tscn` の Skip ボタンに JuicyBounce
- [x] `scenes/ui/countdown_landscape.tscn` の Skip ボタンに JuicyBounce（ゴースト 7 番勝負専用）
- [x] `scripts/ui/individual_result_controller.gd` で 7 グレード分岐 → react_* 呼び出し
  - [x] NEW BEST → react_celebrate + particle on + haptic × 3
  - [x] PERFECT WIN / GREAT WIN / WIN → react_celebrate + haptic × 2
  - [x] IMPROVED → react_think + haptic × 1
  - [x] NICE START → react_celebrate + haptic × 1
  - [x] NICE TRY → react_sad（ハプティックなし）
- [x] HomeController._ready() 末尾に MascotController 取得 + to_idle() を追加
  - [x] 取得元の Node パス決定（home.tscn の配置箇所と一致）
  - [x] _apply_data() 内 accuracy 算出後に MascotController.set_accuracy() を呼ぶ
  - [x] タップで react_tap → SpeechBubble.set_text("ニャ！") のような吹き出し
- [x] グレード別吹き出し文言を定義（12 文字以内、ネガティブ語不使用）
  - [x] NEW BEST: "やったニャ！"
  - [x] WIN 系: "勝ったニャ"
  - [x] IMPROVED: "成長してるニャ"
  - [x] NICE START: "はじまりニャ"
  - [x] NICE TRY: "またやろうニャ"

## フェーズ3: 検証

- [x] `godot --headless --quit-after 30` でパースエラーなし
- [x] `bash scripts_build/deploy_android.sh` でビルド成功
- [x] 実機にデプロイ + 起動確認
- [x] 動作確認:
  - [x] ホームで Sumineko 表示 + タップで吹き出し
  - [x] CTA ボタンタップで scale バウンス + 振動
  - [x] 結果画面で 7 グレード分岐（最低 NEW BEST / PERFECT WIN / WIN / IMPROVED / NICE TRY の 5 ケース、GREAT WIN は可能なら）
    - [x] `OS.get_environment("CAPTURE_CASE")` の `perfect_win` / `nice_try` / `new_best` / `improved` を活用（CAPTURE_CASE 環境変数経由でダミー結果切替可能）
  - [x] NICE TRY 時の `sumineko_double.png` に赤系が無いことを目視確認
  - [x] NICE TRY 吹き出しがネガティブ語不使用（"またやろうニャ" 等）
  - [x] 神経衰弱カード裏面に肉球シルエットが見える
- [x] 既存 6 ゲーム完走（致命的問題なし）

## フェーズ4: ドキュメント

- [x] 旧ステアリング `.steering/20260525-SDキャラ刷新と猫要素強化UX/` の冒頭に「**本ステアリングは 20260526-SDキャラ強化UX書換版 に置き換えられた**」の注記を追加
- [x] MEMORY.md にコンポーネント情報を追記（任意）
- [x] 振り返りに **不足ポーズ 7 種**のリストを直接記載し、次ステアリング（マスコット完全統合 / ポーズ拡張）への引き継ぎとする
  - [x] blink: アイドル時のまばたき
  - [x] yawn: アイドル時のあくび
  - [x] tail_flick: アイドル時のしっぽフリック
  - [x] eyes_only: launch 用、暗闇に目だけ光るシルエット
  - [x] celebrate_burst: NEW BEST 時の最大演出
  - [x] sad_専用: NICE TRY 用、しっぽ膨らみ・耳ペタ（現在は double 流用）
  - [x] think_専用: IMPROVED 用、前足で顎を支えた思案ポーズ（現在は normal 流用）
- [x] 実装後の振り返り（このファイル下部）を記録

---

## 実装後の振り返り

### 実装完了日
2026-05-26

### 計画と実績の差分

**計画と異なった点**:
- juicy_bounce.gd / mascot_controller.gd の attach は Python スクリプト (`/tmp/add_juicy_bounce.py`, `/tmp/add_mascot_controller.py`) で一括処理。tscn の手動編集を回避
- 結果画面のハプティック逐次発火は `await get_tree().create_timer(0.1).timeout` で実装（複数回振動）

**新たに必要になったタスク**:
- home.tscn と individual_result.tscn 内の既存ノードパス（HeroRow vs GhostRow、MascotImage vs GhostChibi）の特定 → 取得元 NodePath の正確な接続

**技術的理由でスキップしたタスク**: なし

### 学んだこと

**技術的な学び**:
- Godot 4 の Tween は async (`await` でチェーンできる) — ハプティック × 3 のような時間差発火は `await create_timer(...)` で書ける
- composition 型コンポーネント（JuicyBounce, MascotController）は `extends Node` + `@export var target` で配置自由度が高い
- TextureRect と Sprite2D の両対応 `_set_pose()` を書いておくと、再生方式変更時の手戻りが減る

**プロセス上の改善点**:
- ステアリング Rev で「`_compute_grade_headline()` の返値型誤認」を事前修正できた効果は大
- 不足ポーズは「次々回ステアリング」へ明示的に引き継ぐ動線（このセクションへの直接記載）が機能

### 次回への改善提案
- 既存シーンへの新ノード追加は Python ヘルパーで自動化するパターンを継続採用

### 不足ポーズ依頼リスト（次ステアリング = マスコット完全統合 へ引き継ぎ）

| 状態 | 用途 | 現在の代替 | 追加要望 |
|---|---|---|---|
| `blink` | アイドル時のまばたき | normal 流用 | normal の目を細めたバリエーション 1 枚 |
| `yawn` | アイドル時のあくび | normal 流用 | 口を開けたあくびポーズ |
| `tail_flick` | アイドル時のしっぽフリック | normal 流用 | しっぽが反対側に振れているコマ |
| `eyes_only` | launch 用、暗闇に目だけ光る | 未使用 | 黒背景 + 目（金 #C8A951）だけ光るシルエット |
| `celebrate_burst` | NEW BEST 時の最大演出 | fight 流用 | 鬼火が大量に舞う豪快ポーズ |
| `sad_専用` | NICE TRY 用、しっぽ膨らみ・耳ペタ | double 流用 | 「応援している」ニュアンス（赤禁止） |
| `think_専用` | IMPROVED 用、前足で顎を支えた思案 | normal 流用 | 思案中ポーズ |

ユーザに上記 7 種の作成依頼を出して、届き次第 MascotController.TEX_* に追加して各 react_* メソッドの流用を解消する。
