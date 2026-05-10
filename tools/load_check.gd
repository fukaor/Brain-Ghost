extends SceneTree

func _init() -> void:
    var scenes := [
        "res://scenes/main/home.tscn",
        "res://scenes/ui/rule_explain.tscn",
        "res://scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn",
    ]
    var failed := 0
    for path in scenes:
        var ps: PackedScene = load(path)
        if ps == null:
            printerr("[load_check] FAIL load: %s" % path)
            failed += 1
            continue
        var inst := ps.instantiate()
        if inst == null:
            printerr("[load_check] FAIL instantiate: %s" % path)
            failed += 1
            continue
        print("[load_check] OK: %s" % path)
        inst.queue_free()
    quit(failed)
