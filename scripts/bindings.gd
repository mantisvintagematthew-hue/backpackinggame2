class_name Bindings
extends RefCounted
const DEFAULTS := {"primary":-MOUSE_BUTTON_LEFT,"secondary":-MOUSE_BUTTON_RIGHT,"next_slot":-MOUSE_BUTTON_WHEEL_DOWN,"prev_slot":-MOUSE_BUTTON_WHEEL_UP,"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"jump":KEY_SPACE,"interact":KEY_E,"drop":KEY_G,"place":KEY_F,"inventory":KEY_TAB,"reload":KEY_R,"cycle":KEY_V,"mode":KEY_B,"voice":KEY_T,"debug":KEY_F3,"menu":KEY_ESCAPE,"rotate_left":KEY_Q,"slot1":KEY_1,"slot2":KEY_2,"slot3":KEY_3,"slot4":KEY_4,"slot5":KEY_5,"slot6":KEY_6,"slot7":KEY_7,"slot8":KEY_8,"slot9":KEY_9,"slot10":KEY_0}
var sensitivity := 0.0025
var invert_y := false
var keys: Dictionary = DEFAULTS.duplicate()
func _init() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://controls.cfg") == OK:
  sensitivity = cfg.get_value("mouse","sensitivity",sensitivity)
  invert_y = cfg.get_value("mouse","invert",false)
  for action: String in keys: keys[action] = cfg.get_value("keys",action,keys[action])
 apply()
func apply() -> void:
 for action: String in keys:
  if not InputMap.has_action(action): InputMap.add_action(action)
  InputMap.action_erase_events(action)
  var event: InputEvent
  if int(keys[action]) < 0:
   event = InputEventMouseButton.new()
   event.button_index = -int(keys[action])
  else:
   event = InputEventKey.new()
   event.physical_keycode = keys[action]
  InputMap.action_add_event(action,event)
func label(action: String) -> String:
 var events := InputMap.action_get_events(action)
 return events[0].as_text().replace(" (Physical)","").replace(" - Physical","") if not events.is_empty() else "?"
func bind(action: String, key: int) -> String:
 for other: String in keys:
  if other != action and keys[other] == key: return "Already assigned to " + other
 keys[action] = key
 apply()
 save()
 return ""
func save() -> void:
 var cfg := ConfigFile.new()
 for action: String in keys: cfg.set_value("keys",action,keys[action])
 cfg.set_value("mouse","sensitivity",sensitivity)
 cfg.set_value("mouse","invert",invert_y)
 cfg.save("user://controls.cfg")
func reset() -> void:
 keys = DEFAULTS.duplicate()
 sensitivity = 0.0025
 invert_y = false
 apply()
 save()
