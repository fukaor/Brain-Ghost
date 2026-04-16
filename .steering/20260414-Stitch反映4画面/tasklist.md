# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった

---

## フェーズ1: ルール説明画面 — Stitch 準拠で再構成

- [x] rule_explain.tscn を Stitch のコンポーネントツリーに合わせて再構成
  - [x] HeaderRow: GameIcon(⚡) + TitleVBox(Title+Subtitle) + Spacer + BackButton(↩右上)
  - [x] ExplanationText: 独立した Label で中央寄せ（GhostCharacter の吹き出しから分離）
  - [x] GhostImage: 吹き出しなしの TextureRect に変更（GhostCharacter コンポーネント削除）
  - [x] HintCardsRow: TARGET カード + FAKE カード (glass_bubble × 2)
  - [x] WarningLabel: 「⚠ フェイクをタップすると、タイムロスになるよ！」
  - [x] StartButton: テキスト「脳トレ開始 ▶」、SkipButton 削除
- [x] rule_explain_controller.gd を新ノード構造に対応
  - [x] RULES dict に ability_name, explanation, hints[], warning フィールド追加
  - [x] @onready 参照を全て新ノード名に書き換え
  - [x] set_rule() で各フィールドを対応ラベルに反映
  - [x] flash_calc 用の RULES エントリも同様に更新

## フェーズ2: 反射タップ プレイ画面 — Stitch 準拠で再構成

- [x] reflex_tap.tscn を Stitch のコンポーネントツリーに合わせて再構成
  - [x] TopHudRow: AvgColumn(CURRENT AVG + 値) + ProgressColumn(PROGRESS + 値) + Spacer + ProgressRing(%)
  - [x] 背景を page_bg_v2 に変更
  - [x] GhostBattleBar: BattleHeader(⚔+ゴーストバトル+LIVE SYNC) + ScoreRow(自分 vs ゴースト)
- [x] reflex_tap_view.gd を新ノード構造に対応
  - [x] @onready 参照を全て新ノード名に書き換え
  - [x] _process() HUD更新: AvgValue(累積平均秒), ProgressValue(x/y), ProgressPercent(%)
  - [x] ゴーストバトルバーのスコア表示（プレースホルダー値）

## フェーズ3: 結果画面 — Stitch 準拠で再構成

- [x] individual_result.tscn を Stitch のコンポーネントツリーに合わせて再構成
  - [x] GhostRow: GhostChibi(小さいちびキャラ) + SpeechBubble（上部配置）
  - [x] ResultsLabel: "● RESULTS"
  - [x] ScoreSection: 大型タイム表示(0.42s) + NewBestBadge + "平均反応時間" サブテキスト
  - [x] ComparisonCard: YOU(値) + VICTORYバッジ + GHOST(値)
  - [x] StatsCard: パーフェクト(回数) + 区切り + ミス(回数)
  - [x] ReplayButton(CTA) + HomeLinkRow(テキストリンク)
  - [x] GhostMascotBg: 背景に薄い Seirei 画像
- [x] individual_result_controller.gd を新ノード構造に対応
  - [x] @onready 参照を全面書き換え
  - [x] set_result(): スコア→平均反応時間(秒)表示に変更
  - [x] パーフェクト/ミス回数を PlayLog.events から算出
  - [x] YOU vs GHOST 比較 + VICTORY/DEFEAT 判定
  - [x] ゴーストセリフを Stitch 準拠に更新

## フェーズ4: ホーム画面 — CTA 微調整

- [x] home.tscn の StartButton にゴーストアイコンを追加

## フェーズ5: 整合性確認

- [x] 全画面の @onready パスが .tscn ノード構造と一致していることを確認
- [x] rule_explain_controller.gd の RULES dict が reflex_tap / flash_calc 両方で正しく動くことを確認

---

## 実装後の振り返り

### 実装完了日
2026-04-14

### 計画と実績の差分

**計画と異なった点**:
- ホーム画面のCTAアイコンは HBox 構成ではなく Unicode 絵文字 👻 をテキストに prefix する方式で対応（Godot の Button はテーマ一任でフォント混在が難しいため）

**新たに必要になったタスク**:
- なし

### 学んだこと

**技術的な学び**:
- GhostCharacter コンポーネント（吹き出し一体型）は画面によって使い分けが必要。ルール説明ではテキストとキャラ画像を分離、結果画面ではちびキャラ+独立吹き出しの構成が適切
- speech_bubble.gd の tail_offset_x を負値にすることで、吹き出しのしっぽを左寄りに配置可能（結果画面で活用）

**プロセス上の改善点**:
- Stitchスクリーンショットを先に全画面精査してからコンポーネントツリーを書き起こすことで、見落としが減った

### 次回への改善提案
- フラッシュ暗算のプレイ画面・結果画面も同様にStitchデザインを作成してから実装に入るべき
- ゴーストシステム実装後、プレースホルダー値（GHOST_AVG_REACTION_MS）を動的値に置き換える必要あり
