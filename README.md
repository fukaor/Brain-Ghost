# ブレインゴースト

> **脳トレ × 自分対戦** — 毎日2分、昨日の自分に挑め
>
> ミニゲーム詰め合わせ型の脳トレアプリ（Godot 4 / Web + Android）

[![Godot](https://img.shields.io/badge/Godot-4.6-478cbf)](https://godotengine.org/)
[![Status](https://img.shields.io/badge/status-MVP%20in%20development-orange)]()

## コンセプト

- **毎日2分で完結する脳トレ** — 1プレイ 3種×30秒 = 約2分
- **ゴースト対戦（独自要素）** — 「いつもの自分」（直近5回平均）と毎プレイ対戦
- **デイリーチャレンジ共通化（独自要素）** — 日付シードで全ユーザー同じ問題を出題、URLで共有可能

## ミニゲーム（MVP: 6種）

1. 反射タップ（反応速度）
2. フラッシュ暗算（計算力）
3. 数字さがし（観察力）
4. ストループ（注意力・判断力）
5. 順番記憶（短期記憶力）
6. 神経衰弱ライト（記憶力・観察力）

## プラットフォーム

| プラットフォーム | ホスト | 配信 | 広告 | 課金 |
|---|---|---|---|---|
| **Web** | Cloudflare Pages (`brain.reigals.com`) | URL 1つで即プレイ | なし（MVP） | なし |
| **Android** | Google Play | ストア配信 | AdMob | 広告非表示買い切り（¥300〜500） |

## ドキュメント

設計ドキュメントはすべて `docs/` 配下にあります。**実装前に必ず関連ドキュメントを読んでください**。

| ドキュメント | 内容 |
|---|---|
| [`docs/ideas/brain_training_gdd.md`](docs/ideas/brain_training_gdd.md) | **GDD v1.0（北極星）** — すべての設計判断の根拠 |
| [`docs/product-requirements.md`](docs/product-requirements.md) | プロダクト要求定義（PRD）— FR-01〜FR-13 |
| [`docs/functional-design.md`](docs/functional-design.md) | 機能設計書 — データモデル・コンポーネント・アルゴリズム |
| [`docs/architecture.md`](docs/architecture.md) | 技術仕様書 — レイヤー責務・パフォーマンス要件・セキュリティ |
| [`docs/repository-structure.md`](docs/repository-structure.md) | リポジトリ構造定義書 — ディレクトリ・命名規則・依存方向 |
| [`docs/development-guidelines.md`](docs/development-guidelines.md) | 開発ガイドライン — GDScript 規約・Git 運用・テスト戦略 |
| [`docs/glossary.md`](docs/glossary.md) | 用語集 — ドメイン用語・技術用語・アルゴリズム |
| [`docs/design/manifest.md`](docs/design/manifest.md) | **デザインマニフェスト** — カラートークン・タイポ・スペーシング・禁則事項 |
| [`docs/design/patterns.md`](docs/design/patterns.md) | **UI パターン集** — ボイラープレート・Theme variation・アンチパターン |
| [`docs/design/references/competitor-research.md`](docs/design/references/competitor-research.md) | 競合 7 アプリの UI/UX リサーチ結果 |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 用プロジェクトメモリ |

## 開発環境セットアップ

```bash
# 1. リポジトリのクローン
git clone https://github.com/<user>/brain-ghost.git
cd brain-ghost

# 2. Godot Engine 4.6.2 以降をインストール
#    https://godotengine.org/download から取得

# 3. Godot Editor で open
#    - Godot を起動
#    - Import → project.godot を選択
#    - Plugins → gut / admob を有効化（必要に応じて）

# 4. CLI で動作確認
godot --headless --path . --quit

# 5. Web版ローカルプレビュー（COOP/COEP 必須）
#    詳細は docs/development-guidelines.md を参照
```

詳細は [`docs/development-guidelines.md`](docs/development-guidelines.md) の「開発環境セットアップ」を参照してください。

## テスト

### ユニットテスト（GUT）

`tests/unit/` 配下のテストは [GUT (Godot Unit Test) v9.6.0](https://github.com/bitwes/Gut) で実行します。プラグインは `addons/gut/` にリポジトリ同梱済みなので別途インストールは不要です。

```bash
# 全テスト実行（推奨）
./scripts_build/run_unit_tests.sh

# 単一ファイル実行
./scripts_build/run_unit_tests.sh -gtest=res://tests/unit/core/test_daily_seed.gd

# ファイル名絞り込み実行（例: "score" を含むファイルのみ）
./scripts_build/run_unit_tests.sh -gselect=score -gdir=res://tests/unit -ginclude_subdirs
```

**初回実行前**: `.godot/` グローバルクラスキャッシュが未生成の場合、`godot --headless --editor --quit-after 60` を一度実行してください（`GutTest` クラスの登録に必要）。

### スモークテスト（GUT なしで走る軽量版）

プラグインを使わない自前アサート版。CI の第一段階や GUT 不在環境での疎通確認に使えます。

```bash
godot --headless --script tools/smoke_test.gd
```

## デザインシステム

UI 実装時は以下の順序で参照してください:

1. **[`docs/design/manifest.md`](docs/design/manifest.md)** — 何を使うか（色・フォント・余白・禁則）
2. **[`docs/design/patterns.md`](docs/design/patterns.md)** — どう組むか（ボイラープレート・Theme variation・ゴースト使用法）
3. **[`docs/design/references/competitor-research.md`](docs/design/references/competitor-research.md)** — トーン参考（競合 7 アプリ分析）

### Theme リソース再生成

色・サイズ・variation を変更したら `assets/themes/default_theme.tres` を再生成してください:

```bash
# 初回 or フォント/テクスチャ追加時: .import 生成
godot --headless --editor --quit-after 3600

# Theme 本体の再生成
godot --headless --script scripts_build/build_theme.gd

# グラデーションテクスチャの再生成（色調整時）
godot --headless --script scripts_build/build_gradients.gd
```

### ゴーストキャラクタ (生霊システム)

ブレインゴースト の独自 UX コンポーネント。**ゴースト = ユーザの生霊** という設定で、精度 % → 不透明度、セリフで状態を案内します。全画面共通の `scenes/ui/ghost_character.tscn` としてインスタンス化し、コントローラから `set_accuracy()` / `set_dialogue()` を呼び出します。詳細は `docs/design/patterns.md` §5 を参照。

## プロジェクト構造

```
brain-ghost/
├── project.godot           # Godot プロジェクト設定
├── scenes/                 # Godot シーン (.tscn)
├── scripts/
│   ├── autoload/           # Singleton (GameManager, DataStore, ...)
│   ├── core/               # サービスレイヤー（Autoload しない）
│   ├── models/             # データモデル（RefCounted）
│   ├── games/              # ミニゲーム実装
│   ├── ui/                 # UI コントローラ
│   └── utils/              # 汎用ユーティリティ
├── assets/                 # フォント・音・画像
├── addons/                 # Godot プラグイン（admob, gut）
├── tests/                  # ユニット / 統合 / E2E
├── web/                    # Web版固有ファイル（_headers, ogp/）
└── docs/                   # 永続ドキュメント
```

詳細は [`docs/repository-structure.md`](docs/repository-structure.md) を参照。

## 開発ステータス

**現在**: MVP 開発中（Week 1 — 環境構築 + 最初の 2 ゲーム）

| バージョン | 内容 |
|---|---|
| **v1.0 (MVP)** 🚧 | 6種ミニゲーム・ゴースト対戦・デイリーチャレンジ・シェアURL・広告・買い切り課金 |
| v1.1 | +3種ミニゲーム（空間認知・推理・瞬間記憶）、Firebase Analytics |
| v1.2 | トレンドグラフ・月次レポート |
| v1.3 | 通知・SNS シェア強化 |
| v2.0 | 英語対応 |
| v2.1 | iOS 対応 |

## ライセンス

未定（MVP 公開時に確定）。フリー素材は `assets/CREDITS.md` を参照。

## 開発者

**ねこぽ / ReigalLabs** — 個人開発 + Claude Code アシスト
