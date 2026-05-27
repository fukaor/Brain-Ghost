# 要求内容

## 概要

旧ステアリング「20260525-SDキャラ刷新と猫要素強化UX」の全面書き換え版。墨絵テーマ刷新（v4 Sumi Ghost）と新キャラ Sumineko（6 ポーズ）の確定を前提に、市場調査レポート（2026-05-25）で提示した「猫要素 UX」の小〜中期施策を本ステアリングで実装する。アプリ名は変更しない。

## 背景

- 2026-05-26 時点でテーマは墨絵調（和紙クリーム + 墨 + 鬼火青）に切替済み
- マスコットは `assets/characters/sumineko_*.png` の 6 ポーズ（normal/fight/running/double/touch/sleep）に確定
- 競合（Lumosity / Peak / Elevate）との差別化として「マスコットが UX 機能として機能する」（Duolingo / Finch 型）アプローチを採用する
- 旧ステアリングは Midnight Cat 配色（漆黒 + シアン + ゴールド）を前提に書かれているため、墨絵パレットへ全面アップデートが必要

## 実装対象の機能

### 1. juicy_button.gd（共通スプリングバウンス + ハプティック）

- すべての CTA に適用する composition 型コンポーネント
- タップで `scale 0.95 → 1.05 → 1.0`（240ms、3 段スプリング）
- Android では `Input.vibrate_handheld(20)` を併発（`Platform.supports_haptics()` 経由）
- 継承型は採用しない（既存 `CardComponent extends Button` 等と多重継承不可のため）

### 2. MascotController（新設）

- Sumineko スプライトの状態遷移を司る Node コンポーネント
- 状態 API: `react_celebrate / sad / shock / think / sleep` ＋ `set_accuracy(0.0〜1.0)`
- 6 ポーズのうち以下に対応:
  - idle → normal
  - celebrate → fight
  - sad → double（生霊化）
  - shock → fight（目光）
  - think → normal（淡墨グロー）
  - run → running
  - sleep → sleep
  - tap_react → touch
- 不足ポーズ（blink / yawn / tail_flick / eyes_only / celebrate_burst / sad 専用 / think 専用）の作成は**スコープ外**。本ステアリングの振り返りセクションに 7 種リストを記録し、次々回ステアリングでユーザに依頼する
- 精度連動グロー: `accuracy` 値を Modulate.a と GPUParticles2D.amount_ratio にバインド

### 3. SpeechBubble の拡張

- 既存 `scripts/ui/speech_bubble.gd` に `set_text(s: String, dwell_sec: float = 2.0)` API 追加
- fade in 0.2s → dwell 2s → fade out 0.3s の Tween 実装
- 連続呼び出しで内部 Tween を `kill()` してから再生
- 1 行 12 文字以内は呼び出し側で担保（コードでは強制しない）

### 4. ホーム常駐マスコット

- `home.tscn` 右下に Sumineko を常駐（既存マスコット位置）
- MascotController を attach、ベースポーズ = normal
- タップで吹き出し + パーティクル発火（鬼火青を吹き出す）
- 30s 放置で sleep 状態へ遷移、120s でフェードアウトしない（和紙背景上の小さい状態維持）

### 5. 結果画面リアクション（既存 7 グレード対応）

`individual_result_controller._compute_grade_headline()` の戻り値で分岐:

| グレード | マスコット状態 | ハプティック |
|---|---|---|
| NEW BEST | fight + 鬼火青パーティクル + ゴールド輝光 | 強 × 3 |
| PERFECT WIN / GREAT WIN / WIN | fight | 弱 × 2 |
| IMPROVED | normal（鬼火増） | 弱 × 1 |
| NICE START | normal | 弱 × 1 |
| NICE TRY | double（生霊化）| なし |

スコア確定 600ms 後にスプリング登場。

### 6. 精度連動グロー

- `ScoreSystem.calculate_accuracy()` の値で MascotController.set_accuracy() を呼ぶ
- ホーム / 結果画面の Sumineko の鬼火パーティクル量と modulate.a が連動
- 値変化はスムーズ補間（Tween）

### 7. 神経衰弱カード裏面に肉球シルエット

- `card.gd` の `_apply_back()` で子 `_IconLabel` に Material Symbols `pets` グリフを薄シアン透過で描画
- 表向き遷移時にアイコンに上書きされる挙動を維持

### 8. AnimationPlayer による疑似アニメ

- AnimatedSprite2D ではなく **AnimationPlayer + Sprite2D**（or TextureRect）で実装（SpriteFrames を作る必要がない）
- 各 react_* は AnimationPlayer の異なるアニメ（フレーム差替え）として登録
- 次ステアリングで AnimatedSprite2D 化を検討

### 9. リブランド表記の整理

- 旧 Midnight Cat / Catboy 表記の残骸を Sumi Ghost / Sumineko に統一
- MEMORY 規約は既に更新済み（前ステアリングで対応）

## 受け入れ条件

### juicy_button.gd

- [ ] 全 CTA（スタート / ホーム / リプレイ）にタップ即時の跳ね返りが体感できる
- [ ] Android 実機でハプティックが鳴る
- [ ] Web 版でクラッシュしない（no-op）
- [ ] 既存 `CardComponent` 等の Button 継承クラスに影響しない（composition 型）

### MascotController

- [ ] 6 ポーズすべてを `react_*` API で表示できる
- [ ] `set_accuracy(0.0)` / `set_accuracy(1.0)` で見た目に明確な差が出る
- [ ] アイドル 30s で sleep に自動遷移
- [ ] タップで触れて touch ポーズに一瞬切替

### SpeechBubble

- [ ] `set_text("やったニャ")` で 0.2s fade in → 2s 表示 → 0.3s fade out
- [ ] 連続呼び出しで前の吹き出しが破棄される
- [ ] 既存 countdown / home / ghost_character の利用箇所が破綻しない

### ホーム常駐マスコット

- [ ] 起動直後に Sumineko がホーム右下に表示
- [ ] タップで吹き出し（"ニャ！" 等）
- [ ] 30s 放置で sleep に切替

### 結果画面リアクション

- [ ] 7 グレード全てでマスコット状態が分岐する（最低でも NEW BEST / PERFECT WIN / WIN / IMPROVED / NICE TRY の 5 ケースを実機で確認、GREAT WIN は可能なら確認）
- [ ] スコア確定 600ms 後にスプリング登場
- [ ] NEW BEST 時に強ハプティック × 3
- [ ] NICE TRY 時の `sumineko_double.png` に赤系色が使われていないことを目視確認（GDD §6 赤禁止）
- [ ] NICE TRY 吹き出し文言が 12 文字以内でネガティブ語不使用（例: "またやろうニャ"）

### 精度連動グロー

- [ ] 精度 0% / 50% / 100% で Sumineko の不透明度・鬼火パーティクル量に視覚差
- [ ] スムーズに補間される

### 神経衰弱カード裏面

- [ ] 裏面の中央に肉球（pets グリフ）が薄シアン透過で表示
- [ ] 表向き遷移時にアイコンが上書きされる

## 成功指標

- 6 ゲームのうち最低 1 ゲーム（推奨: 神経衰弱）でタップ操作の「気持ちよさ」が体感できる
- 結果画面で「マスコットが反応している」と感じられる
- 競合（Lumosity 等）には作れない「猫 × ゴースト × 自分対戦」が視覚で読み取れる

## スコープ外（次回以降）

- 不足ポーズ画像作成（blink / yawn / tail_flick / eyes_only / celebrate_burst / sad / think、ユーザ作業）
- AnimatedSprite2D / AnimationTree への移行（SpriteFrames を要する）
- ゴースト猫の対戦相手化（GhostNeko の別キャラ化）
- アンビエント音、ワードローブ、神経衰弱以外のゲーム内マスコット演出
- 旧 catboy_* 物理削除

## 参照ドキュメント

- `docs/product-requirements.md` / `docs/functional-design.md` / `docs/architecture.md`
- `docs/repository-structure.md`
- `docs/development-guidelines.md`
- 旧ステアリング `20260525-SDキャラ刷新と猫要素強化UX/` (本ステアリングで上書き)
- 直前ステアリング `20260525-墨絵テーマ刷新/` (本ステアリングの前提)
- 2026-05-25 市場調査レポート（マスコット UX）
