## StreakService
##
## ストリーク（連続プレイ日数）の更新ロジック。
## docs/functional-design.md A-06 および PRD FR-09 準拠。
##
## [b]空白日の挙動:[/b]
## - 0 日（同日再プレイ）: 変動なし
## - 1 日（翌日プレイ）: +1
## - 2〜7 日: +1、welcome_back_shown = false（次回ホームで復帰演出を表示）
## - 8 日以上: リセット 1、welcome_back_shown = true（演出なし）
##
## [b]welcome_back_shown フラグ:[/b] false なら次回ホーム描画時に復帰演出を 1 度だけ表示。
##
## [b]保存は呼び出し元の責務:[/b] 本サービスは状態を返すだけで DataStore に書き込まない。
class_name StreakService
extends Node

## ストリーク状態を更新した新しい StreakState を返す（引数の state は変更しない）
##
## [param state] 現在の StreakState
## [param today] 今日の日付（"YYYY-MM-DD" 形式、JST）
func update_streak(state: StreakState, today: String) -> StreakState:
    var new_state := state.clone()

    if new_state.last_played_date.is_empty():
        # 初回プレイ: ストリーク 1 から開始、復帰演出は不要
        new_state.current_streak = 1
        new_state.welcome_back_shown = true
    else:
        var diff: int = DateUtil.days_between(new_state.last_played_date, today)
        if diff == 0:
            pass  # 同日再プレイ、変動なし
        elif diff == 1:
            # 通常の翌日プレイ（復帰演出は出さない）
            new_state.current_streak += 1
        elif diff >= 2 and diff <= 7:
            # 2〜7 日の空白から復帰。次回ホームで復帰演出を 1 度出す
            new_state.current_streak += 1
            new_state.welcome_back_shown = false
        else:
            # diff >= 8: 8 日以上の空白でリセット。復帰演出は出さない
            new_state.current_streak = 1
            new_state.welcome_back_shown = true

    new_state.last_played_date = today
    new_state.longest_streak = max(new_state.longest_streak, new_state.current_streak)
    if not new_state.stamped_dates.has(today):
        new_state.stamped_dates.append(today)
    return new_state
