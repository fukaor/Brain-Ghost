# タスクリスト: 反射タップ結果画面 Stitch準拠

## フェーズ1: テーマスタイル追加

- [x] premium_card variation追加（白グラデ背景、白ボーダー、大シャドウ、角丸4rem→40px→27px）
- [x] stat_card variation追加（白半透明60%、角丸2.5rem→20px）
- [x] victory_badge variation追加（緑背景 #52f9a8、角丸full）
- [x] defeat_badge variation追加（グレー背景、角丸full）

## フェーズ2: tscnレイアウト構築

- [x] individual_result.tscn 基本構造作成（root + 放射グラデ背景 + SafeAreaMargin + MainColumn）
- [x] セクション1: キャラクター＋吹き出しエリア（ChibiTexture + SpeechBubble）
- [x] セクション2: メインスコアカード（RESULTS ヘッダー + 特大スコア + NEW BESTバッジ + キャプション）
- [x] セクション3: ゴーストバトルカード（YOU/GHOST スコア比較 + VICTORY/DEFEATバッジ + 比較バー）
- [x] セクション4: 統計グリッド（パーフェクト回数 + ミス回数の2カラム）
- [x] セクション5: アクションボタン（もう一度プレイ CTA + ホームに戻る secondary）

## フェーズ3: コントローラスクリプト

- [x] individual_result_controller.gd 作成（setup API、ノード参照定義）
- [x] スコア・統計データのUIバインド実装
- [x] 勝敗に応じた表示切替（VICTORY/DEFEAT バッジ、吹き出しテキスト、NEW BESTバッジ表示/非表示）
- [x] ボタン遷移実装（もう一度プレイ → 同ゲーム再開、ホームに戻る → home.tscn）

## フェーズ4: キャプチャ・検証

- [x] 720x1280でXvfbキャプチャ取得
- [x] Stitchデザインと比較・差分確認

## 実装後の振り返り

- **実装完了日**: 2026-04-16
- **計画と実績の差分**:
  - 既存のindividual_result.tscn + controllerが存在していたため、新規作成ではなく全面リビルド
  - コントローラは既存ロジック（ダミーデータ表示、GameManager連携、VICTORY/DEFEAT判定）をそのまま活用し、ノード参照パスの更新 + victory/defeat badge切替 + 比較バー比率更新を追加
  - 統計値フォーマットを「18回」→数値「18」+ユニット「回」のtscn分離に合わせて変更
- **変更ファイル**:
  - `assets/themes/default_theme.tres`: premium_card, stat_card, victory_badge, defeat_badge の4 variation追加
  - `scenes/ui/individual_result.tscn`: Stitch準拠で全面リビルド（5セクション構成）
  - `scripts/ui/individual_result_controller.gd`: ノードパス更新、バッジ切替ロジック追加、バー比率動的更新
