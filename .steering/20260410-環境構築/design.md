# 環境構築 — Design

> **関連**: `docs/architecture.md`, `docs/repository-structure.md`, `docs/development-guidelines.md`, `docs/functional-design.md`

## 実装方針

### 方針1: ドキュメントに忠実な骨格を先に作る

永続ドキュメントは設計レビュー済みで確定している。本タスクは**ドキュメント→コードへの「翻訳」**に徹する。勝手な設計判断は加えない。迷ったら:
1. `docs/functional-design.md` のコンポーネント設計を参照
2. `docs/architecture.md` の依存方向ルールを参照
3. `docs/repository-structure.md` のファイル配置を参照

### 方針2: 「完全実装」と「スタブ」を明確に分ける

本タスクで**完全実装するもの**（後続タスクで触らない）:
- `Platform`（判定ロジックが純粋で後から変わらない）
- `ColorPalette`, `DateUtil`, `UuidUtil`, `JsonUtil`（純粋なユーティリティ）
- `DailySeed`（Fisher-Yates の正しい実装はデイリー共通問題の根幹であり、手戻りリスクを避けたい）
- `StreakService`（A-06 の仕様が固まっており、テストも書ける）
- 全データモデル（`to_dict()` / `from_dict()` 含む）

本タスクで**スタブに留めるもの**:
- `GameManager`, `DataStore`, `AudioService`, `AdService`, `BillingService`（実際の処理は後続タスクで肉付け）
- `ScoreSystem`, `GhostSystem`, `SchemaMigrator`（後続タスクで実装追加）
- `BaseGame`（具体ゲームの実装時に合わせて調整するため骨組みのみ）
- UI コントローラ（`launch_controller.gd` と `home_controller.gd` のみ最小実装）

### 方針3: Autoload と Platform 抽象化を徹底する

`OS.get_name()` は `platform.gd` 以外に現れないようにする。`DataStore`・`AdService`・`BillingService` のプラットフォーム分岐はすべて `Platform.current()` / `Platform.supports_xxx()` を経由する。

### 方針4: テスト可能性を最優先する

- `scripts/core/` は Autoload しない（`ScoreSystem.new()` でインスタンス化可能）
- 日時に依存する関数は、RNG や現在日時を引数で注入可能にする（`calculate_brain_age(..., rng)`、`update_streak(state, today)`）
- ユニットテストは GUT を使うが、プラグイン本体の配置は別タスクなので、本タスクではテストファイル自体は書いておく

### 方針5: Godot 4.6 に合わせる

サンドボックスの Godot は 4.6.2 stable。`docs/architecture.md` は「4.3 以降」と書いていたので問題なし。`project.godot` の `config/features` に `["4.6", "GL Compatibility"]` 相当を入れる（モバイル互換性のため Forward+ ではなく GL Compatibility を選択）。

## 主要ファイルの設計

### `project.godot`（抜粋）

```ini
config_version=5

[application]
config/name="Brain Boost"
config/description="毎日2分、昨日の自分に挑め"
run/main_scene="res://scenes/main/launch.tscn"
config/features=PackedStringArray("4.6", "GL Compatibility")
config/icon="res://icon.svg"

[autoload]
Platform="*res://scripts/autoload/platform.gd"
DataStore="*res://scripts/autoload/data_store.gd"
AudioService="*res://scripts/autoload/audio_service.gd"
AdService="*res://scripts/autoload/ad_service.gd"
BillingService="*res://scripts/autoload/billing_service.gd"
GameManager="*res://scripts/autoload/game_manager.gd"

[display]
window/size/viewport_width=720
window/size/viewport_height=1280
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=1  # portrait

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

**Autoload の登録順に注意**: `Platform` → `DataStore` → `AudioService` → `AdService` → `BillingService` → `GameManager`。上位が下位を呼べる順序で並べる。

### `scripts/autoload/platform.gd`（完全実装）

```gdscript
extends Node

enum Target { WEB, ANDROID, DESKTOP_DEBUG }

func current() -> Target:
    match OS.get_name():
        "Web": return Target.WEB
        "Android": return Target.ANDROID
        _: return Target.DESKTOP_DEBUG

func supports_admob() -> bool:
    return current() == Target.ANDROID

func supports_billing() -> bool:
    return current() == Target.ANDROID

func supports_share_url() -> bool:
    return current() == Target.WEB

func storage_strategy() -> String:
    return "localStorage" if current() == Target.WEB else "user_dir"

func is_web() -> bool:
    return current() == Target.WEB

func is_android() -> bool:
    return current() == Target.ANDROID
```

### `scripts/core/daily_seed.gd`（完全実装、Fisher-Yates）

機能設計書 A-05 の通り。`Array.shuffle()` を使わず `rng.randi()` で手動実装する。

### `scripts/core/streak_service.gd`（完全実装）

機能設計書 A-06 の通り。`welcome_back_shown` フラグの意味を「演出表示済みか」で統一。

### `scripts/models/*.gd`（全て `RefCounted`）

開発ガイドラインの方針に従い `Resource` ではなく `RefCounted` を基底とする。各モデルは:
- メンバ変数（snake_case、型付き）
- `to_dict() -> Dictionary`
- `static func from_dict(d: Dictionary) -> XxxModel`

### Web 版シェル (`web/_headers`)

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Resource-Policy: same-origin
  Permissions-Policy: interest-cohort=()
  X-Content-Type-Options: nosniff
```

### `export_presets.cfg`

Web と Android の 2 preset を空の状態で用意する。本番 AdMob ID は入れず、テスト用 ID またはプレースホルダのみ。

## 検証方針

1. **Godot CLI で parse エラーが出ないこと**: `godot --headless --quit --path /workspace` を実行し、プロジェクトがロードできることを確認
2. **Autoload が正しく登録されているか**: `godot --headless` 起動時にエラーが出ないこと
3. **Fisher-Yates の決定性**: `DailySeed.get_daily_games(20260415)` を複数回呼んで同じ結果になること
4. **StreakService の境界値**: GUT がなくても `godot --headless --script` で手動チェック可能なスモークテストを用意する（GUT は後続タスクで配置）

GUT プラグインがまだ配置されていないため、本タスクでは **`tools/smoke_test.gd` のような簡易スモークスクリプト**を用意し、`godot --headless --script` で実行できるようにする。GUT ディレクトリ `tests/unit/**` にはテストファイルを用意しつつ、GUT が配置されるまでは実行されない。

## リスクと対策

| リスク | 対策 |
|---|---|
| `export_presets.cfg` に誤った値を入れると Godot エディタで開いたとき壊れる | テンプレートとしてコメント付きで最小限のみ記載 |
| Autoload の循環依存 | 依存順序を `Platform → DataStore → AudioService → AdService → BillingService → GameManager` で固定 |
| GUT なしでのテスト | `tools/smoke_test.gd` で直接アサーション、GUT 配置後は `tests/unit/` の GUT テストに移行 |
| `.godot/` の誤コミット | `.gitignore` で最初から除外 |
| 赤色ハードコード混入 | `color_palette.gd` の DOC コメントで明示、PR 前 grep チェックを development-guidelines に記載済み |
