## SchemaMigrator
##
## JSON 永続化データのスキーマバージョンを検知し、将来のバージョンへ移行するユーティリティ。
##
## MVP は schema_version=1 のみで実移行は発生しないが、将来のために空の migrator を用意しておく。
## 新しいスキーマバージョンを導入する際は [code]migrate()[/code] に分岐を追加する。
class_name SchemaMigrator
extends Node

const CURRENT_SCHEMA_VERSION: int = 1

## 与えられたデータのスキーマバージョンを最新に変換する
##
## [param data] 永続化されたデータ（Dictionary）
## [return] マイグレーション後のデータ。失敗時は元データをそのまま返す
func migrate(data: Dictionary) -> Dictionary:
    var version: int = int(data.get("schemaVersion", 0))

    # MVP は v1 のみ
    if version == CURRENT_SCHEMA_VERSION:
        return data

    if version == 0:
        # schemaVersion フィールドがない場合 = 初期データ扱い
        data["schemaVersion"] = CURRENT_SCHEMA_VERSION
        return data

    if version > CURRENT_SCHEMA_VERSION:
        push_warning("SchemaMigrator: data version %d is newer than current %d. Forward compatibility not guaranteed." % [version, CURRENT_SCHEMA_VERSION])
        return data

    # 将来バージョンのマイグレーション:
    # if version == 1:
    #     data = _migrate_v1_to_v2(data)
    #     version = 2

    return data
