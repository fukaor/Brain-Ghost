# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: コントローラ実装

- [x] game_list_controller.gd を作成
  - [x] GAME_CARDS 定数（6ゲーム分のデータ定義）
  - [x] カルーセルロジック（_current_index, _apply_carousel_layout）
  - [x] Tweenアニメーション（scale/alpha/position遷移 0.4s）
  - [x] スワイプ検出（InputEventScreenDrag, 閾値80px）
  - [x] ドットインジケーター更新
  - [x] ゲーム選択→GameManager.start_game()呼び出し
  - [x] COMING SOONバッジ制御（未実装ゲーム）
  - [x] ボトムナビ接続（ホームタブ→ホーム画面遷移）

## フェーズ2: シーン構築

- [x] game_list.tscn を作成
  - [x] SafeAreaMargin + MainColumn レイアウト
  - [x] HeaderSection（タイトル + サブタイトル）
  - [x] CarouselArea（6枚のカードPanelContainer）
  - [x] 各カード内部（アイコン + ゲーム名 + 説明 + メトリック行）
  - [x] DotIndicators（6つのドット）
  - [x] PlayButton（このゲームをプレイ）
  - [x] BottomNavPanel（5タブ、脳トレがアクティブ）
  - [x] Theme適用（StyleBoxFlat をシーン内 sub_resource で定義）

## フェーズ3: ナビゲーション接続

- [x] GameManager に navigate メソッド追加
  - [x] navigate_to_game_list() 追加
  - [x] navigate_to_home() 追加
  - [x] GAME_LIST_SCENE / HOME_SCENE 定数追加
- [x] home_controller.gd を修正
  - [x] _nav_train ボタンで navigate_to_game_list() を呼ぶ
  - [x] IMPLEMENTED_GAMES に "sequence_memory" を追加

## フェーズ4: 確認・修正

- [x] コードレビューで指摘された4件を修正
  - [x] _ready() で await process_frame 後にカルーセル配置（size.x=0 対策）
  - [x] 隣接カードタップでカルーセルをナビゲート
  - [x] on_rule_explain_cancelled が _entry_scene を使い、game_list/home を正しく判定
  - [x] navigate_to_home() でも _entry_scene をリセット
- [x] ノードパス整合性チェック（@onready 9件すべて tscn と一致）
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-04-17

### 計画と実績の差分

**計画と異なった点**:
- レビューで `_ready()` 時の `size.x == 0` 問題を発見 → `await get_tree().process_frame` で対処
- ルール説明の「戻る」が常にホームに戻る問題 → `_entry_scene` 変数で遷移元を追跡する設計に変更
- 隣接カードタップの UX 欠落 → カードタップ時にカルーセルナビゲートを追加

**新たに必要になったタスク**:
- GameManager に `_entry_scene` フィールド追加（設計時に遷移元トラッキングが漏れていた）

### 学んだこと

**技術的な学び**:
- Godot の Control ノードは `_ready()` 時点で size が確定していない。レイアウト依存の計算は `await process_frame` が必要
- カルーセル UI で `pivot_offset` を設定しないと scale がずれる
- リング距離の計算で偶数個の要素の等距離ケースは注意が必要（N=6 では実害なし）

### 次回への改善提案
- シーン遷移の「戻る先」は最初から設計に含めるべき（ナビゲーションスタックのパターン）
- カルーセル系 UI は初期レイアウトのタイミングを常にテストする
