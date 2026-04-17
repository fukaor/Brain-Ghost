## GhostBattleBarController
##
## ゲームプレイ中のリアルタイムスコア比較バー。
## 全ゲーム画面で共有される共通コンポーネント (scenes/shared/ghost_battle_bar.tscn)。
##
## 使い方:
##   var bar = $GhostBattleBar
##   bar.set_ghost_score(385)
##   bar.set_player_score(420)
extends PanelContainer

@onready var _player_score: Label = %PlayerScore
@onready var _ghost_score: Label = %GhostScore


func set_player_score(score: int) -> void:
	_player_score.text = str(score)


func set_ghost_score(score: int) -> void:
	_ghost_score.text = str(score)


func get_player_score_label() -> Label:
	return _player_score


func get_ghost_score_label() -> Label:
	return _ghost_score
