# Brain Boost

> **毎日2分、昨日の自分に挑め**
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
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 用プロジェクトメモリ |

## 開発環境セットアップ

```bash
# 1. リポジトリのクローン
git clone https://github.com/<user>/brain-boost.git
cd brain-boost

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

## プロジェクト構造

```
brain-boost/
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
