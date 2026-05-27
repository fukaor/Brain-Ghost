## MascotController
##
## Sumineko（墨絵調黒猫、6 ポーズ）の状態制御コンポーネント。
##
## 責務:
##   - Sumineko ポーズの切替（テクスチャ差替え）
##   - アイドルタイマーで sleep 自動遷移
##   - 精度 (accuracy 0.0〜1.0) を Modulate.a + GPUParticles2D.amount_ratio に補間
##
## 既存 GhostCharacter との関係（段階的移行）:
##   - 既存 GhostCharacter (set_accuracy/set_dialogue) はそのまま稼働させる
##   - 本コンポーネントは新規配置箇所のみ (home 常駐 / 個別結果のリアクション)
##   - 完全統合は別ステアリングで扱う
class_name MascotController
extends Node

signal mascot_tapped

# 6 ポーズの preload
const TEX_IDLE    = preload("res://assets/characters/sumineko_normal.png")
const TEX_FIGHT   = preload("res://assets/characters/sumineko_fight.png")
const TEX_DOUBLE  = preload("res://assets/characters/sumineko_double.png")
const TEX_TOUCH   = preload("res://assets/characters/sumineko_touch.png")
const TEX_RUNNING = preload("res://assets/characters/sumineko_running.png")
const TEX_SLEEP   = preload("res://assets/characters/sumineko_sleep.png")

## マスコットスプライト（TextureRect または Sprite2D。両対応のため Node 型）
@export var mascot_sprite: Node

## 鬼火青パーティクル（オプション、accuracy に連動）
@export var particles: GPUParticles2D

## true の場合、30s 放置で自動 sleep
@export var auto_idle_to_sleep: bool = true

var _idle_timer: float = 0.0
const SLEEP_THRESHOLD_SEC: float = 30.0

var _acc_tween: Tween = null


# ---------------------------------------------------------------------------
# 公開 API
# ---------------------------------------------------------------------------

func react_celebrate() -> void:
    _set_pose(TEX_FIGHT)
    _idle_timer = 0.0


func react_sad() -> void:
    _set_pose(TEX_DOUBLE)
    _idle_timer = 0.0


func react_shock() -> void:
    _set_pose(TEX_FIGHT)
    _idle_timer = 0.0


func react_think() -> void:
    # 暫定: think 専用ポーズ未着のため normal を流用
    _set_pose(TEX_IDLE)
    _idle_timer = 0.0


func react_tap() -> void:
    _set_pose(TEX_TOUCH)
    _idle_timer = 0.0
    mascot_tapped.emit()


func react_sleep() -> void:
    _set_pose(TEX_SLEEP)


func react_run() -> void:
    _set_pose(TEX_RUNNING)


func to_idle() -> void:
    _set_pose(TEX_IDLE)
    _idle_timer = 0.0


## 精度 0.0〜1.0 を modulate.a と particles.amount_ratio に補間
## GhostCharacter (MIN_ACCURACY_ALPHA=0.25) より高めの 0.6 を最低不透明度に。
## 理由: Sumineko は大型 + 黒主体スプライトのため低透明度だと和紙背景に溶ける
func set_accuracy(value: float) -> void:
    var v: float = clamp(value, 0.0, 1.0)
    if _acc_tween != null and _acc_tween.is_running():
        _acc_tween.kill()
    _acc_tween = create_tween()
    if mascot_sprite != null:
        _acc_tween.tween_property(mascot_sprite, "modulate:a", 0.6 + 0.4 * v, 0.4)
    if particles != null:
        _acc_tween.parallel().tween_property(particles, "amount_ratio", v, 0.4)


# ---------------------------------------------------------------------------
# 内部
# ---------------------------------------------------------------------------

func _set_pose(tex: Texture2D) -> void:
    if mascot_sprite == null:
        return
    if mascot_sprite is TextureRect:
        (mascot_sprite as TextureRect).texture = tex
    elif mascot_sprite is Sprite2D:
        (mascot_sprite as Sprite2D).texture = tex


func _process(delta: float) -> void:
    if not auto_idle_to_sleep:
        return
    if mascot_sprite == null:
        return
    _idle_timer += delta
    if _idle_timer > SLEEP_THRESHOLD_SEC:
        var current_tex: Texture2D = null
        if mascot_sprite is TextureRect:
            current_tex = (mascot_sprite as TextureRect).texture
        elif mascot_sprite is Sprite2D:
            current_tex = (mascot_sprite as Sprite2D).texture
        if current_tex == TEX_IDLE:
            react_sleep()
