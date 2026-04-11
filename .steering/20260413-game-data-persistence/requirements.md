# 要求内容 — DataStore 永続化（PlayLog + GameBest）

## 概要

DataStore に **PlayLog の追加保存** と **GameBest の読み書き** の高レベル API を実装し、GameManager のスタブ (`_save_play_log` / `_load_previous_score`) を本実装に置き換える。これにより「is_new_best が本物になる」「2 回目以降のプレイで前回比が表示される」が実現する。

## 背景

- 反射タップ実装ステアリング (`20260412-reflex-tap-implementation`) で GameManager のスタブ実装に PlayLog 保存とベスト判定を置いた
- DataStore には `save(key, dict) / load_dict(key) / exists(key) / clear(key)` の低レベル API しか存在しない
- 高レベル API (PlayLog 配列の append、GameBest の get/set) が無いため、各画面コントローラから直接 JSON 操作を書くと DRY 違反になる
- ベスト記録の更新ロジック（新スコア > 既存ベスト → 更新）は 1 箇所に集約すべき

## 実装対象

### 1. DataStore に高レベル API を追加

`scripts/autoload/data_store.gd` に以下を追加:

```gdscript
# PlayLog 関連
func append_play_log(log: PlayLog) -> bool
func load_play_logs(game_type: String = "", limit: int = -1) -> Array[PlayLog]
func count_play_logs(game_type: String = "") -> int

# GameBest 関連
func load_best(game_type: String) -> GameBest        # 不在時は score=0 の空 GameBest
func save_best(best: GameBest) -> bool               # 全 GameBest を保存
func update_best_if_better(log: PlayLog) -> bool     # ベストを更新したら true、PlayLog から自動構築
```

**保存スキーマ**:

```json
// PLAY_LOGS
{
  "schemaVersion": 1,
  "logs": [
    { "id": "uuid", "gameType": "reflex_tap", ... },
    ...
  ]
}

// GAME_BESTS
{
  "schemaVersion": 1,
  "bests": {
    "reflex_tap": { "gameType": "reflex_tap", "bestScore": 1020, ... },
    "flash_calc": { ... },
    ...
  }
}
```

### 2. GameManager のスタブを置換

- `_save_play_log(log)` → `DataStore.append_play_log(log)`
- `_load_previous_score(game_type)` → `DataStore.load_best(game_type).best_score`
- ベスト更新タイミング: `on_reflex_tap_finished` 内で `DataStore.update_best_if_better(log)` を呼ぶ
- previous_score の取得タイミング: ゲーム開始時 (`start_reflex_tap`) で `_previous_score` を保存しておき、結果画面で参照

### 3. ユニットテスト追加

`tests/unit/core/test_data_store.gd` 新規作成:

- DataStore.save / load_dict のラウンドトリップ
- append_play_log: 空状態 → 追加 → 読み戻して件数確認
- append_play_log: 複数追加 → 順序保持
- load_play_logs(game_type): フィルタが効く
- load_play_logs(limit): 件数制限が効く
- load_best: 未保存時に score=0 が返る
- update_best_if_better: 新記録なら true & 更新
- update_best_if_better: 同等スコア (>=) でも false
- update_best_if_better: 低スコアで false
- count_play_logs: 種別指定 / 全件カウント
- スキーマ不正データのフォールバック（壊れた JSON で空配列を返す）

### 4. ドキュメント反映

- `docs/functional-design.md` の DataStore コンポーネントセクションに高レベル API を追記
- `docs/repository-structure.md` は変更不要（ファイル増減なし）

## 受け入れ条件

- [ ] DataStore に append_play_log / load_play_logs / count_play_logs / load_best / save_best / update_best_if_better が実装されている
- [ ] GameManager の `_save_play_log` / `_load_previous_score` がスタブから本実装に置き換わっている
- [ ] 反射タップ単体プレイで 2 回目以降に「前回比 +XX」が表示される
- [ ] 反射タップ単体プレイでベスト更新時に「ベスト更新！」バッジが表示される
- [ ] GUT テスト 11+ 件追加、全 GUT 67+/67+ パス
- [ ] godot --headless --quit exit=0
- [ ] 既存テストのリグレッション 0
- [ ] 静的チェック: 生 hex / 絶対配置 / modulate 違反 0 件

## スコープ外

- 他ミニゲーム (次タスク)
- DataStore のスキーママイグレーション機能 (schema_migrator.gd は別タスク)
- localStorage のサイズ制限対策 (ログ件数の上限管理は将来タスク)
- バックアップ・リストア機能
- データエクスポート (シェア URL のスコア込み形式は別タスク)
