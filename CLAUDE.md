# プロジェクトメモリ

## プロジェクト概要

**Brain Boost** — ミニゲーム詰め合わせ型の脳トレアプリ
- コンセプト: 「毎日2分、昨日の自分に挑め」
- 開発者名義: ねこぽ / ReigalLabs
- GDD: `docs/gdd.md`（設計判断の根拠はすべてここにある。実装前に必ず該当セクションを読むこと）

## 技術スタック

- **エンジン**: Godot 4（GDScript）
- **ターゲット**: Web版（HTML5）+ Android版の同時エクスポート
- **Web版ホスト**: Cloudflare Pages（brain.reigals.com）
- **Android版広告**: AdMob（godot-admob-plugin / godot-sdk-integrations版）
- **Android版課金**: 広告非表示の買い切り（¥300〜500）
- **データ保存**: ローカルJSON（Web: localStorage / Android: user://）
- **アート**: フリー素材 + Godot UIテーマ

## 仕様駆動開発の基本原則

### 基本フロー

1. **ドキュメント作成**: 永続ドキュメント(`docs/`)で「何を作るか」を定義
2. **作業計画**: ステアリングファイル(`.steering/`)で「今回何をするか」を計画
3. **実装**: tasklist.mdに従って実装し、進捗を随時更新
4. **検証**: テストと動作確認
5. **更新**: 必要に応じてドキュメント更新

### 重要なルール

#### ドキュメント作成時

**1ファイルずつ作成し、必ずユーザーの承認を得てから次に進む**

承認待ちの際は、明確に伝える:
```
「[ドキュメント名]の作成が完了しました。内容を確認してください。
承認いただけたら次のドキュメントに進みます。」
```

#### 実装前の確認

新しい実装を始める前に、必ず以下を確認:

1. CLAUDE.mdを読む
2. 関連する永続ドキュメント(`docs/`)を読む
3. Grepで既存の類似実装を検索
4. 既存パターンを理解してから実装開始

#### ステアリングファイル管理

作業ごとに `.steering/[YYYYMMDD]-[タスク名]/` を作成:

- `requirements.md`: 今回の要求内容
- `design.md`: 実装アプローチ
- `tasklist.md`: 具体的なタスクリスト

命名規則: `20260410-反射タップ実装` 形式（日本語OK）

#### ステアリングファイルの管理

**作業計画・実装・検証時は`steering`スキルを使用してください。**

- **作業計画時**: `Skill('steering')`でモード1(ステアリングファイル作成)
- **実装時**: `Skill('steering')`でモード2(実装とtasklist.md更新管理)
- **検証時**: `Skill('steering')`でモード3(振り返り)

## ディレクトリ構造

### Godotプロジェクト構造（想定）

```
brain-boost/
├── CLAUDE.md                    # このファイル
├── docs/
│   ├── gdd.md                   # GDD v1.0（設計の北極星）
│   ├── product-requirements.md  # PRD（GDDから抽出）
│   ├── functional-design.md     # 機能設計書
│   ├── architecture.md          # 技術仕様書
│   ├── repository-structure.md  # リポジトリ構造定義書
│   ├── development-guidelines.md # 開発ガイドライン
│   └── glossary.md              # ユビキタス言語定義
├── .steering/                   # 作業単位のドキュメント
├── project.godot                # Godotプロジェクト設定
├── export_presets.cfg           # Web/Androidエクスポート設定
├── scenes/
│   ├── main/
│   │   ├── home.tscn            # ホーム画面
│   │   ├── onboarding.tscn      # 初回オンボーディング
│   │   └── result.tscn          # 総合結果画面
│   ├── games/
│   │   ├── reflex_tap.tscn      # 反射タップ
│   │   ├── flash_calc.tscn      # フラッシュ暗算
│   │   ├── number_search.tscn   # 数字さがし
│   │   ├── stroop.tscn          # ストループ
│   │   ├── sequence_memory.tscn # 順番記憶
│   │   └── card_match.tscn      # 神経衰弱
│   ├── ui/
│   │   ├── rule_explain.tscn    # ルール説明画面
│   │   ├── game_result.tscn     # 個別結果画面
│   │   └── ghost_bar.tscn       # ゴーストインジケーター
│   └── shared/
│       └── countdown.tscn       # カウントダウン演出
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd      # ゲーム全体の状態管理
│   │   ├── score_system.gd      # スコア算出・脳年齢変換
│   │   ├── ghost_system.gd      # ゴースト対戦（直近5回平均）
│   │   ├── daily_seed.gd        # 日付シード生成
│   │   └── data_store.gd        # データ保存（Web/Android分岐）
│   ├── games/
│   │   ├── base_game.gd         # ミニゲーム基底クラス
│   │   ├── reflex_tap.gd
│   │   ├── flash_calc.gd
│   │   ├── number_search.gd
│   │   ├── stroop.gd
│   │   ├── sequence_memory.gd
│   │   └── card_match.gd
│   └── ui/
│       ├── home_screen.gd
│       ├── onboarding.gd
│       ├── result_screen.gd
│       └── share_url.gd         # シェアURL生成
├── assets/
│   ├── fonts/
│   ├── sounds/
│   ├── icons/
│   └── themes/
├── addons/
│   └── admob/                   # AdMobプラグイン（Android版のみ）
└── web/
    ├── _headers                 # Cloudflare Pages COOP/COEP設定
    └── ogp/                     # OGPテンプレート
```

### 永続的ドキュメント(`docs/`)

| ファイル | 内容 | GDDとの対応 |
|---------|------|-----------|
| gdd.md | GDD v1.0原文 | 全体 |
| product-requirements.md | プロダクト要求定義 | GDD §1-2（コンセプト・ペルソナ） |
| functional-design.md | 機能設計 | GDD §4-6（ゲーム・UX・スコアリング） |
| architecture.md | 技術仕様 | GDD §3（プラットフォーム・技術スタック） |
| repository-structure.md | リポジトリ構造 | 上記のディレクトリ構造 |
| development-guidelines.md | 開発ガイドライン | GDD §10（スケジュール）+ Godot規約 |
| glossary.md | 用語定義 | GDD全体から抽出 |

### 作業単位のドキュメント(`.steering/`)

- `requirements.md`: 今回の作業の要求内容
- `design.md`: 変更内容の設計
- `tasklist.md`: タスクリスト

## ドメイン知識（実装時の判断基準）

### ペルソナ（設計判断で迷ったらここを見る）

**ペルソナ1: セルフチャレンジャー（自己改善型）** — DAUと収益の主軸
- 毎朝通勤で2分プレイ。ゴースト対戦・スコア前回比に反応
- **設計判断で迷ったらこちらを優先**

**ペルソナ2: ライトコンペティター（社交型）** — バイラル拡散の手段
- シェアURL経由で流入。結果は必ずシェア。毎日はやらない

### 独自要素（競合にゼロ。差別化の根幹）

1. **ゴースト対戦**: 「いつもの自分」（直近5回平均）と対戦。タイム系ゲームはプレイ中プログレスバー表示、クリア系は結果画面でタイム比較
2. **デイリーチャレンジ共通化**: 日付シードで全ユーザー同一問題（Wordle方式）。`get_daily_seed()`関数
3. **Web版シェアURL**: `brain.reigals.com/daily?d=YYYYMMDD&s=スコア` でOGPカード対応

### 絶対に守るルール

- **ゲームプレイ中は絶対に広告を表示しない**
- **ゲーム間に広告を挟まない**
- **負けてもネガティブ色（赤）は使わない**（勝ち=緑/金、負け=グレー）
- **操作はタップのみ**（マルチタッチ・スワイプ不可）
- **全ゲーム言語非依存**（知識問題・語彙問題は入れない）
- **脳年齢は「エンターテインメント目的」。医学的効果を謳わない**

### スコアリング

| ゲーム | 計算式イメージ |
|--------|-------------|
| フラッシュ暗算 | 正答1問=100点 + 残り秒数×10 |
| 順番記憶 | N段クリア = N×150点 |
| ストループ | 正答1問=100点 − 誤答1回=50点 |
| 反射タップ | (1000 / 平均ms) × 300 |
| 神経衰弱 | (ペア数 / 総タップ数) × 1000 + 時間ボーナス |
| 数字さがし | max(0, 3000 − クリア秒数×100) |

### 脳年齢チューニング

- 初回は実年齢 -3〜5歳（やや甘め）
- 最低でも実年齢 +10歳キャップ
- スコアが上がれば若返る

### 精度システム

```
精度 = プレイ済み種目数 / 全種目数 × 100%
```
- 精度100%（全種プレイ済）でゴースト対戦・レーダーチャート・正式脳年齢が解放
- 新ゲーム追加時は精度が自動低下（6/9=67%）→ 新ゲームプレイの動機

### レーダーチャート能力軸（6つ固定。ゲーム追加時も増やさない）

| 能力軸 | MVPゲーム | 追加枠 |
|--------|----------|--------|
| 計算力 | フラッシュ暗算 | — |
| 記憶力 | 順番記憶 | 瞬間記憶 |
| 注意力 | ストループ | — |
| 反射速度 | 反射タップ | — |
| 観察力 | 数字さがし | — |
| 判断力 | 神経衰弱 | 推理、空間認知 |

## プラットフォーム分岐

### Web版 vs Android版

```gdscript
# プラットフォーム判定パターン
if OS.get_name() == "Web":
    # localStorage経由で保存
    # 広告なし
    # シェアURL生成可能
elif OS.get_name() == "Android":
    # user:// にJSON保存
    # AdMob表示
    # 買い切り課金あり
```

### Web版の技術的注意

- SharedArrayBuffer必須 → COOP/COEP HTTPSヘッダー設定
- 音声の自動再生制限 → ユーザーインタラクション後にAudioServer初期化
- AdMobはWeb版では使えない（ネイティブプラグイン）

## 開発プロセス

### 初回セットアップ

1. このCLAUDE.mdとdocs/gdd.mdをリポジトリに配置
2. `/setup-project` で永続的ドキュメント作成（GDDから抽出して6つ作成）
3. `.steering/20260410-環境構築/` でGodot環境セットアップ
4. Week 1のタスクから `/add-feature` で実装開始

### 日常的な使い方

```bash
# ドキュメントの編集
> PRDにペルソナの補足情報を追加して
> architecture.mdのデータ保存方式を見直して

# 機能追加（定型フロー）
> /add-feature 反射タップゲーム
> /add-feature ゴースト対戦システム
> /add-feature シェアURL生成

# レビュー
> /review-docs docs/functional-design.md
```

### ミニゲーム実装パターン

新しいミニゲームを追加する際の標準フロー:

1. `scripts/games/base_game.gd` の基底クラスを継承
2. GDDのセクション4（ミニゲーム設計）を参照して仕様確認
3. シーン（.tscn）+ スクリプト（.gd）をペアで作成
4. `score_system.gd` にスコア算出ロジックを追加
5. `ghost_system.gd` にゴースト対応（タイム系 or クリア系）を追加
6. `daily_seed.gd` のパラメトリック生成に対応
7. ルール説明画面のデータを追加
8. レーダーチャートの能力軸にマッピング

## ドキュメント管理の原則

### 永続的ドキュメント(`docs/`)

- GDDが「北極星」。設計判断の根拠はすべてGDDに帰着する
- GDDの内容を正式ドキュメント6つに分解して管理
- 頻繁に更新されない

### 作業単位のドキュメント(`.steering/`)

- 特定の作業に特化
- 作業ごとに新規作成
- 履歴として保持
