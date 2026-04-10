# 設計書 — GUT プラグイン配置とユニットテスト実行環境整備

## アーキテクチャ概要

GUT は Godot のエディタプラグインとして `addons/gut/` に配置するサードパーティ製品。今回は「配置 + 有効化 + 実行確認」の 3 ステップに分解する。独自コードは最小限（shell ラッパーのみ）。

```
[開発者/CI]
      │
      │  ./scripts_build/run_unit_tests.sh
      ▼
[Godot CLI]  godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
      │
      ▼
[GUT runner] addons/gut/gut_cmdln.gd
      │
      ▼
[テスト群]  tests/unit/core/*.gd, tests/unit/utils/*.gd
      │
      ▼  各テストは res://scripts/core/*.gd, res://scripts/utils/*.gd を直接 import
[テスト対象] scripts/core/, scripts/utils/
```

## コンポーネント設計

### 1. GUT プラグイン本体（`addons/gut/`）

**責務**:
- テストフレームワーク提供（`test.gd`, `gut.gd`）
- CLI ランナー提供（`gut_cmdln.gd`）
- 結果レポート出力（xml / json / stdout）

**実装の要点**:
- **取得元**: GitHub `bitwes/Gut` の releases から Godot 4 系対応タグ（`v9.x.x`）のソースを取得
- **配置**: zip をダウンロードして `addons/gut/` に展開。ディレクトリ構造は変えない
- **バージョン固定**: `addons/gut/VERSION.txt` または同等のファイルでバージョンを記録し、Git にコミット（再現性確保）
- **ネットワーク前提**: サンドボックス内からの取得。取れない場合は手段を切り替える（後述）
- **バージョン選定**: Godot 4.6.2 環境なので、4.x 系互換と明示されている最新の安定版を選ぶ

**代替取得手段**（GitHub アクセス不可時）:
- `wget https://github.com/bitwes/Gut/archive/refs/tags/v9.x.x.tar.gz`
- `curl -LO https://github.com/bitwes/Gut/releases/download/v9.x.x/Gut-9.x.x.zip`
- どちらも失敗したらユーザーに手動ダウンロードを依頼する

### 2. プロジェクト設定（`project.godot`）

**責務**:
- GUT プラグインをエディタプラグインとして登録
- Autoload の順序や入力マップは環境構築タスクで決定済みのものを維持

**実装の要点**:
- `[editor_plugins]` セクションを追加（既存の `project.godot` には存在しない）
- 値: `enabled=PackedStringArray("res://addons/gut/plugin.cfg")`
- **破壊的変更ではない**: Autoload 定義や display 設定は一切触らない
- GUT プラグインは「エディタ拡張」だが、CLI 実行時にも `plugin.cfg` が登録されていることが期待される（class_name 登録のため）

### 3. 実行ラッパー（`scripts_build/run_unit_tests.sh`）

**責務**:
- GUT の CLI 起動オプションを一箇所に固める
- CI と手元で同じコマンドが使える

**実装の要点**:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec godot --headless \
  -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit \
  -gexit \
  "$@"
```
- `-gexit` で全テスト完了後に自動終了（これがないと CLI がぶら下がる）
- `-gdir` でテストディレクトリを明示
- `$@` で呼び出し側から追加引数（例: `-gtest=res://tests/unit/core/test_daily_seed.gd`）を渡せる
- **実行権限**: `chmod +x` 必須

### 4. `.godot/` キャッシュ再生成

**責務**:
- GUT の `class_name` 登録（`GutTest` など）をグローバルキャッシュに反映

**実装の要点**:
- 前回タスクで学んだ通り、Godot 4 の `class_name` は初回エディタスキャンが必要
- `godot --headless --editor --quit-after 60` を一度走らせて、`.godot/global_script_class_cache.cfg` を更新する
- サンドボックスでは `.godot/` の所有権問題が再発する可能性あり → 必要に応じて `sudo chown -R $(id -u):$(id -g) .godot/` で解消

## データフロー

### GUT CLI 実行フロー

```
1. 開発者が ./scripts_build/run_unit_tests.sh を実行
2. shell が godot --headless -s gut_cmdln.gd -gdir=res://tests/unit -gexit を起動
3. Godot が project.godot を読み込み、Autoload を初期化（Platform → DataStore → ...）
4. gut_cmdln.gd が res://tests/unit を再帰スキャン
5. マッチしたファイル（test_*.gd）をロードしてテストメソッドを実行
6. 各テストで scripts/core/*.gd, scripts/utils/*.gd を new() してアサート
7. GUT が結果をサマリ出力（passed/failed/errors）
8. -gexit により Godot プロセスが終了コード（fail 数）で exit
9. shell が終了コードをそのまま返す
```

## エラーハンドリング戦略

### 想定されるエラーとその対処

| 症状 | 原因 | 対処 |
|---|---|---|
| `res://addons/gut/test.gd` が見つからない | プラグイン未展開 | zip 展開手順の確認、ファイル一覧の検証 |
| `GutTest` のクラスが見つからない | `.godot` キャッシュ未更新 | `godot --headless --editor --quit-after` で再スキャン |
| テストがパスしない | テスト側の記述ミス（前回タスクで未検証） | テストファイルを読み、実装と照合して修正 |
| CLI が終了しない | `-gexit` 未指定 | 実行コマンドを再確認 |
| `.godot/` への書き込み権限エラー | サンドボックスの root 所有 | `sudo chown -R` で解消 |
| `editor_plugins` 登録で警告 | プラグイン内部のシーン依存 | 通常は無視できる。エラーなら個別に対処 |

### GUT 取得失敗時のフォールバック

1. GitHub に HTTPS で到達できない → `git clone https://github.com/bitwes/Gut.git --depth=1 --branch=v9.x.x` を試す
2. `git clone` も不可 → ユーザーに「GUT v9.x.x の zip を手動配置してほしい」と伝えて作業を停止し、ステアリング計画に記録

## テスト戦略

### このタスク自体の検証

1. **配置確認**: `ls addons/gut/` で `plugin.cfg`, `gut.gd`, `test.gd`, `gut_cmdln.gd` の存在を確認
2. **起動確認**: `godot --headless --quit` がエラーなく終わる
3. **プラグイン認識**: `.godot/global_script_class_cache.cfg` に `GutTest` が入っている
4. **テスト実行**: `./scripts_build/run_unit_tests.sh` で全パス
5. **既存スモークテスト**: `godot --headless -s res://tools/smoke_test.gd` が依然 54/54 パス（リグレッション検知）
6. **個別実行**: `./scripts_build/run_unit_tests.sh -gtest=res://tests/unit/core/test_daily_seed.gd` で単体実行できる

### テスト失敗時の優先順位

既存 4 テストのうち実装ミスで失敗するものがあった場合、以下の順で対処:

1. **テスト側のロジックエラー**（assert の引数ミス、型不一致） → テストファイルを修正
2. **実装側のバグ** → バグを発見できたのはラッキー。実装ファイルを修正し、理由を振り返りに記録
3. **GUT の API 仕様差異** → v9.x 系の新旧で `assert_eq` の挙動が違う可能性あり。GUT のドキュメントを確認

## 依存ライブラリ

```
新規: addons/gut/ (GUT v9.x, MIT License)
  - ソース: https://github.com/bitwes/Gut
  - Godot 4.x 対応版
```

## ディレクトリ構造

```
brain-boost/
├── addons/
│   └── gut/                      # 新規（展開後）
│       ├── plugin.cfg
│       ├── gut.gd
│       ├── test.gd
│       ├── gut_cmdln.gd
│       ├── VERSION.txt           # 追加（バージョン固定のため）
│       └── ...
├── project.godot                 # 編集（[editor_plugins] セクション追加）
├── scripts_build/
│   └── run_unit_tests.sh         # 新規
├── README.md                     # 編集（テスト実行セクション追記）
└── tests/unit/                   # 既存（触らない）
    ├── core/
    │   ├── test_daily_seed.gd
    │   ├── test_streak_service.gd
    │   └── test_score_system.gd
    └── utils/
        └── test_date_util.gd
```

## 実装の順序

1. **GUT プラグインの取得と配置**: GitHub から zip を取得 → `addons/gut/` に展開 → バージョン記録
2. **project.godot 編集**: `[editor_plugins]` セクション追加
3. **`.godot/` キャッシュ再生成**: エディタスキャンを一度走らせる
4. **テスト実行**: まず `gut_cmdln.gd` を直接叩いて動作確認
5. **既存テストの修正**: 失敗があれば個別に対処
6. **shell ラッパー作成**: `scripts_build/run_unit_tests.sh`
7. **既存スモークテストの確認**: `tools/smoke_test.gd` がまだ通るか
8. **README 追記**: テスト実行手順
9. **最終検証**: 受け入れ条件を上から順に確認

## セキュリティ考慮事項

- **GUT ソースの信頼性**: `bitwes/Gut` は MIT License、スター 900+ の著名リポジトリ。commit hash ではなく release タグで固定することで改ざんリスクを下げる
- **サンドボックスの権限昇格**: `sudo chown` を使う場面があるが、`.godot/` 以下に限定し、他のディレクトリに影響させない
- **ネットワーク取得**: HTTPS 経由のみ。GitHub 以外のミラーは使わない

## パフォーマンス考慮事項

- GUT 起動は Godot プロセス起動 + スクリプトロードで数秒かかる。これは許容する
- テスト並列実行は GUT v9 系では未サポート。MVP のテスト数なら逐次実行で十分
- `.godot/` キャッシュはコミットしない（`.gitignore` で除外済み）

## 将来の拡張性

- **CI 統合**: `scripts_build/run_unit_tests.sh` を `.github/workflows/test.yml` から呼ぶだけで PR チェックに使える
- **統合テスト**: `tests/integration/` に追加する際も同じ `-gdir` で拾える（`-gdir=res://tests` に変更するだけ）
- **GUT バージョンアップ**: `addons/gut/VERSION.txt` を更新 → zip 差し替え → テスト実行、の流れ
- **カバレッジ**: 将来 `gdscript-coverage`（サードパーティ）が成熟したら導入を検討
