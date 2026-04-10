# リポジトリ構造定義書 (Repository Structure Document)

> **プロダクト**: Brain Boost
> **バージョン**: v1.0 (MVP)
> **最終更新**: 2026-04-10
> **参照**: `docs/product-requirements.md`, `docs/functional-design.md`, `docs/architecture.md`

Godot 4 プロジェクトとして Brain Boost のファイル配置規則を定義する。レイヤー責務は `architecture.md` の「アーキテクチャパターン」に従う。

> **本ドキュメントが正**: `CLAUDE.md` のディレクトリ構造は本ドキュメントを正として書かれている。差異があった場合は本ドキュメントに合わせて `CLAUDE.md` を更新すること。

---

## プロジェクト構造

```
brain-boost/
├── CLAUDE.md                       # プロジェクトメモリ（Claude Code 用）
├── AGENTS.md                       # エージェント向けガイダンス（自動生成）
├── README.md                       # プロジェクト概要
├── LICENSE                         # ライセンス（未定）
├── .gitignore
├── .gitattributes                  # 行末コード・バイナリ指定
├── .godot-version                  # Godot Engine バージョン固定（例: 4.3.stable）
│
├── project.godot                   # Godot プロジェクト設定
├── export_presets.cfg              # Web/Android エクスポート設定
├── icon.svg                        # Godot デフォルトアイコン置き換え
│
├── docs/                           # 永続ドキュメント
│   ├── ideas/                      # 壁打ち・企画段階の生資料
│   │   └── brain_training_gdd.md   # GDD v1.0（北極星ドキュメント）
│   ├── product-requirements.md     # PRD
│   ├── functional-design.md        # 機能設計書
│   ├── architecture.md             # 技術仕様書
│   ├── repository-structure.md     # 本ファイル
│   ├── development-guidelines.md   # 開発ガイドライン
│   └── glossary.md                 # ユビキタス言語定義
│
├── .steering/                      # 作業単位のドキュメント（タスクごと）
│   └── YYYYMMDD-task-name/
│       ├── requirements.md
│       ├── design.md
│       └── tasklist.md
│
├── .claude/                        # Claude Code の設定
│   ├── commands/                   # スラッシュコマンド
│   ├── skills/                     # スキル定義
│   └── settings.json               # フックなどの設定
│
├── .citadel/                       # Citadel ハーネス関連（任意）
│   ├── plugin-root.txt
│   └── project.md
│
├── scenes/                         # Godot シーン（.tscn）
│   ├── main/
│   │   ├── launch.tscn             # スプラッシュ/初期ルーター
│   │   ├── home.tscn               # ホーム画面
│   │   ├── onboarding.tscn         # 初回オンボーディング
│   │   └── settings.tscn           # 設定画面
│   ├── games/                      # 各ミニゲームのシーン
│   │   ├── reflex_tap.tscn
│   │   ├── flash_calc.tscn
│   │   ├── number_search.tscn
│   │   ├── stroop.tscn
│   │   ├── sequence_memory.tscn
│   │   └── card_match.tscn
│   ├── ui/
│   │   ├── rule_explain.tscn       # ルール説明画面
│   │   ├── countdown.tscn          # カウントダウン演出
│   │   ├── individual_result.tscn  # 個別ゲーム結果
│   │   ├── overall_result.tscn     # 総合結果画面（2層構成）
│   │   ├── share_screen.tscn       # シェア画面（Web版）
│   │   ├── ghost_bar.tscn          # ゴーストプログレスバー
│   │   ├── radar_chart.tscn        # レーダーチャート
│   │   ├── stamp_calendar.tscn     # ハンコカレンダー
│   │   └── dialog_common.tscn      # 汎用ダイアログ
│   └── shared/
│       └── audio_controller.tscn   # AudioStreamPlayer まとめ
│
├── scripts/                        # GDScript ソース
│   ├── autoload/                   # Autoload（Singleton）
│   │   ├── game_manager.gd         # 全体状態管理
│   │   ├── data_store.gd           # 永続化
│   │   ├── audio_service.gd        # BGM/SE 管理
│   │   ├── ad_service.gd           # 広告表示（Androidのみ実体、Webはno-op）
│   │   ├── billing_service.gd      # 課金（Androidのみ）
│   │   └── platform.gd             # プラットフォーム判定の集約
│   ├── core/                       # サービスレイヤー
│   │   ├── score_system.gd         # スコア算出 + 脳年齢
│   │   ├── ghost_system.gd         # ゴースト生成・対戦判定
│   │   ├── daily_seed.gd           # 日付シード
│   │   ├── streak_service.gd       # ストリーク更新
│   │   └── schema_migrator.gd      # JSON スキーママイグレーション
│   ├── models/                     # データモデル（struct/Resource）
│   │   ├── user_config.gd
│   │   ├── play_log.gd
│   │   ├── play_event.gd
│   │   ├── ghost_data.gd
│   │   ├── game_best.gd
│   │   └── streak_state.gd
│   ├── games/                      # ゲームコアレイヤー
│   │   ├── base_game.gd            # 基底クラス
│   │   ├── reflex_tap.gd
│   │   ├── flash_calc.gd
│   │   ├── number_search.gd
│   │   ├── stroop.gd
│   │   ├── sequence_memory.gd
│   │   └── card_match.gd
│   ├── ui/                         # UIコントローラ
│   │   ├── launch_controller.gd
│   │   ├── home_controller.gd
│   │   ├── onboarding_controller.gd
│   │   ├── settings_controller.gd
│   │   ├── rule_explain_controller.gd
│   │   ├── countdown_controller.gd
│   │   ├── individual_result_controller.gd
│   │   ├── overall_result_controller.gd
│   │   ├── share_screen_controller.gd
│   │   ├── ghost_bar_controller.gd
│   │   ├── radar_chart_controller.gd
│   │   └── stamp_calendar_controller.gd
│   └── utils/                      # 汎用ユーティリティ
│       ├── uuid.gd                 # UUID生成
│       ├── date_util.gd            # 日付計算（UTC+9 固定）
│       ├── json_util.gd            # JSON パース補助
│       └── color_palette.gd        # 色定数（ポジティブ/グレー等）
│
├── assets/                         # アート・音・フォント
│   ├── fonts/
│   ├── sounds/
│   │   ├── bgm/
│   │   └── se/
│   ├── icons/
│   ├── images/
│   │   └── games/                  # 各ゲーム用画像
│   ├── themes/                     # Godot UI テーマリソース
│   │   └── default_theme.tres
│   └── CREDITS.md                  # フリー素材ライセンス表記
│
├── addons/                         # Godot プラグイン
│   ├── admob/                      # godot-admob-plugin（Android版のみ）
│   └── gut/                        # Godot Unit Test
│
├── tests/                          # テストコード
│   ├── unit/                       # ユニットテスト（GUT）
│   │   ├── core/
│   │   │   ├── test_score_system.gd
│   │   │   ├── test_ghost_system.gd
│   │   │   ├── test_daily_seed.gd
│   │   │   ├── test_streak_service.gd
│   │   │   └── test_schema_migrator.gd
│   │   └── utils/
│   │       ├── test_date_util.gd
│   │       └── test_uuid.gd
│   ├── integration/                # 統合テスト（シーン連携）
│   │   ├── test_onboarding_flow.gd
│   │   ├── test_daily_challenge_flow.gd
│   │   ├── test_ghost_unlock_flow.gd
│   │   └── test_data_persistence.gd
│   ├── e2e/                        # E2E シナリオ手順書
│   │   └── scenarios.md            # 実機テストの手順とチェックリスト
│   └── fixtures/                   # テスト用データ
│       └── sample_play_logs.json
│
├── web/                            # Web版固有ファイル
│   ├── _headers                    # Cloudflare Pages の COOP/COEP
│   ├── index.html.custom           # Web Export のカスタム HTML シェル（必要なら）
│   ├── styles.css                  # Web版独自の薄いスタイル（ローディング等）
│   └── ogp/
│       ├── default.png             # MVP の OGP 画像（静的）
│       └── template.html           # 将来の動的生成用テンプレート
│
├── android/                        # Android 版固有ファイル（必要に応じて）
│   └── build.gradle.snippets       # gradle 追記用のメモ
│
└── scripts_build/                  # ビルド・デプロイ補助スクリプト（ルート汚染回避）
    ├── export_web.sh               # Godot CLI で Web Export → web/dist/
    ├── export_android.sh           # Godot CLI で Android Export
    └── deploy_web.sh               # Cloudflare Pages へのデプロイ手順
```

---

## ディレクトリ詳細

### scenes/ (Godot シーン)

**役割**: ビジュアル要素とノード階層の定義（`.tscn`）

**配置ファイル**:
- `scenes/main/`: アプリの主要画面（ホーム、オンボーディング、設定）
- `scenes/games/`: 6 種ミニゲームのシーン。1 ゲーム 1 シーン
- `scenes/ui/`: 再利用可能な UI コンポーネント（結果画面、カウントダウン、ダイアログ）
- `scenes/shared/`: オーディオコントローラなどの非表示ユーティリティシーン

**命名規則**:
- snake_case + `.tscn`（例: `reflex_tap.tscn`）
- ゲームシーンは `scripts/games/*.gd` とペアで命名

**依存関係**:
- **依存可能**: `scripts/` の対応するコントローラースクリプト、`assets/`
- **依存禁止**: 他ゲームのシーン（疎結合維持）

### scripts/autoload/ (Autoload / Singleton)

**役割**: Godot の Autoload 機能（全シーンからアクセス可能なグローバル）に登録するサービス群

**配置ファイル**:
- `game_manager.gd`: 全体状態管理（Autoload 名: `GameManager`）
- `data_store.gd`: 永続化の唯一の窓口（`DataStore`）
- `audio_service.gd`: BGM/SE 制御（`AudioService`）
- `ad_service.gd`: 広告表示。Web版では no-op 実装（`AdService`）
- `billing_service.gd`: 課金処理。Web版では no-op（`BillingService`）
- `platform.gd`: `OS.get_name()` ラッパー、分岐ロジックの集約（`Platform`）

**命名規則**:
- ファイル名: `snake_case.gd`
- Autoload 名: `PascalCase`
- 1 ファイル 1 Autoload

**依存関係**:
- **依存可能**: `scripts/core/`, `scripts/models/`, `scripts/utils/`
- **依存禁止**: `scripts/ui/`（UI に依存しない）、`scripts/games/`（ゲームの詳細を知らない）

**Autoload 間の依存ルール**:
- `Platform` は**受動的な存在**。他の Autoload から「今どのプラットフォームか？」を問い合わせられるだけで、`Platform` 自身が他の Autoload を呼ぶことはない
- `AdService` と `BillingService` は `Platform.supports_admob()` / `Platform.supports_billing()` を呼んで分岐する
- `DataStore` は `Platform.storage_strategy()` を呼んで保存先を決める
- `GameManager` はすべての他 Autoload を呼び出して良い（最上位のコーディネーター）
- `AudioService` は他の Autoload に依存しない（独立した音声管理）

**重要**: Autoload は副作用の発生源になりやすい。副作用を持つメソッド（`save`, `emit_signal`）とピュアな getter（`get_xxx`）を明確に分けること。

### scripts/core/ (サービスレイヤー)

**役割**: ビジネスロジックの実装。ピュアなアルゴリズムが望ましい

**配置ファイル**:
- `score_system.gd`: 各ゲームのスコア計算、脳年齢算出、精度計算
- `ghost_system.gd`: ゴーストデータの生成・勝敗判定
- `daily_seed.gd`: 日付シード生成とデイリー3種選出
- `streak_service.gd`: FR-09 のストリーク更新ロジック
- `schema_migrator.gd`: JSON データのスキーママイグレーション

**命名規則**:
- ファイル名: `snake_case.gd`
- クラス名: `class_name PascalCase` で宣言（例: `class_name ScoreSystem`）
- Autoload しない（テスト容易性のため、インスタンス化して使う設計を優先）

**依存関係**:
- **依存可能**: `scripts/models/`, `scripts/utils/`
- **依存禁止**: `scripts/autoload/`（逆依存禁止）、`scripts/ui/`, `scripts/games/`

**Autoload にしない理由**: `scripts/core/` のクラスを Autoload にするとシーンツリーが必須となり、ユニットテスト時に `ScoreSystem.new()` のように直接インスタンス化できなくなる。`scripts/core/` は**インスタンス化して注入する設計**を前提とし、テスト容易性を優先する。`DataStore` への書き込みも行わず、計算結果を返すだけの純粋関数に近い設計を目指す。

### scripts/models/ (データモデル)

**役割**: PRD / 機能設計書で定義されたエンティティの型定義

**配置ファイル**:
- 1 エンティティ 1 ファイル
- Godot の `Resource` を継承することでシーン/ファイルに埋め込めるようにする

**命名規則**:
- ファイル名: `snake_case.gd`（例: `play_log.gd`）
- `class_name PascalCase`（例: `class_name PlayLog`）

**依存関係**:
- **依存可能**: 他の `scripts/models/` のみ
- **依存禁止**: 他すべて（純粋なデータ型）

**例**:
```gdscript
# scripts/models/play_log.gd
class_name PlayLog
extends Resource

@export var id: String = ""
@export var game_type: String = ""
@export var mode: String = "free"
@export var played_at: String = ""
@export var played_date: String = ""
@export var daily_seed: int = -1
@export var score: int = 0
@export var is_new_best: bool = false
@export var duration_ms: int = 0
@export var events: Array[Dictionary] = []
@export var ghost_result: Dictionary = {}

func to_dict() -> Dictionary: ...
static func from_dict(d: Dictionary) -> PlayLog: ...
```

### scripts/games/ (ゲームコアレイヤー)

**役割**: ミニゲーム固有のロジック

**配置ファイル**:
- `base_game.gd`: 基底クラス。ライフサイクル（setup/start/finish）、タイマー、イベント記録
- 各ゲームの具体実装: 1 ゲーム 1 ファイル

**命名規則**:
- ファイル名: `snake_case.gd`（`scenes/games/*.tscn` とペア）
- クラス名: `class_name PascalCaseGame`（例: `class_name ReflexTap`）

**依存関係**:
- **依存可能**: `scripts/models/`, `scripts/core/ScoreSystem`（スコア計算のため）, `scripts/utils/`, 自分のシーン
- **依存禁止**: `scripts/autoload/GameManager` への直接依存（Signal 経由でやりとり）、他ゲームの実装

**新ゲーム追加時のチェックリスト**:
1. `scripts/games/new_game.gd` を作成し `BaseGame` を継承
2. `scenes/games/new_game.tscn` を作成し上記スクリプトをアタッチ
3. `ScoreSystem.GAME_TO_ABILITY` に能力軸マッピングを追加
4. `DailySeed.ALL_GAMES` に追加
5. ルール説明のテキスト/画像を `assets/images/games/` に追加
6. `tests/unit/core/test_score_system.gd` にスコア計算テストを追加
7. E2E チェックリスト（`tests/e2e/scenarios.md`）に動作確認項目を追加

### scripts/ui/ (UIコントローラ)

**役割**: 各シーンにアタッチされるコントローラースクリプト

**配置ファイル**:
- 1 シーン 1 コントローラー（ファイル名 = シーン名 + `_controller.gd`）

**命名規則**:
- ファイル名: `snake_case_controller.gd`（例: `home_controller.gd`）
- クラス名: `class_name PascalCaseController`（必要に応じて）

**依存関係**:
- **依存可能**: `scripts/autoload/*`（Autoload 経由で GameManager / DataStore 等を呼ぶ）、`scripts/models/`, `scripts/utils/`
- **依存禁止**: `scripts/games/` の具体実装（ゲームの詳細を UI が知らないように）

### scripts/utils/ (ユーティリティ)

**役割**: 特定機能に依存しない汎用ヘルパー

**配置ファイル**:
- `uuid.gd`: UUID v4 生成
- `date_util.gd`: JST 基準の日付計算、日差計算
- `json_util.gd`: JSON 読書の共通エラーハンドリング
- `color_palette.gd`: プロジェクト共通の色定数

**命名規則**:
- ファイル名: `snake_case.gd`
- `class_name` を宣言、静的メソッド中心

**依存関係**:
- **依存可能**: 他の `scripts/utils/` のみ
- **依存禁止**: 他すべて

### assets/ (アート・音・フォント)

**役割**: バイナリアセット

**配置ファイル**:
- `fonts/`: `.ttf` / `.otf`
- `sounds/bgm/`: BGM の `.ogg`
- `sounds/se/`: 効果音の `.ogg` / `.wav`
- `icons/`: アプリアイコン、UI アイコン
- `images/games/`: ゲームごとの静止画（ルール説明用、背景など）
- `themes/default_theme.tres`: Godot UI テーマ
- `CREDITS.md`: フリー素材のライセンス表記（**必須**）

**命名規則**:
- snake_case
- ゲーム別アセットは `assets/images/games/reflex_tap/` のようにゲーム名でサブディレクトリ

**依存関係**:
- ソースコードからのみ参照される（逆向きはなし）

### addons/ (Godot プラグイン)

**役割**: Godot エディタ/ランタイムプラグイン

**配置ファイル**:
- `admob/`: godot-admob-plugin。Android エクスポート時のみ含まれる
- `gut/`: Godot Unit Test フレームワーク

**依存関係**:
- Git で管理。**コミットハッシュやタグで固定**すること
- 自前コードから `addons/` を import するのは許容するが、抽象化レイヤー（`AdService`）を必ず挟む

### tests/ (テストコード)

#### tests/unit/

**役割**: 純粋ロジックのユニットテスト（GUT フレームワーク）

**構造**（冒頭のプロジェクト構造ツリーと同一。本節は抜粋）:
```
tests/unit/
├── core/
│   ├── test_score_system.gd
│   ├── test_ghost_system.gd
│   ├── test_daily_seed.gd
│   ├── test_streak_service.gd
│   └── test_schema_migrator.gd
└── utils/
    ├── test_date_util.gd
    └── test_uuid.gd
```

**命名規則**:
- パターン: `test_<対象>.gd`
- 例: `score_system.gd` → `test_score_system.gd`
- クラス名: `class_name TestScoreSystem extends GutTest`（GUT の規約に従う）

#### tests/integration/

**役割**: シーン連携・フロー単位のテスト

**構造**:
```
tests/integration/
├── test_onboarding_flow.gd
├── test_daily_challenge_flow.gd
└── test_ghost_unlock_flow.gd
```

**命名規則**: `test_<flow>.gd`

#### tests/e2e/

**役割**: 実機テスト・ブラウザテストの**手順書**（MVP では自動化しない）

**構造**:
```
tests/e2e/
└── scenarios.md     # チェックリスト形式
```

#### tests/fixtures/

**役割**: テスト用データ。本物に近いプレイログなど

### docs/ (プロジェクトドキュメント)

本ドキュメントを含む 6 種類の永続ドキュメント + `ideas/` 配下の生資料。

**配置ドキュメント**:
- `docs/ideas/brain_training_gdd.md`: GDD v1.0（北極星）
- `docs/product-requirements.md`: PRD
- `docs/functional-design.md`: 機能設計書
- `docs/architecture.md`: アーキテクチャ設計書
- `docs/repository-structure.md`: 本ファイル
- `docs/development-guidelines.md`: 開発ガイドライン
- `docs/glossary.md`: 用語集

### .steering/ (作業単位ドキュメント)

**役割**: タスクごとの一時的な計画・進捗管理

**構造**:
```
.steering/
└── YYYYMMDD-タスク名/
    ├── requirements.md
    ├── design.md
    └── tasklist.md
```

**命名規則**: `20260410-環境構築` のように日本語OK。`CLAUDE.md` の指針に従う。

**Git 管理**:
- **MVP 開発期間は Git 管理する**（個人開発でもコンテキストを残すため）
- 完了したタスクは削除せず、履歴として保持

### .claude/ (Claude Code 設定)

**役割**: Claude Code のスラッシュコマンド、スキル、フック設定

**構造**:
```
.claude/
├── commands/
├── skills/
│   ├── prd-writing/
│   ├── functional-design/
│   └── ...
└── settings.json
```

### web/ (Web版固有ファイル)

**役割**: Godot Web Export に関連するプラットフォーム固有ファイル

**配置ファイル**:
- `_headers`: Cloudflare Pages デプロイ時のレスポンスヘッダー設定。**COOP/COEP 必須**
- `index.html.custom`: カスタム HTML シェル（必要に応じて。タッチ操作 CSS・ローディングインジケータ等）
- `styles.css`: Web版独自の薄いスタイル
- `ogp/default.png`: OGP 画像（MVPは静的固定）
- `ogp/template.html`: v1.1 以降の動的 OGP 生成テンプレート

**注意**: Web Export の出力先（例: `web/dist/`）は `.gitignore` に含める。

### scripts_build/ (ビルド・デプロイ補助)

**役割**: プロジェクトルートの汚染を避けるため、補助スクリプトはここに集める

**命名規則**: 用途がわかる名前（`export_web.sh`, `deploy_web.sh`）

---

## ファイル配置規則

### ソースファイル

| ファイル種別 | 配置先 | 命名規則 | 例 |
|---|---|---|---|
| Godot シーン | `scenes/<area>/` | `snake_case.tscn` | `home.tscn`, `reflex_tap.tscn` |
| Autoload スクリプト | `scripts/autoload/` | `snake_case.gd` | `game_manager.gd` |
| サービスクラス | `scripts/core/` | `snake_case.gd` + `class_name` | `score_system.gd` → `ScoreSystem` |
| モデル | `scripts/models/` | `snake_case.gd` + `class_name` | `play_log.gd` → `PlayLog` |
| ミニゲーム | `scripts/games/` | `snake_case.gd` | `reflex_tap.gd` |
| UIコントローラ | `scripts/ui/` | `snake_case_controller.gd` | `home_controller.gd` |
| ユーティリティ | `scripts/utils/` | `snake_case.gd` | `date_util.gd` |
| 画像 | `assets/images/` または `assets/images/games/<game>/` | snake_case | `reflex_tap_bg.png` |
| 音声 | `assets/sounds/bgm/` or `assets/sounds/se/` | snake_case | `bgm_home.ogg`, `se_correct.wav` |
| フォント | `assets/fonts/` | そのまま | `NotoSansJP-Regular.ttf` |
| UIテーマ | `assets/themes/` | `snake_case.tres` | `default_theme.tres` |

### テストファイル

| テスト種別 | 配置先 | 命名規則 | 例 |
|---|---|---|---|
| ユニットテスト | `tests/unit/<layer>/` | `test_<対象>.gd` | `test_score_system.gd` |
| 統合テスト | `tests/integration/` | `test_<flow>.gd` | `test_onboarding_flow.gd` |
| E2E手順書 | `tests/e2e/` | `scenarios.md` | — |
| フィクスチャ | `tests/fixtures/` | 用途がわかる名前 | `sample_play_logs.json` |

### 設定・メタファイル

| ファイル種別 | 配置先 | 備考 |
|---|---|---|
| Godot プロジェクト設定 | ルート `project.godot` | 編集は Godot Editor 経由 |
| エクスポート設定 | ルート `export_presets.cfg` | 秘匿情報を含む場合は注意 |
| Godot バージョン | ルート `.godot-version` | CI/ローカルの整合性 |
| Git 設定 | ルート `.gitignore`, `.gitattributes` | |
| Cloudflare Pages ヘッダー | `web/_headers` | デプロイ時に参照される |

---

## 命名規則

### ディレクトリ名

- **レイヤー・カテゴリ**: 複数形または意味のある名詞、snake_case
  - 例: `scenes/`, `scripts/`, `assets/`, `tests/`
- **サブカテゴリ**: snake_case
  - 例: `scripts/core/`, `scenes/games/`, `tests/unit/core/`
- **作業ディレクトリ**（`.steering/`）: `YYYYMMDD-タスク名` 形式、日本語可

### ファイル名

- **GDScript**: `snake_case.gd`
- **シーン**: `snake_case.tscn`
- **リソース**: `snake_case.tres` または `snake_case.res`
- **画像**: `snake_case.png` / `.svg` / `.jpg`
- **音声**: `snake_case.ogg` / `.wav`

### GDScript クラス名

- **`class_name`**: PascalCase（例: `class_name ScoreSystem`）
- **ファイル名**: snake_case（Godot の慣例）
- **Autoload 名**: PascalCase（例: `GameManager`）
- **定数**: UPPER_SNAKE_CASE
- **メンバ変数**: snake_case
- **プライベート**: `_` プレフィックス（例: `_current_streak`）
- **シグナル**: snake_case、過去形または現在形（例: `game_finished`, `score_updated`）

### テストファイル名

- パターン: `test_<対象>.gd`
- 例: `score_system.gd` → `test_score_system.gd`
- テスト関数名: `test_<説明>()`（GUT の規約）

---

## 依存関係のルール

### レイヤー間の依存

```
scenes/ (UIビジュアル)
    │
    ▼ アタッチ
scripts/ui/ (UIコントローラ)
    │
    ├──────────────────────────────┐
    ▼                              │
scripts/autoload/ ◄────────────────┘
  (GameManager · DataStore · AudioService · AdService · BillingService · Platform)
    │                    │
    ▼                    ▼
scripts/games/      scripts/core/
  (BaseGame + 6種)    (ScoreSystem · GhostSystem · DailySeed · StreakService · SchemaMigrator)
    │                    │
    ▼                    ▼
scripts/models/ ◄──── 共有型
    │
    ▼
scripts/utils/ (純粋ユーティリティ)
```

矢印の意味: `A → B` は「A が B に依存してよい」。`scripts/ui/` は `scripts/autoload/` を直接呼んでよい（Singleton 経由でサービスにアクセス）。

### 許可される依存

| From → To | 許可 |
|---|---|
| `scenes/*` → `scripts/ui/*_controller.gd` | ✅（アタッチ） |
| `scripts/ui/*` → `scripts/autoload/*` | ✅（Singleton 経由） |
| `scripts/ui/*` → `scripts/models/*` | ✅ |
| `scripts/autoload/*` → `scripts/core/*` | ✅ |
| `scripts/autoload/*` → `scripts/models/*` | ✅ |
| `scripts/core/*` → `scripts/models/*` | ✅ |
| `scripts/core/*` → `scripts/utils/*` | ✅ |
| `scripts/games/*` → `scripts/core/ScoreSystem` | ✅（スコア計算のため） |
| `scripts/games/*` → `scripts/models/*` | ✅ |
| `scripts/games/*` → `scripts/utils/*` | ✅ |

### 禁止される依存

| From → To | 理由 |
|---|---|
| `scripts/core/*` → `scripts/autoload/*` | サービスレイヤーは Autoload に依存しない（テスト容易性） |
| `scripts/core/*` → `scripts/ui/*` | 上位への逆依存禁止 |
| `scripts/core/*` → `scripts/games/*` | ゲームの具体実装は知らない |
| `scripts/games/<A>` → `scripts/games/<B>` | ゲーム同士の相互依存禁止（疎結合） |
| `scripts/ui/*` → `scripts/games/*` | UI はゲームの具体実装を知らない |
| `scripts/models/*` → 他すべて | モデルは純粋な型 |
| `scripts/utils/*` → 他すべて | ユーティリティは純粋 |
| `addons/*` → 自前コード | プラグインから逆参照しない |

### 循環依存の禁止

**禁止**: `A → B → A` の循環参照。

**解決策**:
1. 共通型を `scripts/models/` または `scripts/utils/` に抽出
2. シグナルベースの通信で依存方向を逆にする
3. サービスを分割する

---

## スケーリング戦略

### 機能追加の配置方針

| 規模 | 配置方針 |
|---|---|
| **小規模**（既存ゲームの微修正、設定項目追加） | 既存ファイルを編集 |
| **中規模**（新ミニゲーム 1 種追加） | `scripts/games/` と `scenes/games/` にファイルを追加 |
| **大規模**（新しいゲームジャンル、例: マルチプレイ） | 新サブディレクトリ（例: `scripts/multiplayer/`）を切る |

### ファイルサイズの目安

| ファイルタイプ | 推奨上限 | 備考 |
|---|---|---|
| GDScript 1 ファイル | 300 行 | 300 超は分割を検討 |
| サービスクラス | 400 行 | 責務が膨らんだら分割 |
| UIコントローラ | 200 行 | 分岐が多くなったらヘルパーに抜き出す |
| ゲーム実装 | 500 行 | 大きくなりがちだが、シーン側にロジックを逃がす手もある |

**分割の方針**: 責務を分割する（横方向）。`XxxValidation`, `XxxHelper` のような縦方向分割は必要最小限に。

### ミニゲーム追加時の影響範囲（チェックリスト）

新ミニゲームを追加する際に**必ず**確認するファイル:

- [ ] `scripts/games/new_game.gd` を `BaseGame` 継承で新規作成
- [ ] `scenes/games/new_game.tscn` を新規作成しスクリプトをアタッチ
- [ ] `scripts/core/score_system.gd` の `GAME_TO_ABILITY` 定数に能力軸マッピングを追加
- [ ] `scripts/core/score_system.gd` の `calculate_score()` に新ゲーム用 match を追加
- [ ] `scripts/core/daily_seed.gd` の `ALL_GAMES` 配列に追加
- [ ] `assets/images/games/new_game/` にルール説明画像を追加
- [ ] ルール説明テキストを該当リソース（将来のローカライズファイルの先行定義）に追加
- [ ] `tests/unit/core/test_score_system.gd` にスコア計算テストケースを追加
- [ ] `tests/e2e/scenarios.md` に E2E 動作確認手順を追加
- [ ] 能力軸は 6 固定を守っているか確認（新軸を追加しない）
- [ ] ゴースト 5 件未満の「あと X 回で生まれます」表示が動作するか確認

---

## 特殊ディレクトリ

### .steering/

`CLAUDE.md` で定義されている作業単位のドキュメント管理。詳細は `CLAUDE.md` を参照。

### .claude/

Claude Code の設定。`commands/`, `skills/`, `agents/`, `settings.json`。

### .citadel/

Citadel ハーネスの設定（任意）。`plugin-root.txt`, `project.md`。

### addons/

Godot 公式の慣習により**プラグインは `addons/` に配置**する。Godot Editor の AssetLib も同じ場所を使う。

---

## 除外設定

### .gitattributes

行末コードとバイナリ扱いを明示する（Windows/Mac 混在環境でのアセット破損防止）。

```gitattributes
# デフォルトは LF
* text=auto eol=lf

# Godot テキストファイル
*.gd          text eol=lf
*.tscn        text eol=lf
*.tres        text eol=lf
*.cfg         text eol=lf
*.godot       text eol=lf

# バイナリ（差分不要）
*.png         binary
*.jpg         binary
*.jpeg        binary
*.webp        binary
*.ogg         binary
*.wav         binary
*.mp3         binary
*.ttf         binary
*.otf         binary
*.import      binary
*.pck         binary
*.apk         binary
*.aab         binary
*.keystore    binary
```

### .gitignore

```gitignore
# Godot 固有
.godot/
*.import
*.import.md5
export.cfg
.DS_Store

# エクスポート出力
web/dist/
android/build/
build/
dist/
*.pck
*.apk
*.aab

# 秘匿情報
export_presets.cfg.local
*.keystore
android/release.keystore
.env
.env.local

# エディタ
.vscode/
.idea/
*.swp
*.swo
*~

# ログ・一時ファイル
*.log
logs/
tmp/

# Node.js（補助スクリプト用）
node_modules/

# Claude Code セッションキャッシュ
.claude/cache/
```

### .steering/ の扱い

- **Git 管理対象に含める**（CLAUDE.md の方針）
- 完了したタスクも削除せず履歴として残す
- ただし `.steering/**/*.local.md` のようなユーザー固有メモは `.gitignore` に追加して除外可能

### エクスポート成果物

- `web/dist/` と `android/build/` は Git 管理しない
- 配布物は GitHub Releases または Google Play Console / Cloudflare Pages にアップロード

### 秘匿情報

- **Android 署名鍵** (`*.keystore`) は Git に絶対入れない
- **AdMob Unit ID** は `export_presets.cfg` に含まれるが、MVP 段階では Git 管理（本番 ID に差し替えるのは Week 4 のリリース直前）
- **Google Play 課金の製品 ID** はコード内定数で定義、公開しても問題ない
