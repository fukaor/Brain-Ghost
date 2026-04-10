## Platform
##
## プラットフォーム判定の単一窓口。[code]OS.get_name()[/code] は本ファイル以外で使わない。
## すべてのプラットフォーム分岐はここを経由すること（docs/architecture.md）。
##
## Autoload 名: [code]Platform[/code]
extends Node

enum Target { WEB, ANDROID, DESKTOP_DEBUG }

## 現在動作中のプラットフォームを返す
func current() -> Target:
    match OS.get_name():
        "Web":
            return Target.WEB
        "Android":
            return Target.ANDROID
        _:
            return Target.DESKTOP_DEBUG

## AdMob 広告表示がサポートされているか（Android のみ）
func supports_admob() -> bool:
    return current() == Target.ANDROID

## Google Play Billing がサポートされているか（Android のみ）
func supports_billing() -> bool:
    return current() == Target.ANDROID

## Web 版シェア URL がサポートされているか（Web のみ）
func supports_share_url() -> bool:
    return current() == Target.WEB

## 永続化戦略を返す: "localStorage"（Web）/ "user_dir"（それ以外）
func storage_strategy() -> String:
    return "localStorage" if current() == Target.WEB else "user_dir"

func is_web() -> bool:
    return current() == Target.WEB

func is_android() -> bool:
    return current() == Target.ANDROID

func is_desktop_debug() -> bool:
    return current() == Target.DESKTOP_DEBUG
