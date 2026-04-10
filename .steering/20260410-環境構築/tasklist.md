# 環境構築 — Tasklist

> **進捗管理**: `[ ]` → `[x]` で更新。完了後に「申し送り事項」を追記する。

## A. ディレクトリ構造の作成

- [x] A-01: `scenes/{main,games,ui,shared}/` ディレクトリを作成
- [x] A-02: `scripts/{autoload,core,models,games,ui,utils}/` ディレクトリを作成
- [x] A-03: `assets/{fonts,sounds/{bgm,se},icons,images/games,themes}/` ディレクトリを作成
- [x] A-04: `addons/`, `tests/{unit/{core,utils},integration,e2e,fixtures}/`, `web/ogp/`, `scripts_build/`, `tools/` ディレクトリを作成
- [x] A-05: `.gitkeep` を空ディレクトリに配置（Git 管理用）

## B. プロジェクトメタファイル

- [x] B-01: `.gitignore` を作成（Godot + Node + 秘匿情報を網羅）
- [x] B-02: `.gitattributes` を作成（行末コード・バイナリ指定）
- [x] B-03: `.godot-version` を作成（`4.6.2`）
- [x] B-04: `icon.svg` を作成（暫定の Brain Boost アイコン）
- [x] B-05: `README.md` を更新（プロジェクト概要・セットアップ手順）
- [x] B-06: `assets/CREDITS.md` のテンプレを作成

## C. Godot プロジェクト設定

- [x] C-01: `project.godot` を作成（Autoload 登録・ウィンドウ設定・GL Compatibility・入力マップ）
- [x] C-02: `export_presets.cfg` を最小構成で作成（Web と Android の 2 preset、テスト用プレースホルダ）
- [x] C-03: `web/_headers` を作成（COOP/COEP、Permissions-Policy）
- [x] C-04: `web/ogp/default.png` をプレースホルダとして配置（空ファイル or README）

## D. Utility レイヤー（完全実装）

- [x] D-01: `scripts/utils/color_palette.gd` — 禁止色の DOC コメント + 全カラー定数
- [x] D-02: `scripts/utils/date_util.gd` — `today_jst()` / `days_between()` の完全実装
- [x] D-03: `scripts/utils/uuid.gd` — UUID v4 生成
- [x] D-04: `scripts/utils/json_util.gd` — パースの共通エラーハンドリング

## E. データモデル（完全実装、RefCounted）

- [x] E-01: `scripts/models/user_config.gd` — 全フィールド + `to_dict` / `from_dict`
- [x] E-02: `scripts/models/play_event.gd` — 軽量イベント構造
- [x] E-03: `scripts/models/play_log.gd` — `events: Array[PlayEvent]` を含む
- [x] E-04: `scripts/models/game_best.gd`
- [x] E-05: `scripts/models/streak_state.gd`
- [x] E-06: `scripts/models/ghost_data.gd`

## F. Autoload レイヤー

- [x] F-01: `scripts/autoload/platform.gd` — 完全実装（Target enum, supports_xxx 系）
- [x] F-02: `scripts/autoload/data_store.gd` — StoreKey enum + save/load のスケルトン（Platform 経由の分岐ロジックのみ）
- [x] F-03: `scripts/autoload/audio_service.gd` — BGM/SE の on/off ゲッター + Web 音声初期化の枠組み
- [x] F-04: `scripts/autoload/ad_service.gd` — Platform 非サポート時に no-op、Android 時のログ出力のみ
- [x] F-05: `scripts/autoload/billing_service.gd` — 同上、`is_ad_free()` は常に false スタブ
- [x] F-06: `scripts/autoload/game_manager.gd` — プレイモード enum、シグナル定義、メソッドスケルトン

## G. サービスレイヤー（core/）

- [x] G-01: `scripts/core/score_system.gd` — ALL_GAMES 定数、GAME_TO_ABILITY マップ、`calculate_score` に 6 ゲーム全分岐（実装は反射タップ・フラッシュ暗算のみ）、`calculate_brain_age()` 完全実装（A-02）、`calculate_accuracy()` 完全実装
- [x] G-02: `scripts/core/daily_seed.gd` — **完全実装**（A-05、Fisher-Yates）
- [x] G-03: `scripts/core/streak_service.gd` — **完全実装**（A-06）
- [x] G-04: `scripts/core/ghost_system.gd` — `is_feature_unlocked()`, `is_ready_for_game()`, `get_plays_until_ready()` のスケルトン
- [x] G-05: `scripts/core/schema_migrator.gd` — 空の migrator、`CURRENT_SCHEMA_VERSION = 1`

## H. ゲームコア基底

- [x] H-01: `scripts/games/base_game.gd` — ライフサイクルシグナル、setup/start/on_user_input/on_finish の枠組み

## I. UI スケルトン

- [x] I-01: `scenes/main/launch.tscn` — 最小シーン（ルートノード + ラベル）
- [x] I-02: `scripts/ui/launch_controller.gd` — UserConfig 読込 → home or onboarding 振り分け（スタブは home 固定）
- [x] I-03: `scenes/main/home.tscn` — 「Brain Boost」ラベルだけの最小画面
- [x] I-04: `scripts/ui/home_controller.gd` — 最小スタブ

## J. テスト（スモーク）

- [x] J-01: `tools/smoke_test.gd` — GUT なしで実行できる直接アサート版スモークテスト
- [x] J-02: `tests/unit/core/test_daily_seed.gd` — GUT 形式（GUT 配置後に実行）
- [x] J-03: `tests/unit/core/test_streak_service.gd` — GUT 形式
- [x] J-04: `tests/unit/utils/test_date_util.gd` — GUT 形式
- [x] J-05: `tests/e2e/scenarios.md` — 手動 E2E 手順書のひな形

## K. 検証

- [x] K-01: `godot --headless --path /workspace --quit` でエラーなく起動・終了することを確認
- [x] K-02: `godot --headless --path /workspace --script tools/smoke_test.gd` でスモークテストがパス（**54/54 passed**）
- [x] K-03: 全 .gd ファイルに `rg 'Color\(\s*(0\.[789]|1)' scripts/ scenes/` でヒットがないこと（赤色チェック）— クリア
- [x] K-04: `rg 'OS\.get_name\(\)' scripts/ | rg -v 'platform.gd'` でヒットがないこと（Platform 経由ルール）— クリア（platform.gd のみ）

---

## 申し送り事項（2026-04-10 完了）

### 実施結果

- **作成ファイル数**: 24 GDScript + 2 .tscn + 18 設定/テスト/ドキュメント + 20 .gitkeep = 計 **64 ファイル**
- **GDScript 行数**: 1,306 行
- **スモークテスト**: 54 ケース全パス（`godot --headless --script tools/smoke_test.gd`）
- **ヘッドレスロード**: エラーなし（`godot --headless --quit`）
- **使用 Godot バージョン**: 4.6.2 stable

### 完全実装したもの（後続タスクで触らない）

- `scripts/autoload/platform.gd`
- `scripts/utils/color_palette.gd`, `date_util.gd`, `uuid.gd`, `json_util.gd`
- `scripts/core/daily_seed.gd` — Fisher-Yates による決定論的3種選出
- `scripts/core/streak_service.gd` — 0/1/2-7/8日境界の全分岐
- `scripts/core/score_system.gd` の `calculate_brain_age()`, `calculate_accuracy()`, `get_ability()`, `calculate_score()` (反射タップ・フラッシュ暗算・ストループ・数字さがしを式レベルで実装)
- `scripts/core/schema_migrator.gd` (空の migrator)
- 全データモデル（6 個）の `to_dict` / `from_dict`
- `scripts/games/base_game.gd` のライフサイクル枠組み
- 設定ファイル一式（`project.godot`, `export_presets.cfg`, `.gitignore`, `.gitattributes`, `web/_headers`, `README.md`, `assets/CREDITS.md`）

### スタブのまま残したもの（Week 2-4 で肉付け）

- `scripts/autoload/data_store.gd` の実 I/O パスは実装済みだが、スキーマ移行と既存ファイル上書きのエラーハンドリングを後日強化
- `scripts/autoload/audio_service.gd` の BGM/SE 再生本体（Week 2 で実装）
- `scripts/autoload/ad_service.gd` / `billing_service.gd` の AdMob / Play Billing 連携（Week 4）
- `scripts/autoload/game_manager.gd` のシーン遷移ロジック（Week 1-3 で逐次）
- `scripts/core/ghost_system.gd` の平均化アルゴリズム（Week 2-3）
- `scripts/ui/launch_controller.gd` のオンボーディング分岐（オンボーディングシーン実装後）

### 計画と実績の差分

- **想定外の発見**: サンドボックスの `/workspace/.godot/` がデフォルトで root 所有でマウントされており、`class_name` グローバルキャッシュが作れなかった。`sudo chown` で解決し、`godot --headless --editor --quit-after` で初回スキャンを実行することでキャッシュを生成。通常の開発環境ではこの問題は起きない
- **追加実施**: レビュー指摘を受けて `tests/unit/core/test_score_system.gd` を追加で作成（GUT 形式、脳年齢境界値・精度・能力軸を網羅）
- **ドキュメント同期**: `docs/functional-design.md` の ScoreSystem / GhostSystem インターフェース定義を実装シグネチャに合わせて更新

### 学んだこと

1. **Godot 4 の `class_name` はグローバル登録が前提**で、初回スキャンがないと autoload での参照が失敗する。CI では `godot --headless --editor --quit-after 30` を最初に回すこと
2. **`Array.shuffle()` は `RandomNumberGenerator` のシードを無視する** — これを知らずに使っていたらデイリーチャレンジ共通問題が壊れる重大バグになっていた。レビューで検出できてよかった
3. **`welcome_back_shown` フラグは「演出表示済みか」の意味で統一**した方が読みやすい（`false` = 次回に表示すべき状態）
4. **Godot の Autoload はテスト容易性を下げる** — `scripts/core/` は Autoload せずにインスタンス化するルールが正解だった
5. **`JavaScriptBridge.eval()` の文字列補間は将来リスク** — ユーザー自由入力が増える前に `create_object()` / `btoa()` に切り替える時期を見極めること

### 次回への改善提案

1. **GUT プラグインの配置タスクを独立させる**: `addons/gut/` は手動ダウンロードが必要なため、次のタスクで配置し `tests/unit/**` を実行可能にする
2. **AdMob プラグインの実配置**: テスト用 Unit ID の設定も含めて Week 4 直前ではなく Week 2 あたりで事前配置する（ビルド互換性の早期検知）
3. **CI ワークフローの整備**: `scripts_build/serve_local.js`（COOP/COEP 付き Node 簡易サーバ）と `.github/workflows/test.yml` を追加検討
4. **Android 側の `.gitignore` 要素**: `android/` ディレクトリはまだ作成していないが、実 Android ビルド時に `android/build/`, `android/plugins/`, `*.keystore` の除外が効くか確認
5. **`docs/ideas/brain_training_gdd.md`** の GDD はまだプロジェクトの唯一の北極星として最新だが、今後の変更は PR で更新履歴を残す運用に

### 次のステアリング候補

- `20260411-gut-plugin-setup` — GUT プラグイン配置と `tests/unit/` の実行確認
- `20260412-reflex-tap-implementation` — 反射タップゲームの実装（Week 1 タスク）
- `20260414-flash-calc-implementation` — フラッシュ暗算ゲームの実装
