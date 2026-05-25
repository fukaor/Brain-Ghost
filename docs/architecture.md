# 技術仕様書 (Architecture Design Document)

> **プロダクト**: ブレインゴースト
> **バージョン**: v1.0 (MVP)
> **最終更新**: 2026-04-10
> **参照**: `docs/product-requirements.md`, `docs/functional-design.md`

PRD と機能設計書の内容を技術的に実現するための、システム構造・テクノロジースタック・非機能設計を定義する。

---

## テクノロジースタック

### 言語・ランタイム

| 技術 | バージョン | 備考 |
|---|---|---|
| **Godot Engine** | **4.6.2 stable**（固定） | MVP 開発で確定したバージョン。`.godot-version` ファイルに記載。バージョンアップは独立 PR で。Web/Android 同時エクスポート可能 |
| **GDScript** | Godot 4.6 同梱 | プロジェクトの主言語 |
| **HTML5 / JavaScript** | ES2020 以降 | Web版の `JavaScriptBridge` 連携用 |
| **Node.js（開発補助）** | 20.x LTS | デプロイスクリプト、`_headers` 生成等の補助スクリプト用。実行環境には含まない |

> **Godot のバージョン固定方針**: `project.godot` の `config/features` にビルド時の Godot バージョンを明記する。バージョン更新は独立した PR で行い、リグレッションを全 E2E で確認してからマージする。

### フレームワーク・ライブラリ

| 技術 | バージョン | 用途 | 選定理由 |
|---|---|---|---|
| **godot-admob-plugin**（godot-sdk-integrations版） | Godot 4 対応最新版 | Android版広告表示（バナー/インタースティシャル/リワード） | Godot 4 対応 AdMob プラグインで最もメンテが継続されている。GDD §3 で指定 |
| **Google Play Billing Library**（Godot ラッパー経由） | 6.x 以降 | 広告非表示買い切り課金（non-consumable） | Google Play 公式の課金 SDK。代替なし |
| **Godot 標準 UI テーマ** | Godot 4.3 同梱 | ボタン・ラベル・カウントダウン等の共通 UI | 独自テーマの作成コストを MVP では払わない |
| **Godot GUT**（Godot Unit Test） | 9.x 以降 | ユニットテストフレームワーク | Godot エコシステムで最も一般的。CI 連携も可能 |
| **フリー素材（効果音・フォント・アイコン）** | — | アセット | 自作コスト削減。ライセンスは MVP 前にリスト化し `assets/CREDITS.md` にまとめる |

> **採用しないライブラリ**: MVP では Godot エコシステム外のサードパーティ依存を極力入れない。GDScript 標準（`Time`, `JSON`, `FileAccess`, `RandomNumberGenerator`, `JavaScriptBridge`）で実装できるものは自前で書く。

### 開発ツール

| 技術 | バージョン | 用途 | 選定理由 |
|---|---|---|---|
| **Godot Editor** | 4.6.2 以降（`.godot-version` と一致） | 開発・デバッグ・エクスポート | 唯一の開発 IDE |
| **Git** | 2.x | バージョン管理 | 標準 |
| **GitHub**（private repo） | — | リモートリポジトリ、Issue管理 | 個人開発者の標準 |
| **Cloudflare Pages** | — | Web版の静的ホスティング | 既存 ReigalLabs インフラ流用、無料枠で十分 |
| **Google Play Console** | — | Android版配信 | 必須 |
| **Android Studio**（ビルドツール用） | 最新 LTS | Android Export に必要な SDK/NDK/JDK 提供 | Godot Export 要件 |
| **VS Code**（補助） | — | GDScript 編集補助、ドキュメント編集、コミット作成 | 任意 |
| **GitHub Actions**（任意） | — | Web版の自動エクスポート＆Cloudflare Pages デプロイ | MVP 中盤以降で導入判断 |

### ホスティング・配信

| 項目 | 技術 | 選定理由 |
|---|---|---|
| Web版ホスティング | Cloudflare Pages | 無料・高速・カスタムドメイン対応・`_headers` で COOP/COEP 設定可能 |
| Web版ドメイン | `brain.reigals.com`（サブドメイン） | 既存 ReigalLabs ドメイン流用 |
| Android版配信 | Google Play（日本向け） | 日本市場での主要配信チャネル |
| OGP 画像ホスト | Cloudflare Pages（`/ogp/` 配下の静的画像） | MVP では静的 PNG 1 枚で固定。v1.1 以降で Cloudflare Workers で動的生成 |

---

## アーキテクチャパターン

### 全体構造: サーバレス・シングルバイナリクライアント

ブレインゴースト は**バックエンドを持たない**。単一の Godot プロジェクトから Web/Android にエクスポートされ、すべてのロジックとデータがクライアント側で完結する。

```
┌──────────────────────────────────────────────────────────┐
│                        ユーザー                           │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│          UIレイヤー（scenes/ + scripts/ui/）              │
│   ホーム / ルール説明 / ゲーム / 結果 / 設定              │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│        ゲームコアレイヤー（scripts/games/）               │
│        base_game.gd + 6ゲームの具体実装                   │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│      Autoload / Singleton（scripts/autoload/）            │
│  game_manager · data_store · audio_service                │
│  ad_service · billing_service · platform                  │
│  （グローバルに常駐する状態管理と永続化・I/O の窓口）       │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│      サービスレイヤー（scripts/core/ — Autoload しない）   │
│  score_system · ghost_system · daily_seed                 │
│  streak_service · schema_migrator                         │
│  （純粋なビジネスロジック。インスタンス化してテスト可）     │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│          データモデル（scripts/models/）                   │
│  user_config · play_log · game_best · streak_state        │
│  ghost_data（純粋な型）                                    │
└──────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────┐
│                 プラットフォーム層                         │
│  ┌─────────────────┐       ┌────────────────────────┐     │
│  │ Web:            │       │ Android:               │     │
│  │  JavaScriptBridge│       │  user:// + AdMob       │     │
│  │  + localStorage  │       │  + Play Billing        │     │
│  └─────────────────┘       └────────────────────────┘     │
│  （scripts/autoload/platform.gd が分岐を集約する）          │
└──────────────────────────────────────────────────────────┘
```

**重要**: `GameManager` / `DataStore` / `AudioService` / `AdService` / `BillingService` / `Platform` は **Autoload（Singleton）** として登録され、`scripts/autoload/` に配置される。一方、`ScoreSystem` / `GhostSystem` / `DailySeed` / `StreakService` / `SchemaMigrator` はサービスレイヤー（`scripts/core/`）に置かれ、**Autoload しない**（ユニットテストでインスタンス化して使えるようにするため）。

### 各レイヤーの責務

#### UIレイヤー（`scenes/`, `scripts/ui/`）
- **責務**: 画面表示、入力受付、アニメーション、画面遷移
- **許可される操作**: サービスレイヤー呼び出し、シグナル受信・発火
- **禁止される操作**: `DataStore` への直接アクセス、ミニゲーム固有ロジックの内包、広告 SDK への直接呼び出し

#### ゲームコアレイヤー（`scripts/games/`）
- **責務**: ミニゲーム固有のロジック（問題生成、入力処理、スコア判定）
- **許可される操作**: `BaseGame` 基底クラスの拡張、`ScoreSystem` 呼び出し（スコア計算のため）、プレイログの蓄積
- **禁止される操作**: `DataStore` への直接書き込み（必ず `GameManager` 経由）、UIレイヤーへの直接依存

#### Autoload / Singleton（`scripts/autoload/`）
- **責務**: 全体状態管理（`GameManager`）、永続化の唯一の窓口（`DataStore`）、広告/課金/音声などの副作用を持つ外部サービスのラッパー、プラットフォーム分岐の集約（`Platform`）
- **許可される操作**: `scripts/core/` のサービス呼び出し、OS/プラグイン API への直接アクセス、シグナル発火
- **禁止される操作**: ミニゲームの具体ロジックの内包、UIレイヤーへの直接依存（通知はシグナル経由）

#### サービスレイヤー（`scripts/core/`）
- **責務**: 純粋なビジネスロジック（スコア計算、脳年齢、ゴースト生成、シード生成、ストリーク判定、スキーママイグレーション）
- **許可される操作**: `scripts/models/` の参照、`scripts/utils/` の呼び出し
- **禁止される操作**: UIレイヤーへの依存、Autoload への逆依存（`GameManager` や `DataStore` を呼ばない）、ミニゲーム固有ロジックの内包
- **データ永続化のルール**: `scripts/core/` のサービスは **`DataStore` を直接呼ばない**。`StreakService` は計算結果を返すだけで、保存は呼び出し元の Autoload（典型的には `GameManager` または UIコントローラ）が `DataStore.save()` を通じて行う。これにより、サービスは純粋関数に近い形でユニットテストできる
- **Autoload しない理由**: Autoload にするとシーンツリーが必須となりユニットテストで直接インスタンス化できない。`scripts/core/` はインスタンス化して注入する設計とする

#### データストアレイヤー（`scripts/core/data_store.gd`）
- **責務**: JSON シリアライズ/デシリアライズ、プラットフォーム分岐保存
- **許可される操作**: `FileAccess`, `JavaScriptBridge`
- **禁止される操作**: ビジネスロジックの実装（マイグレーションを除く）

#### プラットフォーム層
- **責務**: OS 固有機能（広告、課金、ストレージ）の提供と `OS.get_name()` による分岐
- **許可される操作**: OS/SDK 呼び出し
- **禁止される操作**: サービスレイヤーのロジックを直接呼び出すこと（常にサービスレイヤー経由でアクセスされる受動的役割）

### 依存方向の原則

**上位レイヤーは下位レイヤーを呼び出してよい。下位レイヤーは上位レイヤーを知らない。**

- UIレイヤーは Signal を通じてサービスレイヤーに通知を受ける（依存逆転）
- ゲームコアレイヤーは Signal で `GameManager` にプレイ結果を返す（`GameManager` がサービスレイヤーに流す）
- プラットフォーム層はポータビリティのため抽象インターフェース（`DataStore`, `AdService`, `BillingService`）で隠蔽する

### プラットフォーム分岐戦略

```gdscript
# シングルポイントオブトゥルース: scripts/core/platform.gd
class_name Platform
extends Node

enum Target { WEB, ANDROID, DESKTOP_DEBUG }

static func current() -> Target:
    match OS.get_name():
        "Web": return Target.WEB
        "Android": return Target.ANDROID
        _: return Target.DESKTOP_DEBUG  # Linux/Windows/macOS はエディタ実行時

static func supports_admob() -> bool:
    return current() == Target.ANDROID

static func supports_billing() -> bool:
    return current() == Target.ANDROID

static func supports_share_url() -> bool:
    return current() == Target.WEB

static func storage_strategy() -> String:
    return "localStorage" if current() == Target.WEB else "user_dir"
```

**原則**: `OS.get_name()` を散らさず、`Platform.gd` に集約する。これによりテスト時のプラットフォームモックが容易になる。

---

## データ永続化戦略

### ストレージ方式

| データ種別 | ストレージ（Web） | ストレージ（Android） | フォーマット | 理由 |
|---|---|---|---|---|
| UserConfig | `localStorage["brainghost_user_config"]` | `user://user_config.json` | JSON | 小容量・シンプルな key-value |
| PlayLogs | `localStorage["brainghost_play_logs"]` | `user://play_logs.json` | JSON | 時系列配列、最大 360 件 |
| GameBests | `localStorage["brainghost_game_bests"]` | `user://game_bests.json` | JSON | 6 件のみ |
| StreakState | `localStorage["brainghost_streak_state"]` | `user://streak_state.json` | JSON | 軽量、ハンコ日付配列含む |
| GhostCache | `localStorage["brainghost_ghost_cache"]` | `user://ghost_cache.json` | JSON | 再計算可能なキャッシュ |

**保存の粒度**: ファイル1つ = エンティティ1種類。ファイル境界を超える整合性はトランザクションではなく、**エンティティごとの全上書き**で保つ。

**保存タイミング**:
- プレイ完了直後に `PlayLogs` と `GameBests` と `StreakState` と `GhostCache` を一括保存（最悪でもこの4つの不整合は1プレイ分だけ）
- 設定変更時に `UserConfig` を即保存
- ホーム画面遷移時に軽量な整合性チェック（schemaVersion だけ）

### バックアップ戦略

MVP では**自動バックアップ機能を実装しない**。根拠:

- プレイログ自体は失われても「楽しい体験」には致命的ではない（スコアが1日分消えるだけ）
- ゴーストは PlayLog から再計算可能
- ストレージは `localStorage` / `user://` に限定されており、ユーザー自身がエクスポート要求する動機が MVP 段階で低い

**代わりに実装する保護策**:
- **原子的な保存**: `FileAccess.WRITE` で一時ファイルに書いてからリネーム（Android版）。`localStorage` は一回の `setItem` がアトミックなのでそのまま
- **JSON パースエラー耐性**: 読込失敗時は該当ファイルのみデフォルトに戻し、他のデータは残す
- **スキーマバージョン管理**: すべての JSON ファイルに `schemaVersion` を持ち、将来のマイグレーションパスを残す

**v1.2 以降で検討**: ユーザー手動エクスポート（JSONダウンロード）機能。クラウドセーブは v2.1（iOS対応）と併せて検討。

### ストレージ容量見積もり

| データ | 想定サイズ | 計算根拠 |
|---|---|---|
| UserConfig | 500 B | フィールド10個程度 |
| PlayLog 1 件 | 1 〜 3 KB | events 配列 30 〜 100 件 |
| PlayLogs 全体（上限 360 件） | 最大 ~1 MB | 3 KB × 360 |
| GameBests | 1 KB | 6 ゲーム × 数フィールド |
| StreakState | 1 〜 5 KB | stampedDates 配列が成長 |
| GhostCache | 50 KB | 6 ゲーム × averageEvents 配列 |
| **合計** | **最大 ~1.1 MB** | |

- `localStorage` の容量上限は通常 5〜10 MB（ブラウザ依存）。十分収まる
- Android の `user://` は実質無制限

---

## パフォーマンス要件

### レスポンスタイム

| 操作 | 目標時間 | 測定環境 |
|---|---|---|
| アプリ起動（スプラッシュ → ホーム） | ≤ 3 秒（Android）/ ≤ 5 秒（Web） | Android: Galaxy A シリーズ（ミドル機）/ Web: Chrome DevTools デバイスエミュレーション「Slow 4G」プリセット（1.6 Mbps下り / 750 kbps上り / 150ms RTT） |
| ホーム → ゲーム開始（カウントダウン含む） | ≤ 2 秒 | 同上 |
| ミニゲームのフレームレート | 60fps 維持 | プレイ中の全画面 |
| タップ反応時間計測精度 | ±16 ms 以内 | ゴースト7番勝負（反射速度計測） |
| PlayLog 保存 | ≤ 50 ms | 360 件上限時 |
| Web版の初回総アセットサイズ | ≤ 20 MB | Chrome DevTools Network タブで測定 |

### リソース使用量（Android版基準）

| リソース | 上限 | 理由 |
|---|---|---|
| メモリ（RAM） | ≤ 200 MB | Galaxy A シリーズのミドル機でも余裕を持つ |
| APK/AAB サイズ | ≤ 30 MB | Google Play の軽量アプリカテゴリ |
| ディスク使用量（インストール後） | ≤ 50 MB | 上記 + ユーザーデータ |
| CPU 使用率（プレイ中） | ≤ 25% | バッテリー消費抑制 |
| ネットワーク通信 | 0（オフライン完全動作）+ 広告読込時のみ | GDD §3 の要件 |

### パフォーマンス対策

- **シーンのプリロード**: `ResourceLoader.load_threaded_request()` でゲームシーンを事前ロード
- **オブジェクトプール**: タップ反応のターゲットやカードなど、頻繁に生成/破棄されるノードはプール化
- **GC 回避**: プレイ中は `Dictionary.new()` / `Array.new()` の毎フレーム生成を避け、既存オブジェクトを再利用
- **テクスチャアトラス**: 小さな画像アセットは 1 枚のアトラスに統合、ドローコール削減
- **Web版の gzip 圧縮**: Cloudflare Pages が自動適用、`.wasm` ファイルが特に圧縮効果大
- **ログの剪定**: PlayLog は 360 件上限、古いものから削除

---

## セキュリティアーキテクチャ

### データ保護

| 項目 | 方針 |
|---|---|
| **暗号化** | MVP では実施しない。理由: 保存データに個人情報を含まず、改ざんされても実害が限定的（ローカルスコアのみ）。課金状態は Google Play 標準フローに従うため独自暗号化不要 |
| **アクセス制御** | Android の `user://` は OS レベルでアプリ専用。Web の `localStorage` はオリジン分離により他ドメインからアクセス不可 |
| **機密情報管理** | AdMob の本番 Unit ID はリポジトリに含めない運用とする。詳細は下記「AdMob Unit ID の管理フロー」参照 |
| **課金状態の信頼源** | `user_config.json` の `hasPurchasedAdFree` はあくまで**キャッシュ**扱いとする。**信頼源は Google Play Billing の `queryPurchasesAsync()`** であり、アプリ起動時・フォアグラウンド復帰時・広告表示直前に毎回照合する。照合結果をローカルキャッシュと比較し、差分があればキャッシュを上書きする（root 端末での改ざん対策） |

#### AdMob Unit ID の管理フロー

- **開発・テストビルド**: `project.godot` の `config/admob/test_unit_id` に Google 提供の**テスト用 Unit ID**（公開可）を記載。Git リポジトリに含めて良い
- **本番ビルド**: 本番 Unit ID は `export_presets.cfg.local`（`.gitignore` 対象）または CI 環境変数経由で注入する
- **切り替え**: `ad_service.gd` 起動時に `OS.is_debug_build()` と `Engine.is_editor_hint()` を使って自動判定。本番ビルド時のみ本番 ID を読み込む
- **キーストア等の秘匿情報**: `android/release.keystore`、パスフレーズ、本番 Unit ID、プライバシーポリシーの未公開 URL はすべて Git 管理外

### 入力検証

| 項目 | 方針 |
|---|---|
| **ユーザー入力** | ゲーム内のタップのみ。テキスト入力欄は MVP に存在しない |
| **URL パラメータ（Web版シェアURL）** | `d` は正規表現 `^\d{8}$` と実在日付チェック、`s` は整数範囲チェック。不正な値はホームにリダイレクト |
| **ファイル読込**（JSON） | `JSON.parse_string()` の失敗時は初期化処理へ。型不一致は各フィールドの個別検証で防ぐ |
| **スキーマバージョン** | 未知のバージョンは未来バージョン扱いで警告表示 → 安全にフォールバック |

### プライバシー

| 項目 | 対応 |
|---|---|
| **個人情報収集** | 実施しない（ユーザー名・メール・位置情報等） |
| **プライバシーポリシー** | ReigalLabs 名義で事前準備し、アプリ内 [設定] → [プライバシーポリシー] からリンク。ストアページにも掲載 |
| **AdMob 広告識別子** | Google の標準フローに従う。13 歳未満向け広告を無効化（COPPA 対応） |
| **Cookie / トラッキング** | Web版では Cloudflare Web Analytics のみ（クッキーレス）。AdSense 非承認中は広告トラッキングなし |
| **年齢確認** | ストアのコンテンツレーティングで対応（実装レベルでは年齢ゲートを設けない） |

### ネットワーク通信

- **MVP ではアプリ本体のネットワーク通信はゼロ**（オフライン完全対応）
- 広告配信時のみ AdMob が通信する（ユーザーが広告非表示購入済みなら通信もゼロ）
- Web版のアセット配信は Cloudflare Pages の HTTPS のみ
- 将来（v1.1）に Firebase Analytics を追加する際は、HTTPS 通信のみ、匿名ID のみ送信とする

### Web版の COOP/COEP 要件

Godot 4 の WebAssembly は `SharedArrayBuffer` を使うため、Web版はクロスオリジン分離が必須。

```
# brain.reigals.com/_headers
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Resource-Policy: same-origin
```

これを怠ると起動時にクラッシュする。デプロイ時の QA で必ず確認する。

---

## スケーラビリティ設計

### データ増加への対応

**想定データ量**:
- 1 ユーザーあたり年間プレイ数: 約 1,000 回（デイリー3種 × 365日 / 少し余裕）
- 実際の保存上限: PlayLog 360 件（直近 60 日分程度）

**パフォーマンス劣化対策**:
- PlayLog の剪定（60 件/ゲーム = 360 件）を `DataStore.save()` 内で自動実行
- GhostCache は新 PlayLog 保存時にインクリメンタル更新（全再計算しない）
- `stampedDates` は年が変わるたびに古い年分を圧縮（カレンダーUIの表示期間だけ保持）

**アーカイブ戦略**:
- MVP では実装しない（剪定で十分）
- v1.2 以降で「プレイ履歴エクスポート」を実装し、ユーザーが手動でバックアップ可能にする

### 機能拡張性

**ミニゲーム追加（v1.1 で +3 種）**:
- 新ゲームは `scripts/games/` に追加し `BaseGame` を継承するだけ
- `ScoreSystem.GAME_TO_ABILITY` に能力軸マッピングを追加
- `DailySeed.ALL_GAMES` に追加
- **レーダーチャートの能力軸は 6 つで固定**（新ゲームは既存軸にマッピング）
- 精度計算 `プレイ済み / 全種目数` は自動で 9 種対応

**言語追加（v2.0 英語対応）**:
- ゲーム自体は言語非依存のため、UI のみローカライズ必要
- Godot 標準の翻訳リソース（`.po` / `.csv`）を使用
- 翻訳対象: 画面テキスト・通知・ストア表記

**iOS 対応（v2.1）**:
- Godot の iOS エクスポートで基本的に動く
- 広告は AdMob iOS SDK（Godot プラグイン）に差し替え
- 課金は StoreKit（Godot プラグイン）に差し替え
- `Platform.gd` に `IOS` ケースを追加

**サーバ機能追加（v2.x）**:
- 現行はサーバレス。将来ランキング実装時は Firebase Firestore か Cloudflare D1 を検討
- シェアURL は既にサーバレスで機能している（URL パラメータのみ）ため、サーバ無しで拡張可能

### 設定のカスタマイズ

- MVP で外部設定可能な項目: `project.godot` の `config/features`、`export_presets.cfg` の Build Path / AdMob Unit ID
- ユーザーによるカスタマイズは「年代選択」「BGM/SE オンオフ」のみ
- 実験的な A/B 設定は MVP では持たない（リモートコンフィグは v1.3 で検討）

---

## テスト戦略

### ユニットテスト

- **フレームワーク**: **Godot GUT**（Godot Unit Test）
- **配置場所**: `tests/unit/`
- **対象**:
  - `ScoreSystem.calculate_score()` — 各ゲーム3ケース（境界含む）
  - `ScoreSystem.calculate_brain_age()` — 5年代 × 3スコア段階
  - `DailySeed` — 日付シードの決定性、月末・年末境界
  - `GhostSystem` — 4件時の `isReady=false`、5件時の平均化、勝敗判定
  - `StreakState` 更新ロジック — 0/1/2-7/8日以上の全分岐（FR-09 キャッチアップ仕様の回帰防止）
  - `DataStore` — JSON パースエラー時のフォールバック、スキーママイグレーション
- **カバレッジ目標**: サービスレイヤー（`scripts/core/`）の **70%**。UI レイヤーはユニットテスト対象外

### 統合テスト

- **方法**: Godot シーンテスト。`tests/integration/` に `.tscn` シナリオを配置し、GUT でシーンを起動して順序実行
- **対象シナリオ**:
  - IT-01: 初回オンボーディング → PlayLog 永続化
  - IT-02: 同一日のデイリーチャレンジ 2 回開始 → 2 回目も起動可能
  - IT-03: 5 件未満のゲームでゴーストバー非表示
  - IT-04: 5 件ちょうどでゴーストバー表示
  - IT-05: 広告非表示購入後に広告ノード生成なし
  - IT-06: Web版 localStorage クリア → デフォルト値で起動
  - IT-07: スキーマ v1 → v2 の模擬マイグレーション

### E2E テスト

- **Android**: 実機（Galaxy A / Pixel / Xperia ミドル）でテストシナリオを手動実行
  - E2E-01: 初回オンボーディング完走
  - E2E-02: デイリーチャレンジ完走 + 広告表示（3回に1回）
  - E2E-03: 広告非表示買い切り購入 → 再起動後の復元
  - E2E-06: クラッシュ率・FPS 確認
  - E2E-07: ストリーク境界テスト（端末時刻操作 7/8 日）
- **Web版**: Chrome モバイル + Chrome DevTools デバイスモードで実施
  - E2E-04: シェアURL経由プレイ → 比較表示
  - E2E-05: 音声の自動再生制限回避確認
- **自動化**: MVP ではしない。v1.1 で検討

### パフォーマンステスト

- プレイ中 FPS を Godot の Monitor または Chrome DevTools Performance タブで測定
- Web版のロード時間: Chrome DevTools Network タブ + Lighthouse（Performance 80+ を目標）
- 360 件 PlayLog 状態での保存時間を Godot プロファイラで測定

### QA チェックリスト（MVP リリース前）

- [ ] 全 6 種ゲームが 3 回連続で完走できる（クラッシュなし）
- [ ] 広告非表示購入が Android 実機で機能する
- [ ] Web版の COOP/COEP ヘッダーが Cloudflare Pages に反映されている
- [ ] 初回起動から 30 秒以内に 1 種目開始できる
- [ ] デイリー 3 種完走まで 2 分 ± 30 秒
- [ ] ゴーストバーが 4 回目までは非表示、5 回目から表示される
- [ ] ストリーク 7 日空け → 維持、8 日空け → リセット
- [ ] 負けの画面でどこにも赤色が使われていない
- [ ] プライバシーポリシーが設定画面からリンクされている

---

## 技術的制約

### 環境要件

| 項目 | 要件 |
|---|---|
| **対応 OS（Android）** | Android 8.0（API 26）以降 |
| **対応 OS（Web）** | Chrome 90+, Safari 15+, Firefox 90+ |
| **最小 RAM** | 2 GB（Android） |
| **必要ディスク容量** | 50 MB（Android インストール後） |
| **ネットワーク** | 不要（広告配信時のみ、任意） |
| **画面解像度** | 縦持ち 9:16 を基準、16:9 および 9:20 にも対応 |
| **タッチ要件** | シングルタップ操作のみ（マルチタッチ不要） |

### パフォーマンス制約

- プレイ中は 60fps 維持が必須（反応速度ゲームの公正性のため）
- 入力レイテンシ ≤ 16ms（ゴースト7番勝負の計測精度担保）
- Web版の総アセットサイズ ≤ 20 MB（モバイル回線でのロード時間を許容範囲に）
- Android アプリサイズ ≤ 30 MB（軽量アプリカテゴリ維持）
- 起動時間は Galaxy A シリーズで 3 秒以内

### セキュリティ制約

- 個人情報を一切収集しない（ユーザー名・メール・位置情報・年齢の生データ）
- 13 歳未満への広告は AdMob 設定で無効化（COPPA）
- プライバシーポリシーを ReigalLabs 名義で事前準備・ストア掲載必須
- Web版の COOP/COEP ヘッダー設定が必須（設定ミスでアプリが起動不能になる）
- Google Play のターゲット API レベル要件に追従（毎年更新が必須）

### Godot 特有の制約

- **Web版の SharedArrayBuffer 要件**: COOP/COEP ヘッダー必須
- **Web版の音声自動再生制限**: 最初のユーザータップで `AudioServer` を明示的に有効化する。`AudioService` Autoload に初期化フラグを持ち、最初のタップ入力でバスのミュート解除を行う

    ```gdscript
    # scripts/autoload/audio_service.gd の要点
    extends Node

    var _initialized: bool = false

    func _unhandled_input(event: InputEvent) -> void:
        if _initialized:
            return
        if event is InputEventScreenTouch or event is InputEventMouseButton:
            if event.is_pressed():
                _initialize()

    func _initialize() -> void:
        _initialized = true
        # Master バスのミュートを外し、以降の再生を可能にする
        AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
    ```

- **Godot 4.x のモバイル広告プラグイン**: バージョン互換性に注意。Godot バージョンアップ時は AdMob プラグインも検証
- **GDScript の型付け**: 可能な限り静的型付けを使用（パフォーマンスとエラー検出のため）

### 法務・ストア制約

- Google Play のコンテンツレーティング: 全年齢向け（脳トレジャンル）
- 特商法表記: ReigalLabs 名義の既存サイトに準拠
- 脳年齢表示は**エンターテインメント目的**の注記必須（医学的効果を謳わない）
- 免責事項をプライバシーポリシーまたはヘルプに記載

---

## 依存関係管理

| ライブラリ/プラグイン | 用途 | バージョン管理方針 |
|---|---|---|
| **Godot Engine** | ランタイム | 固定（`project.godot` と `.godot-version` ファイルに記載）。バージョンアップは独立 PR |
| **godot-admob-plugin** | Android版広告 | 固定。GitHub のコミットハッシュで指定して `addons/admob/` に配置 |
| **Google Play Billing** | Android版課金 | 固定（Godot プラグイン同梱バージョン） |
| **Godot GUT** | テストフレームワーク | 固定。`addons/gut/` に配置 |
| **フリー素材（フォント・効果音・アイコン）** | アセット | ライセンスを `assets/CREDITS.md` に明記。差し替え時は該当箇所のみ更新 |
| **Node.js スクリプト（あれば）** | デプロイ補助 | `package-lock.json` で固定 |

### 更新ポリシー

- **セキュリティアップデート**: Godot Engine は公式アナウンスを監視し、セキュリティパッチは 1 週間以内に取り込む
- **マイナーアップデート**: 独立 PR で取り込み、全 E2E シナリオを回してからマージ
- **メジャーアップデート**: 安定化まで 1 ヶ月以上待ってから検討（互換性破壊の可能性）
- **AdMob プラグイン**: Godot バージョンとの互換性確認後に更新
- **依存追加のハードル**: MVP では **新規依存の追加に必ずユーザー承認を得る**。GDScript 標準で書けるものは自前実装を優先
