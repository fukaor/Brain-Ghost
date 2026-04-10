## UserConfig
##
## ユーザー設定と基本情報。`user_config.json` に永続化される。
## docs/functional-design.md 「データモデル定義 > UserConfig」準拠。
class_name UserConfig
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1

var schema_version: int = CURRENT_SCHEMA_VERSION
var age_group: String = ""                  # "" | "10s" | "20s" | "30s" | "40s" | "50s+"
var age_banner_dismissed: bool = false
var bgm_enabled: bool = true
var se_enabled: bool = true
var has_purchased_ad_free: bool = false
var first_launch_at: String = ""            # ISO8601
var last_played_at: String = ""             # ISO8601
var onboarding_completed: bool = false

func to_dict() -> Dictionary:
    return {
        "schemaVersion": schema_version,
        "ageGroup": age_group,
        "ageBannerDismissed": age_banner_dismissed,
        "bgmEnabled": bgm_enabled,
        "seEnabled": se_enabled,
        "hasPurchasedAdFree": has_purchased_ad_free,
        "firstLaunchAt": first_launch_at,
        "lastPlayedAt": last_played_at,
        "onboardingCompleted": onboarding_completed,
    }

static func from_dict(d: Dictionary) -> UserConfig:
    var c := UserConfig.new()
    c.schema_version = int(d.get("schemaVersion", CURRENT_SCHEMA_VERSION))
    c.age_group = String(d.get("ageGroup", ""))
    c.age_banner_dismissed = bool(d.get("ageBannerDismissed", false))
    c.bgm_enabled = bool(d.get("bgmEnabled", true))
    c.se_enabled = bool(d.get("seEnabled", true))
    c.has_purchased_ad_free = bool(d.get("hasPurchasedAdFree", false))
    c.first_launch_at = String(d.get("firstLaunchAt", ""))
    c.last_played_at = String(d.get("lastPlayedAt", ""))
    c.onboarding_completed = bool(d.get("onboardingCompleted", false))
    return c

## 年代が未設定（空文字）なら true
func is_age_group_unset() -> bool:
    return age_group.is_empty()
