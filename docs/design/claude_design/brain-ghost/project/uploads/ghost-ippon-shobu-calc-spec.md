# 🥋 ゴースト一本勝負（計算編） 詳細設計書 v1.3

> **親ドキュメント**: `brain_training_gdd_v1.2.md` §4-1（フラッシュ暗算の再設計）
> **姉妹ドキュメント**: `ghost-7ban-shobu-spec.md`（反射タップ版「ゴースト 7 番勝負」）
> **最終更新**: 2026-04-25
> **ステータス**: Ready for Week 1-2 実装
> **実装者**: ねこぽ / ReigalLabs
> **対応能力軸**: 計算力（レーダーチャート §10b）

> **変更履歴**:
> - v1.3 (2026-04-25): v1.2 のペーパーレビューを反映。**(1) 適正ティア判定の最低プレイ数を 3 → 5 回に**。**(2) 解放条件を「1 回正解」から「直近 5 回中 3 回正解」に厳格化**。**(3) デイリーチャレンジを「デフォルトティア優先」に統一**（§8 と §14-5 の矛盾解消）。**(4) ホーム画面を折りたたみ式に**（適正 ± 1 ティアのみデフォルト表示）。**(5) データ構造から play_count, win_count を削除**（必要時に last_5_plays から計算）。加えて、**緩和ロジックの段階化**、**T6-T7 答え 4 桁防止**、**「練習仲間→いつもの自分」専用演出化**、**音響表の再生フェーズ明記**、**台詞のリソースファイル化** を反映。
> - v1.2 (2026-04-25): 適応難度の自動切替を廃止し、ユーザー主導のティア選択 + 段階的解放方式に変更。
> - v1.1 (2026-04-25): 適応難度システム（自動ティア切替）+ 謙虚な練習仲間人格を導入。
> - v1.0 (2026-04-25): 初版（リブート）。1 試合形式に再設計。

---

## 1. 概要

### 1-1. コンセプト

**「自分のレベルを自分で選び、過去の自分とフラッシュ暗算の一本勝負」**

反射版「ゴースト 7 番勝負」が短いラウンドの連続なら、計算編は **1 試合に集中する一本勝負**。8 段階の難度ティアから自由に選べることで、ユーザーが自分の実力と気分に合わせて挑戦できる。上位ティアは段階的解放制で、達成感を持って次のレベルへ進む。

### 1-2. 核となる設計思想

**「自分との闘い」をユーザーの主導権で実現する**:

```
ユーザーが自分の適正を見極める
    ↓
ユーザーが今日のティアを選ぶ
    ↓
そのティアのゴースト（過去の自分）と一本勝負
    ↓
直近5回中3回正解できたら次のティアが解放される
    ↓
新たな挑戦をユーザー自身が決める
```

これにより:
- **級位や段位といった外部基準を持ち込まない**（コンセプト一貫性）
- **天井問題を構造的に解決**（8 ティアと各ティアのベスト更新が永続目標）
- **すべて「自分との闘い」の中で完結**（ゴーストもユーザーも共に成長する仲間）
- **ユーザーが完全な主導権を持つ**

### 1-3. 核のメカニクス

```
[ホーム画面でティア選択]
       ↓
[予告]  →  [数字フラッシュ]  →  [入力 + ゴーストCD]  →  [判定]  →  [結果演出]
 1.5秒      4〜5秒              約8〜20秒              瞬間       約8秒
       ↓
[ティア解放演出（条件達成時のみ）]
```

### 1-4. ゴーストカウントダウンバー

入力フェーズ中も「過去の自分」が見える緊張感が体験の核。

```
フラッシュ最終枚表示と同時にバー満タン
    │  バー満タン  👻 [████████████]
    ↓
時間経過とともに減少
    │  バー半分    👻 [██████░░░░░░]
    ↓
ゴーストの解答時刻に到達
    │  バーゼロ    👻 [░░░░░░░░░░░░] ⚡ "解けたよ"
```

---

## 2. ゲームルール

### 2-1. 全体の流れ

```
┌─ ホーム画面 ──────────────────┐
│ ▼ あなたの戦績（折りたたみ式）  │
│ T2 ✓ ベスト 920                 │
│ T3 ✓ ベスト 1,150 【適正】     │ ← デフォルト 3 ティア表示
│ T4 ✓ ベスト 980                 │
│ [全ティアを表示]                │
│ [今日のチャレンジ] [ティア選択]│
└────────────────────────────────┘
       ↓
┌─ ゲーム開始 ──────────────────┐
│ 1. 予告表示（1.5 秒）          │
│ 2. 数字フラッシュ              │
│ 3. テンキー + ゴースト CD     │
│ 4. 確定 or タイムアウト       │
│ 5. 判定 → 結果演出            │
│ 6. (条件達成時) 解放演出       │
└────────────────────────────────┘
```

### 2-2. 判定ルール

| 判定 | 条件 | 結果 | 演出 |
|---|---|---|---|
| **PERFECT** | 正解 + ゴースト CD バー残量 50% 以上 | 圧勝 | ⭐ 金色フラッシュ + ファンファーレ |
| **GREAT** | 正解 + ゴースト CD バー残量 1〜49% | 勝利 | 白フラッシュ |
| **CLOSE** | 正解 + ゴースト CD バーゼロ ±200ms | 接戦勝利 | 通常演出 |
| **LOSE** | 正解 + ゴースト CD バーゼロ後 | 敗北 | グレー演出 |
| **WRONG** | 不正解 | 自動敗北 | 赤フラッシュ |
| **TIMEOUT** | 30 秒以内に確定なし | 自動敗北 | グレー |

### 2-3. 勝敗判定

```gdscript
func judge_match(player_correct: bool, player_delta_ms: int, ghost_delta_ms: int) -> bool:
    if not player_correct:
        return false
    return player_delta_ms < ghost_delta_ms
```

### 2-4. 入力仕様

- テンキー配置: 電卓配置（7-8-9 が上段）
- 答えの最大桁数: ティアに応じて変化（2-3 桁）
- 自動遷移: 想定最大桁数到達で自動確定
- 確定ボタン併設: 想定最小桁数の場合は `OK` 押下が必要
- 誤入力訂正: `⌫` で 1 文字削除、訂正中もタイマー進行

---

## 3. 画面レイアウト

### 3-1. ホーム画面（v1.3 で折りたたみ式）

**デフォルト表示**: 適正ティア ± 1 の 3 ティアのみ。`[全ティアを表示]` ボタンで全 8 ティア展開。

```
┌──────────────────────────────────────┐
│ 🥋 ゴースト一本勝負（計算編）          │
│                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━     │
│  ▼ あなたの戦績                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━     │
│                                      │
│  T2 (11枚 1桁)                        │
│  ✓ クリア済 / 👻 9.2 秒 / 勝率 65%   │
│  ベスト 920 pts                      │
│                                      │
│  T3 (12枚 1桁)             【適正】   │ ← デフォルトティア
│  ✓ クリア済 / 👻 10.1秒 / 勝率 50%   │
│  ベスト 1,150 pts                    │
│                                      │
│  T4 (12枚 1桁高速)                    │
│  ✓ クリア済 / 👻 12.8秒 / 勝率 30%   │
│  ベスト 980 pts                      │
│                                      │
│  [▽ 全ティアを表示]                   │ ← 折りたたみ展開
│                                      │
│  [今日のチャレンジ (T3)]              │
│  [ティア選択]                         │
└──────────────────────────────────────┘
```

**展開時の表示**:

```
┌──────────────────────────────────────┐
│  T1 (10枚 1桁)                        │
│  ✓ クリア済 / ベスト 850             │
│                                      │
│  T2, T3 (適正), T4                   │
│  （上記と同じ詳細表示）               │
│                                      │
│  T5 (13枚 1桁高速)                    │
│  ✓ 解放済 / 👻 未対戦 / —             │
│                                      │
│  🔒 T6 (12枚 1〜2桁混合)               │
│  解放条件: T5 での実力を磨こう        │
│                                      │
│  🔒 T7 (14枚 1〜2桁混合)               │
│  🔒 T8 (15枚 2桁高速)                  │
│                                      │
│  [△ 折りたたむ]                       │
└──────────────────────────────────────┘
```

**「適正」ラベルの判定（v1.3 で厳格化）**:
- そのティアでの **直近 5 回プレイのうち、勝率 40-60% のティア** を適正と表示
- 5 回未満のプレイ履歴しかないティアは適正判定の対象外
- 複数該当時は最上位ティア
- 該当なし時は最後にプレイしたティア（フォールバック）

**「ベスト」**: そのティアでの過去最高スコア。

**ロックされたティア（v1.3 で簡素化）**:
- 「🔒」アイコン + 「解放条件: T(N-1) での実力を磨こう」のみ表示
- 進捗（残り正解数など）は表示しない（v1.2 で「未来予知的すぎる」批判を反映）

### 3-2. プレイ画面（数字フラッシュフェーズ）

```
┌──────────────────────────────────────┐
│ 🥋 T3 / フラッシュ暗算 一本勝負       │
│                                      │
│  👻 いつもの自分: 10.1 秒で解答        │
│                                      │
│              ┌──────┐                │
│              │  4   │                │
│              └──────┘                │
│                                      │
│       表示中... ●●●●●●●○○○             │
└──────────────────────────────────────┘
```

### 3-3. プレイ画面（入力フェーズ + ゴースト CD バー）

```
┌──────────────────────────────────────┐
│ 🥋 T3 / フラッシュ暗算 一本勝負       │
│                                      │
│  👻 [██████████░░░░░] 残り 4.7 秒    │
│                                      │
│         合計は？                      │
│                                      │
│         ┌────────────┐                │
│         │   4 7 _    │                │
│         └────────────┘                │
│                                      │
│   ┌───┬───┬───┐                      │
│   │ 7 │ 8 │ 9 │                      │
│   ├───┼───┼───┤                      │
│   │ 4 │ 5 │ 6 │                      │
│   ├───┼───┼───┤                      │
│   │ 1 │ 2 │ 3 │                      │
│   ├───┼───┼───┤                      │
│   │ ⌫ │ 0 │OK │                      │
│   └───┴───┴───┘                      │
│                                      │
│  ⏱ 制限時間: 18.3 秒                 │
└──────────────────────────────────────┘
```

### 3-4. 結果画面（勝利時 PERFECT）

```
┌──────────────────────────────────────┐
│           ⭐ PERFECT ⭐               │
│         圧勝！ 君の勝利！              │
│                                      │
│  答え: 47                             │
│  ┌─────────────────────────┐         │
│  │ 👤 今日の自分: 4.2 秒 ★BEST│       │
│  │ 👻 いつもの自分: 7.8 秒   │         │
│  │  差: −3.6 秒（圧勝）      │         │
│  └─────────────────────────┘         │
│                                      │
│  T3 / スコア: 1,560 pts               │
│  前回比: +287 ⬆                       │
│  ベスト更新！ 🎉                       │
│                                      │
│  [次のゲームへ]  [もう一回]            │
└──────────────────────────────────────┘
```

### 3-5. 結果画面（敗北時・不正解時）

v1.2 と同じ。割愛。

### 3-6. ティア解放演出

T(N) で **直近 5 回中 3 回以上正解** した瞬間に表示:

```
┌──────────────────────────────────────┐
│             🔓 解放                   │
│        T4 (12枚 1桁高速) が解放されました │
│                                      │
│  👻「君の成長を見てきたよ。            │
│      次のレベルでも一緒に頑張ろう」    │
│                                      │
│  [挑戦してみる]  [今は T3 を続ける]    │
└──────────────────────────────────────┘
```

「挑戦してみる」を選ぶと **次回ホーム画面のデフォルトティアが T4 に**。
「今は T3 を続ける」なら現状維持（ホームから手動で T4 を選ぶことは常に可能）。

ホームに戻った時、解放されたティアにバッジ「NEW」が表示。次回プレイ時に消える。

### 3-7. SNS シェア時の表現

```
今日のフラッシュ暗算一本勝負
🥋 T3 で 勝利！ 4.2 秒で正解
スコア: 1,560 pts
brain.reigals.com/...
```

ティアラベルが SNS で実力指標として機能する。

---

## 4. 難度ティア体系

### 4-1. 難度ティア表

| ティア | 数字枚数 | 桁数 | 表示間隔（追い込み） | 答えの最大桁 | スコア倍率 |
|---|---|---|---|---|---|
| **T1** | 10 枚 | 1 桁 | 0.30 秒 | 2 桁 | × 1.0 |
| **T2** | 11 枚 | 1 桁 | 0.30 秒 | 2 桁 | × 1.1 |
| **T3** | 12 枚 | 1 桁 | 0.30 秒 | 2 桁 | × 1.25 |
| **T4** | 12 枚 | 1 桁 | 0.25 秒 | 2 桁 | × 1.4 |
| **T5** | 13 枚 | 1 桁 | 0.22 秒 | 2 桁 | × 1.6 |
| **T6** | 12 枚 | 1〜2 桁混合 | 0.30 秒 | 3 桁 | × 2.0 |
| **T7** | 14 枚 | 1〜2 桁混合 | 0.27 秒 | 3 桁 | × 2.5 |
| **T8** | 15 枚 | 2 桁 | 0.20 秒 | 3 桁 | × 3.0 |

**設計のポイント**:
- T1 (初心者) 〜 T8 (達人) で難度が段階的に上昇
- T6 で「混合」を導入（1 桁数字 8 枚 + 2 桁数字 4 枚、67% / 33%）
- 8 段階の根拠: 5 段階だと粗すぎ、10 段階だと細かすぎ

### 4-2. 段階的速度カーブ

各ティアで「ウォームアップ → 本番 → 追い込み」の 3 段階速度を採用:

| フェーズ | 表示間隔（T1〜T3）| 表示間隔（T4〜T5）| 表示間隔（T6〜T7）| 表示間隔（T8）|
|---|---|---|---|---|
| ウォームアップ（最初の 30%）| 0.6 秒 | 0.5 秒 | 0.6 秒 | 0.4 秒 |
| 本番（中盤 40%）| 0.4 秒 | 0.35 秒 | 0.4 秒 | 0.3 秒 |
| 追い込み（最後 30%）| 0.30 秒 | 0.25 秒 | 0.27 秒 | 0.20 秒 |

---

## 5. 段階的解放システム（v1.3 で厳格化）

### 5-1. 解放条件

- 初期解放: **T1 のみ**
- T(N) で **直近 5 回中 3 回以上正解** → T(N+1) が解放
- 解放されたティアはいつでも自由にプレイ可能
- ティアダウンの制限なし

### 5-2. 解放の永続性

一度解放されたティアは、その後どのような結果でも再ロックされない:
- 解放後にずっと不正解続きでも T(N) は解放されたまま
- 解放後に長期休止しても解放されたまま
- 最高ベストスコアやプレイ履歴は永久保持

### 5-3. v1.3 で「直近 5 回中 3 回正解」に厳格化した理由

| 条件 | v1.2 | v1.3 |
|---|---|---|
| 1 回正解で解放 | ✅ 採用 | ❌ 廃止 |
| 直近 5 回中 3 回正解 | ❌ 不採用 | ✅ 採用 |

**v1.3 での修正理由**:
- v1.2 設計だと「まぐれ正解 1 回で解放されるが、まだ実力不足」のケースが頻発
- 解放されたが勝率 0% のティアがホームに並ぶ
- 「適正ティアの可視化」と矛盾（実力に対して解放が早すぎる）
- 直近 5 回中 3 回正解 = 60% 正解率は「定着した」と見なせる水準
- 「直近 5 回」のロジックがゴースト中央値計算と整合

**ユーザー視点**:
- 解放には平均 5-10 回程度のプレイが必要
- 解放された時点で「次のティアでも勝負になる」実力が担保される
- ホーム画面の各ティアが「✓ クリア済 / 勝率 30-70%」のように健全に並ぶ

### 5-4. 全ティア解放後の長期目標

T8 まで解放されたユーザーへの長期目標:
- 各ティアのベストスコア更新
- 全ティア通算プレイ数
- 全ティア通算正解数
- T8 でのベストタイム
- v1.2 以降で追加される T9, T10（3 桁加算など）

---

## 6. ゴースト対戦との接続（§5b）

### 6-1. データ構造（v1.3 で簡素化）

各ティアで独立したゴーストデータを保持。**v1.3 では派生値（play_count, win_count）を保持せず、必要時に last_5_plays から計算**:

```python
ghost_data = {
    "game": "ghost_ippon_shobu_calc",
    "tier_data": {
        "T1": {
            "last_5_plays": [
                {"date": "2026-04-21", "correct": True, "delta_ms": 8500, "score": 850},
                {"date": "2026-04-22", "correct": True, "delta_ms": 9200, "score": 760},
                {"date": "2026-04-23", "correct": False, "delta_ms": null, "score": 0},
                {"date": "2026-04-24", "correct": True, "delta_ms": 7800, "score": 920},
                {"date": "2026-04-25", "correct": True, "delta_ms": 10500, "score": 720},
            ],
            "best_score": 920,  # ベストのみ別保持（過去全プレイから）
        },
        "T2": {...},
        # ティアごとに同じ構造
    },
    "unlocked_tiers": ["T1", "T2", "T3", "T4", "T5"],
    "default_tier": "T3",  # ユーザーが「挑戦してみる」を選んだティア
    "last_played_tier": "T3"
}
```

**派生値（必要時に計算）**:

```python
def get_play_count(tier: str) -> int:
    return len(ghost_data["tier_data"][tier]["last_5_plays"])

def get_correct_count(tier: str, limit: int = 5) -> int:
    plays = ghost_data["tier_data"][tier]["last_5_plays"][:limit]
    return sum(1 for p in plays if p["correct"])

def get_win_rate(tier: str) -> float:
    plays = ghost_data["tier_data"][tier]["last_5_plays"]
    if not plays:
        return 0.0
    wins = sum(1 for p in plays if p.get("player_win", False))
    return wins / len(plays)
```

### 6-2. ゴースト Δt の算出（緩和ロジック段階化）

```python
def get_ghost_delta(tier: str) -> int:
    plays = ghost_data["tier_data"][tier]["last_5_plays"]
    correct_plays = [p for p in plays if p["correct"]]

    if len(correct_plays) >= 3:
        # 3 回以上正解 → 中央値
        deltas = sorted([p["delta_ms"] for p in correct_plays])
        return deltas[len(deltas) // 2]
    elif len(correct_plays) == 2:
        # 2 回正解 → 平均値
        deltas = [p["delta_ms"] for p in correct_plays]
        return sum(deltas) / 2
    elif len(correct_plays) == 1:
        # 1 回正解 → その Δt と初期値の中間（v1.3 で段階化）
        return int((correct_plays[0]["delta_ms"] + TIER_INITIAL_DELTAS[tier]) / 2)
    elif len(plays) >= 5:
        # 5 回プレイ済みで全敗 → 初期値の 1.3 倍に緩和
        return int(TIER_INITIAL_DELTAS[tier] * 1.3)
    else:
        # データ不足 → 初期値
        return TIER_INITIAL_DELTAS[tier]
```

**v1.2 からの変更点**: 正解 1 回時の段差をなくすため、初期値との中間値を採用。連続不正解で凹んでるユーザーが運良く正解した時、急にゴーストが厳しくならない。

### 6-3. 各ティアの初期ゴースト Δt

| ティア | 初期ゴースト Δt |
|---|---|
| T1 | 12,000 ms |
| T2 | 11,000 ms |
| T3 | 9,000 ms |
| T4 | 7,000 ms |
| T5 | 5,500 ms |
| T6 | 4,500 ms |
| T7 | 3,500 ms |
| T8 | 2,500 ms |

### 6-4. ゴーストの呼称切替

| プレイ回数 | 呼称 | 説明 |
|---|---|---|
| 1〜3 回目 | **「練習仲間」** | 履歴が少ない |
| 4 回目以降 | **「いつもの自分」** | 直近 5 回中央値が安定算出 |

**v1.3 で専用演出化**: 4 回目のゲーム開始前に専用画面を表示:

```
┌──────────────────────────────────────┐
│                                      │
│     👻 いつもの自分から伝言           │
│                                      │
│  「お互いの戦い方が見えてきたね。     │
│   ここから先は、いつもの自分として    │
│   全力で戦うよ」                      │
│                                      │
│            [スタート]                 │
└──────────────────────────────────────┘
```

切替演出は各ティアで 1 回のみ表示。

---

## 7. ゴースト生霊キャラクタとの接続（§5e）

### 7-1. 人格設定

ゴースト生霊は **「謙虚な練習仲間」** として人格を統一する:

- ✅ ユーザーをリスペクトする
- ✅ 自分も日々練習している努力家
- ✅ ユーザーと共に上達する仲間（並走者）
- ❌ 上から目線・煽り・敵対的・試す態度
- ❌ 「許可を与える」「導いてあげる」スタンス

口調・性別・人称は **SD キャラクター制作時に正式定義**。本 spec の台詞は仮置き、トーンの方向性のみを定める。

### 7-2. 台詞ガイドライン（v1.3 でリソース化）

**v1.3 で台詞を設定ファイルに切り出し**: `dialogues/ghost_ippon_shobu_calc.json` のようなリソースファイルとして管理。SD キャラ確定後にバッチ更新可能。

```json
{
  "duelist": {
    "match_start": "今日もよろしく。最近僕も練習したよ",
    "input_phase_30pct": "もう少しで僕も解けそう",
    "input_phase_0pct": "解けたよ",
    "perfect": "すごい速さだったね、勉強になる",
    "great": "今日は君の方が一歩先だった",
    "close": "いい勝負だった、次は僕も頑張る",
    "lose": "今日は先に解けた。明日もよろしく",
    "wrong": "正解は{answer}だったね、次は一緒に当てよう"
  },
  "companion": {
    "tier_unlock": "君の成長を見てきたよ。次のレベルでも一緒に頑張ろう",
    "new_tier_first": "ここからは僕も初めて。一緒に挑戦しよう",
    "ghost_label_switch": "お互いの戦い方が見えてきたね。ここから先は、いつもの自分として全力で戦うよ"
  }
}
```

実装時は `DialogueManager.get("duelist.match_start")` のように呼び出す。

### 7-3. 表示位置

プレイ中はゴースト生霊をプレイ画面右上に小さく半透明で配置（反射版は左上、計算編は右上）。

---

## 8. パラメトリック生成（v1.3 で 4 桁防止）

### 8-1. 問題生成ロジック

```gdscript
func generate_daily_calc_problem(seed: int, tier: String) -> Dictionary:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed + tier_to_int(tier)

    var config = TIER_CONFIGS[tier]
    var numbers = []
    var total = 0

    for j in range(config.number_count):
        var n = generate_number_for_tier(rng, tier)
        numbers.append(n)
        total += n

    # v1.3: 4 桁防止チェック
    if total >= 1000:
        # 再生成（合計が 999 を超えないように）
        return generate_daily_calc_problem(seed + 1, tier)

    return {
        "tier": tier,
        "numbers": numbers,
        "answer": total,
        "flash_intervals": calculate_intervals(tier, config.number_count)
    }

func generate_number_for_tier(rng: RandomNumberGenerator, tier: String) -> int:
    if tier in ["T1", "T2", "T3", "T4", "T5"]:
        return rng.randi_range(1, 9)
    elif tier in ["T6", "T7"]:
        return rng.randi_range(1, 9) if rng.randf() < 0.67 else rng.randi_range(10, 99)
    else:  # T8
        return rng.randi_range(10, 99)
```

### 8-2. デイリーチャレンジの提供方針（v1.3 で統一）

**「今日のチャレンジ」ボタンは、ユーザーのデフォルトティアの問題を提供**:

```gdscript
func on_daily_challenge_pressed():
    var default_tier = ghost_data.default_tier  # 解放時にユーザーが選んだティア
    var optimal_tier = calculate_optimal_tier()

    # デフォルトティアを優先、未設定時のみ適正ティア
    var tier = default_tier if default_tier else optimal_tier
    GameStarter.start_game(tier)
```

**v1.2 からの変更**: §8 と §14-5 の矛盾を解消し、**デフォルトティア優先** に統一。ユーザーが「挑戦してみる」を選んだティアが常に尊重される。

ボタン表示: `[今日のチャレンジ (T3)]` のようにティアを併記し、押す前にユーザーが内容を把握できる。

---

## 9. エラー処理

### 9-1. 不正解（WRONG）

不正解は自動敗北、スコア 0 点。**次ティアの解放カウントには加算されない**（直近 5 回中 3 回正解の条件）。

### 9-2. タイムアウト（TIMEOUT）

全体制限時間（T1-T5: 30 秒、T6-T8: 35 秒）以内に確定がない場合、自動敗北。

### 9-3. ゴースト CD バーゼロ後の処理

CD バーがゼロになっても、全体制限時間内であれば入力は受け付ける:
- 正解確定 → スコアは付くが、勝敗は LOSE
- 正解で次ティア解放カウントには加算される

### 9-4. 誤入力訂正

`⌫` ボタンで 1 文字削除。訂正中もタイマー・CD バー進行。

---

## 10. 実装アーキテクチャ（Godot 4 / GDScript）

### 10-1. シーン構成

```
ghost_ippon_shobu_calc.tscn (Node2D)
├── HomeScreen (CanvasLayer)
│   ├── TierList (VBoxContainer)
│   │   └── TierItem × 8
│   ├── ToggleAllTiersButton  ← v1.3 で新設
│   ├── DailyChallengeButton
│   └── TierSelectButton
├── GameLogic (Node)
│   └── script: ghost_ippon_shobu_calc.gd
├── UI (CanvasLayer)
│   ├── TitleHeader (Label)
│   ├── GhostStatsLabel (Label)
│   ├── NumberFlash (Control)
│   ├── ProgressDots (HBoxContainer)
│   ├── GhostCountdownBar (Control)
│   ├── InputArea (Control)
│   ├── GlobalTimer (Label)
│   ├── ResultPopup (Control, hidden)
│   ├── TierUnlockAnnouncement (Control, hidden)
│   └── GhostLabelSwitchAnnouncement (Control, hidden)  ← v1.3 で新設
├── GhostCharacter (ghost_character.tscn インスタンス)
└── DialogueManager (Node, autoload)  ← v1.3 で新設
    └── 設定ファイルから台詞を読み込み
```

### 10-2. 主要スクリプト: ghost_ippon_shobu_calc.gd

```gdscript
extends Node
class_name GhostIpponShobuCalc

const TIER_LIST = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8"]

const TIER_CONFIGS = {
    "T1": {"number_count": 10, "digit_mode": "1digit", "flash_speed": 1.0, "score_mult": 1.0},
    "T2": {"number_count": 11, "digit_mode": "1digit", "flash_speed": 1.0, "score_mult": 1.1},
    "T3": {"number_count": 12, "digit_mode": "1digit", "flash_speed": 1.0, "score_mult": 1.25},
    "T4": {"number_count": 12, "digit_mode": "1digit", "flash_speed": 1.2, "score_mult": 1.4},
    "T5": {"number_count": 13, "digit_mode": "1digit", "flash_speed": 1.35, "score_mult": 1.6},
    "T6": {"number_count": 12, "digit_mode": "mixed", "flash_speed": 1.0, "score_mult": 2.0},
    "T7": {"number_count": 14, "digit_mode": "mixed", "flash_speed": 1.1, "score_mult": 2.5},
    "T8": {"number_count": 15, "digit_mode": "2digit", "flash_speed": 1.5, "score_mult": 3.0}
}

const TIER_INITIAL_DELTAS = {
    "T1": 12000, "T2": 11000, "T3": 9000, "T4": 7000,
    "T5": 5500, "T6": 4500, "T7": 3500, "T8": 2500
}

var game_phase: String = "waiting"
var current_tier: String = "T1"
var problem: Dictionary = {}
var flash_end_time_ms: int = 0
var ghost_delta_ms: int = 0
var current_input: String = ""

@onready var ghost_character = $GhostCharacter
@onready var number_flash = $UI/NumberFlash
@onready var ghost_cd_bar = $UI/GhostCountdownBar
@onready var input_area = $UI/InputArea
@onready var ghost_stats_label = $UI/GhostStatsLabel
@onready var global_timer = $Timers/GlobalTimer
@onready var unlock_announcement = $UI/TierUnlockAnnouncement
@onready var ghost_label_switch = $UI/GhostLabelSwitchAnnouncement

func start_game(tier: String):
    current_tier = tier
    problem = generate_daily_calc_problem(DailySeed.get_today_seed(), tier)
    ghost_delta_ms = get_ghost_delta(tier)

    # v1.3: 4 回目開始時の切替演出
    var play_count = GhostData.get_play_count("ghost_ippon_shobu_calc", tier)
    if play_count == 3:  # これから 4 回目を始める
        await ghost_label_switch.show_and_wait()

    var ghost_label = "練習仲間" if play_count < 4 else "いつもの自分"
    ghost_character.set_mode("duelist")
    ghost_character.set_dialogue(DialogueManager.get("duelist.match_start"))
    ghost_stats_label.text = "👻 %s: %.1f 秒で解答" % [ghost_label, ghost_delta_ms / 1000.0]

    start_pre_announce()

func start_pre_announce():
    game_phase = "pre_announce"
    await get_tree().create_timer(1.5).timeout
    start_flash()

func start_flash():
    game_phase = "flashing"
    input_area.hide()
    ghost_cd_bar.hide()
    number_flash.show()

    var intervals = problem.flash_intervals

    for i in range(problem.numbers.size()):
        number_flash.show_number(str(problem.numbers[i]))
        $UI/ProgressDots.set_progress(i + 1, problem.numbers.size())
        await get_tree().create_timer(intervals[i]).timeout

    flash_end_time_ms = Time.get_ticks_msec()
    start_input_phase()

func start_input_phase():
    game_phase = "input"
    number_flash.hide()
    input_area.show()

    ghost_cd_bar.show()
    ghost_cd_bar.start_countdown(ghost_delta_ms)
    ghost_cd_bar.connect("ghost_completed", _on_ghost_cd_zero)

    var timeout = get_global_timeout_sec()
    global_timer.start(timeout)

func get_global_timeout_sec() -> float:
    return 35.0 if current_tier in ["T6", "T7", "T8"] else 30.0

func on_numpad_press(digit: int):
    if game_phase != "input":
        return
    var max_digits = get_max_answer_digits(current_tier)
    if current_input.length() >= max_digits:
        return
    current_input += str(digit)
    input_area.update_display(current_input)
    if current_input.length() == max_digits:
        on_input_confirm()

func on_input_confirm():
    if game_phase != "input" or current_input.is_empty():
        return

    var confirm_time_ms = Time.get_ticks_msec()
    var delta_ms = confirm_time_ms - flash_end_time_ms
    var input_value = int(current_input)
    global_timer.stop()
    ghost_cd_bar.stop_countdown()

    var is_correct = (input_value == problem.answer)
    record_match(is_correct, delta_ms)

func _on_ghost_cd_zero():
    ghost_character.set_dialogue(DialogueManager.get("duelist.input_phase_0pct"))

func _on_global_timer_timeout():
    record_match(false, 0)

func record_match(is_correct: bool, delta_ms: int):
    game_phase = "judged"

    var player_win = is_correct and (delta_ms < ghost_delta_ms)

    var reaction_score = 0
    if is_correct:
        reaction_score = int(3000.0 / (delta_ms / 1000.0))

    var score_mult = TIER_CONFIGS[current_tier].score_mult
    var duel_bonus = 200 if player_win else 0
    var total_score = int(reaction_score * score_mult) + duel_bonus

    var judgment = determine_judgment(is_correct, delta_ms, ghost_delta_ms)

    GhostData.save_play("ghost_ippon_shobu_calc", current_tier, {
        "correct": is_correct,
        "delta_ms": delta_ms,
        "player_win": player_win,
        "score": total_score,
        "date": Time.get_date_string_from_system()
    })

    show_result(judgment, is_correct, delta_ms, player_win, total_score)

    # v1.3: 解放判定を「直近 5 回中 3 回正解」に厳格化
    if is_correct:
        check_and_unlock_next_tier()

func check_and_unlock_next_tier():
    var current_index = TIER_LIST.find(current_tier)
    if current_index == -1 or current_index >= TIER_LIST.size() - 1:
        return  # T8 ならこれ以上解放なし

    var next_tier = TIER_LIST[current_index + 1]
    var unlocked = GhostData.get_unlocked_tiers("ghost_ippon_shobu_calc")

    if next_tier in unlocked:
        return  # 既に解放済み

    # v1.3: 直近 5 回中 3 回以上正解で解放
    var correct_count = GhostData.get_correct_count_in_recent("ghost_ippon_shobu_calc", current_tier, 5)
    if correct_count >= 3:
        GhostData.unlock_tier("ghost_ippon_shobu_calc", next_tier)
        unlock_announcement.queue_for_after_result(next_tier)
```

### 10-3. ホーム画面ロジック（v1.3 で折りたたみ式）

```gdscript
extends Control
class_name HomeScreen

var is_expanded: bool = false

@onready var tier_list = $TierList
@onready var toggle_button = $ToggleAllTiersButton

func _ready():
    refresh_tier_list()

func refresh_tier_list():
    var unlocked = GhostData.get_unlocked_tiers("ghost_ippon_shobu_calc")
    var optimal_tier = calculate_optimal_tier()
    var visible_tiers = get_visible_tiers(optimal_tier, unlocked)

    for tier in TIER_LIST:
        var item = tier_list.get_node(tier)
        var is_visible = tier in visible_tiers or is_expanded
        item.visible = is_visible

        if is_visible:
            var is_unlocked = tier in unlocked
            var is_optimal = (tier == optimal_tier)

            item.set_unlocked(is_unlocked)
            item.set_optimal_label(is_optimal)
            if is_unlocked:
                item.set_stats(GhostData.get_tier_stats(tier))
            else:
                # v1.3: ロックティアは解放条件のみ簡素表示
                item.set_unlock_condition("解放条件: T%d での実力を磨こう" % (tier_index(tier)))

    toggle_button.text = "△ 折りたたむ" if is_expanded else "▽ 全ティアを表示"

func get_visible_tiers(optimal: String, unlocked: Array) -> Array:
    """デフォルト: 適正ティア ± 1 のみ表示（v1.3 新設）"""
    var optimal_index = TIER_LIST.find(optimal)
    var visible = []
    for offset in [-1, 0, 1]:
        var idx = optimal_index + offset
        if idx >= 0 and idx < TIER_LIST.size():
            visible.append(TIER_LIST[idx])
    return visible

func calculate_optimal_tier() -> String:
    """v1.3: 最低 5 回プレイの条件追加"""
    var unlocked = GhostData.get_unlocked_tiers("ghost_ippon_shobu_calc")
    var candidates = []

    for tier in unlocked:
        var play_count = GhostData.get_play_count("ghost_ippon_shobu_calc", tier)
        if play_count < 5:  # v1.3: 5 回未満は判定対象外
            continue

        var win_rate = GhostData.get_win_rate("ghost_ippon_shobu_calc", tier)
        if 0.4 <= win_rate and win_rate <= 0.6:
            candidates.append({"tier": tier, "win_rate": win_rate})

    if candidates.is_empty():
        return GhostData.get_last_played_tier("ghost_ippon_shobu_calc")

    candidates.sort_custom(func(a, b): return tier_index(a.tier) > tier_index(b.tier))
    return candidates[0].tier

func _on_toggle_all_tiers_pressed():
    is_expanded = !is_expanded
    refresh_tier_list()

func _on_daily_challenge_pressed():
    """v1.3: デフォルトティア優先で統一"""
    var default_tier = GhostData.get_default_tier("ghost_ippon_shobu_calc")
    var optimal = calculate_optimal_tier()
    var tier = default_tier if default_tier else optimal
    GameStarter.start_game(tier)
```

### 10-4. 計測精度（ms）の注意点

- `Time.get_ticks_msec()` 採用（フレーム非依存）
- フラッシュ最終枚の終了時刻 = `flash_end_time_ms` を CD バー基準
- Web 版は `performance.now()` で同等精度
- 入力ボタンは ButtonUp で誤タップ防止

---

## 11. MVP と v1.1 以降の境界

### v1.0 MVP（Week 1-2 実装）

| 項目 | 実装範囲 |
|---|---|
| ホーム画面 | ティア選択 UI（折りたたみ式）、適正ラベル、ベスト表示 |
| コアゲーム | フラッシュ暗算 1 試合（T1〜T8）|
| 数字フラッシュ | ティア別の段階的速度カーブ + 桁数モード |
| ゴースト CD バー | 核ギミック、色変化、残り秒表示 |
| 入力 UI | 電卓配置テンキー、自動遷移、ティア別桁数対応 |
| 判定 | 6 段階 |
| ゴースト | ティア独立、初回〜3 回目「練習仲間」、4 回目以降「いつもの自分」、緩和ロジック段階化 |
| 段階的解放 | **直近 5 回中 3 回正解で次ティア解放**（v1.3 厳格化） |
| 解放演出 | 結果画面後の専用画面 |
| 切替演出 | 「練習仲間」→「いつもの自分」専用画面（v1.3 新設） |
| 生霊キャラクタ接続 | DialogueManager 経由 + 「謙虚な練習仲間」台詞 |
| デイリーチャレンジ | デフォルトティア優先で提供（v1.3 統一） |
| スコア | 反応時間 × 難度倍率 + 勝敗ボーナス |
| 効果音 | 13 種、判定別 + 解放音 + 切替演出音 |
| 4 桁防止 | 問題生成時のチェック（v1.3 追加） |

### v1.1 拡張

- 表情バリエーション、BGM 切替、結果演出強化
- 長期休止後のゴースト緩和
- ベスト更新を「勝利時のみ」に
- ティア別ゴースト生霊の見た目変化

### v1.2 以降

- そろばん表示モード、ライバルモード
- 3 桁加算ティア（T9, T10）
- 連続正解記録

---

## 12. 計測の妥当性

### 12-1. なぜユーザー主導 + 段階的解放（厳格化）か

| 方式 | 天井対策 | コンセプト整合性 | 主導権 | 解放の質 | 採用 |
|---|---|---|---|---|---|
| 固定難度（v1.0）| ❌ | ✅ | ❌ | — | ❌ |
| 適応難度（v1.1）| ✅ | ⚠️ | ❌ | — | ❌ |
| 1 回正解で解放（v1.2）| ✅ | ✅ | ✅ | ⚠️ 早すぎ | ❌ |
| **5 回中 3 回正解で解放（v1.3 採用）**| ✅ | ✅ | ✅ | ✅ | ✅ |

### 12-2. 既存ツールとの比較

| ツール | 解放条件 | 本作との関係 |
|---|---|---|
| Duolingo | レッスン完了率 80% | 本作の「5 回中 3 回 = 60%」より厳しい |
| Mental Math Cards | 一定スコア達成 | スコアベースの解放は v1.3 候補 |
| King of Math | ステージクリア（全問正解）| 全問正解は厳しすぎ、本作は 60% |

→ 60% 正解率は「定着した」と見なせる業界的な妥当値。

### 12-3. 統計的安定性

各ティア独立で、データが 4 回以上溜まれば中央値で安定。それ以下は段階的なロジック（中間値、平均値、初期値）で代替。

### 12-4. 脳年齢への変換

```python
def convert_to_brain_age(plays_by_tier: dict) -> int:
    best_scores = []
    for tier, data in plays_by_tier.items():
        if data.best_score > 0:
            tier_index = ["T1","T2",...,"T8"].index(tier)
            normalized = data.best_score / TIER_CONFIGS[tier].score_mult
            best_scores.append(normalized)

    if not best_scores:
        return 60

    avg_normalized = sum(best_scores) / len(best_scores)
    max_tier = max([tier_index for tier in plays_by_tier])

    if max_tier >= 7 and avg_normalized > 800:
        return 25
    elif max_tier >= 5 and avg_normalized > 700:
        return 35
    elif max_tier >= 3:
        return 45
    elif max_tier >= 2:
        return 55
    else:
        return 65
```

---

## 13. UX 細部

### 13-1. 初回オンボーディング

v1.2 と同じ。割愛。

### 13-2. 2 回目以降

- ホーム画面でティア選択
- 同じティアを連続プレイ: 結果画面の「もう一回」
- 別ティアに切り替え: 結果画面の「次のゲームへ」 → ホーム

### 13-3. 音響設計（v1.3 で再生フェーズ明記）

| 音 | タイミング | 長さ | 再生フェーズ |
|---|---|---|---|
| 予告音 | 予告開始 | 0.3 秒 | pre_announce |
| フラッシュ音 × 3 段階 | 表示間隔別 | 0.1〜0.05 秒 | flashing |
| 入力音 | テンキー押下 | 0.05 秒 | input |
| ゴースト CD 警告音 | 残量 30% 到達 | 0.2 秒 | input |
| ゴースト解答音 | CD ゼロ | 0.5 秒 | input |
| PERFECT 音 | PERFECT 判定 | 1.0 秒 | judged |
| GREAT 音 | GREAT 判定 | 0.5 秒 | judged |
| CLOSE 音 | CLOSE 判定 | 0.5 秒 | judged |
| LOSE 音 | LOSE 判定 | 0.6 秒 | judged |
| WRONG 音 | WRONG | 0.4 秒 | judged |
| ベスト更新音 | ベスト更新時 | 1.0 秒 | judged（result 画面）|
| ティア解放音 | 次ティア解放時 | 1.5 秒 | unlock_announcement 画面 |
| 切替演出音（v1.3）| 4 回目開始前 | 1.0 秒 | ghost_label_switch 画面 |

→ ベスト更新音とティア解放音は **別画面で時系列に再生** されるので重複しない。

### 13-4. アクセシビリティ

- 色覚配慮: ○/× アイコン併記
- フォント: 数字 64sp 以上、ms 表示 24sp 以上
- 効果音のみでもプレイ可能
- 振動フィードバック（Android）
- ボタン最小 48x48dp
- 下位ティアでの自由プレイ

### 13-5. テンキー UI 詳細

電卓配置採用。設定切替は v1.1 で検討。

### 13-6. ティア表示の方針

- ホーム画面で適正ティア ± 1 をデフォルト表示、折りたたみで全 8 ティア
- 「T3」のような中性的なラベル
- 「3 級」「上級」のような階層用語は使わない

---

## 14. ティア解放演出

### 14-1. 解放のトリガー（v1.3 で厳格化）

T(N) で **直近 5 回中 3 回以上正解** した瞬間に T(N+1) が解放。

```gdscript
func check_and_unlock_next_tier():
    var correct_count = GhostData.get_correct_count_in_recent(
        "ghost_ippon_shobu_calc", current_tier, 5
    )
    if correct_count >= 3:
        # 解放処理
        ...
```

### 14-2. 演出のフロー

正解確定 → 結果画面表示 → 裏で解放処理 → 結果画面の次ボタンで解放専用画面 → ユーザーの選択 → ホーム or 新ティアゲーム

### 14-3. 解放演出後の遷移（v1.3 で確定）

「挑戦してみる」を選んだ場合 → **ホーム画面に戻る**（直接新ティアのゲームを開始しない）

理由:
- ホーム画面でティア選択の主導権を保つ
- 新ティアの戦績欄を見せて、何が解放されたかをユーザーに認識させる
- すぐ始めたい場合はホームから新ティアを 1 タップで選べる

ホーム画面の **新ティアにバッジ「NEW」** を表示。次回プレイで消える。

### 14-4. 解放の頻度

各ユーザーごとに 1 ティアにつき 1 回のみ表示。

### 14-5. デフォルトティアの管理（v1.3 で統一）

```gdscript
# 解放後にユーザーが「挑戦してみる」を選んだ場合
GhostData.set_default_tier("ghost_ippon_shobu_calc", new_tier)

# ホームの「今日のチャレンジ」ボタン押下時
func on_daily_challenge_pressed():
    var default_tier = GhostData.get_default_tier("ghost_ippon_shobu_calc")
    var optimal_tier = calculate_optimal_tier()

    # v1.3: デフォルトティアを優先、未設定時のみ適正ティア
    var tier = default_tier if default_tier else optimal_tier
    GameStarter.start_game(tier)
```

---

## 付録 A. 開発タスクリスト（Week 1-2 分）

| No | タスク | 工数目安 | 依存 |
|---|---|---|---|
| 1 | `ghost_ippon_shobu_calc.tscn` 基本シーン | 1h | — |
| 2 | `NumberFlash` ノード | 2.5h | 1 |
| 3 | `NumPad` ノード（電卓配置、桁数可変）| 2.5h | 1 |
| 4 | `GhostCountdownBar` ノード | 2.5h | 1 |
| 5 | 入力検証ロジック（自動遷移・桁数判定）| 1.5h | 3 |
| 6 | Δt 計算ロジック | 1h | 2, 5 |
| 7 | 1 試合制御（フェーズ管理）| 1.5h | 4, 6 |
| 8 | ティア体系・解放管理（`GhostData` 拡張、5 回中 3 回正解）| 2.5h | 7 |
| 9 | **ホーム画面（折りたたみ式、適正 ± 1 表示）** | **4h** | 8 |
| 10 | デイリーシード対応（4 桁防止チェック含む）| 1.5h | 8 |
| 11 | ゴーストデータ読み書き（ティア独立、緩和ロジック段階化）| 2.5h | 8 |
| 12 | スコア算出（難度倍率込み）| 1h | 8 |
| 13 | **`DialogueManager` autoload + 設定ファイル管理** | **2h** | — |
| 14 | `GhostCharacter` 連携 + 呼称切替 | 1.5h | 13 |
| 15 | 効果音実装（13 種 + 解放音 + 切替演出音）| 2.5h | 7 |
| 16 | 結果演出（5 種、判定別）| 3h | 12 |
| 17 | ティア解放演出 | 2.5h | 8, 14 |
| 18 | **「練習仲間」→「いつもの自分」切替演出** | **1.5h** | 14 |
| 19 | 初回オンボーディング | 3h | 14 |
| 20 | Web/Android 動作確認 | 2h | 17, 19 |
| **合計** | | **約 41h** | = Week 1-2 で約 7 日（90 分/日 × 27 セッション）|

→ v1.2（35h）から +6h（ホーム画面の折りたたみ実装、DialogueManager、切替演出など）。共通基盤再利用で実工数 **約 33h**（Week 1-2 分散）。

**スケジュール**: GDD §10 の Week 1 想定（10.5h）を超過するため、**Week 1-2 で分散実装**。GDD v1.3 でスケジュール見直しが必要。

---

## 付録 B. 競合から取り込んだ設計判断サマリー

| 要素 | パクリ元 | 採用箇所 |
|---|---|---|
| 1 試合 = 10 口算の単位 | 日本フラッシュ暗算協会 公式検定 5 級 | §1, §4 T1 |
| ユーザー主導のレベル選択 | Mental Math Cards / Duolingo | §3-1, §5 |
| 段階的解放（5 回中 3 回正解）| Duolingo（80% より緩い、本作独自）| §5-3 |
| 段階的速度カーブ | 暗算の達人 | §4-2 |
| 数字フラッシュ表示 | フラッシュ暗算（日本伝統 / drillio）| §2 |
| ゴーストカウントダウンバー | レースゲームのゴースト機能 | §1-4 核ギミック |
| テンキー入力＋自動遷移 | Zetamac / FastMath | §13-5 |
| 1v1 対戦の物語性 | Matiks / Math Duel | §6 |
| デイリー共通問題 | Wordle / Nerdle / Mathler | §8 |
| 答え選択式の排除 | みんなの脳トレレビュー不満 | §13-5 |
| ゴースト = 謙虚な練習仲間 | Duolingo の owl の上から目線への反省 | §7 |
| 適正レベルの可視化 | 本作独自設計 | §3-1, §10-3 |
| 折りたたみ式ホーム | UI 一般論 | §3-1（v1.3 追加）|
| 台詞のリソース化 | GDScript 慣習 | §10-1（v1.3 追加）|

---

## 付録 C. 次の設計議論候補

### v1.0 → v1.3 で解決済み

- ~~天井問題~~ → 8 ティア + ベスト更新
- ~~級位の外部基準~~ → ユーザー主導のティア選択
- ~~適応難度の自動切替の不自然さ~~ → ユーザー主導で根本解決
- ~~初回「いつもの自分」違和感~~ → 「練習仲間」呼称 + 4 回目専用切替演出
- ~~適正ティア判定が新ティア解放直後に変~~ → 最低 5 回プレイ条件
- ~~解放が早すぎて勝率 0% のティアが並ぶ~~ → 5 回中 3 回正解で厳格化
- ~~デイリーチャレンジが §8 と §14-5 で矛盾~~ → デフォルトティア優先で統一
- ~~ホーム画面の情報過多~~ → 折りたたみ式
- ~~データ構造の冗長性~~ → 派生値削除
- ~~緩和ロジックの段差~~ → 段階化
- ~~T6-T7 の 4 桁問題~~ → 生成時チェック
- ~~SD キャラ未確定での台詞ハードコード~~ → リソースファイル化

### v1.3 で残っている論点

1. **ティア閾値（数字枚数・速度・桁数）のチューニング**: MVP テストで検証
2. **適正ティア判定の勝率レンジ（40-60%）**: 妥当か MVP 後に検証
3. **「練習仲間」→「いつもの自分」の切替タイミング（4 回目）**: 3 回目 / 5 回目とどちらが自然か
4. **解放条件「5 回中 3 回正解」の妥当性**: 60% より厳しい/緩いべきか
5. **「フラッシュ暗算」のネーミング維持**: T6 以降は混合・2 桁加算で「フラッシュ暗算」と呼べるか
6. **T6 の「1〜2 桁混合」の比率（67% / 33%）**: 妥当か
7. **GDD §10 Week 1 スケジュール見直し**: 41h を Week 1-2 にどう分散するか
8. **全ティア解放後の長期目標**: ベスト更新以外に追加すべき指標はあるか
9. **長期休止後のゴースト緩和**: v1.1 拡張で実装するか

---

## 付録 D. GDD §5b への逆輸入提案

**「ユーザー主導のティア選択 + 段階的解放はアプリ全体のコア哲学である」** という設計思想を GDD §5b に追記する。

### 提案内容

GDD §5b（ゴースト対戦システム）に以下を追加:

> ### ティア選択 + 段階的解放
> 
> 本アプリの全ミニゲームに、以下の設計原則を適用する：
> 
> 1. **複数の難度ティア**を用意し、各ティア独立のゴーストデータを保持
> 2. ユーザーが解放済みティアから自由選択
> 3. **解放条件は 1 つ下のティアで「直近 5 回中 3 回以上の条件達成」**
> 4. ティアは中性的なラベル（T1〜T8 など）で表示、級位用語は使わない
> 5. 解放演出は控えめに、ゴーストの成長報告として伝える

### 反射版への適用案

| ティア | ゴースト平均 Δt | ターゲット移動速度 | フェイク予告 | 解放条件 |
|---|---|---|---|---|
| T1 | 250ms 以上 | 標準 | なし | 初期解放 |
| T2 | 220ms | + 10% | なし | T1 で直近 5 回中 3 回 4 勝以上 |
| T3 | 200ms | + 20% | R7 のみ | T2 で同上 |
| ... | ... | ... | ... | ... |
| T8 | 130ms | + 80% | 毎ラウンド | T7 で同上 |

---

## 付録 E. 廃案の経緯メモ

### v1.0 廃案: 7 番勝負形式（`ghost-calc-7ban-shobu-spec.md`）
**廃案理由**: フラッシュ暗算の本質的単位と 7 戦形式が両立しない。
**学び**: 各ゲームの本質的単位を尊重する。

### v1.1 廃案: 適応難度の自動切替
**廃案理由**: コンセプトの主導権が曖昧、実装複雑。
**学び**: ユーザーの主導権をシンプルに渡す。

### v1.2: ユーザー主導 + 1 回正解解放
**部分廃案理由（v1.3 で）**: 解放が早すぎて、勝率 0% のティアが並ぶケース頻発。
**学び**: 解放条件は「実力定着」を担保するレベルに厳格化。

### v1.3: ユーザー主導 + 5 回中 3 回正解解放
**現行採用**:
- ✅ コンセプト「自分との闘い」を完全実現
- ✅ 解放の質が担保される（勝率破綻なし）
- ✅ ホーム画面が折りたたみ式で情報整理
- ✅ ペーパーレビューの懸念を 13 項目反映
- ✅ Week 1-2 で実装可能なスコープ

---

## 参照

- 親 GDD: `brain_training_gdd_v1.2.md` §4-1, §5b, §5e, §6, §10
- 姉妹ドキュメント（反射版）: `ghost-7ban-shobu-spec.md`
- ゴースト生霊キャラクタ機能設計: `docs/functional-design.md` A-10
- UI パターン: `docs/design/patterns.md` §5
- デイリーシード実装: `brain_training_gdd_v1.2.md` §5c
- 開発スケジュール: `brain_training_gdd_v1.2.md` §10 Week 1-2（要 v1.3 で更新）
- 廃案版（参考）: `archive/ghost-calc-7ban-shobu-spec-v1.1.md`
