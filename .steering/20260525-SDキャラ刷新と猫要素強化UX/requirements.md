# 要求内容

> ⚠️ **本ステアリングは超過済み**
> 2026-05-26 に **`.steering/20260526-SDキャラ強化UX書換版/`** に全面置き換えられました。
> 墨絵テーマ刷新（v4 Sumi Ghost）に伴う配色変更と、新マスコット Sumineko（6 ポーズ）への対応のため。
> 本ファイルは履歴として残置。新規実装の参照はすべて新ステアリングへ。

## 概要

ブレインゴーストのマスコットを現行 Catboy（catboy_electric / confident / energetic）から新規 SD キャラへ刷新し、市場調査レポート（2026-05-25）に基づいて UI/UX 全般に猫要素を注入する。目的は「触っていて楽しい（juicy）」操作感の実現と、「猫 × ゴースト × 自分対戦」というアイデンティティの視覚化。

## 背景

- ゲーム機能としては 6 種そろい一通り完成しているが、操作の手応え・愛着が薄く、競合（Lumosity / Peak / Elevate）との差別化が弱い
- 現状のマスコットは画面に「置かれている」だけで、UX 機能（リアクション・状態表現・空状態演出）として活きていない
- 競合調査（Duolingo / Finch / Neko Atsume / Forest）の結論：**マスコットは装飾ではなく UX 機能であるとき、最も engagement に寄与する**
- 新キャラ画像はユーザが並行で制作中。差し替え + 演出強化を一括で進めるのが効率的

## 実装対象の機能

### 1. SD キャラ アセット差し替え

- 現行 Catboy 系 4 ファイル（catboy_electric / confident / energetic / 旧 ghost_seirei）の参照箇所を新キャラに置換
- 新キャラの命名は `assets/characters/<charname>_<state>.png` 形式に統一（例: `ghostneko_idle.png`, `ghostneko_celebrate.png`）
- 旧アセットは互換性のため当面残置するが、参照はゼロ化

### 2. juicy_button.gd（共通スプリングバウンス + ハプティック）

- すべての CTA ボタンに適用する共通スクリプト
- タップで `scale 0.95 → 1.05 → 1.0`（240ms / Tween.TRANS_SPRING）
- Android では `Input.vibrate_handheld(20)` を同時発火（プラットフォーム分岐は `Platform` Autoload 経由）

### 3. ホーム常駐マスコット

- `home.tscn` 右下に 96px のマスコットを配置（既存配置を移動）
- idle / blink / yawn / tail_flick の 4 ループをランダムに 8〜15s 間隔で切替
- タップで「ニャ」吹き出し + パーティクル発火、30s 放置で curl_up → 120s 放置で寝る

### 4. 結果画面リアクション（既存 7 段階評価に対応）

`individual_result_controller._compute_grade_headline()` が既に算出する 7 グレードに、マスコット状態を 1:1 で割り当てる。

| 既存グレード | マスコット状態 | ハプティック |
|---|---|---|
| NEW BEST | `react_celebrate` + electric burst + 紙吹雪 | 強 × 3 |
| PERFECT WIN / GREAT WIN（ghost_7ban_shobu） | `react_celebrate` | 弱 × 2 |
| WIN（汎用: スコアが previous_score 超え） | `react_celebrate` | 弱 × 2 |
| IMPROVED（自己ベスト未満だが previous_score 超え） | `react_think`（応援系）| 弱 × 1 |
| NICE START（初プレイ） | `react_celebrate`（控えめ） | 弱 × 1 |
| NICE TRY（previous_score 未満） | `react_sad`（しっぽ膨らみ） | なし |

- スコア確定の 600ms 後にスプリングで登場
- 赤は使わず、`react_sad` は「応援している」ニュアンス（耳ペタ + しっぽ膨らみ）に統一

### 5. 精度連動グロー

- `accuracy`（プレイ済み種目数 / 全種目数）が 0.0〜1.0 で増えるほど、マスコットの発光と電撃パーティクルが強くなる
- ホーム常駐マスコットおよび結果画面のマスコットに適用
- バインド先: `Sprite2D.modulate.a`（または `self_modulate`）と `electric_particles.amount`

### 6. 神経衰弱カード裏面を肉球シルエット化

- `card.gd` の裏面表示（現状 暗グラス + シアン枠 + 空テキスト）に**肉球（paw）アイコン**を中央配置（薄シアン透過）
- マスコットのモチーフを神経衰弱に持ち込む最小改修

### 7. AnimationTree ステートマシン基盤

- 新マスコット用の Godot 4 `AnimationTree`（StateMachine モード）を構築
- 状態 7 系統先行：`idle / celebrate / sad / shock / think / sleep / zap`
- 拡張時はノード追加だけで済む構造に

### 8. launch / home 起動演出更新

- launch.tscn: 黒画面 → マスコットの目が 2 つ光る → ロゴへスプリング展開
- home.tscn: 既存配置の整理 + 常駐マスコット位置確定

### 9. 吹き出しコンポーネント拡張

- 既存 `scripts/ui/speech_bubble.gd`（しっぽ描画担当の PanelContainer）を**拡張**
- `set_text(s: String, dwell_sec: float = 2.0)` API 追加（0.2s in / 2s 滞在 / 0.3s out）
- 既存の `theme_type_variation = "speech_bubble"` 利用箇所（countdown / home / ghost_character 等）と後方互換性を保つ
- 新規パスは作らない

## 受け入れ条件

### SD キャラ差し替え

- [ ] `grep "catboy_" scripts/ scenes/` でランタイム参照ゼロ
- [ ] ホーム / カウントダウン（縦・横）/ 個別結果 / ゴースト 7 番勝負 の 5 シーンで新キャラが表示される
- [ ] 旧アセット 4 枚は assets/characters/ に残置（削除しない）

### juicy_button.gd

- [ ] すべてのスタートボタン / ホームボタン / リプレイボタンに適用済み
- [ ] タップで明らかに「跳ね返る」フィードバックが体感できる
- [ ] Android 実機でハプティックが鳴る
- [ ] Web 版でハプティック呼び出しが安全にスキップされる（クラッシュしない）

### ホーム常駐マスコット

- [ ] ホーム画面でマスコットが 4 種類のアイドルアニメをランダム再生
- [ ] タップで反応（吹き出し + パーティクル）
- [ ] 30s 放置で curl_up、120s 放置で sleep に遷移

### 結果画面リアクション

- [ ] 既存 7 グレード（NEW BEST / PERFECT WIN / GREAT WIN / WIN / IMPROVED / NICE START / NICE TRY）すべてでマスコット状態が分岐する
- [ ] スコア確定の 600ms 後にマスコットがスプリングで登場
- [ ] ハプティック：NEW BEST=強 × 3、Win 系=弱 × 2、IMPROVED/NICE START=弱 × 1、NICE TRY=なし

### 精度連動グロー

- [ ] 精度 0% / 50% / 100% でマスコットの発光に視覚的差がある
- [ ] 値の変化に対してスムーズに補間される（瞬間切替でない）

### 神経衰弱カード

- [ ] 裏面の中央に肉球シルエットが薄シアンで表示される
- [ ] 表向き時にはアイコンに上書きされる（既存挙動を維持）

### AnimationTree

- [ ] 7 状態を AnimationTree で遷移可能
- [ ] スクリプトから `state.travel("celebrate")` で遷移できる
- [ ] 既存の AnimatedSprite2D ベース実装と共存可能（段階移行）

### launch / home 演出

- [ ] launch シーンで「目だけ光る」イントロ → ロゴへのスプリングが入る
- [ ] home 配置で他 UI と重ならない（最小 720x1280 で確認）

### 吹き出しコンポーネント拡張

- [ ] 既存 `scripts/ui/speech_bubble.gd` に `set_text(text, dwell_sec)` API 追加
- [ ] fade in / dwell / fade out が動作する
- [ ] 既存の countdown / home / ghost_character の利用箇所が壊れない（後方互換）

## 成功指標

- 操作 1 回ごとに「跳ねる / 鳴る / 光る」フィードバックがある（A-1 + B-5）
- マスコットが「画面に居る」のではなく「アプリと一緒に生きている」と感じる（A-2 + A-3）
- 競合（Lumosity 等）には作れない「猫 × ゴースト × 自分対戦」が画面で読み取れる（A-5）

## スコープ外（次回以降）

以下は本ステアリングでは扱わず、別の steering で扱う:

- B-2 ゴースト猫の対戦相手化（GhostNeko の別キャラ化）
- B-3 アンビエント効果（生活音 SE / 寝息）
- B-4 ワードローブ / アクセサリ解放（連続プレイ報酬）
- C のうち神経衰弱以外（ストループ / 数字さがし / フラッシュ暗算 / 順番記憶 / ゴースト 7 番勝負 のゲーム内マスコット演出）
- D-3 以降（ゲーム選択時のマスコット動線、ゲーム内挙動）
- 旧 Catboy 系 4 ファイルの物理削除

## 参照ドキュメント

- `docs/product-requirements.md` — PRD（ペルソナ・コンセプト）
- `docs/functional-design.md` — 機能設計（スコア・脳年齢・精度システム）
- `docs/architecture.md` — Godot プロジェクト構造・Autoload 分担
- `docs/repository-structure.md` — リポジトリ規約
- `docs/development-guidelines.md` — 開発ガイドライン
- `docs/ideas/brain_training_gdd.md` — GDD（北極星）
- 2026-05-25 市場調査レポート（本セッション内、Duolingo / Finch / Neko Atsume / Forest / Juicy UI 2025 / Rive ステートマシン / Empty State パターン）
