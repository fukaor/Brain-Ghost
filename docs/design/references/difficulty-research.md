# 脳トレアプリの難易度設計リサーチ

作成日: 2026-04-10
対象プロジェクト: Brain Boost（ブレインゴースト）
目的: 反射タップ・フラッシュ暗算が「簡単すぎる」というフィードバックを受け、難易度設計の方針を決定するため、競合アプリと業界研究を調査する。

---

## 1. 競合の難易度システム比較表

| アプリ | 方式 | 具体例 | 備考 |
|---|---|---|---|
| **Lumosity** | アダプティブ（完全自動） | 初回の "Fit Test" でベースライン計測 → 以降はスコアが上がると自動的にレベルが上昇。プレイヤーは難易度を明示的に選ばない | 35+ ゲーム。各ゲーム内に「多数のスキルレベル」が内部的に存在するが、ユーザーに見えるのは「今のLPI（Lumosity Performance Index）」だけ |
| **Peak**（Brainbow → ex-Hyper Hippo） | アダプティブ＋目標選択 | 初回に「記憶/語彙/集中/問題解決/メンタル俊敏/感情処理」のうち伸ばしたい領域を選択。以降 "Coach" が各ゲームのパフォーマンスを分析し、毎日3〜5ゲームを自動生成。ゲーム内レベル（Level 1〜20+）は見えるが、進行は成績ベースで自動 | 40+ ゲーム。レベルは「履歴」として可視化されるが操作対象ではない |
| **Elevate** | アダプティブ＋セッション内ランプ | 毎日3〜5ゲームの "Personalized Workout"。各ゲームは正解ごとにレベルが上昇、誤答で下降（セッション内ランプ）。累積で「Pro Level」が上がる | ゲーム内でリアルタイムに難易度が変動。フィードバックは即時 |
| **みんなの脳トレ**（QQ TSUBASA） | 難易度調整なし（固定） | 6種×30秒。問題レベルは調整できない | レビューで「記憶力/計算力で問題のばらつきがある」と指摘されている。ランダム生成のばらつきが実質的な難易度差になっている |
| **毎日脳トレ**（nullhouse） | アンロック型＋メダル | 24ゲーム。スタンプを集めると新ゲームが解放。各ゲームで目標スコアを達成するとメダル獲得 | ゲーム自体の難易度はほぼ固定で低め。ユーザーのレビューで「モグラ叩きだけ異常に難しい」と指摘される程度 |
| **Brain Age（脳トレDS / Switch）** | プレイヤー選択＋一部アンロック | 数独は Basic / Intermediate / Advanced の3段階（Advanced は Basic+Intermediate を 48問クリアでアンロック）。計算 20 / 計算 100 / 計算 X 100 など「問題数の違い」で難易度帯を分ける | "Daily Training" 自体はレベル選択なし。脳年齢チェックは完全固定ルール |

**要点:**

- Western big three（Lumosity / Peak / Elevate）はいずれも **アダプティブが主流**。ユーザーに難易度を選ばせない代わりに、Coach 的な UI でパーソナライズ感を演出している。
- 日本の軽量脳トレアプリ（みんなの脳トレ、毎日脳トレ）は **難易度調整がほぼ存在しない**。30秒×数ゲームで脳年齢を出すスタイル。競合分析としてはむしろ Brain Boost に最も近い。
- Brain Age（任天堂）は **コンテンツ単位で "Easy/Normal/Hard" を選ばせる** 古典的スタイル。ただし「ランクを上げる解放条件」も併用している。

---

## 2. 業界の傾向と研究

学術研究・業界記事を総合すると、**短時間セッション（2〜5分）の Casual / Cognitive Training ジャンルではアダプティブ難易度（DDA: Dynamic Difficulty Adjustment）が明確な主流** である。理由は3つある。

**第一に、フロー理論との親和性。** Csikszentmihalyi のフロー理論では「スキルと挑戦のバランスが保たれている状態」でエンゲージメントが最大化する。短時間アプリではプレイヤーが難易度設定画面を経由する余裕がなく、「起動 → すぐプレイ」が理想であるため、明示レベル選択は UX のボトルネックになる。IntechOpen のレビュー論文は、DDA が「退屈と欲求不満の間」を狙うのに最も確実な手段だと結論している。

**第二に、短時間の "microflow" は 3〜4 分が至適。** モバイルゲームの研究では、1セッションあたりの集中時間（microflow）は約3〜4分で最大化し、それを超えると逆に認知負荷で離脱率が上がる。Brain Boost の「3ゲーム合計2分」はこの帯域のど真ん中で、**セッション内で難易度設定 UI を挟むと確実に体験が切れる**。

**第三に、リテンションへの定量効果。** 2024-2025 のカジュアルゲーム研究では、アダプティブ要素の導入で **リテンション（7日/30日継続率）が最大20%以上向上** という報告が複数ある。逆に、ユーザーに難易度を選ばせた場合、カジュアル層は平均 4.00/7 付近の「楽な設定」を選ぶ傾向があり、結果として「簡単すぎて飽きる → 離脱」のパターンに陥りやすい（Game Developer 誌「Difficulty Modes and DDA」）。

**ただし注意点。** 2024年の比較研究では「どのDDA手法が最も優れているか単一の結論は出なかった」とある。重要なのは **手法の選択よりも、プレイヤーに "自分に合っている" と感じさせること**。Peak の Coach、Elevate の Pro Level、Lumosity の LPI はすべて「パーソナライズ感の演出 UI」という点で共通している。

**結論として業界のコンセンサスは:** 短時間脳トレでは (a) 難易度はアダプティブで自動調整、(b) プレイヤーには「今の自分のランク」を可視化する、(c) 明示レベル選択 UI は入口に置かない、の3点に集約される。

---

## 3. 反射タップ系の難易度パラメータ調整

反射タップ系（Whack-a-mole 系）で調整可能な難易度パラメータは、研究と実装例から以下の6つに整理できる。重要度順。

1. **ターゲット出現間隔（wait_ms）** — 最も体感差が大きい。現状 400-1200ms → 易化なら 200-800ms、中難度 150-600ms、高難度 100-400ms
2. **ターゲットサイズ（target_size_px）** — Fitts の法則により「サイズ半減 ≒ 距離倍増」の効果。現状 80-120px → 中難度 60-100px、高難度 50-80px
3. **ターゲット表示時間（visible_duration_ms）** — 出現中に叩けないと消える「ペナルティ時限」。現状は実質無制限 → 中難度 900ms、高難度 600ms
4. **フェイクターゲット頻度（fake_ratio）** — 現状 20ターゲット中3-5個 → 中難度 5-7個、高難度 8-10個、さらにフェイクの見た目を本物に近づける
5. **ターゲット密度/個数（target_count）** — 30秒固定なら個数が実質的にインターバルに連動。現状 20個 → 易化 15個、高難度 30個
6. **画面内のどこに出るか（spawn_zone）** — 画面全体 → 端寄り、に変えると視線移動距離が増える

**スロー反応者への配慮（重要）:**

ターゲット持続時間にフロアを必ず設ける（最低 500ms は表示）。高齢者・疲労時の平均反応時間は 350-500ms なので、これを下回るとフェアでなくなる。Lumosity は "Reaction" 系ゲームで「N回連続ミスしたら難易度を1段下げる」救済ロジックを入れている（公開仕様ではないが挙動から推定）。Brain Boost でも同様に **セッション内で3回連続ミスしたらその場で wait_ms を +200ms する** ような "soft floor" を推奨する。

また、「簡単すぎる」フィードバックへの最小コスト対応として、**wait_ms 下限を 400ms → 200ms、target_count を 20 → 25、fake_ratio を 3-5 → 5-7 に引き上げる** だけでも体感難易度は大きく変わる。これを「アダプティブ」ではなく「初期値を厳しくする」チューニングとして先に実施してから、アダプティブ化を検討するのが合理的。

---

## 4. ゴースト対戦との相互作用

**核心の問い:** すでにゴースト対戦（直近5回平均との勝負）がある状態で、explicit なレベル選択を追加すべきか？

**答え: 追加すべきではない。** 理由は以下。

**理由1: ゴースト対戦そのものが "個人適応型 DDA" として機能している。** プレイヤーのスコアが上がれば次回のゴースト（=次回の目標）も上がる。これは Lumosity の LPI、Peak の Coach と **機能的に等価**。つまり Brain Boost は既に「パーソナライズされた動的目標」を持っている。そこに静的な "Easy/Normal/Hard" を足すと、(a) 「Normal でゴーストに勝った」と「Hard でゴーストに勝った」のスコアをどう比較するかで設計が破綻する、(b) 脳年齢の計算式にレベル補正を入れる必要が生じ、仕様が複雑化する。

**理由2: レベル選択 UI はセッション体験を破壊する。** Brain Boost の UVP は「毎日2分、起動してすぐプレイ」。Home → Rule → Countdown → Play の導線に「難易度選択」を挟むと導線が 20-30% 長くなる。朝の通勤ペルソナには致命的。

**理由3: 独自性が薄まる。** 「ゴースト対戦」は現時点の競合ゼロの差別化要素。ここにレベル選択という "古典的 Brain Age 方式" を足すと、差別化が「平均的な脳トレ＋ゴースト」になる。むしろゴーストを徹底して磨く方が ROI が高い。

**ただし、問題は残る:** 「初心者や初回プレイでは、ゴースト対戦はまだ有効化されていない（直近5回の履歴がないため）」。つまり **初回〜4回目のプレイには DDA が効かない**。ここが今回の「簡単すぎる」フィードバックが出た原因の一つと考えられる。

**解決策: ゴースト対戦が有効化される前の区間のみ、静的な絶対難易度を "少しだけ厳しめ" に設定する。** これは「セッション内で難易度を動かさない」「レベル選択 UI も出さない」「ただし初期パラメータをチャレンジ寄りに」という方針。直近5回平均が揃ったらゴーストが DDA を引き継ぐ。

**併用の先行事例:** Elevate は同じ構造を採っている。初回は「自分のレベルを測る」ために厳しめに出題し、以降は Pro Level（=ゴースト相当）に応じて調整する。Brain Boost のゴースト対戦は Elevate の Pro Level より素直で強力な仕組み。

---

## 5. ブレインゴーストへの推奨

### 選択肢 A-F の評価

| 案 | メリット | デメリット | ゴーストとの相性 |
|---|---|---|---|
| **A. 明示レベル（Easy/Normal/Hard）** | わかりやすい。導入が容易 | UI が1画面増える。スコア比較が破綻。UVP を損なう | ✗ 競合する |
| **B. アダプティブ（セッション間）** | 業界主流。フロー維持 | **ゴーストと機能が重複する**。二重調整になる | △ 重複 |
| **C. マスタリーアンロック（Nクリアで N+1）** | 進行感が強い。達成感あり | 30秒×6種の構成に合わない。UVP の「気軽に2分」を損なう | ✗ 競合する |
| **D. セッション内ランプ（30秒中に上昇）** | UI 追加ゼロ。短時間で「壁を感じる」体験を作れる | 初級者が後半に追い詰められる。スコアのばらつきが増える | ○ 併存可 |
| **E. 現状維持（ゴーストのみ）** | 追加コストゼロ。UVP を守る | 初回4回のプレイまでゴーストが効かない。「簡単すぎる」問題は解決しない | － |
| **F. ハイブリッド（初期パラ厳しめ + 内部ランプ + ゴースト）** | 初回から手応え。UI 追加なし。ゴーストを壊さない | チューニングにコストがかかる | ◎ 相補 |

### 最終推奨: **F. ハイブリッド（初期パラ厳しめ化 + セッション内ランプ + ゴースト対戦は据え置き）**

具体的な3層構造:

1. **初期パラメータを "少しだけ厳しく" 再調整する**（explicit UI なし）
2. **セッション内で微かに難易度を上げる**（後半5秒で wait_ms を 10-20% 短縮する等、プレイヤーが意識しない範囲）
3. **ゴースト対戦は一切変更しない**。直近5回平均が揃えばそれが DDA を担う

**推奨の理由（5点）:**

1. **UVP を守れる**：難易度選択 UI を入れず「起動 → 即プレイ」を維持できる
2. **ゴースト対戦の差別化を壊さない**：ゴーストが担うレイヤー（セッション間調整）と、今回追加するレイヤー（セッション内＋初期値）は役割が重ならない
3. **初回4プレイ問題が解決する**：ゴーストが有効化される前でも、初期値が厳しめなら手応えがある
4. **実装コストが最も低い**：新しい UI、新しいデータモデル、新しい設定画面がどれも不要。パラメータ定数の変更と、セッション後半のランプ式 1行で済む
5. **A/B で後から戻せる**：もし厳しすぎたと判明しても、定数を戻すだけ。DDA 実装のような不可逆な設計決定を避けられる

### 実装上の注意点

**反射タップ（優先度 高）:**

- `wait_ms` の範囲を `[400, 1200]` → `[250, 900]` に引き下げる
- `target_count` を 20 → 24 に増やす
- `fake_ratio` を 3-5 → 5-7 に引き上げる
- **セッション内ランプ**: 残り10秒を切ったら `wait_ms` を 0.85 倍にする（内部処理、UI 非表示）
- **救済フロア**: 連続ミス3回で `wait_ms` に +150ms の一時補正（その試行のみ）
- `target_size_px` は 80-120 のまま維持（老眼・疲労時の救済）

**フラッシュ暗算（優先度 高）:**

- 現状 4つの数字（1-9）の和 → **後半は数字の個数を増やす**（0-15問目は4数字、16-23問目は5数字、24問目以降は6数字）
- 加算のみ → 後半は負の数を混ぜる（例: `3 + 5 - 2 + 7`）
- 問題数 12 → 15（30秒は据え置き）
- **初回プレイではこのランプを無効にする**（最初に4数字固定を8問まで出すと「とっつきやすさ」が確保される）

**共通:**

- どの調整もゴースト対戦のロジックには触れない
- `base_game.gd` に `get_session_difficulty_multiplier(progress: float) -> float` を追加し、各ゲームで 0.0 → 1.0 の進捗を渡せば倍率が返るパターンに統一する
- チューニング用の定数は `scripts/core/difficulty_config.gd` に集約する（後からの A/B テストと balance 変更が容易）
- 変更後は必ず **自分自身でプレイして「2-3 回失敗する体験」が 1 セッション中に入るか** を確認する。これが入っていないと「簡単すぎる」は解消しない

**やってはいけないこと:**

- ❌ 設定画面に "Easy / Normal / Hard" を出す
- ❌ ゲーム開始前に難易度ダイアログを表示する
- ❌ ゴースト対戦のロジックにレベル補正を足す
- ❌ スコア計算式に難易度係数を掛ける（脳年齢チューニングが壊れる）

---

## 出典

- [Lumosity Adaptive Training](https://www.ai-toptier.com/ai-tools/lumosity)
- [Lumosity Cognitive Games](https://www.lumosity.com/en/cognitive-games/)
- [Peak Brain Training (公式)](https://www.peak.net/)
- [Peak - Expert Review (mindtools.io)](https://mindtools.io/programs/peak-brain-training/)
- [Develop a Brain Training App like Peak (IdeaUsher)](https://ideausher.com/blog/develop-a-brain-training-app-like-peak/)
- [Elevate - App Store](https://apps.apple.com/us/app/elevate-brain-training-games/id875063456)
- [Elevate App Review (Nibble)](https://nibble-app.com/blog/elevate-app-review)
- [Elevate Brain Training (The Mind Company)](https://themindcompany.com/apps/elevate)
- [みんなの脳トレ（QQ TSUBASA） - APPLION](https://applion.jp/%E3%81%BF%E3%82%93%E3%81%AA%E3%81%AE%E8%84%B3%E3%83%88%E3%83%AC/iphone-633246396/)
- [毎日脳トレ (nullhouse) - Google Play](https://play.google.com/store/apps/details?id=info.nullhouse.braintraining)
- [Brain Age: Train Your Brain in Minutes a Day - Wikipedia](https://en.wikipedia.org/wiki/Brain_Age:_Train_Your_Brain_in_Minutes_a_Day!)
- [Brain Age Walkthrough (StrategyWiki)](https://strategywiki.org/wiki/Brain_Age/Walkthrough)
- [Dynamic Difficulty Adjustment in Games (IntechOpen)](https://www.intechopen.com/chapters/1228576)
- [DDA in Computer Games: A Review (Wiley)](https://onlinelibrary.wiley.com/doi/10.1155/2018/5681652)
- [Closing the Loop: Experience-Driven Game Adaptation (arXiv 2505.01351)](https://arxiv.org/html/2505.01351v1)
- [Flow of the Game: HMM of Player Engagement (INFORMS)](https://pubsonline.informs.org/doi/10.1287/isre.2021.0217)
- [How Adaptive Difficulty Enhances Player Engagement (Dr. Öztürk, 2025)](https://www.drozcanozturk.com/en/how-adaptive-difficulty-enhances-player-engagement-in-casual-games-2025/)
- [The Designer's Notebook: Difficulty Modes and DDA (Game Developer)](https://www.gamedeveloper.com/design/the-designer-s-notebook-difficulty-modes-and-dynamic-difficulty-adjustment)
- [Reaction Time and Game Design (RGDZ)](https://www.retrogamedeconstructionzone.com/2020/05/reaction-time-and-game-design.html)
- [Game Player Response Times vs Task Dexterity (WPI)](https://web.cs.wpi.edu/~claypool/papers/reaction-time/paper.pdf)
- [Fitts's Law & Reaction Time (Sage Journals)](https://journals.sagepub.com/doi/abs/10.2466/pms.1990.71.2.367)
- [Flow theory applied to game design (Think Game Design)](https://thinkgamedesign.com/flow-theory-game-design/)
- [Default Difficulty Settings in Casual Games](https://drdetox.ca/default-difficulty-settings-in-casual-games-insights-and-examples/)
