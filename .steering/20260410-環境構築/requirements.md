# 環境構築 — Requirements

> **作業日**: 2026-04-10
> **担当**: ねこぽ / Claude Code
> **関連ドキュメント**: `docs/architecture.md`, `docs/repository-structure.md`, `docs/development-guidelines.md`

## 目的

Brain Boost プロジェクトの**Godot 4 プロジェクト骨格**を作成し、Week 1 の実装タスク（反射タップ・フラッシュ暗算）に即着手できる状態にする。

## 背景

`/setup-project` で 6 つの永続ドキュメントが作成・レビュー・修正済みで、設計仕様は確定している。ただしリポジトリには `docs/` と `CLAUDE.md`・`AGENTS.md` しか存在せず、Godot プロジェクトファイルも `scenes/` / `scripts/` / `assets/` などの実コード用ディレクトリも存在しない状態。本タスクではこれらを一括でスキャフォールドする。

## スコープ（In Scope）

1. **Godot プロジェクト設定ファイル**:
   - `project.godot`（Godot 4.6 基準、Autoload 登録、入力マップ、ウィンドウ設定、機能フラグ）
   - `.godot-version`（Godot バージョン固定）
   - `icon.svg`（Godot デフォルトの置き換え、暫定）
   - `export_presets.cfg`（Web / Android の 2 preset、テスト用 AdMob ID）

2. **ディレクトリ構造**:
   - `docs/repository-structure.md` に定義された全ディレクトリを作成
   - `scenes/main/`, `scenes/games/`, `scenes/ui/`, `scenes/shared/`
   - `scripts/autoload/`, `scripts/core/`, `scripts/models/`, `scripts/games/`, `scripts/ui/`, `scripts/utils/`
   - `assets/{fonts,sounds/{bgm,se},icons,images,themes}/`
   - `addons/`, `tests/{unit/{core,utils},integration,e2e,fixtures}/`, `web/{ogp/}`, `scripts_build/`

3. **Autoload スタブ**（6 個）:
   - `scripts/autoload/platform.gd` — **完全実装**（判定ロジックは自明で依存なし）
   - `scripts/autoload/game_manager.gd` — 最小スタブ（シグナル定義と空メソッド）
   - `scripts/autoload/data_store.gd` — 最小スタブ（StoreKey enum + save/load の骨組み）
   - `scripts/autoload/audio_service.gd` — 最小スタブ（Web 音声初期化の枠組み）
   - `scripts/autoload/ad_service.gd` — 最小スタブ（Web で no-op）
   - `scripts/autoload/billing_service.gd` — 最小スタブ（Web で no-op）

4. **ユーティリティ（完全実装可能なもの）**:
   - `scripts/utils/color_palette.gd` — 禁止色の DOC コメント付き、全カラー定数
   - `scripts/utils/date_util.gd` — JST 固定の日付計算、`days_between` 実装
   - `scripts/utils/uuid.gd` — UUID v4 生成
   - `scripts/utils/json_util.gd` — JSON 読書の共通エラーハンドリング

5. **データモデル骨格**（6 個、全て `RefCounted` 継承）:
   - `scripts/models/user_config.gd`
   - `scripts/models/play_log.gd`
   - `scripts/models/play_event.gd`
   - `scripts/models/game_best.gd`
   - `scripts/models/streak_state.gd`
   - `scripts/models/ghost_data.gd`

6. **サービスクラス骨格**（全て `Node` 継承、Autoload しない）:
   - `scripts/core/score_system.gd` — `calculate_score()` を反射タップ・フラッシュ暗算のみ実装、他はスタブ
   - `scripts/core/ghost_system.gd` — `is_feature_unlocked()` / `is_ready_for_game()` のスタブ
   - `scripts/core/daily_seed.gd` — **Fisher-Yates 完全実装**（全ユーザー共通問題の根幹）
   - `scripts/core/streak_service.gd` — **完全実装**（機能設計書 A-06）
   - `scripts/core/schema_migrator.gd` — 空のマイグレーター

7. **メインシーンスタブ**:
   - `scenes/main/launch.tscn` + `scripts/ui/launch_controller.gd` — 初期ルーター（DataStore から `onboardingCompleted` を読み、ホーム or オンボーディングへ）
   - `scenes/main/home.tscn` + `scripts/ui/home_controller.gd` — 最小のホーム画面（「Brain Boost」ラベルのみ）

8. **BaseGame 基底クラス**:
   - `scripts/games/base_game.gd` — ライフサイクル（setup/start/on_user_input/on_finish）の枠組み

9. **Web版の設定**:
   - `web/_headers` — Cloudflare Pages 用の COOP/COEP 設定
   - `web/ogp/default.png` — 空ファイル placeholder（実画像は Week 4）

10. **開発補助ファイル**:
    - `.gitignore`（Godot + Node + 秘匿情報）
    - `.gitattributes`（行末コード・バイナリ指定）
    - `assets/CREDITS.md`（フリー素材ライセンス表記のテンプレ）
    - `README.md` の更新（プロジェクト概要とセットアップ手順）

11. **GUT プラグイン**:
    - `addons/gut/` への配置ガイド（実ファイルのダウンロードは別タスクまたは手動）

12. **スモークテスト**:
    - `tests/unit/core/test_daily_seed.gd` — `DailySeed.get_daily_games()` が同じシードで同じ結果を返すこと
    - `tests/unit/core/test_streak_service.gd` — 7/8 日境界のテスト
    - `tests/unit/utils/test_date_util.gd` — `days_between` のテスト

## スコープ外（Out of Scope）

- 実際のミニゲームの実装（Week 1-3 の別タスクで実施）
- AdMob プラグインの実ダウンロード・設定（本物の API キーを扱うため別タスク）
- GUT プラグインの実ダウンロード（ネットワーク制限があるため、配置先のみ用意し手動で置いてもらう）
- 本番用アセット（フォント・音・画像）の準備
- Google Play Console 登録
- Cloudflare Pages デプロイ設定
- Android 署名鍵の生成

## 受け入れ条件

- [ ] `godot --headless --path /workspace --quit` がエラーなく起動・終了できる
- [ ] `project.godot` の Autoload セクションに 6 つの Autoload が登録されている
- [ ] `docs/repository-structure.md` に定義された全ディレクトリが存在する
- [ ] `DailySeed.get_daily_games()` が同じシードで同じ結果を返すスモークテストがパスする
- [ ] `StreakService.update_streak()` が 7/8 日境界を正しく扱うスモークテストがパスする
- [ ] 全 GDScript ファイルが Godot の parse エラーを出さない（`godot --headless --check-only` 相当）
- [ ] 全 `#ef4444` / 赤系の色がコードに存在しないこと
- [ ] `.gitignore` が `.godot/` や `export_presets.cfg.local` を除外している
