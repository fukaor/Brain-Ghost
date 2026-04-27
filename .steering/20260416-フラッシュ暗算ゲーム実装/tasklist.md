# タスクリスト: フラッシュ暗算ゲーム実装

## フェーズ1: テーマスタイル追加

- [x] keypad_button variation追加（白背景、底8pxシャドウ、角丸1.5rem→16px）
- [x] keypad_confirm variation追加（青背景 #007BFF、白文字、底シャドウ）
- [x] keypad_card variation追加（glass-card: 白60%半透明、角丸3.5rem→24px）

## フェーズ2: ゲームロジック (flash_calc.gd)

- [x] FlashCalcクラス作成（BaseGame継承、game_type="flash_calc"）
- [x] 問題生成ロジック（rng決定論、＋/−混合、負にならない保証）
- [x] 正誤判定 + イベント記録（"correct" / "wrong"）
- [x] 30秒タイマー管理（_on_start で開始、タイムアップで finish）
- [x] スコア算出用データ提供（correct_count, remaining_sec）

## フェーズ3: シーン + ビュー (flash_calc.tscn + flash_calc_view.gd)

- [x] tscn基本構造（放射グラデ背景 + SafeAreaMargin + MainColumn）
- [x] 計算表示エリア（Num1 + Operator + Num2、超大文字、演算子色分け）
- [x] 回答表示ラベル（"???" → ユーザー入力連動）
- [x] タイマー表示（右上、円形背景 + 残り秒数ラベル）
- [x] ゴーストバトルバー（共有シーンインスタンス）
- [x] テンキーパッド（3x4 GridContainer: 1-9, BS, 0, OK）
- [x] flash_calc_view.gd（テンキー入力処理、タイマー更新、問題切替、正誤フィードバック）

## フェーズ4: GameManager連携確認

- [x] GameManager._build_play_data_for("flash_calc") が正しく動作するか確認
- [x] individual_result の flash_calc 設定での表示確認

## フェーズ5: キャプチャ・検証

- [x] 720x1280でXvfbキャプチャ取得
- [x] Stitchデザインと比較・差分確認

## 実装後の振り返り

- **実装完了日**: 2026-04-16
- **計画と実績の差分**:
  - 既存のflash_calc.gd/view/tscnが存在していたため新規作成ではなく全面リビルド
  - 既存は「4-6数字の合計」方式だったが、Stitchデザインの「2数＋/−演算」方式に変更
  - GameManagerのflash_calc対応は既に完了していたため追加作業なし
- **変更ファイル**:
  - `assets/themes/default_theme.tres`: keypad_button, keypad_confirm, keypad_card の3 variation追加
  - `scripts/games/flash_calc.gd`: Stitch準拠で全面リビルド（2数演算、＋/−混合）
  - `scripts/ui/flash_calc_view.gd`: Stitch準拠でリビルド（テンキー入力、演算子色分け、タイマー、バトルバー）
  - `scenes/games/flash_calc.tscn`: Stitch準拠でリビルド（放射グラデ、超大文字計算式、テンキーカード、共有バトルバー）
