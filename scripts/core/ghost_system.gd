## GhostSystem
##
## ゴースト生成・対戦判定を担うサービス。
## docs/functional-design.md 「コンポーネント設計 > core/GhostSystem」および A-03 準拠。
##
## [b]解放モデル（2段階）:[/b]
## - 第 1 段階: 精度 100% で機能解放（全体のロックが外れる）
## - 第 2 段階: 各ゲーム 5 回プレイでデータ成立（そのゲームのゴーストが生成・表示）
##
## MVP スタブ: 判定ロジックの枠組みと 5 回境界のみ実装。平均化の完全実装は Week 2-3。
class_name GhostSystem
extends Node

const REQUIRED_PLAYS_FOR_GHOST: int = 5
const FEATURE_UNLOCK_ACCURACY: float = 1.0  # 精度 100%

# --- 機能解放判定（第1段階） ---

## 精度に基づき、ゴースト対戦機能全体が解放されているか
func is_feature_unlocked(accuracy: float) -> bool:
    return accuracy >= FEATURE_UNLOCK_ACCURACY

# --- ゲーム別データ成立判定（第2段階） ---

## そのゲームで 5 件以上のプレイログがあるか
##
## [b]NOTE:[/b] スペック (docs/functional-design.md §GhostSystem) では
## [code]is_ready_for_game(game_type: String) -> bool[/code] となっているが、
## MVP スタブでは呼び出し元でカウント済みの [code]play_log_count[/code] を
## 直接渡す設計とした（DataStore への逆依存を避けるため）。
## Week 2-3 の実装時には [code]GameManager[/code] が
## [code]DataStore.load_logs_for(game_type).size()[/code] を渡して呼ぶ想定。
func is_ready_for_game(play_log_count: int) -> bool:
    return play_log_count >= REQUIRED_PLAYS_FOR_GHOST

## 「あと○回で生まれます」に表示する残り回数
##
## [b]NOTE:[/b] 上記 [code]is_ready_for_game[/code] と同じシグネチャ設計の理由。
func get_plays_until_ready(play_log_count: int) -> int:
    return max(0, REQUIRED_PLAYS_FOR_GHOST - play_log_count)

# --- ゴースト生成（スタブ） ---

## 直近 5 件の PlayLog からゴーストデータを生成する
## TODO: Week 2-3 で A-03 の平均化アルゴリズムを実装
func compute_ghost(game_type: String, recent_logs: Array) -> GhostDataModel:
    var ghost := GhostDataModel.new()
    ghost.game_type = game_type
    if recent_logs.size() < REQUIRED_PLAYS_FOR_GHOST:
        ghost.is_ready = false
        return ghost
    ghost.is_ready = true
    # TODO: averageEvents / averageScore / averageDurationMs の計算
    return ghost

# --- 対戦結果判定（スタブ） ---

## 自分のスコア/タイムとゴーストを比較して勝敗を返す
## TODO: Week 2-3 で実装
func judge_result(_game_type: String, _self_value: float, _ghost: GhostDataModel) -> Dictionary:
    return {
        "result": "draw",
        "selfValue": 0.0,
        "ghostValue": 0.0,
        "diff": 0.0,
    }
