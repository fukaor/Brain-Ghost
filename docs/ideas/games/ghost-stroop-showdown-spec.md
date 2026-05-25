# 🎨 色文字ストループ 詳細設計書 v1.1

> **親ドキュメント**: `brain_training_gdd_v1.3.md` §4-3
> **最終更新**: 2026-05-20
> **ステータス**: Ready for Week 3 実装
> **実装者**: ねこぽ / ReigalLabs
> **対応能力軸**: 注意力（レーダーチャート §10b）

> **変更履歴**:
> - v1.1 (2026-05-20): レビュー反映。ゲーム名を GDD 命名体系に準拠し「色文字ストループ」に変更（旧「ストループ・ショーダウン」）。ティア解放条件の「正答率」定義を明確化（§4-3）。図形干渉の操作原則を「画面中央の色を答える」で統一（§2-2）。生霊セリフを GDD v1.3 トーン規約に完全準拠（§7）。デイリーシード生成をティアから分離し Wordle 公平性を維持（§8）。計測精度の注意点を追加（§10-4）。MVP 範囲を T1〜T3（Shape 含む）に明確化（§11）。
> - v1.0 (2026-05-20): 初版。競合調査（Focusaur Stroop / Hacaro StroopTest / EncephalApp / Brain Test: Stroop Effect / Stroop効果テスト / みんなの脳トレ「判断力」/ PEAK「Color Match」/ Lumosity「Color Match」等 8 本）を経て、30 秒タイムアタック＋干渉段階制＋言語非依存モードを設計。GDD §5b ゴースト対戦・§5e ゴースト生霊キャラクタと統合。

---

## 1. 概要

### 1-1. コンセプト

**「色と文字の干渉に打ち勝て。30 秒で注意力を鍛える色文字ストループ」**

GDD §4-3 の基本設計を深掘りし、**言語非依存の干渉メカニクス**（色＋形状、色名に加え図形干渉を導入）と**段階的な干渉強度**で、既存ストループ系ゲームの「慣れると単調」「色覚多様性に非対応」「言語依存で海外展開不可」の 3 大問題を構造的に解決する。

### 1-1b. ゲーム名と命名体系

GDD のミニゲーム命名には 2 つの体系がある:

| 体系 | 対象 | 命名例 | 共通点 |
|---|---|---|---|
| **「ゴースト○○」体系** | 決闘系・一本勝負系（ゴーストとの対戦がゲーム体験の核心） | ゴースト7番勝負、ゴースト一本勝負 | プレイ中にゴーストとの勝敗が逐次表示される |
| **日本語名体系** | タイム系・クリア系（ゴースト対戦は結果画面で比較） | 順番記憶、数字さがし、神経衰弱ライト | プレイ中のゴースト表示はプログレスバーまたは非表示 |

本ゲームは**タイム系**（プレイ中はプログレスバーで比較、結果画面で勝敗判定）のため、**日本語名体系**を採用し「色文字ストループ」とする。「ストループ」はストループ効果の認知度が日本語圏でも一定あるため（脳トレ文脈でよく使われる用語）、そのまま採用。

### 1-2. 核のメカニクス

```
[刺激提示]  →  [干渉処理]  →  [回答選択]  →  [正誤判定 + 次の問題]
  即時          脳内 0.5〜1.5秒    タップ         0.1秒
```

1. 画面中央に **干渉刺激**（色名文字を別の色で表示、または図形内に矛盾する色名テキスト）が提示される
2. プレイヤーは **「画面中央の色」** を回答する（全刺激タイプ共通の操作原則。§2-2 参照）
3. 画面下部の 4 つの回答ボタンから正しい色をタップ
4. 30 秒間に何問正解できるかでスコアを算出

### 1-3. 差別化ポイント（競合類型との比較）

| 類型 | 代表例 | 問題点 | 本作の改善 |
|---|---|---|---|
| A. 標準ストループ（色名文字のみ） | Hacaro StroopTest / EncephalApp | 慣れると干渉が弱まり天井に達する | **干渉段階制（§4）**で段階的に干渉強度を上げる |
| B. Yes/No 判定型 | PEAK「Color Match」/ Lumosity「Color Match」 | 50% の確率で正解可能。ストループ効果の計測精度が低い | **4 択方式**で偶然正解率を 25% に引き下げ |
| C. 色名漢字のみ（日本語特化） | みんなの脳トレ「判断力」 | 日本語読めないと成立しない。色覚配慮なし | **図形干渉モード（§2-2）**で言語非依存を実現 |
| D. 単純タイムアタック | Stroop効果テスト / memorymatching.com | 速度だけで正確性が軽視される | **正答＋誤答のネットスコア**で正確性を重視 |
| E. 広告過多 | Brain Test: Stroop Effect / Word or Color | 毎ゲーム後に広告。フリーズバグ報告あり | GDD §7 広告設計に準拠。プレイ中広告ゼロ |

### 1-4. ストループの本質と本作のスタンス

ストループ効果は「自動処理（文字を読む）」と「制御処理（色を識別する）」の干渉現象。認知心理学では前頭葉の注意制御機能を測定する標準的パラダイムとして 1935 年の Stroop 論文以来使われ続けている。

本作では：
- **エンターテインメント目的**であることを明示（GDD §13 リスク対策に準拠）
- 臨床的な干渉量（Incongruent vs Congruent の反応時間差）は計測するが、医学的診断には使わない
- 非母語話者が有利になる問題（Focusaur ユーザーレビューで複数報告）を**図形干渉モード**で構造的に解消

---

## 2. ゲームルール

### 2-1. 全体の流れ

```
┌─ 30 秒タイムアタック ────────────────┐
│ 1. 刺激提示（画面中央に干渉文字/図形）│
│ 2. 4 択回答ボタンから正しい色をタップ  │
│ 3. 正誤判定 → 次の問題（即時遷移）    │
│ 4. 繰り返し（30 秒間）               │
└──────────────────────────────────────┘
  ↓
結果表示（正答数・誤答数・平均反応時間・ゴースト勝敗）
```

### 2-2. 刺激の種類と統一操作原則

#### 操作原則（全刺激タイプ共通）

> **「画面中央の色を答える」** — これが唯一のルール。

刺激の形式が変わっても、プレイヤーが行う判断は常に同じ: **画面中央に表示されているものの「色」をタップで回答する**。文字が何を言っているか、図形が何の形かは無視する。

この統一原則により:
- 刺激タイプが混在する T3 以降でも操作迷いが生じない
- オンボーディングで一度教えれば、ティアが上がっても追加説明不要
- 7番勝負の「ターゲットがラインに来た瞬間にタップ」と同様の、ゲームを貫く一貫した操作原則

#### 刺激タイプ

ストループの干渉強度を段階的に制御するため、3 種類の刺激を設計する。

| 種類 | 画面中央の表示 | 「画面中央の色」とは | 干渉源 | 干渉強度 |
|---|---|---|---|---|
| **Congruent（一致）** | 色名テキスト（例：赤色で「あか」） | テキストの表示色（= 赤） | なし（文字の意味と色が一致） | なし |
| **Incongruent（不一致）** | 色名テキスト（例：青色で「あか」） | テキストの表示色（= 青） | 文字の意味「あか」が干渉 | 高 |
| **Shape（図形干渉）** | 色付き図形 + 内部に色名テキスト（例：青い■の中に「あか」） | **図形の塗りつぶし色**（= 青） | 文字の意味「あか」＋ 図形の形状認知が干渉 | 最高 |

**図形干渉の設計意図**:
- Focusaur の Shape Stroop Test から着想を得た発展形
- 「画面中央の色を答える」原則は維持。テキスト単体なら「テキストの色」、図形なら「図形の色」と対象が一貫して「最も目立つ色要素」を指す
- 図形内のテキストが矛盾する色名 → 二重干渉（形状知覚 + 文字読みの両方が色判断を妨害）
- **言語非依存**: v2.0 英語対応時も図形干渉はそのまま使える

| 出現比率 | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|
| Congruent | 50% | 30% | 20% | 0% | 0% | 0% |
| Incongruent | 50% | 70% | 50% | 60% | 40% | 0% |
| Shape | 0% | 0% | 30% | 40% | 40% | 50% |
| 逆ストループ | 0% | 0% | 0% | 0% | 20% | 50% |

### 2-3. 使用する色

色覚配慮と日本語圏の馴染みを両立する **4 色体系**:

| 色 | 通常表示 | 色覚配慮モード | 形状アイコン |
|---|---|---|---|
| **あか** | `#E53935` | `#E53935`（赤は維持） | ● |
| **あお** | `#1E88E5` | `#1565C0`（濃青に調整） | ▲ |
| **みどり** | `#43A047` | `#FFB300`（黄色に置換） | ■ |
| **きいろ** | `#FDD835` | `#7B1FA2`（紫に置換） | ◆ |

**色覚配慮モードの設計思想**:
- GDD §9 で「みんなの脳トレで『色弱にはムリ』と指摘済み」を改善対策として明記
- 赤緑色覚異常（P 型・D 型、男性の約 5%）への対応が最優先
- 色覚配慮モード ON 時: みどり → 黄、きいろ → 紫 に置換し、全色が明度・色相の両方で識別可能に
- 形状アイコン（●▲■◆）を回答ボタンに常時併記（色だけでなく形でも識別可能）
- 色覚配慮モード ON 時、ひらがなラベルも変更（「みどり」→「きいろ」、「きいろ」→「むらさき」）

### 2-4. 回答ボタンの配置

```
画面下部に 4 つの色ボタンを横一列に配置

┌────┐ ┌────┐ ┌────┐ ┌────┐
│ ●  │ │ ▲  │ │ ■  │ │ ◆  │
│あか│ │あお│ │みどり│ │きいろ│
└────┘ └────┘ └────┘ └────┘
```

**ボタン配置のランダム化**:
- **問題ごとにボタンの並び順をシャッフルする**
- 固定配置だと「位置記憶」で解けてしまい、ストループ効果の計測精度が下がる
- Hacaro StroopTest やストループ効果2 アプリでも採用されている手法
- ただし**毎問シャッフルは認知負荷が高すぎる**ため、**3〜5 問ごとにシャッフル**（ブロック単位）
- ティアが上がるとシャッフル頻度も上がる（§4-1 参照）

### 2-5. 判定ルール

| 判定 | 条件 | スコア影響 |
|---|---|---|
| **正解** | 正しい色のボタンをタップ | +100 pts |
| **誤答** | 間違った色のボタンをタップ | −50 pts（ペナルティ） |
| **タイムアウト** | 3 秒以内に回答しない場合、自動で次の問題へ | 0 pts（加減なし） |

**誤答ペナルティの設計意図**:
- 正答のみカウントだと「とりあえず押しまくる」戦略が最適になる
- −50 pts のペナルティで「速さ vs 正確性」のトレードオフを作る
- ただし GDD §6 の赤禁止ルールに従い、誤答表示はグレーフラッシュ（赤は使わない）

---

## 3. 画面レイアウト

### 3-1. プレイ画面

```
┌──────────────────────────────────────┐
│ 🎨 色文字ストループ     ⏱ 18秒      │  ← 上部 HUD
│                                      │
│ 👤 今日:       ████████░░ 8問        │  ← ゴーストプログレスバー
│ 👻 いつもの自分: ██████░░░░ 6問       │     (タイム系ゲーム表示)
│                                      │
│                                      │
│              「 あか 」               │  ← 刺激文字（青色で表示）
│                                      │     フォント: 48sp 太字
│       → 画面中央の色を答えよう        │     操作原則リマインダ（初回のみ表示）
│                                      │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐        │  ← 回答ボタン 4 択
│  │ ●  │ │ ▲  │ │ ■  │ │ ◆  │        │     各ボタン最低 48dp
│  │あか│ │あお│ │みどり│ │きいろ│        │     タップ領域 56dp 以上
│  └────┘ └────┘ └────┘ └────┘        │
│                                      │
│  正解: 8  誤答: 1  ⭐ベスト: 14      │  ← 下部ステータス
└──────────────────────────────────────┘
```

### 3-2. 図形干渉モードの表示（T3 以降）

```
┌──────────────────────────────────────┐
│              ┌──────┐                │
│              │      │                │
│              │ あか │  ← 青い■の中に │
│              │      │    「あか」の文字│
│              └──────┘                │
│                                      │
│   正解 = あお（画面中央の色 = 図形の  │
│               塗りつぶし色）         │
└──────────────────────────────────────┘
```

操作原則は変わらない:「画面中央の色を答える」→ 図形の塗りつぶし色 = 青 → 「あお」をタップ

### 3-3. 正誤フィードバック（0.1 秒）

```
正解時: 画面中央に ✓ マーク（緑フラッシュ 0.1 秒）→ 次の問題
誤答時: 画面中央に × マーク（グレーフラッシュ 0.1 秒）→ 次の問題
        ※ 赤フラッシュは使わない（GDD §6 赤禁止ルール）
```

フィードバックは **0.1 秒** で十分（ストループは速度が命。長い演出は 30 秒の貴重な時間を奪う）。

### 3-4. 結果画面

```
┌──────────────────────────────────────┐
│ 🎨 色文字ストループ 結果              │
│                                      │
│        正解 12 問  誤答 2 問          │
│        ネットスコア: 1,100 pts        │
│        前回比: ↑ +150 pts            │
│                                      │
│  👤 今日: 12 問    👻 いつもの自分: 10問│
│       いつもの自分に勝利！ +2問差     │
│                                      │
│  ┌─ 詳細 ──────────────────┐          │
│  │ 平均反応時間: 782 ms     │          │
│  │ 一致問題:   平均 520 ms  │          │
│  │ 不一致問題: 平均 890 ms  │          │
│  │ 図形干渉:   平均 1,020 ms│          │
│  │ 干渉量:     370 ms       │  ← おまけ情報│
│  │ (不一致 − 一致の差)      │          │
│  └──────────────────────────┘          │
│                                      │
│  [次のゲームへ]  [シェア]             │
└──────────────────────────────────────┘
```

**干渉量（Interference Score）**: 不一致条件と一致条件の平均反応時間差。ストループ効果の強さを数値化する追加指標。スコアには影響しないが、セルフチャレンジャー（ペルソナ 1）向けの深掘りデータ。

---

## 4. 干渉段階制（ティア対応）

GDD §5b の「ティア選択 + 段階的解放」原則に準拠し、ストループの干渉強度をティアで制御する。

### 4-1. ティア体系

| ティア | 名称（内部） | 刺激構成 | ボタン配置 | 制限時間 | 難度倍率 |
|---|---|---|---|---|---|
| **T1** | 入門 | Congruent 50% / Incongruent 50% | 固定 | 30 秒 | ×1.0 |
| **T2** | 基本 | Congruent 30% / Incongruent 70% | 固定 | 30 秒 | ×1.2 |
| **T3** | 標準 | Congruent 20% / Incongruent 50% / Shape 30% | 3 問ごとシャッフル | 30 秒 | ×1.5 |
| **T4** | 上級 | Incongruent 60% / Shape 40% | 毎問シャッフル | 30 秒 | ×1.8 |
| **T5** | 達人 | Incongruent 40% / Shape 40% / 逆ストループ 20% | 毎問シャッフル | 30 秒 | ×2.2 |
| **T6** | 超達人 | Shape 50% / 逆ストループ 50% | 毎問シャッフル + ダミーボタン 1 個追加（5 択化） | 30 秒 | ×2.8 |

### 4-2. 逆ストループ（T5 以降で導入）

通常のストループ: **「画面中央の色」** を答える
逆ストループ: **「画面中央の文字の意味」** を答える（色を無視する）

ゲーム中に「通常 → 逆」の切替が発生する:

```
画面上部に指示ラベルが表示:
  🎨 → 色を答えて！（通常ストループ）
  📖 → 文字を読んで！（逆ストループ）
```

- 切替タイミング: 5〜8 問ごとにランダム切替
- 切替時: 画面全体が一瞬パルス + 指示ラベル変更
- **タスクスイッチング（課題切替）コスト**を測定できる → 注意力の高度な指標
- 逆ストループ時も「画面中央を見て答える」の大原則は維持（答えるものが「色」→「意味」に変わるだけ）

### 4-3. 解放条件

GDD §5b の原則に準拠:

```
解放条件: 現在ティアで直近 5 回中 3 回、正答率 70% 以上を達成
```

**正答率の定義**:

```
正答率 = correct / (correct + wrong)
```

- **タイムアウト（未回答）は分母に含めない**。タイムアウトはスコアに影響しない（0 pts）ため、解放条件にも影響しない
- 例: 正解 10 問・誤答 2 問・タイムアウト 3 問 → 正答率 = 10 / (10 + 2) = **83%** → 条件達成

**なぜ 70% か**（一本勝負の「5 回中 3 回正解」との対比）:
- 一本勝負は「正解/不正解」の二値。ストループは連続回答のため、完答率で判定する方が適切
- 80% だと T3（Shape 混在）で解放が厳しすぎる可能性。MVP テストプレイで 70%/80% を A/B 比較予定
- T1 は初回から解放
- 各ティア独立のゴーストデータを保持
- 解放されたティアは再ロックしない

---

## 5. スコア算出

### 5-1. ネットスコア

```gdscript
func calculate_stroop_score(correct: int, wrong: int, tier_multiplier: float) -> int:
    var net = correct * 100 - wrong * 50
    return int(max(0, net) * tier_multiplier)
```

**例**: T3 で正解 12 問・誤答 2 問の場合
- ネット = 12 × 100 − 2 × 50 = 1100
- スコア = 1100 × 1.5 = **1650 pts**

### 5-2. GDD §6 スコア表との整合

GDD §6 の式: `正答1問=100点 − 誤答1回=50点`
本 spec はこれを踏襲しつつ、ティア倍率を追加。

### 5-3. 反応時間の記録

スコアには直接影響しないが、問題ごとの反応時間を記録する:

```gdscript
var response_log = []
# 各問題ごとに記録
response_log.append({
    "stimulus_type": "incongruent",  # congruent / incongruent / shape / reverse
    "display_color": "blue",
    "text_content": "あか",
    "correct_answer": "blue",
    "player_answer": "blue",
    "is_correct": true,
    "is_timeout": false,
    "reaction_time_ms": 782,
    "timestamp_ms": 12300  # ゲーム開始からの経過時間
})
```

この `response_log` は:
1. ゴーストデータとして保存（§6 参照）
2. 結果画面の「干渉量」算出に使用
3. v1.2 以降のトレンドグラフのデータソース

---

## 6. ゴースト対戦との接続（§5b）

### 6-1. 比較対象

GDD §5b で定義された「直近 5 回のプレイ平均」を、色文字ストループでは**各秒時点の累計正答数**として保持する。

```python
# 保存データ構造
ghost_data = {
    "game": "stroop",
    "tier": "T3",
    "last_5_plays": [
        {
            "date": "2026-05-19",
            "total_correct": 11,
            "total_wrong": 3,
            "net_score": 950,
            "events": [
                {"time_ms": 1200, "correct": true},
                {"time_ms": 2800, "correct": true},
                {"time_ms": 4500, "correct": false},
                # ... 30秒分
            ]
        },
        # ... 直近 5 回分
    ]
}

# ゴースト表示用: 直近 5 回の events を平均化
# → 各秒時点での「平均正答数」を算出してプログレスバーに反映
def get_ghost_progress_at(elapsed_ms: int) -> float:
    totals = []
    for play in ghost_data["last_5_plays"]:
        count = sum(1 for e in play["events"]
                    if e["time_ms"] <= elapsed_ms and e["correct"])
        totals.append(count)
    return sum(totals) / len(totals)
```

### 6-2. プレイ中のゴースト表示

GDD §5b「タイム系ゲームのゴースト UI」に準拠:

```
│ 👤 今日:       ████████░░ 8問  │
│ 👻 いつもの自分: ██████░░░░ 6問 │
```

- ゴーストの進捗は事前計算済みのデータから再生（リアルタイムシミュレーション不要）
- バーは控えめなサイズ（ゲーム画面を圧迫しない）
- チラ見で「勝ってる/負けてる」がわかる程度

### 6-3. 初回プレイ時のゴースト

初回はゴーストデータが存在しない。**平均的な成人のストループ成績**を初期値として設定:

| ティア | 初期ゴースト正答数/30秒 | 根拠 |
|---|---|---|
| T1 | 10 問 | Focusaur 平均データ（congruent 混在で約 10〜12 問） |
| T2 | 9 問 | Incongruent 比率増加で 1〜2 問低下 |
| T3 | 8 問 | Shape 干渉追加でさらに低下 |
| T4〜T6 | 6〜7 問 | 高干渉条件での推定値 |

2 回目以降は自分の直近プレイがゴーストになる。

---

## 7. ゴースト生霊キャラクタとの接続（§5e）

### 7-1. モード

色文字ストループは「タイム系」ゲームのため、ゴースト7番勝負や一本勝負のような「決闘相手モード」は使わない。生霊は**常時「相棒モード（companion）」**で登場する。

```gdscript
# ゲーム開始前（ルール説明〜カウントダウン）
ghost_character.set_mode("companion")
ghost_character.set_dialogue("今日も一緒に頑張ろう。僕も色に惑わされないよう練習してるよ")

# プレイ中
# MVP では非表示（集中阻害回避）

# 結果画面（勝利）
ghost_character.set_dialogue("すごいね！ 前より確実に速くなってる")
# 結果画面（敗北）
ghost_character.set_dialogue("いい勝負だった！ 僕も追いつけるように頑張るね")
# 結果画面（ベスト更新）
ghost_character.set_dialogue("ベスト更新！ きみの集中力、本当にすごい！")
```

**v1.3 トーン規約チェック**:
- ✅「一緒に頑張ろう」「僕も練習してる」→ 並走者としての謙虚な姿勢
- ✅「いい勝負だった」→ ユーザーをリスペクト
- ❌ ~~「色に惑わされないで」~~（旧 v1.0: 指示口調で「上から目線」に該当）→ 修正済み
- ❌ ~~「でも干渉量は減ってるよ」~~（旧 v1.0: 「導いてあげる」スタンスに近い）→ 修正済み

### 7-2. ティア解放時のセリフ

GDD §5e のトーン規約（謙虚な練習仲間）に準拠:

```gdscript
# ティア解放時
ghost_character.set_dialogue("最近僕もこのレベルに挑戦し始めたんだ。一緒に頑張ろう")
```

### 7-3. 登場場面

| 画面 | 役割 | セリフ例 |
|---|---|---|
| ルール説明 | 初見ユーザへの補足 | "画面の真ん中の色を見てね。文字に惑わされるけど、慣れると楽しいよ" |
| カウントダウン | 期待値を上げる | "3…2…1…集中！" |
| プレイ中 | MVP では非表示 | — |
| 結果（勝利） | 祝福 | "すごいね！ 前より確実に速くなってる" |
| 結果（敗北） | 励まし | "いい勝負だった！ 僕も追いつけるように頑張るね" |
| 結果（ベスト更新） | 特別演出 | "ベスト更新！ きみの集中力、本当にすごい！" |
| ティア解放 | 成長報告 | "次のレベルでも一緒に練習しよう" |

---

## 8. パラメトリック生成（デイリーシード対応）

GDD §5c のデイリーシード方式に準拠。**全ユーザー共通の刺激シーケンス**を生成する。

### 8-1. シード生成とティアの分離

**設計原則: デイリーシードは刺激パターン（色・文字・図形の組み合わせ）を決定する。ティアは出現比率のフィルタリングのみを行う。**

これにより:
- 同じ日に T1 でプレイするユーザーも T3 でプレイするユーザーも、**同じ刺激プールの部分集合**を体験する
- Wordle 方式の「全員が同じ問題を解く」公平性が、ティアをまたいでも維持される
- X シェアで「同じ日のストループやってみて」が成立する（ティアが違っても基盤パターンは共通）

```gdscript
func generate_daily_stroop(seed: int) -> Array:
    """シードから全ティア共通の刺激プールを生成する。
    ティア別の出現比率フィルタリングは呼び出し側で行う。"""
    var rng = RandomNumberGenerator.new()
    rng.seed = seed

    var colors = ["red", "blue", "green", "yellow"]
    var pool = []

    # 30 秒間に最大 20 問程度 × 各タイプを十分に生成（余裕を持って 40 問）
    for i in range(40):
        var display_color = colors[rng.randi() % 4]
        var other_colors = colors.filter(func(c): return c != display_color)
        var interfere_color = other_colors[rng.randi() % 3]
        var shape_type = ["circle", "square", "triangle", "diamond"][rng.randi() % 4]

        pool.append({
            "index": i,
            "display_color": display_color,
            "congruent_text": color_to_japanese(display_color),
            "incongruent_text": color_to_japanese(interfere_color),
            "shape": shape_type,
            # 各タイプのバリエーションを事前計算
        })

    return pool

func select_stimuli_for_tier(pool: Array, tier: String) -> Array:
    """共通プールからティア別の出現比率に従って刺激を選出する。"""
    var ratios = get_tier_ratios(tier)
    var stimuli = []
    var type_counts = {"congruent": 0, "incongruent": 0, "shape": 0, "reverse": 0}

    for item in pool:
        var stim_type = weighted_select_type(ratios, type_counts)
        var stimulus = build_stimulus(item, stim_type)
        stimuli.append(stimulus)

    return stimuli
```

### 8-2. デイリー共通化の効果

- 全ユーザーが同じ色・文字の組み合わせプールを体験 → スコア比較が公平
- ティアが異なっても「今日の 3 問目は青地に『あか』だった」が共通話題になる
- X シェア URL からの流入でも同じパターンが再生される

---

## 9. アクセシビリティ設計

### 9-1. 色覚配慮モード

GDD §9 の指摘「みんなの脳トレで『色弱にはムリ』」への対応:

```
通常モード:
  ボタン = [🔴●あか] [🔵▲あお] [🟢■みどり] [🟡◆きいろ]

色覚配慮モード:
  ボタン = [🔴●あか] [🔵▲あお] [🟡■きいろ] [🟣◆むらさき]
  ※ みどり→きいろ、きいろ→むらさき に色・ラベル両方を置換
  ※ 形状アイコンを全モードで常時併記
```

### 9-2. ひらがな表記

GDD §4 の「言語非依存」原則と矛盾するが、MVP（日本語のみ）では:
- 色名は**ひらがな**（「あか」「あお」「みどり」「きいろ」）
- 漢字（「赤」「青」「緑」「黄」）ではなく、ひらがなを使う理由:
  - 漢字は画数が多く、色の認識を文字の形状認識が阻害するリスク
  - ひらがなの方がストループ干渉が強い（認知心理学研究で確認済み: 表語文字より表音文字の方が読みの自動化が強い）
  - 子供・外国人にも読みやすい

### 9-3. v2.0 英語対応時

```
英語モード:
  色名 = "RED" / "BLUE" / "GREEN" / "YELLOW"
  回答ボタン = 色パッチ + 英語テキスト

図形干渉モード:
  言語に依存しないため、そのまま流用可能
```

→ **図形干渉モード（T3 以降）は言語非依存のため、ローカライズコストゼロ**

---

## 10. 実装アーキテクチャ（Godot 4 / GDScript）

### 10-1. シーン構成

```
stroop.tscn (Node2D)
├── GameLogic (Node)
│   └── script: stroop.gd
├── UI (CanvasLayer)
│   ├── TimerDisplay (Label)
│   ├── GhostProgressBars (VBoxContainer)
│   │   ├── PlayerBar (ProgressBar + Label)
│   │   └── GhostBar (ProgressBar + Label)
│   ├── ScoreDisplay (Label)
│   ├── StimulusArea (CenterContainer)
│   │   ├── StimulusLabel (RichTextLabel)    -- 色名テキスト（色付き）
│   │   └── ShapeContainer (TextureRect)     -- 図形干渉モード時のみ表示
│   ├── ModeIndicator (Label)                -- 逆ストループ時の指示（T5+）
│   ├── OperationReminder (Label)            -- 「画面中央の色を答えよう」（初回のみ）
│   ├── AnswerButtons (HBoxContainer)
│   │   ├── ColorButton × 4 (Button)
│   │   └── ColorButton × 1 (Button, T6 ダミー用)
│   └── FeedbackOverlay (ColorRect + Label)  -- ✓/× フラッシュ
├── GhostCharacter (ghost_character.tscn インスタンス)
└── ResultPopup (stroop_result.tscn)
```

### 10-2. 主要スクリプト: stroop.gd

```gdscript
extends Node
class_name Stroop

# 定数
const GAME_DURATION_SEC = 30.0
const ANSWER_TIMEOUT_MS = 3000
const FEEDBACK_DURATION_SEC = 0.1
const COLORS = ["red", "blue", "green", "yellow"]

# 状態
var current_tier: String = "T1"
var daily_pool: Array = []    # シード由来の共通プール
var stimuli: Array = []       # ティア別にフィルタ済み
var current_index: int = 0
var correct_count: int = 0
var wrong_count: int = 0
var response_log: Array = []
var game_start_time_ms: int = 0
var stimulus_start_time_ms: int = 0
var is_reverse_mode: bool = false
var button_order: Array = []

# 参照
@onready var ghost_character = $GhostCharacter
@onready var stimulus_label = $UI/StimulusArea/StimulusLabel
@onready var shape_container = $UI/StimulusArea/ShapeContainer
@onready var timer_display = $UI/TimerDisplay
@onready var answer_buttons = $UI/AnswerButtons
@onready var mode_indicator = $UI/ModeIndicator
@onready var feedback_overlay = $UI/FeedbackOverlay
@onready var ghost_bars = $UI/GhostProgressBars

# ゴーストデータ
var ghost_progress_data: Array = []

func _ready():
    current_tier = TierManager.get_selected_tier("stroop")

    # Step 1: 共通プール生成（ティア非依存）
    daily_pool = generate_daily_stroop(DailySeed.get_today_seed())
    # Step 2: ティア別フィルタリング
    stimuli = select_stimuli_for_tier(daily_pool, current_tier)

    ghost_progress_data = GhostData.load_time_progress("stroop", current_tier)
    ghost_character.set_mode("companion")
    ghost_character.set_dialogue("今日も一緒に頑張ろう。僕も色に惑わされないよう練習してるよ")

    start_game()

func start_game():
    game_start_time_ms = Time.get_ticks_msec()
    present_stimulus(0)

func present_stimulus(index: int):
    if index >= stimuli.size():
        finish_game()
        return

    current_index = index
    var stim = stimuli[index]

    # 逆ストループ切替チェック（T5+）
    if stim.has("is_reverse_mode") and stim.is_reverse_mode != is_reverse_mode:
        is_reverse_mode = stim.is_reverse_mode
        update_mode_indicator()

    # 刺激表示
    if stim.type == "shape":
        stimulus_label.visible = false
        shape_container.visible = true
        render_shape_stimulus(stim)
    else:
        shape_container.visible = false
        stimulus_label.visible = true
        stimulus_label.text = stim.text_content
        stimulus_label.add_theme_color_override(
            "default_color", color_string_to_color(stim.display_color))

    # ボタン配置更新
    update_button_order(index)

    # タイマー開始
    stimulus_start_time_ms = Time.get_ticks_msec()
    answer_timeout_timer.start(ANSWER_TIMEOUT_MS / 1000.0)

func on_answer_button_pressed(color: String):
    answer_timeout_timer.stop()
    var reaction_ms = Time.get_ticks_msec() - stimulus_start_time_ms
    var stim = stimuli[current_index]
    var is_correct = (color == stim.correct_answer)

    if is_correct:
        correct_count += 1
        show_feedback(true)
    else:
        wrong_count += 1
        show_feedback(false)

    # ログ記録
    response_log.append({
        "stimulus_type": stim.type,
        "display_color": stim.display_color,
        "text_content": stim.text_content,
        "correct_answer": stim.correct_answer,
        "player_answer": color,
        "is_correct": is_correct,
        "is_timeout": false,
        "reaction_time_ms": reaction_ms,
        "timestamp_ms": Time.get_ticks_msec() - game_start_time_ms
    })

    # ゴーストバー更新
    update_ghost_bars()

    # 30 秒チェック
    var elapsed = (Time.get_ticks_msec() - game_start_time_ms) / 1000.0
    if elapsed >= GAME_DURATION_SEC:
        finish_game()
        return

    # フィードバック後に次の問題
    await get_tree().create_timer(FEEDBACK_DURATION_SEC).timeout
    present_stimulus(current_index + 1)

func _on_answer_timeout():
    # タイムアウト: 0 pts、正答率の分母にも含めない
    response_log.append({
        "stimulus_type": stimuli[current_index].type,
        "is_correct": false,
        "is_timeout": true,
        "reaction_time_ms": ANSWER_TIMEOUT_MS,
        "timestamp_ms": Time.get_ticks_msec() - game_start_time_ms
    })
    present_stimulus(current_index + 1)

func finish_game():
    var tier_multiplier = get_tier_multiplier(current_tier)
    var net_score = correct_count * 100 - wrong_count * 50
    var total_score = int(max(0, net_score) * tier_multiplier)

    GhostData.save_play("stroop", current_tier, response_log, correct_count, wrong_count)
    TierManager.check_unlock("stroop", current_tier, correct_count, wrong_count)

    ghost_character.set_mode("companion")
    var ghost_correct = ghost_progress_data[-1] if ghost_progress_data.size() > 0 else get_initial_ghost(current_tier)
    if correct_count > ghost_correct:
        ghost_character.set_dialogue("すごいね！ 前より確実に速くなってる")
    elif correct_count == ghost_correct:
        ghost_character.set_dialogue("いい勝負だったね。お互い成長してる")
    else:
        ghost_character.set_dialogue("いい勝負だった！ 僕も追いつけるように頑張るね")

    emit_signal("game_finished", total_score, correct_count, wrong_count)

func get_initial_ghost(tier: String) -> int:
    match tier:
        "T1": return 10
        "T2": return 9
        "T3": return 8
        _: return 7

func update_ghost_bars():
    var elapsed_ms = Time.get_ticks_msec() - game_start_time_ms
    var player_correct = correct_count
    var ghost_correct = GhostData.get_ghost_progress_at(
        "stroop", current_tier, elapsed_ms)
    ghost_bars.update(player_correct, ghost_correct)
```

### 10-3. ボタン配置シャッフル

```gdscript
func update_button_order(stimulus_index: int):
    var should_shuffle = false
    match current_tier:
        "T1", "T2":
            should_shuffle = false  # 固定配置
        "T3":
            should_shuffle = (stimulus_index % 3 == 0)  # 3問ごと
        _:
            should_shuffle = true  # 毎問

    if should_shuffle or stimulus_index == 0:
        button_order = COLORS.duplicate()
        button_order.shuffle()
        reorder_buttons(button_order)
```

### 10-4. 計測精度の注意点

7番勝負 spec §10-3 と同様の注意事項:

- **`Time.get_ticks_msec()` はフレーム非依存** なのでこれを使う
- `_process(delta)` の delta からは計算しない（フレームレート揺れの影響）
- Web 版（HTML5）ではブラウザの `performance.now()` がバックエンドで使われるため、同等の精度
- ストループの反応時間は 500〜2000ms レンジのため、モニタのリフレッシュレート（60Hz = 16.67ms 単位）の影響は 7 番勝負（100〜300ms レンジ）よりも小さい
- **ただし**、正誤フィードバック（0.1 秒）の描画遅延が次の刺激提示タイミングに影響する可能性あり。`await create_timer()` ではなく `SceneTreeTimer` の精度を確認する

---

## 11. MVP と v1.1 以降の境界

### v1.0 MVP（Week 3 実装）

| 項目 | 実装範囲 |
|---|---|
| コアゲーム | 30 秒タイムアタック、4 色 × 4 択 |
| 刺激タイプ | Congruent + Incongruent + **Shape（T3 で導入）** |
| ティア | **T1〜T3 まで実装**（T3 は Shape 含む） |
| 色覚配慮 | 形状アイコン常時併記 **+ 色置換モード**（4 色→4 色の差し替えのみ。実装コスト低） |
| ゴースト | タイム系プログレスバー表示 |
| 生霊キャラクタ接続 | `set_mode("companion")` + `set_dialogue` のみ |
| デイリーシード | ✅ 対応（ティア分離方式） |
| スコア | ネットスコア + ティア倍率 |
| 効果音 | 正解音・誤答音・タイマー警告音の 3 種 |
| 逆ストループ | 未実装（T5 以降、v1.1） |
| ボタン配置 | T1-T2 固定 / T3 ブロックシャッフル |

**MVP に T3（Shape）を含める理由**:
- Shape はストループの差別化要素（競合にゼロ）であり、初期テストプレイで反応を見たい
- Shape の実装は `ShapeContainer` + 色付け + テキスト配置のみ。追加工数は約 2h
- T3 なしだと MVP テスターが 2 ティアで飽きるリスク

### v1.1 拡張

| 項目 | 拡張内容 |
|---|---|
| ティア T4〜T6 | 逆ストループ + 5 択化 + 毎問シャッフル |
| 干渉量トレンド | 過去 30 日の干渉量推移グラフ |
| 図形バリエーション | 三角・六角形・星形の追加 |
| 音声応答モード | マイク入力で色名を声で回答（実験的。Brain Test: Stroop Effect のレビューでリクエストあり） |

### v1.2 以降（検討中）

- **エモーショナル・ストループ**: ポジティブ/ネガティブな単語を色付きで表示（PEAK「Happy River」の発想を応用）
- **数字ストループ**: 「3」を 5 個並べて「いくつある？」（数量と数字の干渉）
- **デュアルタスクモード**: ストループ + 暗算を同時進行（CogniFit の長時間集中コンセプトの応用）

---

## 12. 計測の妥当性

### 12-1. ストループ効果の計測

本作では以下の 3 指標を記録する:

| 指標 | 計算方法 | 用途 |
|---|---|---|
| **正答数** | 30 秒間の正解数 | スコア算出（メイン） |
| **平均反応時間** | 全正答の反応時間平均（タイムアウト除外） | 結果画面の詳細表示 |
| **干渉量** | Incongruent 平均 RT − Congruent 平均 RT | セルフチャレンジャー向け深掘り指標 |

### 12-2. 既存ツールとの比較

| ツール | 試行数 | 時間制限 | 判定方式 | 本作との関係 |
|---|---|---|---|---|
| 臨床ストループ検査 | 各条件 100 項目 | 条件ごとに計時 | 色名呼称 | 学術標準。本作は簡易版 |
| Focusaur Stroop | 無制限 | なし | 4 択クリック | スコア品質指標を参考 |
| PEAK Color Match | 不明 | 45 秒 | Yes/No | 50% 偶然正解を避けるため 4 択を採用 |
| Lumosity Color Match | 不明 | 不明 | Yes/No | 同上 |
| Hacaro StroopTest | 条件ごとに固定 | 計時 | 4 択タップ | 4 色 × 4 択の基本構成を参考 |
| みんなの脳トレ「判断力」 | 10 問程度 | 30 秒 | 4 択 | 色覚配慮なしの問題を改善 |

### 12-3. 脳年齢への変換

GDD §6 の脳年齢アルゴリズムに入力される注意力スコアは **ネットスコア（ティア倍率適用前）** そのもの。

- 15 問以上正解（誤答 0）= 若年（20 代相当）
- 10〜14 問正解 = 標準（30〜40 代）
- 9 問以下 = シニア（50 代以上）

※ 実際の変換係数は MVP 実装後のテストプレイデータで調整。

---

## 13. UX 細部

### 13-1. 初回オンボーディング

```
画面 1: "色文字ストループ"
       → "画面の真ん中の色を当ててね！"
画面 2: [一致問題の例]
       → "これは簡単。「あか」が赤色で書かれてるね → 答えは「あか」"
画面 3: [不一致問題の例]
       → "これが本番。「あか」だけど…色は青！ → 答えは「あお」"
画面 4: [練習 3 問]
       → "練習成功！ 本番は 30 秒だよ"
画面 5: [カウントダウン] → "3...2...1... スタート！"
```

**操作原則の刷り込み**: 画面 1〜3 で「画面中央の色を答える」を 3 回繰り返す。これにより T3 で図形干渉が出ても追加説明が不要になる。

### 13-2. 2 回目以降

- [スキップ] ボタンで即スタート（GDD §5 の説明画面仕様に準拠）
- カウントダウンのみ表示して開始

### 13-3. 音響設計

| 音 | タイミング | 長さ | 備考 |
|---|---|---|---|
| 正解音 | 正解タップ時 | 0.1 秒 | ピッ（軽い） |
| 誤答音 | 誤答タップ時 | 0.1 秒 | ブッ（低い） |
| タイマー警告 | 残り 5 秒 | 0.3 秒 | ティッティッ（焦り喚起） |
| 終了音 | 30 秒経過 | 0.5 秒 | ピピピッ |
| モード切替音 | 逆ストループ切替時（T5+） | 0.2 秒 | パルス音 |

BGM なし（ストループは集中力勝負。BGM は干渉を増やしすぎる）。GDD §9 に従い個別オンオフ可能。

### 13-4. アクセシビリティ

- 色覚配慮: §2-3 の色置換 + 形状アイコン併記
- フォント: 刺激テキストは 48sp。回答ボタンは 20sp 以上
- ボタンサイズ: 最低 48dp、タップ領域 56dp 以上
- 効果音のみでもプレイ可能（視覚情報が全て）
- 振動フィードバック: 正解=短振動、誤答=長振動（Android 版、設定でオン/オフ）

---

## 付録 A. 開発タスクリスト（Week 3 分）

| No | タスク | 工数目安 | 依存 |
|---|---|---|---|
| 1 | `stroop.tscn` 基本シーン作成 | 1h | — |
| 2 | `StimulusLabel` + 色付けロジック | 1h | 1 |
| 3 | `AnswerButtons` 4 択 + タップ処理 | 2h | 2 |
| 4 | 30 秒タイマー + ゲームループ | 1h | 3 |
| 5 | Congruent / Incongruent 刺激生成 | 1h | 4 |
| 6 | 正誤判定 + フィードバックオーバーレイ | 1h | 4 |
| 7 | デイリーシード対応（ティア分離方式） | 1h | 5 |
| 8 | ゴーストデータ読み書き + プログレスバー | 2h | 4 |
| 9 | スコア算出 (`calculate_stroop_score`) | 0.5h | 6 |
| 10 | `GhostCharacter` 連携（companion + セリフ） | 0.5h | §5e 実装済み前提 |
| 11 | 効果音実装 | 0.5h | 6 |
| 12 | 初回オンボーディング + カウントダウン | 1.5h | 10 |
| 13 | 結果画面（正答数・干渉量・ゴースト勝敗） | 2h | 9 |
| 14 | ティア T1〜T3 + 解放ロジック | 1.5h | 5 |
| 15 | 図形干渉モード（ShapeContainer）**← MVP 範囲** | 2h | 2, 5 |
| 16 | ボタン配置シャッフルロジック | 1h | 3 |
| 17 | 色覚配慮: 形状アイコン併記 + 色置換 | 1.5h | 3 |
| 18 | Web/Android 両方で動作確認 | 1.5h | 17 |
| **合計** | | **約 22h** | = 約 4 日（90分/日 × 15 セッション） |

→ Week 3 の他タスク（順番記憶・神経衰弱 + スコアリング + レーダーチャート）と並行。ストループは 4 日で完了可能。

---

## 付録 B. 競合から取り込んだ設計判断サマリー

| 要素 | パクリ元 | 採用箇所 |
|---|---|---|
| 4 色 × 4 択の基本構成 | Hacaro StroopTest / みんなの脳トレ「判断力」 | §2 全体構造 |
| Shape Stroop（図形干渉） | Focusaur Shape Stroop Test | §2-2 図形干渉モード |
| ボタン配置のランダム化 | ストループ効果2 / Hacaro | §2-4 ブロックシャッフル |
| 逆ストループの導入 | Hacaro（Color Naming + Incongruent 2 課題） / 臨床ストループ検査 | §4-2 逆ストループ（T5+） |
| 色覚配慮の形状アイコン | GDD §9（みんなの脳トレ不満から導出） | §2-3 / §9 |
| Yes/No ではなく 4 択 | PEAK/Lumosity の Yes/No 方式の問題点から逆算 | §1-3 偶然正解率の引き下げ |
| 干渉量（Interference Score）の表示 | 臨床ストループ検査の標準指標 | §3-4 結果画面 |
| 誤答ペナルティ | Focusaur のスコア品質指標 | §2-5 −50 pts |
| 広告過多の回避 | Brain Test: Stroop Effect レビュー不満 | GDD §7 準拠 |
| 音声応答リクエスト | Brain Test: Stroop Effect レビューの機能要望 | v1.1 検討候補 |

---

## 付録 C. 次の設計議論候補

1. **ひらがな vs 漢字**: ひらがな「あか」と漢字「赤」でストループ干渉量が異なる。MVP はひらがなで開始し、v1.1 で漢字モードを A/B テスト候補に
2. **BGM の有無**: ストループは「干渉への耐性」を鍛えるゲーム。BGM 自体が干渉源になり得る。意図的に BGM を「干渉要素」として T5+ に追加する案あり
3. **5 色への拡張**: T6 で 5 択化する際、5 色目を何にするか（紫 / オレンジ / ピンク）。色覚配慮モードとの整合性要検討
4. **タイムアウトの 3 秒設定**: 3 秒は長すぎるか。2 秒でもいいかもしれないが、初心者の離脱リスクとのトレードオフ
5. **干渉量のゴースト比較**: 正答数だけでなく「干渉量の改善」もゴースト比較対象にする案。ペルソナ 1 向けの深掘り指標として v1.2 で検討
6. **色名の表示フォント**: 太ゴシック vs 明朝体で干渉量が変わる可能性。フォント選択自体がティアの変数になり得る
7. **解放条件の閾値**: 70% vs 80%。T3（Shape 混在）での解放難易度を MVP テストプレイで A/B 比較

---

## 付録 D. 言語非依存性の検証

GDD §4 設計原則 1「全ゲーム言語非依存」との整合性:

| モード | 言語依存度 | 対応 |
|---|---|---|
| 色名テキスト（あか/あお/みどり/きいろ） | **依存あり** | v2.0 英語対応時にテキスト差し替え（ローカライズコスト: 極小） |
| 図形干渉モード（色付き図形 + 色名テキスト） | **テキスト部分のみ依存** | 同上 |
| 回答ボタン（色パッチ + 形状アイコン） | **非依存** | 色と形状でユニバーサルに識別可能 |

→ ストループは構造的に「色名の言語テキスト」を使うため、完全な言語非依存は不可能。ただし:
1. テキストは 4 単語のみ → ローカライズコストは最小
2. 図形干渉モードでは文字を読む必要性が低い（図形の色が正解）
3. 回答ボタンは色パッチ + 形状アイコンで言語不要

GDD §4 の原則は「知識問題（四字熟語・語彙）を排除する」が主旨。ストループの色名テキストは「知識」ではなく「認知干渉の素材」であり、原則の趣旨に反しない。

---

## 付録 E. レビュー対応ログ（v1.0 → v1.1）

v1.0 に対するセルフレビューで検出した 7 件の修正を記録。

| ID | 重要度 | 概要 | 修正内容 |
|---|---|---|---|
| C1 | 🔴 Critical | ゲーム名が GDD 命名体系と不整合 | 「ストループ・ショーダウン」→「色文字ストループ」に変更。命名体系を §1-1b で明文化 |
| C2 | 🔴 Critical | ティア解放条件「正答率」の定義が曖昧 | §4-3 に `正答率 = correct / (correct + wrong)`、タイムアウト除外を明記。閾値を 80%→70% に変更（A/B テスト候補として付録 C に記載） |
| C3 | 🔴 Critical | 図形干渉で「何の色を答えるか」の混乱リスク | §2-2 に統一操作原則「画面中央の色を答える」を新設。全刺激タイプで一貫した判断基準を明示 |
| M1 | 🟡 Major | 生霊セリフが v1.3 トーン規約に一部違反 | §7 の全セリフを書き換え。旧「色に惑わされないで」等の指示口調を排除。修正前後の差分を §7-1 に記載 |
| M2 | 🟡 Major | デイリーシードがティア依存で Wordle 公平性崩壊 | §8 をティア分離方式に全面書き換え。`generate_daily_stroop(seed)` と `select_stimuli_for_tier(pool, tier)` の 2 段階に分離 |
| m1 | 🟢 Minor | 計測精度の注意点セクションが欠落 | §10-4 を新設。7番勝負 spec §10-3 と同等の内容 + ストループ固有の描画遅延注意を追加 |
| m2 | 🟢 Minor | MVP 範囲に Shape（T3）を含むか不明確 | §11 MVP 表を修正。T3（Shape 含む）を MVP 範囲に明確化。含める理由を追記 |

---

## 参照

- 親 GDD: `brain_training_gdd_v1.3.md` §4-3, §5b, §5e, §6, §9, §10
- ゴースト生霊キャラクタ機能設計: `docs/functional-design.md` A-10
- UI パターン: `docs/design/patterns.md` §5
- デイリーシード実装: `brain_training_gdd_v1.3.md` §5c
- ティア選択設計: `brain_training_gdd_v1.3.md` §5b
- 開発スケジュール: `brain_training_gdd_v1.3.md` §10 Week 3
- 競合ストループ系ツール:
  - Focusaur Stroop Test: https://www.focusaur.com/pages/stroop-effect-test
  - Focusaur Shape Stroop: https://www.focusaur.com/pages/shape-stroop-effect-test
  - Hacaro StroopTest: https://apps.apple.com/jp/app/hacaro-strooptest/id1447081813
  - Brain Test: Stroop Effect: https://apps.apple.com/us/app/brain-test-stroop-effect/id791503877
