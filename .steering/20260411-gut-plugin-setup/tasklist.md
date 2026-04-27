# GUT プラグイン配置とユニットテスト実行環境整備 — Tasklist

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

---

## フェーズ A: GUT プラグインの取得と配置

- [x] A-01: Godot 4.6 互換の GUT バージョンを確定する（**v9.6.0** を採用。リリースノートに「Compatibility changes for Godot 4.6.」の記載あり、2026-02-24 リリース）
- [x] A-02: GUT のソースを取得する（GitHub release tarball / zip を wget or curl で）
  - [x] A-02a: 一次手段: `https://github.com/bitwes/Gut/archive/refs/tags/v9.6.0.tar.gz` を取得（1018K、256 files）
  - [x] ~~A-02b~~ 不要（A-02a 成功）
  - [x] ~~A-02c~~ 不要（A-02a 成功）
- [x] A-03: 取得したアーカイブを展開し、`addons/gut/` にコピー（248 files）
- [x] A-04: 必須ファイルの存在を検証: `plugin.cfg`, `test.gd`, `gut.gd`, `gut_cmdln.gd`, `LICENSE.md` 全て存在確認
- [x] A-05: `addons/gut/VERSION.txt` にインストール済みバージョンとソース URL を記録
- [x] A-06: ~~不要なディレクトリ削除~~（tarball は既に `addons/gut/` サブセットのみで不要物を含まないため no-op）

## フェーズ B: プロジェクト設定の更新

- [x] B-01: `project.godot` に `[editor_plugins]` セクションを追加し、`res://addons/gut/plugin.cfg` を enabled で登録
- [x] B-02: `.gitignore` を更新し `addons/**/*.import` を再包含（GUT の `icon.png.import` などをコミット対象に戻す）
- [x] B-02b: **（想定外）** Godot 4.6 ネイティブ `ColorPalette` と `scripts/utils/color_palette.gd:class_name ColorPalette` が衝突するため `ColorPaletteUtil` にリネーム。`docs/development-guidelines.md` のサンプルコードも同時更新
- [x] B-03: ~~`.godot/` の所有権問題~~（現環境では godot:godot 所有で問題なし。no-op）
- [x] B-04: `godot --headless --editor --quit-after 120` 実行。`global_script_class_cache.cfg` に `GutTest`, `ColorPaletteUtil`, `DateUtil`, `JsonUtil`, `UuidUtil` 登録を確認
- [x] B-05: `godot --headless --quit` がエラーなく終了することを確認（Parse Error 無し。既存の ObjectDB leak warning は環境構築タスクから継続している pre-existing で本タスクのリグレッションではない）

## フェーズ C: テスト実行の確立

- [x] C-01: GUT を CLI で直接起動してテストを実行
  - **注意**: `-gdir` だけではサブディレクトリを拾わない。`-ginclude_subdirs` フラグが必須
  - 最終コマンド: `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit`
- [x] C-02: 全テストの結果を確認（**Scripts 4 / Tests 45 / Passing 45 / Asserts 65 / 0.719s**）
- [x] C-03: 失敗ゼロのため原因調査は不要
  - [x] ~~C-03a~~ 不要
  - [x] ~~C-03b~~ 不要
  - [x] ~~C-03c~~ 不要
- [x] C-04: `test_daily_seed.gd` 6/6 パス
- [x] C-05: `test_streak_service.gd` 8/8 パス
- [x] C-06: `test_score_system.gd` 22/22 パス
- [x] C-07: `test_date_util.gd` 9/9 パス
- [x] C-08: GUT 実行の終了コード 0（`All tests passed!` 出力確認）

## フェーズ D: 実行ラッパーの整備

- [x] D-01: `scripts_build/run_unit_tests.sh` を作成。引数の有無で分岐（引数なし: デフォルト `-gdir=res://tests/unit -ginclude_subdirs`、引数あり: そのまま透過）
- [x] D-02: 実行権限を付与（`chmod +x scripts_build/run_unit_tests.sh`）
- [x] D-03: `./scripts_build/run_unit_tests.sh` で全 45 テストが通ることを確認
- [x] D-04: `./scripts_build/run_unit_tests.sh -gtest=...` で単一ファイル実行（6/6）ができることを確認

## フェーズ E: ドキュメント更新

- [x] E-01: `README.md` に「テスト」セクションを追加（GUT 実行コマンド 3 パターンとスモークテスト実行例）
- [x] E-02: `README.md` に GUT v9.6.0 と MIT License を明記
- [x] E-03: `assets/CREDITS.md` の GUT エントリをバージョン v9.6.0 付きに更新（GUT 行は既存だったため補強）

## フェーズ F: 品質チェックとリグレッション確認

- [x] F-01: `godot --headless --quit` exit=0、ParseError なし
- [x] F-02: `godot --headless --script tools/smoke_test.gd` が **54/54** パス（リグレッションなし）
- [x] F-03: `./scripts_build/run_unit_tests.sh` exit=0、45/45 パス
- [x] F-04: `OS.get_name()` は `platform.gd` 内のみ（前回と同じ状態）
- [x] F-05: `Color(0.[789]|1` 正規表現ヒットは `color_palette.gd` の GOLD/LIGHT_GRAY/BG_LIGHT（非赤系の false positive）とコメント行の禁止色説明のみ。前回タスクと同様 clear 扱い

## フェーズ G: 振り返り

- [x] G-01: 「実装後の振り返り」セクションを更新
- [x] G-02: 次のステアリング候補を記録

---

## 実装後の振り返り

### 実装完了日
2026-04-10

### 実施結果サマリ

- **GUT バージョン**: v9.6.0（2026-02-24 リリース、Godot 4.6 互換を公式明言）
- **配置ファイル数**: `addons/gut/` 配下 249 ファイル（うち .gd 82 ファイル）
- **新規作成ファイル**:
  - `addons/gut/` 一式
  - `addons/gut/VERSION.txt`（バージョン固定のためのメタ）
  - `scripts_build/run_unit_tests.sh`（実行ラッパー、chmod +x 済み）
- **編集ファイル**:
  - `project.godot`（`[editor_plugins]` セクション追加）
  - `.gitignore`（`!addons/**/*.import` で addons 内の .import 再包含）
  - `scripts/utils/color_palette.gd`（`class_name ColorPalette` → `ColorPaletteUtil` にリネーム）
  - `docs/development-guidelines.md`（サンプルコードの `ColorPalette` → `ColorPaletteUtil`）
  - `README.md`（「テスト」セクション追加）
  - `assets/CREDITS.md`（GUT エントリを v9.6.0 付きに補強）
- **テスト結果**:
  - GUT: **4 scripts / 45 tests / 65 asserts / 0.72s / All passed**
  - スモークテスト: 54/54 passed（リグレッションなし）

### 計画と実績の差分

**計画と異なった点**:

1. **`class_name ColorPalette` と Godot 4.6 ネイティブクラスの衝突**（想定外・最大のサプライズ）
   - Godot 4.6 で `ColorPalette` がリソースのネイティブクラスとして追加されていた
   - `godot --headless --editor --quit-after` でクラススキャンした瞬間に Parse Error
   - 環境構築タスク（前回）では `--editor` モードを走らせていたにもかかわらずこの問題が表面化しなかった可能性がある。前回のスモークテスト実行環境では `ColorPalette` が当たっていなかったのか、Godot 4.6.2 にバージョンが進んだタイミングで新規追加されたのか、後者のほうが有力
   - 対処: `ColorPaletteUtil` にリネーム。他の util 群（`DateUtil`, `JsonUtil`, `UuidUtil`）の `*Util` 接尾辞命名規則と一貫性が出たので結果オーライ

2. **`-gdir` 単独ではサブディレクトリを再帰しない**
   - 当初は `-gdir=res://tests/unit -gexit` だけで動くと想定していたが、「Nothing was run.」エラーで停止
   - GUT の CLI ヘルプ（`-gh`）を確認して `-ginclude_subdirs` フラグが必須と判明
   - `scripts_build/run_unit_tests.sh` とドキュメントの両方に反映済み

3. **`.gitignore` の `*.import` が addons を誤除外していた**
   - 前回タスクの時点では addons 配下が空だったので発覚せず
   - GUT 配置で `icon.png.import`, `source_code_pro.fnt.import` を含むようになり問題化
   - `!addons/**/*.import` の再包含ルールを追加して解決

4. **ラッパー shell の設計を途中で変更**
   - 当初は `"$@"` を末尾にそのまま渡す単純実装
   - 単体テスト時に `-gtest` と `-gdir` が併存して意図通りに絞り込めない問題が発覚
   - 引数の有無で分岐する設計に変更（引数なし = デフォルト、引数あり = ユーザー指定優先）

**新たに必要になったタスク**:
- B-02b（`ColorPalette` リネーム）— 計画時には予見できず、実行中に発生
- `docs/development-guidelines.md` のサンプルコード同期（ドキュメントと実装の整合性維持）

**技術的理由でスキップしたタスク**:
- A-02b / A-02c（git clone / 手動配置フォールバック）— A-02a の tarball 取得が成功したため不要
- B-03（`.godot/` 所有権問題の対処）— 現環境では godot:godot 所有で問題なし
- A-06（不要ディレクトリ削除）— tarball が既に `addons/gut/` サブセットのみで不要物を含んでいなかったため no-op

### 学んだこと

**技術的な学び**:

1. **Godot 4.6 のネイティブクラス拡張に注意**
   - バージョンアップで新しい `class_name` がエンジンに追加されると、プロジェクトの同名 `class_name` が `hides a native class` エラーで Parse Error になる
   - **対策**: `class_name` は Godot 標準と衝突しない名前（プロジェクト固有接頭辞 or `*Util`/`*Service` 等の接尾辞）を選ぶ。CI で `godot --headless --editor --quit-after` を必ず通して、衝突を早期検知する

2. **GUT CLI の主要フラグ**
   - `-gdir` = スキャン対象ディレクトリ（リスト可、デフォルト再帰なし）
   - `-ginclude_subdirs` = サブディレクトリを再帰
   - `-gtest` = 単一ファイル指定
   - `-gexit` = 実行後に自動終了（これがないと CLI がハング）
   - `-gselect` = ファイル名部分一致フィルタ
   - `-gh` = ヘルプ全文

3. **GUT の UID 警告は起動時に大量に出るが無害**
   - `addons/gut/gui/*.tscn` の `ext_resource, invalid UID` 警告は `.godot/` 初回スキャン未完了時に出る。テストは正常に走るので無視してよい

4. **`.gitignore` の否定パターン `!` の使い所**
   - 上位で広くパターン除外 → 下位で特定サブツリーだけ再包含（`!addons/**/*.import`）は Git のネガティブパターンが正解。ルールを分けるより 1 行追加のほうが意図が明確

5. **shell ラッパーの「引数あり/なしで分岐」パターン**
   - ラッパーがデフォルト値を渡しつつ、ユーザーが完全上書きできる柔軟性を保つには `$# -eq 0` 分岐が簡潔で効果的

**プロセス上の改善点**:

- **tasklist.md 駆動の恩恵**: 「A-01 → A-02 → ... → G-02」と粒度細かく刻んだおかげで、途中で予期せぬ問題（ColorPalette 衝突）が発生しても、どこまで進んでいたかが迷わず追跡できた
- **想定外タスクの扱い**: B-02b のように新規タスクを途中で挿入する運用は healthy。前回のタスクで学んだ「差分を明示する」ことが効いた

### 次回への改善提案

1. **Godot バージョン上げ時のクラス名衝突チェックを自動化**
   - `.github/workflows/test.yml` または `scripts_build/sanity_check.sh` 的なチェックで、`godot --headless --editor --quit-after 60` を最初に走らせて Parse Error がないか確認する手順を追加したい
   - 今回のように Godot パッチアップデートで何かのクラスが増えるリスクはゼロではない

2. **GUT 関連のドキュメントリンクを整備**
   - `docs/development-guidelines.md` のテスト戦略セクションに `-ginclude_subdirs` 必須のことを追記する価値あり（今回はドキュメント上の具体例が古いままだった）
   - 次に development-guidelines を触るタスクで追記する

3. **既存テストの `after_each()` で `queue_free()` 追加**
   - 今回の実行で `test_score_system.gd` と `test_streak_service.gd` に orphan node 警告が出た（各テストで `ScoreSystem.new()` / `StreakService.new()` したものが後始末されていない）
   - テスト失敗ではないのでスコープ外として手を入れなかったが、次のテスト追加タスクで一緒に直すと綺麗
   - `test_daily_seed.gd` は正しく `after_each()` で `queue_free()` している（0 orphans）ので、これをテンプレとして踏襲する

4. **CI 統合の前準備が整った**
   - `./scripts_build/run_unit_tests.sh` を呼ぶだけで全ユニットテストが走るようになったので、次に `.github/workflows/test.yml` を書くときはこのスクリプトを 1 行で呼べばよい
   - GUT のキャッシュ生成（`godot --headless --editor --quit-after 60`）を事前ステップとして入れるのを忘れない

### 次のステアリング候補

- `20260412-reflex-tap-implementation` — 反射タップゲーム実装（Week 1 本丸。GUT が動くようになったので、スコア計算のユニットテストを書きながら TDD 風に進められる）
- `20260414-flash-calc-implementation` — フラッシュ暗算ゲーム実装
- `20260411-gut-hygiene` — orphan 警告の解消（優先度低・数分で終わる軽量タスク）
