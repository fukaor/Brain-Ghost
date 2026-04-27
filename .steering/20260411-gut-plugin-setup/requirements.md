# 要求内容 — GUT プラグイン配置とユニットテスト実行環境整備

## 概要

Godot Unit Test（GUT）プラグインを `addons/gut/` に配置し、既存の `tests/unit/**` にある GUT 形式テストを CLI から実行できる状態を作る。環境構築フェーズ（`20260410-環境構築`）で作成済みのテストが「配置すれば走る」状態にあることを確認する。

## 背景

前回の環境構築タスクで `tests/unit/core/test_daily_seed.gd` / `test_streak_service.gd` / `test_score_system.gd` / `tests/unit/utils/test_date_util.gd` を GUT 形式（`extends "res://addons/gut/test.gd"`）で作成済み。しかし GUT プラグイン本体は未配置のため、現在は `tools/smoke_test.gd` による自前スモークテスト（54 ケース）しか動かせない。

Week 1 の反射タップ実装以降、各ミニゲームのスコア計算・ゴースト対戦ロジックに対するユニットテストが増え続けるため、**このタイミングで GUT 実行環境を確立しないと、実装の品質担保が自前アサート頼みになって破綻する**。

CLAUDE.md の「docs/development-guidelines.md」テスト戦略セクションでもフレームワークは Godot GUT（`addons/gut/`）、カバレッジ目標は `scripts/core/` の 70% と明記されている。

## 実装対象の機能

### 1. GUT プラグイン本体の配置

- GitHub リリースから Godot 4 対応版の GUT を取得して `addons/gut/` に展開
- Godot 4.6 で動作するバージョン（9.x 系）を選定
- ライセンスファイル（MIT）を含めて正しく配置

### 2. project.godot でのプラグイン有効化

- `[editor_plugins]` セクションに `res://addons/gut/plugin.cfg` を登録
- `.godot/` グローバルクラスキャッシュを再生成（前回タスクで学んだ手順）

### 3. CLI からのテスト実行確認

- `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit` で `tests/unit/**` が走ること
- 既存 4 ファイルのテストが全てパスすること（パスしない場合はテスト側の記述ミスを修正）
- 終了コードが 0 になること

### 4. 実行ラッパーとドキュメント

- `scripts_build/run_unit_tests.sh` — GUT 実行コマンドをラップした shell スクリプト
- `README.md` の「テスト実行」セクションに GUT 実行手順を追記
- `.gitignore` / `.gitattributes` に GUT 関連の調整があれば反映

## 受け入れ条件

### GUT プラグイン配置
- [ ] `addons/gut/plugin.cfg` が存在する
- [ ] `addons/gut/gut_cmdln.gd` が存在する
- [ ] `addons/gut/test.gd` が存在する（既存テストの extends 先）
- [ ] GUT のライセンスファイル（LICENSE.md など）が含まれている

### プラグイン有効化
- [ ] `project.godot` の `[editor_plugins]` セクションに GUT が登録されている
- [ ] `godot --headless --quit` がエラーなく終了する

### テスト実行
- [ ] `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit` が終了コード 0
- [ ] `test_daily_seed.gd` の全 6 ケースがパス
- [ ] `test_streak_service.gd` の全ケースがパス
- [ ] `test_score_system.gd` の全ケースがパス
- [ ] `test_date_util.gd` の全ケースがパス
- [ ] 既存の `tools/smoke_test.gd` も依然パスする（54/54）

### ドキュメント
- [ ] `README.md` に GUT 実行コマンドが記載されている
- [ ] `scripts_build/run_unit_tests.sh` が実行可能（`chmod +x`）

## 成功指標

- **定量**: GUT で 4 テストファイル・合計 20 ケース以上が実行され、全パス
- **定量**: GUT 実行時間が 10 秒以内（ローカル環境）
- **定性**: 今後の `/add-feature` で新しいテストを `tests/unit/` に追加するだけで CLI から走る状態

## スコープ外

以下はこのフェーズでは実装しない:

- **CI/CD 統合（GitHub Actions）** — Week 4 以降。ただし GUT コマンドだけは `scripts_build/run_unit_tests.sh` に固めておくので、後から `.github/workflows/test.yml` から呼ぶだけでよい
- **統合テスト（`tests/integration/`）の拡充** — シーン連携テストは反射タップ実装後に着手
- **カバレッジ計測ツール** — Godot にネイティブのカバレッジ計測がないため MVP では不要
- **新しいユニットテストの追加** — 既存テストを動かすことが目的。新規テストはミニゲーム実装時に追加
- **GUT のアップデート監視自動化**

## 参照ドキュメント

- `docs/development-guidelines.md` — テスト戦略（569-638 行目あたり）
- `docs/repository-structure.md` — `addons/gut/` の位置づけ
- `.steering/20260410-環境構築/tasklist.md` — 前回タスクの申し送り（「GUT プラグインの配置タスクを独立させる」と明記）
- `tests/unit/core/test_daily_seed.gd` — 既存テストの extends 形式
- `CLAUDE.md` — Autoload は `scripts/autoload/` のみ、`core/` は `new()` でインスタンス化（= テスト容易性）の原則
