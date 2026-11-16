extends CanvasLayer
var lab: Node3D
var status: Label
var guide: Label
var panel: PanelContainer
var state_label: Label
var feedback: Label
var stove: Node

func _ready() -> void:
 layer = 20
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 status = label("",22)
 status.position = Vector2(38,28)
 root.add_child(status)
 guide = label("FIELD GUIDE\n\nE  interact / open container\nQ  carry / set down object\nB  wear / set down backpack\nTab  personal inventory\nR  reload weapon\nEscape  pause / settings\n\nIn inventory: right-click to use\nMove supplies out of pack to cook",19)
 guide.position = Vector2(850,32)
 root.add_child(guide)
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.position = Vector2(-360,-240)
 panel.size = Vector2(720,480)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("142622")
 style.set_corner_radius_all(12)
 style.set_content_margin_all(28)
 panel.add_theme_stylebox_override("panel",style)
 root.add_child(panel)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",12)
 panel.add_child(body)
 body.add_child(label("CAMP STOVE",30))
 body.add_child(label("Prepare a warm meal with water and fuel.",18))
 state_label = label("",22)
 body.add_child(state_label)
 var grid := GridContainer.new()
 grid.columns = 2
 body.add_child(grid)
 for entry: Array in [["Hydrate meal · 250 mL","hydrate"],["Attach fuel","fuel_in"],["Load hydrated meal","meal_in"],["Ignite / extinguish","ignite"],["Take meal","meal_out"],["Detach fuel","fuel_out"]]:
  var b := Button.new()
  b.text = entry[0]
  b.custom_minimum_size = Vector2(310,48)
  b.add_theme_font_size_override("font_size",19)
  b.pressed.connect(func(): perform(entry[1]))
  grid.add_child(b)
 feedback = label("",18)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.add_child(feedback)
 var close := Button.new()
 close.text = "Return to camp"
 close.pressed.connect(close_stove)
 body.add_child(close)
 panel.hide()

func label(text: String, size: int) -> Label:
 var l := Label.new()
 l.text = text
 l.add_theme_font_override("font",load("res://addons/cogito/Assets/Fonts/Montserrat/Montserrat-Medium.ttf"))
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color("f3e5c7"))
 l.add_theme_color_override("font_outline_color",Color("18332a"))
 l.add_theme_constant_override("outline_size",1)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

func open_stove(target: Node) -> void:
 stove = target
 panel.show()
 feedback.text = "Hydrate a meal, attach fuel, load the meal, then ignite."
 lab.player.is_movement_paused = true
 lab.player.is_showing_ui = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_stove() -> void:
 panel.hide()
 lab.player.is_movement_paused = false
 lab.player.is_showing_ui = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
 if panel.visible and event.is_action_pressed("menu"):
  close_stove()
  get_viewport().set_input_as_handled()

func perform(action: String) -> void:
 if not is_instance_valid(stove) or lab.player.global_position.distance_to(stove.global_position)>3:
  feedback.text = "Move closer to the stove."
  return
 match action:
  "hydrate": feedback.text = lab.hydrate()
  "ignite": feedback.text = stove.ignite()
  "fuel_in": feedback.text = stove.attach("fuel",lab.player.inventory_data)
  "meal_in": feedback.text = stove.attach("meal",lab.player.inventory_data)
  "fuel_out": feedback.text = stove.detach("fuel",lab.player.inventory_data)
  "meal_out": feedback.text = stove.detach("meal",lab.player.inventory_data)

func _process(_dt: float) -> void:
 status.text = "FIELD LAB  /  BASECAMP\nCOGITO + JOLT  ·  SOLO FOUNDATION\n\nHunger %d  ·  Thirst %d\nPack: %s" % [lab.hunger,lab.thirst,"worn — set down to access" if lab.pack.worn else "in the world"]
 guide.position.x = get_viewport().get_visible_rect().size.x - 390
 guide.visible = not lab.player.is_showing_ui and not get_tree().paused
 status.visible = not lab.player.is_showing_ui and not get_tree().paused
 if panel.visible and is_instance_valid(stove):
  state_label.text = "%s\nFuel: %.1f s    Meal: %s" % ["BURNING" if stove.burning else "OFF",stove.fuel.inventory_item.fuel_seconds if stove.fuel else 0,"%.1f / 10 s · %s" % [stove.meal.inventory_item.heat_seconds,stove.meal.inventory_item.phase] if stove.meal else "empty"]
