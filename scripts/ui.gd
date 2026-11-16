extends CanvasLayer
var app: Node3D
var panel: PanelContainer
var body: VBoxContainer
var hud: Label
var prompt: Label
var hotbar: Label
var toast: Label
var debug: Label
var crosshair: Label
var toast_text := ""
var remapping := ""
var selected := ""
var mode := ""
var items_list: ItemList
var list_ids: Array[String] = []
var selected_label: Label
var actions: HFlowContainer
var destinations: OptionButton
var destination_paths: Array[String] = []
var container_select: OptionButton
var container_ids: Array[String] = []
var container_id := ""
var details: Label
var refresh_timer := 0.0
var rendered_signature := ""

func _ready() -> void:
 var theme := Theme.new()
 theme.default_font_size = 16
 var style := StyleBoxFlat.new()
 style.bg_color = Color("172925")
 style.border_color = Color("627c69")
 style.set_border_width_all(1)
 style.set_corner_radius_all(6)
 style.content_margin_left = 12
 style.content_margin_right = 12
 style.content_margin_top = 8
 style.content_margin_bottom = 8
 theme.set_stylebox("normal","Button",style)
 var hover := style.duplicate()
 hover.bg_color = Color("405744")
 theme.set_stylebox("hover","Button",hover)
 theme.set_stylebox("pressed","Button",hover)
 theme.set_color("font_color","Button",Color("f3e8cc"))
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.theme = theme
 add_child(root)
 hud = label("",24)
 hud.position = Vector2(28,20)
 root.add_child(hud)
 prompt = label("",18)
 prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 prompt.position = Vector2(-270,35)
 prompt.size = Vector2(540,80)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 root.add_child(prompt)
 crosshair = label("+",24)
 crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 crosshair.position = Vector2(-7,-15)
 root.add_child(crosshair)
 hotbar = label("",16)
 hotbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 hotbar.position = Vector2(28,-78)
 root.add_child(hotbar)
 toast = label("",17)
 toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 toast.position = Vector2(28,-110)
 toast.modulate = Color("f0cf8a")
 root.add_child(toast)
 debug = label("",14)
 debug.position = Vector2(28,110)
 root.add_child(debug)
 panel = PanelContainer.new()
 var background := StyleBoxFlat.new()
 background.bg_color = Color(0.055,0.09,0.08,0.98)
 background.set_corner_radius_all(10)
 background.content_margin_left = 26
 background.content_margin_right = 26
 background.content_margin_top = 22
 background.content_margin_bottom = 22
 panel.add_theme_stylebox_override("panel",background)
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.position = Vector2(-490,-325)
 panel.size = Vector2(980,650)
 root.add_child(panel)
 body = VBoxContainer.new()
 body.add_theme_constant_override("separation",12)
 panel.add_child(body)

func label(text: String, font_size := 16) -> Label:
 var l := Label.new()
 l.text = text
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",Color("e7ead6"))
 l.add_theme_color_override("font_outline_color",Color("14231f"))
 l.add_theme_constant_override("outline_size",3)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

func button(text: String, callback: Callable, parent: Node = body) -> Button:
 var b := Button.new()
 b.text = text
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func is_open() -> bool:
 return panel.visible

func clear(title: String, subtitle: String) -> void:
 for child: Node in body.get_children(): body.remove_child(child); child.queue_free()
 panel.visible = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 body.add_child(label(title,30))
 body.add_child(label(subtitle,15))

func close_panel() -> void:
 panel.visible = false
 mode = ""
 remapping = ""
 if app.session: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_menu() -> void:
 mode = "menu"
 clear("FIELD LAB", "COOPERATIVE BACKPACKING  /  MECHANICS SANDBOX  /  01")
 body.add_child(label("A shared place to test equipment, camp routines and movement.\nPrimitive equipment. Persistent state. Up to four hikers.",20))
 body.add_child(label(app.status))
 var row := HBoxContainer.new()
 body.add_child(row)
 button("Solo session",app.start_solo,row)
 var port := SpinBox.new()
 port.min_value = 1024
 port.max_value = 65535
 port.value = 24567
 port.prefix = "UDP "
 row.add_child(port)
 button("Host LAN",func(): app.start_host(int(port.value)),row)
 var address := LineEdit.new()
 address.text = "127.0.0.1"
 address.placeholder_text = "Host address"
 address.custom_minimum_size.x = 200
 row.add_child(address)
 button("Join",func(): app.join_server(address.text.strip_edges(),int(port.value)),row)
 body.add_child(label("START HERE\n01   Approach the amber supply stations and interact.\n02   Take a pack; use inventory to wear it or manage slots.\n03   Place your stove, attach fuel and cook a hydrated meal.\n04   Equip a firearm, reload, then test the targets.",18))
 var row2 := HBoxContainer.new()
 body.add_child(row2)
 if app.session:
  button("Return to field",close_panel,row2)
  button("Disconnect",func(): app.end_session("Disconnected"),row2)
 button("Controls & settings",show_settings,row2)
 if app.authority():
  button("Sandbox tools",show_tools,row2)
 body.add_child(label("Mouse look · %s interact · %s equipment · %s placement · %s menu" % [app.bindings.label("interact"),app.bindings.label("inventory"),app.bindings.label("place"),app.bindings.label("menu")]))
 body.add_child(label(VoiceHooks.STATUS+"\nLocalhost / LAN only. No matchmaking or voice capture.",14))

func show_tools() -> void:
 mode = "tools"
 clear("SANDBOX TOOLS", "Host controls / all changes apply to the shared session")
 button("Recover host to spawn",func(): app.submit("recover"))
 button("Cleanup empty loose objects",func(): app.submit("cleanup"))
 body.add_child(label("Cleanup preserves containers with contents, burning stoves, occupied bags and carried gear."))
 button("Reset arena…",func():
  var confirm := ConfirmationDialog.new()
  confirm.dialog_text = "Reset all equipment and active cooking/reloads for every hiker?"
  confirm.confirmed.connect(func(): app.submit("reset"); confirm.queue_free())
  add_child(confirm)
  confirm.popup_centered()
 )
 button("Back",show_menu)

func show_settings() -> void:
 mode = "settings"
 clear("CONTROLS", "Click an action, then press a key or mouse button. Duplicate bindings are rejected.")
 var row := HBoxContainer.new()
 body.add_child(row)
 row.add_child(label("Mouse sensitivity"))
 var slider := HSlider.new()
 slider.min_value = 0.0005
 slider.max_value = 0.008
 slider.step = 0.0001
 slider.value = app.bindings.sensitivity
 slider.custom_minimum_size.x = 250
 slider.value_changed.connect(func(v: float): app.bindings.sensitivity = v; app.bindings.save())
 row.add_child(slider)
 var invert := CheckButton.new()
 invert.text = "Invert Y"
 invert.button_pressed = app.bindings.invert_y
 invert.toggled.connect(func(v: bool): app.bindings.invert_y = v; app.bindings.save())
 row.add_child(invert)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size.y = 370
 body.add_child(scroll)
 var grid := GridContainer.new()
 grid.columns = 3
 scroll.add_child(grid)
 for action: String in app.bindings.keys:
  button(action.capitalize()+"  /  "+app.bindings.label(action),func(): remapping = action; toast_text = "Press a key for " + action,grid)
 var row2 := HBoxContainer.new()
 body.add_child(row2)
 button("Reset defaults",func(): app.bindings.reset(); show_settings(),row2)
 button("Back",show_menu,row2)
 body.add_child(label("Mouse buttons: primary / aim or cancel. Wheel: quick slot navigation.\nKeyboard bindings and mouse settings persist locally; simulation keeps running.",14))

func _input(event: InputEvent) -> void:
 if not remapping.is_empty() and (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
  var error: String = app.bindings.bind(remapping,event.physical_keycode if event is InputEventKey else -event.button_index)
  toast_text = error if not error.is_empty() else "Binding saved"
  remapping = ""
  get_viewport().set_input_as_handled()
  show_settings()

func show_station(station: String) -> void:
 mode = "station"
 clear(station.to_upper()+" / STATION", "Fresh instances are created by the host. Move within reach to use this station.")
 var grid := GridContainer.new()
 grid.columns = 3
 body.add_child(grid)
 if station == "water":
  for loc: String in app.registry.slots(app.local_peer()):
   var id: String = app.registry.at(loc)
   if not id.is_empty() and app.registry.items[id].def == "bottle": button("Fill bottle "+id,func(): app.submit("fill",id),grid)
  body.add_child(label("Carry a bottle in hands, belt, pocket or an external pack slot to refill it."))
 else:
  button("Spawn ready-to-use kit",func(): app.submit("spawn","",{"station":station,"kind":"kit"}),grid)
  var kinds: Array = ["pack","bag","stove","fuel","bottle","meal"] if station == "camp" else ["pistol","rifle","p_mag","r_mag","p_ammo","r_ammo"]
  for kind: String in kinds: button(Catalog.DEFS[kind].name,func(): app.submit("spawn","",{"station":station,"kind":kind}),grid)
 button("Return to field",close_panel)

func show_inventory(id := "") -> void:
 mode = "inventory"
 selected = id
 rendered_signature = ""
 clear("EQUIPMENT", "Select an item → choose an action or a destination. Shared world equipment requires reach and line of sight.")
 var columns := HBoxContainer.new()
 columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(columns)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 430
 columns.add_child(left)
 container_select = OptionButton.new()
 container_select.item_selected.connect(func(index: int): container_id = container_ids[index]; rendered_signature = ""; refresh_inventory())
 left.add_child(container_select)
 items_list = ItemList.new()
 items_list.custom_minimum_size = Vector2(430,340)
 items_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
 items_list.item_selected.connect(func(index: int): selected = list_ids[index]; refresh_actions())
 left.add_child(items_list)
 var right := VBoxContainer.new()
 right.custom_minimum_size.x = 460
 columns.add_child(right)
 selected_label = label("Select an item",19)
 selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(selected_label)
 details = label("",14)
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(details)
 actions = HFlowContainer.new()
 actions.custom_minimum_size.y = 160
 right.add_child(actions)
 right.add_child(label("TRANSFER TO"))
 destinations = OptionButton.new()
 destinations.custom_minimum_size.x = 420
 right.add_child(destinations)
 button("Move selected item",func():
  if not selected.is_empty() and destinations.selected >= 0 and destinations.selected < destination_paths.size(): app.submit("transfer",selected,{"dest":destination_paths[destinations.selected]})
 ,right)
 var footer := HBoxContainer.new()
 body.add_child(footer)
 button("Active hand: LEFT",func(): app.submit("hand","",{"hand":"hand0"}),footer)
 button("Active hand: RIGHT",func(): app.submit("hand","",{"hand":"hand1"}),footer)
 button("Return to field",close_panel,footer)
 body.add_child(label("Pack internals: accessible only while held or placed. Burning stoves cannot be packed.\nReload: 1.2 seconds. Cycle ejects any chambered round, then feeds the next.",14))
 refresh_inventory()

func refresh_inventory() -> void:
 if mode != "inventory" or not app.registry.players.has(app.local_peer()): return
 var r: ItemRegistry = app.registry
 var peer: int = app.local_peer()
 var containers: Array[String] = []
 for id: String in r.items:
  if r.items[id].def in ["pack","crate","stove"] and r.accessible(peer,id): containers.append(id)
 containers.sort()
 if not containers.has(container_id): container_id = ""
 # Keep destination list available for all reachable containers, even when viewing equipment.
 var accessible_signature := ""
 for item: String in r.items:
  if r.accessible(peer,item): accessible_signature += item+str(r.items[item].loc)+str(r.items[item].rev)
 var signature := str(r.epoch)+str(containers)+container_id+accessible_signature+str(r.players[peer].hand)
 if not selected.is_empty() and r.items.has(selected): selected_label.text = Catalog.DEFS[r.items[selected].def].name+" / "+app.detail(selected)
 if signature == rendered_signature: return
 rendered_signature = signature
 container_select.clear()
 container_ids = [""]
 container_select.add_item("Accessible equipment & nearby world")
 for id: String in containers:
  container_ids.append(id)
  container_select.add_item(Catalog.DEFS[r.items[id].def].name+" · "+id)
 container_select.select(container_ids.find(container_id))
 items_list.clear()
 list_ids.clear()
 var ids: Array = r.items.keys()
 ids.sort()
 for id: String in ids:
  if not r.accessible(peer,id): continue
  var it: Dictionary = r.items[id]
  if not container_id.is_empty() and not String(it.loc).begins_with("i:"+container_id+":") and id != container_id: continue
  # Inserted magazines are displayed in the weapon state; don't offer ordinary transfers.
  if String(it.loc).ends_with(":mag"): continue
  list_ids.append(id)
  items_list.add_item("%s  |  %s" % [Catalog.DEFS[it.def].name,app.detail(id)])
  if id == selected: items_list.select(list_ids.size()-1)
 if not list_ids.has(selected): selected = ""
 refresh_actions()

func refresh_actions() -> void:
 for child: Node in actions.get_children(): actions.remove_child(child); child.queue_free()
 destinations.clear()
 destination_paths.clear()
 var r: ItemRegistry = app.registry
 var peer: int = app.local_peer()
 if selected.is_empty() or not r.items.has(selected): selected_label.text = "Select an item"; details.text = ""; return
 var id := selected
 var it: Dictionary = r.items[id]
 selected_label.text = Catalog.DEFS[it.def].name+"  /  "+app.detail(id)
 details.text = "ID %s · revision %d\nLocation: %s" % [id,it.rev,location_label(it.loc)]
 var available: Array = [["Take / equip","equip"],["Stow accessibly","stow"]]
 if r.held(peer,id):
  available.append(["Drop","drop"])
  button("Place in field",func(): close_panel(); app.placing = true,actions)
 if it.def == "pack": available.append(["Wear pack","wear"])
 if it.def == "bag": available.append_array([["Roll / unroll","roll"],["Enter / exit rest","rest"]])
 if it.def == "stove": available.append(["Ignite / extinguish","ignite"])
 if it.def == "bottle": available.append_array([["Drink 100 mL","drink"],["Fill at source","fill"]])
 if it.def == "meal": available.append_array([["Hydrate · 250 mL","hydrate"],["Eat cooked meal","eat"]])
 if it.def in ["p_mag","r_mag"]: available.append_array([["Load one","load"],["Unload one","unload"]])
 if Catalog.gun(it.def):
  available.append_array([["Reload fullest","reload"],["Remove magazine","remove_mag"],["Drop magazine","drop_mag"],["Cycle action","cycle"]])
  if it.def == "rifle": available.append(["Semi / auto","mode"])
  for loc: String in r.slots(peer):
   var mag := r.at(loc)
   if not mag.is_empty() and r.compatible(mag,r.socket(id,"mag")):
    button("Insert %s (%s)" % [mag,app.detail(mag)],func(): app.submit("insert",id,{"target":mag}),actions)
 for pair: Array in available:
  button(pair[0],func(): app.submit(pair[1],id),actions)
 var paths := r.slots(peer)
 paths.append(r.pslot(peer,"pack"))
 for parent: String in container_ids:
  if parent.is_empty() or not r.items.has(parent): continue
  var kind: String = r.items[parent].def
  if kind in ["pack","crate"]:
   for i in (12 if kind == "pack" else 32): paths.append(r.socket(parent,"in%d" % i))
   if kind == "pack":
    for i in 4:
     var loc := r.socket(parent,"ext%d" % i)
     if not paths.has(loc): paths.append(loc)
  if kind == "stove": paths.append(r.socket(parent,"fuel")); paths.append(r.socket(parent,"cook"))
 for path: String in paths:
  if not r.destination_access(peer,path) or not r.compatible(id,path): continue
  destination_paths.append(path)
  var occupant := r.at(path)
  destinations.add_item(location_label(path)+ ("  / empty" if occupant.is_empty() else "  / OCCUPIED"))

func _process(dt: float) -> void:
 toast.text = toast_text
 hud.text = "FIELD LAB   /   "+app.status
 crosshair.visible = app.session and not is_open()
 prompt.visible = crosshair.visible
 hotbar.visible = app.session
 debug.visible = app.debug_visible and app.session
 if not app.session: return
 var r: ItemRegistry = app.registry
 var peer: int = app.local_peer()
 if not r.players.has(peer): return
 hud.text += "\nHUNGER %d   /   THIRST %d   /   HIKERS %d/4" % [r.players[peer].hunger,r.players[peer].thirst,r.players.size()]
 var active := r.active(peer)
 if app.placing:
  prompt.text = "PLACE · "+("VALID" if app.placement_valid else "NEEDS CLEAR LEVEL SURFACE")+("\n[%s] confirm · [%s] cancel · " % [app.bindings.label("primary"),app.bindings.label("secondary")])+app.bindings.label("rotate_left")+" / "+app.bindings.label("interact")+" rotate"
 elif not app.focus_id.is_empty() and r.items.has(app.focus_id):
  prompt.text = Catalog.DEFS[r.items[app.focus_id].def].name+"  /  "+app.detail(app.focus_id)+"\n["+app.bindings.label("interact")+"] Actions"
 elif not app.focus_station.is_empty(): prompt.text = app.focus_station.to_upper()+" STATION\n["+app.bindings.label("interact")+"] Open"
 else: prompt.text = "["+app.bindings.label("inventory")+"] Equipment"+ ("\n"+app.detail(active) if not active.is_empty() else "")
 var slots := r.slots(peer)
 if not slots.has(app.selected_slot): app.selected_slot = ""
 app.hotbar_page = mini(app.hotbar_page,(slots.size()-1)/10)
 var quick := "ACCESSIBLE SLOTS   /   PAGE %d   /   WHEEL TO NAVIGATE\n" % (app.hotbar_page+1)
 for index in range(app.hotbar_page*10,mini(slots.size(),app.hotbar_page*10+10)):
  var id := r.at(slots[index])
  var item_text: String = r.items[id].def if not id.is_empty() else "—"
  if not id.is_empty():
   var state: Dictionary = r.items[id].state
   if state.has("rounds"): item_text += "(%d)" % state.rounds
   elif state.has("count"): item_text += "(%d)" % state.count
   elif state.has("water"): item_text += "(%d)" % state.water
  quick += "%s[%s] %s   " % ["•" if slots[index]==app.selected_slot else "",app.bindings.label("slot%d" % (index%10+1)),item_text]
 hotbar.text = quick
 if debug.visible and app.avatars.has(peer):
  debug.text = "PEER %d / %s\nPOS %s / %s\nFOCUS %s / SLOT %s\nITEMS %d / EPOCH %d / REV %d\n%s\n%s" % [peer,"HOST" if app.authority() else "CLIENT",app.avatars[peer].position,app.avatars[peer].surface,app.focus_id,app.selected_slot,r.items.size(),r.epoch,r.revision,VoiceHooks.STATUS,"\n".join(app.log_lines)]
 refresh_timer += dt
 if refresh_timer > 0.2: refresh_timer = 0; refresh_inventory()

func location_label(path: String) -> String:
 if path == "world": return "Nearby world"
 var parts := path.split(":")
 if parts.size() != 3: return path
 var slot: String = parts[2]
 if parts[0] == "p":
  if slot == "hand0": return "Left hand"
  if slot == "hand1": return "Right hand"
  if slot == "pack": return "Worn backpack"
  if slot.begins_with("belt"): return "Belt %d" % (int(slot.substr(4))+1)
  if slot.begins_with("pocket"): return "Pocket %d" % (int(slot.substr(6))+1)
 var parent: String = parts[1]
 var prefix: String = Catalog.DEFS[app.registry.items[parent].def].name+" "+parent if app.registry.items.has(parent) else parent
 if slot.begins_with("in"): return prefix+" · Internal %d" % (int(slot.substr(2))+1)
 if slot.begins_with("ext"): return prefix+" · External "+String(Catalog.EXTERNAL.get(slot,""))
 return prefix+" · "+slot.capitalize()+" socket"
