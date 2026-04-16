# 設計: ホーム画面 Stitch準拠修正

## 修正方針
テーマバリエーション依存をやめ、HTMLのpx値をスケール比2/3で換算した明示的サイズを設定する。

## 要素ごとの修正内容

### 1. ヘッダーパネル (BrainAge / GhostBattle)
- パネルpadding: 12/10 → **27/21**
- パネル角丸: → **27px**
- 「約」プレフィックス: 削除
- 「娯楽目的です」: 削除
- 脳年齢キャプション: → **font_size 16**
- 脳年齢数値: → **font_size 48, color primary, font extrabold**
- 脳年齢単位: → **font_size 20, color primary**
- ゴーストバトルバー高さ: 24 → **32**
- バトルアイコン: → **font_size 21**

### 2. 吹き出し (SpeechBubble)
- padding: → **21px**
- テキスト: → **font_size 24, center, bold**
- tail_directionはDOWN（下向き）のまま、tail_offset_xでキャラ側に寄せる

### 3. 能力カード (AbilityCard)
- カードpadding: 16/14 → **27/27**
- カード角丸: → **40px**
- タイトルアイコン: → **font_size 32**
- タイトルテキスト: → **font_size 21, bold**
- グリッドアイコン: 48x48 → **85x85**
- グリッドラベル: → **font_size 13**
- grid h_separation/v_separation: 4 → **10**

### 4. CTAボタン
- psychologyアイコン追加（font_size 48）
- テキスト: → **font_size 32**
- 角丸: → **27px**
- padding: → py **32**

### 5. ボトムナビ
- ナビアイコン: → **font_size 32**
- ナビラベル: → **font_size 13**
- ナビ高さ: → 調整
- アクティブタブ角丸: → **21px**

### 6. 全体余白
- SafeAreaMargin: 28/40/28/12 → **32/43/32/0** (ナビは別管理)
- MainColumn separation: 16 → 適切に調整

### 7. ゴーストキャラ
- Stitch HTMLでは全身キャラだが、ルール説明画面と統一して**ちびキャラ(ghost_seirei.png)**を使用
- 配置: 吹き出しが上、ちびキャラが下（縦並び。ルール説明画面の横並びとは異なる）

## 流用コンポーネント
- `speech_bubble.gd`: TailDirection enumでDOWN/LEFT/RIGHT対応済み
- glass_bubbleテーマ: 吹き出し・カードで共通使用
- cta_blueテーマ: CTAボタン共通
