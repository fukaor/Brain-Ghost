## UuidUtil
##
## UUID v4（ランダム 128bit）を生成するユーティリティ。
## PlayLog.id などに使用する。
class_name UuidUtil
extends RefCounted

## UUID v4 を "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx" 形式で生成
##
## [param rng] テスト時にシード付き RNG を注入できる。省略時は新規作成
static func v4(rng: RandomNumberGenerator = null) -> String:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()

    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(16)
    for i in range(16):
        bytes[i] = rng.randi() & 0xFF

    # RFC 4122 v4 に従い、バージョン番号と variant を設定
    bytes[6] = (bytes[6] & 0x0F) | 0x40  # version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80  # variant 10

    return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5],
        bytes[6], bytes[7],
        bytes[8], bytes[9],
        bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15],
    ]
