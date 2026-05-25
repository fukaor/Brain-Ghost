# 開発ガイドライン (Development Guidelines)

> **プロダクト**: ブレインゴースト
> **バージョン**: v1.0 (MVP)
> **最終更新**: 2026-04-10
> **参照**: `docs/architecture.md`, `docs/repository-structure.md`, `CLAUDE.md`

Godot 4 / GDScript プロジェクトとしての ブレインゴースト のコーディング規約、Git 運用、テスト戦略、コードレビューの基準を定義する。**個人開発（ねこぽ/ReigalLabs）+ Claude Code アシスト**という開発体制を前提とする。

---

## 基本原則

### 0. GDD を北極星とする

**すべての設計判断は `docs/ideas/brain_training_gdd.md` に帰着する**。実装で迷ったら、PRD → 機能設計書 → GDD の順で参照する。GDD に書かれていない判断を新規に行う場合は、`.steering/` の `design.md` に根拠を明記する。

> **GDD のパス**: `docs/ideas/brain_training_gdd.md`（`docs/gdd.md` ではない）。CLAUDE.md・各スキル・他の永続ドキュメントもすべてこのパスを参照する。

### 1. ペルソナ1（セルフチャレンジャー）を優先する

UX 判断で迷ったら、プライマリーペルソナ（通勤2分で毎日プレイ）を優先する。シェア機能のためにオンボーディングを長くする、などのトレードオフは避ける。

### 2. 絶対ルール（GDD §4 + §6 + §7）

以下は**恒久的な禁止事項**であり、いかなる実装判断でも変更してはならない:

- **プレイ中に広告を表示しない**
- **ゲーム間に広告を挟まない**
- **負けの表示に赤系を使わない**（勝ち=緑/金、負け=グレー）
- **マルチタッチ・スワイプを操作に必須としない**
- **知識問題・語彙問題を追加しない**（全ゲーム言語非依存）
- **脳年齢に医学的効果を謳わない**（「エンターテインメント目的」の注記必須）
- **個人情報を収集しない**

### 3. シンプル優先

- MVP は 1 ヶ月スコープ。迷ったら**やらない**選択を取る
- 抽象化は 3 度目の重複が現れてから行う
- `/add-feature` で新機能を追加するときは必ず既存パターンを踏襲する

---

## コーディング規約（GDScript）

### 命名規則

#### ファイル名

| 種別 | 規則 | 例 |
|---|---|---|
| GDScript | `snake_case.gd` | `score_system.gd`, `number_search.gd` |
| シーン | `snake_case.tscn` | `home.tscn` |
| リソース | `snake_case.tres` | `default_theme.tres` |

#### コード内の識別子

```gdscript
# クラス名: PascalCase（class_name で宣言）
class_name ScoreSystem
extends Node

# 定数: UPPER_SNAKE_CASE
const MAX_TOTAL_SCORE := 17000
const GAME_TO_ABILITY := {
    "flash_calc": "calculation",
    "sequence_memory": "memory",
}

# enum: PascalCase、値は UPPER_SNAKE_CASE
enum GameMode { DAILY, FREE, ONBOARDING }

# メンバ変数: snake_case
var current_mode: String
var current_game_index: int
var _internal_cache: Dictionary  # プライベートは _ プレフィックス

# シグナル: snake_case、過去形または現在形の動詞
signal game_finished(play_log: PlayLog)
signal score_updated(new_score: int)
signal onboarding_completed

# メソッド: snake_case、動詞で始める
func calculate_score(game_type: String, data: Dictionary) -> int: ...
func is_feature_unlocked(accuracy: float) -> bool: ...
func get_ghost_for_game(game_type: String) -> GhostData: ...

# ブーリアン関数・変数: is_ / has_ / should_ / can_ プレフィックス
func is_ready() -> bool: ...
var has_played_today: bool = false

# プライベートメソッド: _ プレフィックス
func _update_cache() -> void: ...
```

#### Autoload 名

- Autoload として登録するときは **PascalCase** のグローバル名にする
- ファイル名は `snake_case.gd`
- **Autoload は `scripts/autoload/` 配下にのみ配置する**。`scripts/core/` のサービスクラスは Autoload にしない（テスト容易性のため、`ScoreSystem.new()` でインスタンス化できる設計を維持）

```
scripts/autoload/game_manager.gd   →  Autoload 名: GameManager
scripts/autoload/data_store.gd     →  Autoload 名: DataStore
scripts/autoload/audio_service.gd  →  Autoload 名: AudioService
scripts/autoload/ad_service.gd     →  Autoload 名: AdService
scripts/autoload/billing_service.gd →  Autoload 名: BillingService
scripts/autoload/platform.gd       →  Autoload 名: Platform
```

配置ルールの詳細は `docs/repository-structure.md` の `scripts/autoload/` と `scripts/core/` の節を参照。

### 型付け（GDScript 4）

**原則: すべてのメンバ変数・関数の引数・返り値に型注釈をつける**。動的型は特別な理由があるときだけ許容する。

```gdscript
# ✅ 良い例: 静的型付け
var current_score: int = 0
var play_logs: Array[PlayLog] = []

func calculate_brain_age(total_score: int, age_group: String) -> int:
    var center: int = AGE_GROUP_CENTER.get(age_group, 30)
    return center  # 実装略

# ❌ 悪い例: 型なし
var current_score = 0
var play_logs = []

func calculate_brain_age(total_score, age_group):
    var center = AGE_GROUP_CENTER.get(age_group, 30)
    return center
```

**例外**: Godot の `JSON.parse_string()` の返り値 (`Variant`) など、動的にならざるを得ない境界は許容。その場合は直後に型を絞る:

```gdscript
var raw: Variant = JSON.parse_string(text)
if raw is Dictionary:
    var data: Dictionary = raw
    # 以降は型が保証される
```

### コードフォーマット

- **インデント**: タブ（Godot Editor のデフォルト）
- **行の長さ**: 最大 **100 文字**
- **空行**: 関数間は 2 行、メソッド間は 1 行
- **波括弧**: 使わない（GDScript はインデントベース）
- **改行**: `if` / `for` の後に必ず改行

### コメント規約

#### ドキュメントコメント（関数・クラス）

```gdscript
## ScoreSystem
##
## 各ミニゲームの生スコア算出、脳年齢変換、能力軸マッピングを担当する。
## GDD §6 および docs/functional-design.md の アルゴリズム A-01, A-02 参照。
class_name ScoreSystem
extends Node

## 指定ゲームのスコアを算出する
##
## [param game_type] "flash_calc" / "ghost_7ban_shobu" など。DailySeed.ALL_GAMES の値
## [param play_data] ゲーム固有のフィールド（correct_count, remaining_sec 等）
## [return] 0 以上の整数スコア。不正な game_type なら 0
func calculate_score(game_type: String, play_data: Dictionary) -> int:
    ...
```

**Godot 4 の `##` コメントはエディタのヘルプに表示される**。公開 API にはつける。

#### インラインコメント

```gdscript
# ✅ 良い例: なぜ（why）を説明
# Web版ではユーザー操作後でないと AudioServer が動かないため、最初のタップまで初期化を遅延
_audio_initialized = false

# ❌ 悪い例: 何（what）を説明（コードを読めばわかる）
# _audio_initialized を false にする
_audio_initialized = false
```

**コメントは過去と約束の言語**。将来の自分が「なぜこれは素直に書かれていないのか」と悩む箇所にのみ残す。

### 関数設計

**原則**:

1. **1 関数 1 責務**: 「〜する」と「〜も」が入ったら分割
2. **20 行以内が望ましい**、50 行を超えるなら分割を検討
3. **副作用を明示する**: pure な関数とそうでないものを名前で区別する（`calculate_` / `update_` / `save_`）
4. **早期リターン**: ネストを減らす

```gdscript
# ✅ 良い例: 早期リターン + 責務分離
func update_streak(state: StreakState, today: String) -> StreakState:
    if state.last_played_date.is_empty():
        return _initialize_streak(state, today)

    var diff: int = DateUtil.days_between(state.last_played_date, today)
    if diff == 0:
        return state
    if diff <= 7:
        return _increment_streak(state, today, diff >= 2)
    return _reset_streak(state, today)

# ❌ 悪い例: ネストの深い if
func update_streak(state: StreakState, today: String) -> StreakState:
    if state.last_played_date == "":
        state.current_streak = 1
        state.last_played_date = today
    else:
        var diff = _days(state.last_played_date, today)
        if diff == 0:
            pass
        else:
            if diff == 1:
                state.current_streak += 1
            else:
                if diff <= 7:
                    state.current_streak += 1
                    state.welcome_back_shown = false
                else:
                    state.current_streak = 1
    return state
```

### エラーハンドリング

GDScript には例外機構がない。**`null` 返し / 空値返し / `push_error()` + 既定値復帰** のどれかを状況に応じて使う。

#### パターン1: 取得系 → null または空値

```gdscript
## 指定ゲームのゴーストを取得。未成立なら null を返す
func get_ghost_for_game(game_type: String) -> GhostData:
    var logs := _load_logs_for(game_type)
    if logs.size() < 5:
        return null
    return _compute_ghost(logs)
```

呼び出し側で `if ghost == null:` を必ずチェックする。

#### パターン2: 計算系 → 既定値フォールバック + 警告

```gdscript
## スコア計算。不正な game_type なら 0 を返し警告を出す
func calculate_score(game_type: String, play_data: Dictionary) -> int:
    match game_type:
        "flash_calc":
            return play_data.get("correct_count", 0) * 100 + play_data.get("remaining_sec", 0) * 10
        # 他ゲーム...
        _:
            push_warning("Unknown game_type: %s" % game_type)
            return 0
```

#### パターン3: 保存系 → bool を返す

```gdscript
## JSON を保存。成功なら true、失敗なら push_error + false
func save(key: StoreKey, data: Dictionary) -> bool:
    var json_text := JSON.stringify(data)
    if OS.get_name() == "Web":
        return _save_web(key, json_text)
    return _save_native(key, json_text)

func _save_native(key: StoreKey, json_text: String) -> bool:
    var path := _get_path(key)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to open file for write: %s" % path)
        return false
    file.store_string(json_text)
    file.close()
    return true
```

#### クラッシュさせてよい条件

`assert()` は開発ビルドでのみ動作する。プログラマーのバグ（不変条件の破れ）にのみ使う:

```gdscript
func set_game_index(index: int) -> void:
    assert(index >= 0 and index < 6, "game_index out of range: %d" % index)
    current_game_index = index
```

**本番リリース時は `assert` が削除されるため、ユーザー入力の検証には使わない**。

### シグナルの使い方

- **下位から上位への通知は必ずシグナル**で行う（依存方向を正しく保つ）
- シグナルに渡す値は**可能な限り型付け**する
- シグナル名は「何が起こったか」を表す過去形/現在形

```gdscript
# ✅ 良い例
signal game_finished(play_log: PlayLog)
signal ghost_unlocked(game_type: String)

# Emit 側
game_finished.emit(log)

# Connect 側
base_game.game_finished.connect(_on_game_finished)

func _on_game_finished(log: PlayLog) -> void:
    GameManager.register_play_log(log)
```

### Autoload の副作用管理

**Autoload（Singleton）は副作用の温床**になる。以下を徹底:

1. **pure な getter と副作用持ちの method を名前で区別**
   - `get_xxx()` / `is_xxx()` は副作用なし
   - `update_xxx()` / `save_xxx()` / `register_xxx()` は副作用あり
2. **シグナルを通じて状態変化を広報する**（呼び出し側が能動的にポーリングしない）
3. **依存関係を最小化**: Autoload が他の Autoload を直接呼ぶのは最小限にする

### データモデルの基底クラス（Resource vs RefCounted）

`scripts/models/` の `PlayLog`, `StreakState` 等のデータモデルは **`RefCounted` を基底**とする。`Resource` は選ばない。

**理由**:
- `.tres` ファイルとして保存しない（本プロジェクトは JSON 永続化）
- `Resource` はエディタインスペクタの依存が重く、ユニットテストでのインスタンス化コストが高い
- `RefCounted` は純粋なメモリ上オブジェクトで、`to_dict()` / `from_dict()` を手書きしやすい

```gdscript
# ✅ 良い例
class_name PlayLog
extends RefCounted

var id: String
var score: int

func to_dict() -> Dictionary: ...
static func from_dict(d: Dictionary) -> PlayLog: ...

# ❌ 避ける（理由: Resource の重さとインスペクタ依存）
class_name PlayLog
extends Resource

@export var id: String
@export var score: int
```

---

## プロジェクト固有のルール

### ゴースト対戦の2段階解放

- **第1段階**: 精度 100%（全6種プレイ済） → `GhostSystem.is_feature_unlocked(accuracy)`
- **第2段階**: 各ゲーム 5 回プレイ蓄積 → `GhostSystem.is_ready_for_game(game_type)`

UI 実装時、両段階を混同しないこと。ロックアイコンと「あと○回で生まれます」メッセージの使い分けは `docs/functional-design.md` の UC-04 に従う。

### 日付の扱い

- **すべての日付は JST (UTC+9) 固定**。`DateUtil` で一元管理
- デイリーチャレンジのシードは `YYYYMMDD` の整数
- ストリーク判定で UTC を使わない（深夜の境界問題を避ける）

```gdscript
# ✅ 良い例: DateUtil 経由
var today: String = DateUtil.today_jst()  # "2026-04-10"

# ❌ 悪い例: Time.get_datetime_dict_from_system() を直接使う
var dict := Time.get_datetime_dict_from_system()
var today := "%d-%02d-%02d" % [dict.year, dict.month, dict.day]  # タイムゾーン判定を散らしている
```

### プラットフォーム分岐

**必ず `Platform.gd` を経由**する。`OS.get_name()` をコード内に散らさない。

```gdscript
# ✅ 良い例
if Platform.supports_admob():
    AdService.show_banner()

# ❌ 悪い例
if OS.get_name() == "Android":
    AdService.show_banner()
```

### 色の使用

- 色は `scripts/utils/color_palette.gd` の定数から引く
- ハードコードされた `Color(1, 0, 0)` や `#EF4444` は**PRで必ず指摘**する
- `ColorPaletteUtil.RED` は定義しない（そもそも使わないため存在しない）。`color_palette.gd` の冒頭 DOC コメントにも「赤系は意図的に定義しない — 詳細は development-guidelines.md §色の使用」と明記する
- クラス名は `ColorPaletteUtil`（Godot 4.6 のネイティブ `ColorPalette` との衝突回避。他の util 群と同じ `*Util` 接尾辞で統一）

```gdscript
# ✅ 良い例
$ScoreLabel.modulate = ColorPaletteUtil.POSITIVE_GREEN

# ❌ 悪い例
$ScoreLabel.modulate = Color(0.13, 0.77, 0.37)  # 直接指定
```

**禁止色の検出コマンド**:

PR 作成前にローカルで実行してクリーンであることを確認する。

```bash
# 16進赤系のハードコード
rg -n --type-add 'godot:*.{gd,tscn,tres}' -t godot '#(ef4444|dc2626|b91c1c|e11d48|f87171|fca5a5)' scenes/ scripts/

# Color() の RGB 指定で赤成分が強いもの（R >= 0.7 かつ G/B が低い範囲）
rg -n --type-add 'godot:*.{gd,tscn,tres}' -t godot 'Color\(\s*(0\.[789]|1(\.0)?)\s*,\s*0\.[0-3]' scenes/ scripts/

# 名前に red を含む定数
rg -n --type-add 'godot:*.{gd,tscn,tres}' -t godot '\b[Rr]ed\b' scripts/utils/color_palette.gd scenes/ scripts/
```

いずれもヒットゼロが望ましい。どうしても必要な箇所（例: システム通知のエラー表示）が発生したら PR で議論する。

---

## Git 運用ルール

### ブランチ戦略

個人開発のため**軽量な GitHub Flow**を採用する。Git Flow のような複雑な分岐は避ける。

```
main            ← 常にリリース可能な状態
  └─ feature/xxx       ← 機能追加
  └─ fix/xxx           ← バグ修正
  └─ docs/xxx          ← ドキュメント変更
  └─ refactor/xxx      ← リファクタリング
```

- **`main` は常にリリース可能**。壊れた状態で放置しない
- **`develop` ブランチは作らない**（個人開発では過剰）
- feature ブランチは短命（数日以内にマージ）
- ブランチ名に日本語は使わない

### コミットメッセージ規約

**Conventional Commits** を採用。

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type

| Type | 用途 |
|---|---|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメント更新 |
| `style` | コードフォーマット（動作変更なし） |
| `refactor` | リファクタリング（動作変更なし） |
| `test` | テスト追加・修正 |
| `chore` | ビルド、補助ツール、依存関係更新 |
| `perf` | パフォーマンス改善 |

#### Scope の例（ブレインゴースト 固有）

- `game/flash_calc`, `game/ghost_7ban_shobu`, `game/number_search`, `game/card_match`, `game/stroop`, `game/sequence_memory`
- `core/score`, `core/ghost`, `core/daily_seed`, `core/streak`
- `ui/home`, `ui/result`, `ui/onboarding`
- `platform/web`, `platform/android`
- `data`, `ads`, `billing`
- `docs`, `tests`

#### 例

```
feat(game/ghost_7ban_shobu): ターゲット出現方向のランダム化を実装

- 20回タップのランダム配置を RandomNumberGenerator で実装
- フェイクターゲット混入ロジックを追加
- スコア算出は ScoreSystem.calculate_score() を経由

Closes #12
```

```
fix(core/streak): 8日以上空白時のリセットが動作しない問題を修正

diff 計算で day_of_year を使っていたため年末年始をまたぐと誤判定していた。
DateUtil.days_between() に置き換え、年またぎも正しくカウントするよう修正。
ユニットテストに年末年始ケースを追加。
```

#### コミットの粒度

- **1 コミット 1 目的**。関係ない変更を混ぜない
- WIP コミットは push 前に rebase で整理する
- 大きな機能は **論理的な単位で分割してコミット**する

### PR プロセス

個人開発でも **PR を使う**（レビューとマージ履歴のために）。

#### PR 作成前のチェックリスト

- [ ] Godot Editor でプロジェクトが起動する
- [ ] 該当するユニットテスト（GUT）がパス
- [ ] 追加/変更したファイルに関係する既存テストがパス
- [ ] Web版・Android版の両方でビルドが通る（大きな機能追加時）
- [ ] ハードコードされた赤色・`OS.get_name()` の散在・ハードコードされた日付がない
- [ ] `docs/` の関連ドキュメント（主に `functional-design.md`）と整合している

#### PR テンプレート

```markdown
## 概要
[変更内容の簡潔な説明]

## 関連ドキュメント
- PRD: FR-XX
- 機能設計書: UC-XX / A-XX
- ステアリング: `.steering/YYYYMMDD-xxx/`

## 変更内容
- [変更点1]
- [変更点2]

## 検証
- [ ] ユニットテスト追加/更新
- [ ] Godot Editor で実機確認
- [ ] Web版ビルド確認（該当する場合）
- [ ] Android版ビルド確認（該当する場合）

## スクリーンショット
[該当する場合]

## 関連 Issue
Closes #XX
```

### タグ / リリース

```
v1.0.0 — MVP リリース
v1.0.1 — パッチ
v1.1.0 — 新ゲーム 3 種追加
```

- セマンティックバージョニングに従う
- `main` の各リリース時点にタグを打つ
- GitHub Releases にリリースノートを記載

---

## テスト戦略

### テストピラミッド

```
          E2E（手動）          ← 10%：実機 / ブラウザでの手動シナリオ
         ─────────────
      統合テスト（GUT）         ← 20%：シーン連携、フロー単位
     ──────────────────
  ユニットテスト（GUT）         ← 70%：core/ のロジック
 ────────────────────────
```

### ユニットテスト

**対象**: `scripts/core/` と `scripts/utils/` 配下のロジック

**フレームワーク**: Godot GUT（`addons/gut/`）

**配置**: `tests/unit/<layer>/test_<対象>.gd`

**カバレッジ目標**: **サービスレイヤー（`scripts/core/`）の 70%**

**命名規則**:

```gdscript
# パターン: test_<メソッド>_<条件>_<期待>()
func test_calculate_score_flash_calc_returns_correct_value():
    ...

func test_update_streak_with_8day_gap_resets_to_1():
    ...

func test_get_ghost_for_game_with_4_logs_returns_null():
    ...
```

**例**:

```gdscript
# tests/unit/core/test_streak_service.gd
extends GutTest

var service: StreakService

func before_each():
    service = StreakService.new()

func test_update_streak_first_time_sets_to_1():
    var state := StreakState.new()
    state.last_played_date = ""
    var result := service.update_streak(state, "2026-04-10")
    assert_eq(result.current_streak, 1)
    assert_eq(result.last_played_date, "2026-04-10")

func test_update_streak_next_day_increments():
    var state := StreakState.new()
    state.current_streak = 3
    state.last_played_date = "2026-04-09"
    var result := service.update_streak(state, "2026-04-10")
    assert_eq(result.current_streak, 4)

func test_update_streak_7_day_gap_maintains():
    var state := StreakState.new()
    state.current_streak = 5
    state.last_played_date = "2026-04-03"  # 7日前
    var result := service.update_streak(state, "2026-04-10")
    assert_eq(result.current_streak, 6)
    assert_false(result.welcome_back_shown)  # 復帰演出フラグが立つ

func test_update_streak_8_day_gap_resets():
    var state := StreakState.new()
    state.current_streak = 10
    state.last_played_date = "2026-04-02"  # 8日前
    var result := service.update_streak(state, "2026-04-10")
    assert_eq(result.current_streak, 1)
```

### 統合テスト

**対象**: シーン連携、データ永続化、フロー全体

**配置**: `tests/integration/test_<flow>.gd`

**方法**: シーンを GUT 内で起動して順序実行。`DataStore` はテスト用の一時ディレクトリを使う。

### E2E テスト

**対象**: ユーザーシナリオ全体

**方法**: MVP では**自動化しない**。`tests/e2e/scenarios.md` にチェックリストを用意し、リリース前に手動で実施。

**主要シナリオ**（`functional-design.md` のテスト戦略セクション参照）:
- E2E-01: 初回オンボーディング完走
- E2E-02: デイリーチャレンジ 3 種完走 + 広告確認
- E2E-03: 広告非表示購入 → 再起動後の復元
- E2E-04: Web版シェアURL経由プレイ
- E2E-05: Web版の音声自動再生制限回避
- E2E-06: 複数機種でのクラッシュ・FPS 確認
- E2E-07: ストリーク境界値（7/8 日）

### モック・スタブ

- **プラットフォーム層は Platform.gd で抽象化**されているため、テスト時に差し替え可能
- `DataStore` は `user://` の代わりに `res://tests/fixtures/` 配下を読むモードを持つ
- `AdService`, `BillingService` は Web版で自動的に no-op になるため、デスクトップ実行ではそのまま無効化される

---

## コードレビュー基準

### レビュー観点

**機能性**:
- [ ] PRD の受け入れ条件を満たしているか
- [ ] GDD の絶対ルール（広告・色・操作・知識問題禁止）に抵触していないか
- [ ] エッジケース（ログ 0 件、5 件境界、7/8 日境界など）が考慮されているか
- [ ] プラットフォーム分岐（Web / Android）が正しいか

**可読性**:
- [ ] 命名が明確か（GDScript 命名規則に従っているか）
- [ ] 型注釈が付いているか
- [ ] 複雑なロジックに why コメントがあるか

**保守性**:
- [ ] 重複コードが 3 回以上現れていないか
- [ ] レイヤー間の依存方向を守っているか（`core/` から `ui/` への依存禁止など）
- [ ] シグナル方向が正しいか

**パフォーマンス**:
- [ ] プレイ中のフレームごとの GC（`Dictionary.new()`, `Array.new()` の多用）がないか
- [ ] ファイルIO が適切にバッファされているか
- [ ] 不要な再計算がないか

**セキュリティ / プライバシー**:
- [ ] 個人情報を新規に収集していないか
- [ ] AdMob Unit ID 等の設定値が適切な場所にあるか
- [ ] Web版の COOP/COEP ヘッダーへの影響がないか

### レビューコメントの書き方

優先度ラベル:

- `[必須]`: 修正必須。マージ前に対応
- `[推奨]`: 修正推奨。別 PR でも可
- `[提案]`: 検討してほしい
- `[質問]`: 理解のための質問
- `[褒め]`: 良かった点を明示的に残す（個人開発でも自分への記録として有効）

```markdown
## ✅ 良い例
[必須] この `calculate_score` は `match` の default 節で `-1` を返していますが、
呼び出し側は戻り値を `int` のスコアとして扱うため、0 のほうが整合します。
`_` に `push_warning` + `return 0` を追加してください。

[提案] `_compute_ghost_events` が 60 行ほどあり、ステップが見えにくくなっています。
`_extract_logs_for_game` と `_average_event_arrays` に分割するとテストしやすくなると思います。

## ❌ 悪い例
この書き方は良くないです。
```

---

## 開発プロセス（`.steering/` との連携）

`CLAUDE.md` で定義されている通り、作業ごとに `.steering/YYYYMMDD-タスク名/` を作成する。

### 作業フロー

```
1. 作業計画
   └─ Skill: steering (mode 1)
   └─ .steering/YYYYMMDD-タスク名/ に requirements.md, design.md, tasklist.md を作成
   └─ ユーザー承認

2. 実装
   └─ Skill: steering (mode 2)
   └─ tasklist.md のタスクを順に実装、進捗を随時更新
   └─ 実装中に設計が変わったら design.md を更新

3. 検証
   └─ Skill: steering (mode 3)
   └─ 振り返り、次に活かす点を整理
```

### ステアリングディレクトリの命名規則

**正**: `.steering/YYYYMMDD-タスク名/`

- `YYYYMMDD` 形式の日付 + `-` + タスク名
- **タスク名は日本語 OK**（CLAUDE.md の指針に従う）。例: `.steering/20260521-数字さがしゲーム実装/`
- 英語表記でも構わないが、プロジェクト内で統一する（個人開発のため一貫性優先）
- ファイル名（`requirements.md`, `design.md`, `tasklist.md`）は英語で固定

### ドキュメントとコードの対応

| ドキュメント | 更新頻度 | 更新トリガー |
|---|---|---|
| `docs/ideas/brain_training_gdd.md` | ほぼ不変 | 大規模なピボット時のみ |
| `docs/product-requirements.md` | 低 | 機能追加時（FR 追加） |
| `docs/functional-design.md` | 中 | アルゴリズム変更・UC 追加 |
| `docs/architecture.md` | 低 | 技術スタック変更 |
| `docs/repository-structure.md` | 低 | ディレクトリ構造変更 |
| `docs/development-guidelines.md` | 中 | 規約変更、経験値の反映 |
| `docs/glossary.md` | 中 | 用語追加 |
| `.steering/YYYYMMDD-xxx/` | 高 | 作業ごと |
| `CLAUDE.md` | 低 | プロジェクト全体の方針変更時 |

---

## 開発環境セットアップ

### 必要なツール

| ツール | バージョン | インストール方法 | 備考 |
|---|---|---|---|
| **Godot Engine** | 4.3 以降 | 公式サイト https://godotengine.org | LTS 候補を優先 |
| **Android Studio** | 最新 LTS | 公式 | Android Export 用。SDK/NDK/JDK を含む |
| **Java JDK** | 17 | Android Studio 同梱で OK | Android ビルドに必要 |
| **Git** | 2.x | OS パッケージマネージャ | |
| **Node.js** | 20 LTS | nvm 推奨 | 補助スクリプトのみ。実行環境ではない |
| **Chrome / Edge** | 最新 | — | Web版デバッグ |
| **Android 実機** | Android 8.0+ | — | E2E テスト用。USB デバッグ有効化 |

### セットアップ手順

```bash
# 1. リポジトリのクローン
git clone https://github.com/<user>/brain-ghost.git
cd brain-ghost

# 2. Godot Editor で open
# Godot を起動 → Import → project.godot を選択

# 3. プラグインの有効化
# Project Settings → Plugins
#   - admob: ON（Android Export 時のみ）
#   - gut: ON（テスト実行時）

# 4. ユニットテストの実行
# Godot Editor で Scene → Run Tests (GUT パネル)
# または CLI: godot --headless --script addons/gut/gut_cmdln.gd

# 5. Web版エクスポート（確認用）
# Godot Editor → Project → Export → Web → Export Project
# 出力: web/dist/

# 6. ローカルで Web版プレビュー
# ⚠️ python3 -m http.server は COOP/COEP ヘッダーを付けないため SharedArrayBuffer が動かず、
#    Godot Web版は起動時にクラッシュする。必ず COOP/COEP 対応のサーバを使うこと。

# 方法A: npx serve に手動でヘッダー設定
# serve.json を web/dist/ に配置してから起動
cat > web/dist/serve.json <<EOF
{
  "headers": [
    {
      "source": "**/*",
      "headers": [
        {"key": "Cross-Origin-Opener-Policy", "value": "same-origin"},
        {"key": "Cross-Origin-Embedder-Policy", "value": "require-corp"}
      ]
    }
  ]
}
EOF
npx serve web/dist -l 8000

# 方法B: 簡易 Node スクリプトを用意（推奨）
# scripts_build/serve_local.js に COOP/COEP を付与する簡易サーバを書いておく
node scripts_build/serve_local.js 8000

# ブラウザで http://localhost:8000 を開く
# DevTools の Security タブで "This page is cross-origin isolated" を確認できれば OK
```

### Android 署名鍵の管理

- `android/release.keystore` は **Git に絶対含めない**（`.gitignore` 済み）
- パスフレーズは環境変数または `export_presets.cfg.local` に記載
- 1Password などのパスワードマネージャにバックアップ

### 推奨 VS Code 拡張（任意）

- **godot-tools** — GDScript シンタックスハイライト、定義ジャンプ
- **Markdown All in One** — ドキュメント編集補助
- **Conventional Commits** — コミットメッセージ補助

---

## CI / 自動化（任意・v1.1 以降で検討）

MVP では CI を構築しない（個人開発の速度優先）。以下は v1.1 以降で検討する項目:

- **GitHub Actions**: PR 時に `godot --headless --script addons/gut/gut_cmdln.gd` でユニットテスト実行
- **Web版の自動デプロイ**: main への push 時に Web Export → Cloudflare Pages へ自動デプロイ
- **Android APK の自動ビルド**: tag push 時に AAB を生成し GitHub Releases にアップロード

---

## チェックリスト

### MVP リリース前の確認

- [ ] 6 種すべてのゲームが 3 回連続で完走できる
- [ ] 初回オンボーディング → ホーム遷移 → デイリー 3 種完了までクラッシュなし
- [ ] Android 実機 3 機種でクラッシュ率 < 1%
- [ ] Web版が Cloudflare Pages で正常動作（COOP/COEP 適用済）
- [ ] **Web版でユーザーの最初のタップ後に BGM/SE が正常に再生される**（音声自動再生制限の回避確認）
- [ ] BGM/SE の個別オンオフが設定画面で機能する
- [ ] 広告非表示買い切り購入 → 再起動後の復元が機能する
- [ ] Play Billing の `queryPurchasesAsync()` がアプリ起動時に実行され、ローカルキャッシュと照合される
- [ ] ストリーク境界（0/1/2-7/8 日）がすべて正しく動く
- [ ] 2〜7 日の空白後に復帰演出が 1 度だけ表示される（2 度目は出ない）
- [ ] ゴースト 5 件境界が正しく動く（4 件未満は非表示、5 件でゴーストバー出現）
- [ ] 精度 100% でゴースト対戦機能全体のロックが外れる
- [ ] 全画面でどこにも赤系の色が使われていない（上記 `rg` コマンドでチェック）
- [ ] デイリーチャレンジが同日に同じ 3 種を選出することを 2 台以上のデバイスで確認（シード一致）
- [ ] プライバシーポリシーがアプリ内からリンクされている
- [ ] 脳年齢表示に「エンターテインメント目的」の注記がある
- [ ] `assets/CREDITS.md` にすべてのフリー素材のライセンスが記載されている
- [ ] AdMob 本番 Unit ID が本番ビルドにのみ注入されていること（デバッグビルドはテスト ID のまま）
