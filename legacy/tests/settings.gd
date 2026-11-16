extends SceneTree
func _initialize() -> void:
 var b := Bindings.new()
 var original: Dictionary = b.keys.duplicate()
 var sensitivity := b.sensitivity
 var invert := b.invert_y
 assert(not b.bind("interact",KEY_W).is_empty())
 assert(b.bind("interact",KEY_P).is_empty())
 assert(b.bind("primary",KEY_H).is_empty())
 b.sensitivity = 0.004
 b.invert_y = true
 b.save()
 var reloaded := Bindings.new()
 assert(reloaded.keys.interact==KEY_P and reloaded.label("interact").contains("P"))
 assert(reloaded.keys.primary==KEY_H and reloaded.sensitivity==0.004 and reloaded.invert_y)
 reloaded.keys = original
 reloaded.sensitivity = sensitivity
 reloaded.invert_y = invert
 reloaded.apply()
 reloaded.save()
 print("SETTINGS_RESULT passed: duplicates rejected; keyboard/mouse actions and sensitivity persist")
 quit()
