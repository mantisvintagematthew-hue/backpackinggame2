extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
const UIScript = preload("res://scripts/ui.gd")
var registry := ItemRegistry.new()
var bindings := Bindings.new()
var voice := VoiceHooks.new()
var motion := WorldMotion.new()
var arena: LabArena
var ui: CanvasLayer
var avatars: Dictionary = {}
var world_views: Dictionary = {}
var session := false
var status := "OFFLINE / READY"
var sequence := 0
var snapshot_timer := 0.0
var input_timer := 0.0
var last_input: Dictionary = {}
var spawn_times: Dictionary = {}
var command_times: Dictionary = {}
var request_seen: Dictionary = {}
var focus_id := ""
var focus_station := ""
var placing := false
var placement_yaw := 0.0
var placement_valid := false
var placement_pos := Vector3.ZERO
var ghost: MeshInstance3D
var hotbar_page := 0
var selected_slot := ""
var debug_visible := false
var log_lines: Array[String] = []
var last_epoch := 0
var smoke := false
var smoke_time := 0.0
var smoke_done := false
var smoke_duration := 10.0
var probe = preload("res://tests/network_probe.gd").new()
var connection_elapsed := 0.0

func _ready() -> void:
 arena = LabArena.new()
 add_child(arena)
 registry.near_check = can_reach
 ui = UIScript.new()
 ui.app = self
 add_child(ui)
 ghost = MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(0.5,0.4,0.5)
 ghost.mesh = box
 ghost.visible = false
 add_child(ghost)
 multiplayer.peer_connected.connect(peer_connected)
 multiplayer.peer_disconnected.connect(peer_disconnected)
 multiplayer.connected_to_server.connect(connected)
 multiplayer.connection_failed.connect(func(): end_session("Connection failed — check address, port and firewall"))
 multiplayer.server_disconnected.connect(func(): end_session("Host left the session"))
 var args := OS.get_cmdline_user_args()
 smoke = "--smoke" in args
 var port := 24567
 for a: String in args:
  if a.begins_with("--port="): port = int(a.trim_prefix("--port="))
  if a.begins_with("--duration="): smoke_duration = float(a.trim_prefix("--duration="))
 if "--host" in args: start_host(port)
 elif "--join" in args: join_server("127.0.0.1",port)
 elif "--solo" in args: start_solo()
 else: ui.show_menu()

func local_peer() -> int:
 return multiplayer.get_unique_id() if session else 1

func authority() -> bool:
 return session and multiplayer.is_server()

func start_solo() -> void:
 end_session("")
 multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 session = true
 status = "SOLO / AUTHORITATIVE"
 initialize_world()
 add_avatar(1)
 ui.close_panel()

func start_host(port: int) -> void:
 end_session("")
 var peer := ENetMultiplayerPeer.new()
 var error := peer.create_server(port,3)
 if error != OK: status = "Cannot host: " + error_string(error); ui.show_menu(); return
 multiplayer.multiplayer_peer = peer
 session = true
 status = "HOST / UDP %d" % port
 initialize_world()
 add_avatar(1)
 ui.close_panel()

func join_server(address: String, port: int) -> void:
 end_session("")
 var peer := ENetMultiplayerPeer.new()
 var error := peer.create_client(address,port)
 if error != OK: status = "Cannot join: " + error_string(error); ui.show_menu(); return
 multiplayer.multiplayer_peer = peer
 status = "CONNECTING / " + address
 connection_elapsed = 0
 ui.show_menu()

func connected() -> void:
 session = true
 status = "CLIENT / CONNECTED"
 ui.close_panel()

func end_session(reason: String) -> void:
 session = false
 multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 for avatar: Node in avatars.values(): avatar.queue_free()
 avatars.clear()
 for view: Node in world_views.values(): view.queue_free()
 world_views.clear()
 registry = ItemRegistry.new()
 registry.near_check = can_reach
 motion.velocities.clear()
 spawn_times.clear()
 command_times.clear()
 request_seen.clear()
 last_input.clear()
 sequence = 0
 placing = false
 if not reason.is_empty(): status = reason; note(reason)
 if is_instance_valid(ui): ui.show_menu()

func initialize_world() -> void:
 registry.reset()
 motion.velocities.clear()
 spawn_kit("camp",Vector3(-4,0.3,-3))
 spawn_kit("weapons",Vector3(4,0.3,-3))

func spawn_kit(kind: String, pos: Vector3) -> void:
 var kinds: Array = ["pack","bag","stove","fuel","bottle","meal"] if kind == "camp" else ["pistol","rifle","p_mag","r_mag","p_ammo","r_ammo"]
 for i in kinds.size():
  var id := registry.spawn(kinds[i],pos+Vector3((i%3)*0.7,0,float(i/3)*0.7))
  if kinds[i] in ["p_mag","r_mag"]: registry.items[id].state.rounds = 8 if kinds[i]=="p_mag" else 20

func add_avatar(peer: int) -> void:
 if avatars.has(peer): return
 var player := PlayerScript.new() as LabPlayer
 player.peer_id = peer
 player.spawn_index = avatars.size()
 player.name = "Hiker_%d" % peer
 add_child(player)
 player.recover()
 player.target_position = player.position
 avatars[peer] = player
 if authority(): registry.add_player(peer)
 player.local_view(peer == local_peer())

func peer_connected(peer: int) -> void:
 if authority():
  add_avatar(peer)
  note("Hiker joined: %d" % peer)
  send_snapshot()

func peer_disconnected(peer: int) -> void:
 if authority() and avatars.has(peer):
  registry.disconnect_player(peer,avatars[peer].safe_position)
  request_seen.erase(peer)
  command_times.erase(peer)
  spawn_times.erase(peer)
  avatars[peer].queue_free()
  avatars.erase(peer)
  note("Hiker %d left; equipment recovered" % peer)

func note(message: String) -> void:
 log_lines.push_front(message)
 if log_lines.size() > 6: log_lines.resize(6)
 print("LAB: ",message)
 if is_instance_valid(ui): ui.toast_text = message

func _physics_process(dt: float) -> void:
 if not session:
  if status.begins_with("CONNECTING"):
   connection_elapsed += dt
   if connection_elapsed > 7: end_session("Connection timed out / server may be full (4 players maximum)")
  if smoke:
   smoke_time += dt
   if smoke_time > smoke_duration: print("SMOKE_NOT_CONNECTED ",status); get_tree().quit(2)
  return
 var peer := local_peer()
 if avatars.has(peer):
  var player: LabPlayer = avatars[peer]
  var intent := {"move":Vector2.ZERO,"yaw":player.yaw,"pitch":player.pitch,"jump":false,"sprint":false,"crouch":false,"aim":false}
  if not ui.is_open() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
   intent.move = Input.get_vector("left","right","forward","back")
   intent.jump = Input.is_action_just_pressed("jump")
   intent.sprint = Input.is_action_pressed("sprint")
   intent.crouch = Input.is_action_pressed("crouch")
   intent.aim = Input.is_action_pressed("secondary")
  if authority(): player.intent = intent
  else: input_intent.rpc_id(1,intent)
 if authority():
  for id: int in avatars:
   var p: LabPlayer = avatars[id]
   if id != 1 and Time.get_ticks_msec()-int(last_input.get(id,0)) > 300: p.intent["move"] = Vector2.ZERO; p.intent["jump"] = false
   p.resting = not String(registry.players[id].rest).is_empty()
   p.simulate(dt,arena)
  registry.tick(dt)
  motion.tick(self,dt)
  snapshot_timer += dt
  if snapshot_timer >= 0.05: snapshot_timer = 0; send_snapshot()
 else:
  for id: int in avatars: avatars[id].interpolate(dt,id==peer)
 sync_views()
 update_focus()
 if placing: update_placement()
 if avatars.has(peer):
  var active := registry.active(peer)
  if not active.is_empty() and registry.items.has(active) and registry.items[active].def == "rifle" and registry.items[active].state.mode == "auto" and Input.is_action_pressed("primary") and not ui.is_open() and not placing:
   input_timer -= dt
   if input_timer <= 0: input_timer = 0.11; submit("fire",active)
 if smoke: smoke_tick(dt)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func input_intent(data: Dictionary) -> void:
 if not authority(): return
 var peer := multiplayer.get_remote_sender_id()
 if not avatars.has(peer): return
 if not data.get("move") is Vector2 or not data.get("yaw") is float or not data.get("pitch") is float: return
 if not data.move.is_finite() or not is_finite(data.yaw) or not is_finite(data.pitch): return
 avatars[peer].intent = {"move":data.move.limit_length(1),"yaw":fmod(data.yaw,TAU),"pitch":clampf(data.pitch,-1.5,1.5),"jump":bool(data.get("jump",false)),"sprint":bool(data.get("sprint",false)),"crouch":bool(data.get("crouch",false)),"aim":bool(data.get("aim",false))}
 last_input[peer] = Time.get_ticks_msec()

func send_snapshot() -> void:
 if multiplayer.get_peers().is_empty(): return
 var positions: Dictionary = {}
 for peer: int in avatars:
  var p: LabPlayer = avatars[peer]
  positions[peer] = {"pos":p.position,"yaw":p.yaw,"pitch":p.pitch,"surface":p.surface,"crouch":p.crouched}
 receive_snapshot.rpc(registry.snapshot(),positions)

@rpc("authority", "call_remote", "reliable", 0)
func receive_snapshot(data: Dictionary, positions: Dictionary) -> void:
 if authority(): return
 registry.restore(data)
 for id: int in positions:
  add_avatar(id)
  var p: LabPlayer = avatars[id]
  p.target_position = positions[id].pos
  p.target_yaw = positions[id].yaw
  p.surface = positions[id].surface
  if id != local_peer(): p.head.rotation.x = positions[id].pitch
  p.head.position.y = 0.95 if positions[id].crouch else 1.6
 for id: int in avatars.keys():
  if not positions.has(id): avatars[id].queue_free(); avatars.erase(id)
 if last_epoch != registry.epoch:
  last_epoch = registry.epoch
  placing = false
  ui.close_panel()

func ray_from(peer: int, distance := 2.5, spread := 0.0) -> Dictionary:
 if not avatars.has(peer): return {}
 var p: LabPlayer = avatars[peer]
 var origin := p.global_position+Vector3(0,p.head.position.y,0)
 var basis := Basis.from_euler(Vector3(p.pitch+randf_range(-spread,spread),p.yaw+randf_range(-spread,spread),0))
 var query := PhysicsRayQueryParameters3D.create(origin,origin-basis.z*distance)
 query.exclude = [p.get_rid()]
 return get_world_3d().direct_space_state.intersect_ray(query)

func can_reach(peer: int, pos: Vector3) -> bool:
 if not avatars.has(peer): return false
 var p: LabPlayer = avatars[peer]
 var origin := p.position+Vector3(0,p.head.position.y,0)
 if origin.distance_to(pos) > 2.8: return false
 var query := PhysicsRayQueryParameters3D.create(origin,pos+Vector3(0,0.08,0))
 query.exclude = [p.get_rid()]
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 return hit.is_empty() or hit.position.distance_to(pos) < 0.5

func submit(op: String, id := "", extra: Dictionary = {}) -> void:
 if not session: return
 sequence += 1
 var req := {"op":op,"id":id,"seq":sequence,"epoch":registry.epoch,"rev":registry.items[id].rev if registry.items.has(id) else -1}
 req.merge(extra,true)
 if authority(): handle_request(local_peer(),req)
 else: request_action.rpc_id(1,req)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_action(req: Dictionary) -> void:
 if authority(): handle_request(multiplayer.get_remote_sender_id(),req)

func handle_request(peer: int, req: Dictionary) -> void:
 if not avatars.has(peer): return
 var op: String = req.get("op","")
 var id: String = req.get("id","")
 var now := Time.get_ticks_msec()
 if now-int(command_times.get(peer,0)) < 20: respond(peer,"Please slow down"); return
 command_times[peer] = now
 if req.get("epoch",-1) != registry.epoch: respond(peer,"Stale arena; refresh"); return
 if int(req.get("seq",0)) <= int(request_seen.get(peer,0)): respond(peer,"Duplicate request"); return
 request_seen[peer] = int(req.get("seq",0))
 var p: LabPlayer = avatars[peer]
 if op in ["reset","recover","cleanup"]:
  if peer != 1: respond(peer,"Host-only sandbox control"); return
  if op == "reset":
   initialize_world()
   for avatar: LabPlayer in avatars.values(): avatar.recover()
   ui.close_panel()
  elif op == "recover": p.recover()
  else:
   for item: String in registry.items.keys():
    if registry.items[item].loc != "world" or not registry.movable(item): continue
    var has_contents := false
    for child: Dictionary in registry.items.values():
     if String(child.loc).begins_with("i:"+item+":"): has_contents = true
    if not has_contents: registry.items.erase(item)
  respond(peer,op.capitalize()+" complete")
  return
 if op == "spawn":
  var station: String = req.get("station","")
  if not LabArena.STATIONS.has(station) or not can_reach(peer,LabArena.STATIONS[station]+Vector3(0,0.5,0)): respond(peer,"Approach the spawn station"); return
  if now-int(spawn_times.get(peer,-1000)) < 1000: respond(peer,"Station cooldown: one second"); return
  spawn_times[peer] = now
  var kind: String = req.get("kind","")
  var pos := p.position-p.transform.basis.z*1.1+Vector3(0,0.25,0)
  if kind == "kit": spawn_kit(station,pos)
  elif Catalog.DEFS.has(kind) and kind != "crate": registry.spawn(kind,pos)
  respond(peer,"Spawned fresh equipment")
  return
 if op == "hand":
  var hand: String = req.get("hand","")
  if hand in ["hand0","hand1"]: registry.players[peer].hand = hand
  return
 if not registry.items.has(id): respond(peer,"Item no longer exists"); return
 if op == "fill" and not can_reach(peer,LabArena.STATIONS.water+Vector3(0,0.5,0)): respond(peer,"Bring the bottle to the water source"); return
 if op in ["drop","cycle","drop_mag"]:
  var hit := ray_from(peer,1.0)
  req.pos = p.position-p.transform.basis.z*0.7+Vector3(0,1.0,0)
  if not hit.is_empty(): req.pos = p.position+Vector3(0,0.3,0)
 if op == "place":
  var rotation_y := float(req.get("yaw",0))
  if not is_finite(rotation_y): respond(peer,"Invalid placement angle"); return
  var placement := placement_for(peer,rotation_y)
  if not placement.valid: respond(peer,"Placement needs a clear, level surface within reach"); return
  req.pos = placement.pos
 if op == "transfer" and req.get("dest","world") == "world": respond(peer,"Use explicit Drop or Place for world transfers"); return
 var error := registry.command(peer,req)
 if error.is_empty():
  if op == "fire": resolve_shot(peer)
  if op == "drop": motion.drop(id,-p.transform.basis.z*1.2+Vector3.UP*0.4)
  if op == "place":
   registry.items[id]["yaw"] = fmod(float(req.get("yaw",0)),TAU)
   motion.velocities.erase(id)
  respond(peer,op.capitalize()+" accepted")
 else: respond(peer,error)

func respond(peer: int, message: String) -> void:
 if peer == local_peer(): note(message)
 else: action_result.rpc_id(peer,message)

@rpc("authority", "call_remote", "reliable", 0)
func action_result(message: String) -> void:
 note(message)

func resolve_shot(peer: int) -> void:
 var hit := ray_from(peer,100,0.002 if avatars[peer].intent.get("aim",false) else 0.012)
 if not hit.is_empty() and hit.collider.has_meta("target"):
  var index: int = hit.collider.get_meta("target")
  target_flash(index)
  if not multiplayer.get_peers().is_empty(): target_flash.rpc(index)
  respond(peer,"Target %d hit" % index)
 # Ray also stops on teammates; they receive no damage.

@rpc("authority", "call_remote", "unreliable", 1)
func target_flash(index: int) -> void:
 if index <= 0 or index > arena.targets.size(): return
 var target := arena.targets[index-1]
 var mesh := target.get_child(0) as MeshInstance3D
 mesh.material_override = LabArena.material(Color("f8f3b1"))
 get_tree().create_timer(0.18).timeout.connect(func(): mesh.material_override = LabArena.material(Color("d99163")))

func placement_for(peer: int, rotation_y := 0.0) -> Dictionary:
 var hit := ray_from(peer)
 var result := {"valid":false,"pos":Vector3.ZERO}
 if hit.is_empty(): return result
 var size := Vector3(0.4,0.4,0.4)
 var id := registry.active(peer)
 if registry.items.has(id): size = Catalog.dimensions(registry.items[id].def,registry.items[id].state)
 result.pos = hit.position+Vector3(0,size.y/2+0.03,0)
 if hit.normal.dot(Vector3.UP) < 0.92: return result
 if hit.collider.has_meta("item") or hit.collider.has_meta("station"): return result
 var query := PhysicsShapeQueryParameters3D.new()
 var shape := BoxShape3D.new()
 shape.size = size+Vector3(0.04,0,0.04)
 query.shape = shape
 query.transform = Transform3D(Basis(Vector3.UP,rotation_y),result.pos)
 query.exclude = [avatars[peer].get_rid()]
 result.valid = get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
 return result

func sync_views() -> void:
 for id: String in world_views.keys():
  if not registry.items.has(id) or registry.items[id].loc != "world": world_views[id].queue_free(); world_views.erase(id)
 for id: String in registry.items:
  var it: Dictionary = registry.items[id]
  if it.loc != "world": continue
  if not world_views.has(id):
   var root := StaticBody3D.new()
   root.set_meta("item",id)
   add_child(root)
   var mesh := MeshInstance3D.new()
   var shape := BoxMesh.new()
   shape.size = Catalog.dimensions(it.def,it.state)
   mesh.mesh = shape
   mesh.material_override = LabArena.material(Color(Catalog.DEFS[it.def].color))
   root.add_child(mesh)
   var collision := CollisionShape3D.new()
   var box := BoxShape3D.new()
   box.size = shape.size
   collision.shape = box
   root.add_child(collision)
   var label := Label3D.new()
   label.font_size = 20
   label.pixel_size = 0.008
   label.position.y = 0.5
   label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   root.add_child(label)
   world_views[id] = root
  var view: StaticBody3D = world_views[id]
  view.position = it.pos
  view.rotation.y = it.get("yaw",0.0)
  var state := detail(id)
  (view.get_child(2) as Label3D).visible = id == focus_id
  (view.get_child(2) as Label3D).text = Catalog.DEFS[it.def].name+"\n"+state
  if it.def == "bag":
   var size := Vector3(0.65,0.15,1.6) if it.state.unrolled else Vector3(0.4,0.4,0.4)
   (view.get_child(0) as MeshInstance3D).mesh.size = size
   (view.get_child(1) as CollisionShape3D).shape.size = size
 voice.head_positions.clear()
 for peer: int in avatars:
  avatars[peer].show_equipment(registry,peer==local_peer())
  voice.head_positions[peer] = avatars[peer].head.global_position

func detail(id: String) -> String:
 if not registry.items.has(id): return ""
 var it: Dictionary = registry.items[id]
 var s: Dictionary = it.state
 match String(it.def):
  "bottle": return "%d mL" % s.water
  "fuel": return "%.1f s fuel" % s.fuel
  "meal": return "%s · %.1f / 10 s" % [s.phase,s.heat]
  "stove": return "BURNING" if s.burning else "Off"
  "bag": return ("Occupied" if s.occupant != 0 else "Unrolled") if s.unrolled else "Rolled"
  "pistol","rifle":
   var mag := registry.at(registry.socket(id,"mag"))
   return "%d + %d · %s%s" % [registry.items[mag].state.rounds if not mag.is_empty() else 0,int(s.chamber),s.mode," · RELOADING" if registry.reloads.has(id) else ""]
  "p_mag","r_mag": return "%d / %d rounds" % [s.rounds,Catalog.DEFS[it.def].capacity]
  "p_ammo","r_ammo": return "%d rounds" % s.count
 return "ID " + id

func update_focus() -> void:
 focus_id = ""
 focus_station = ""
 if not avatars.has(local_peer()): return
 var hit := ray_from(local_peer())
 if hit.is_empty(): return
 focus_id = hit.collider.get_meta("item","")
 focus_station = hit.collider.get_meta("station","")

func update_placement() -> void:
 var result := placement_for(local_peer(),placement_yaw)
 var id := registry.active(local_peer())
 if registry.items.has(id): ghost.mesh.size = Catalog.dimensions(registry.items[id].def,registry.items[id].state)
 placement_valid = result.valid
 placement_pos = result.pos
 ghost.visible = not ui.is_open()
 ghost.position = placement_pos
 ghost.rotation.y = placement_yaw
 var color := Color("78dca2") if placement_valid else Color("f06e62")
 color.a = 0.4
 var mat := LabArena.material(color)
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 ghost.material_override = mat

func _unhandled_input(event: InputEvent) -> void:
 if ui.remapping != "": return
 if event.is_action_pressed("menu"):
  if placing: placing = false; ghost.visible = false
  elif ui.is_open() and session: ui.close_panel()
  else: ui.show_menu()
  return
 if not session or ui.is_open() or not avatars.has(local_peer()): return
 var p: LabPlayer = avatars[local_peer()]
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  p.yaw -= event.relative.x*bindings.sensitivity
  p.pitch = clampf(p.pitch-event.relative.y*bindings.sensitivity*(-1 if bindings.invert_y else 1),-1.5,1.5)
  p.rotation.y = p.yaw
  p.head.rotation.x = p.pitch
 var active := registry.active(local_peer())
 if event.is_action_pressed("debug"): debug_visible = not debug_visible
 if event.is_action_pressed("inventory"): ui.show_inventory(); return
 if event.is_action_pressed("voice"): note(VoiceHooks.STATUS)
 if placing:
  if event.is_action_pressed("secondary"): placing = false; ghost.visible = false
  if event.is_action_pressed("interact"): placement_yaw += PI/4
  if event.is_action_pressed("rotate_left"): placement_yaw -= PI/4
  if event.is_action_pressed("primary") and placement_valid:
   submit("place",active,{"yaw":placement_yaw})
   placing = false
   ghost.visible = false
  return
 if event.is_action_pressed("interact"):
  if not focus_id.is_empty(): ui.show_inventory(focus_id)
  elif not focus_station.is_empty(): ui.show_station(focus_station)
  elif not active.is_empty(): ui.show_inventory(active)
 if event.is_action_pressed("place") and not active.is_empty(): placing = true
 if event.is_action_pressed("drop") and not active.is_empty(): submit("drop",active)
 for pair: Array in [["reload","reload"],["cycle","cycle"],["mode","mode"]]:
  if event.is_action_pressed(pair[0]) and not active.is_empty(): submit(pair[1],active)
 if event.is_action_pressed("primary"):
  if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  elif not active.is_empty():
   if Catalog.gun(registry.items[active].def): submit("fire",active); p.pitch = clampf(p.pitch-0.01,-1.5,1.5)
   else: ui.show_inventory(active)
 if event.is_action("secondary"): p.camera.fov = 55 if event.is_pressed() else 75
 for i in 10:
  if event.is_action_pressed("slot%d" % (i+1)): select_quick(hotbar_page*10+i)
 if event.is_action_pressed("next_slot") or event.is_action_pressed("prev_slot"):
  var slots := registry.slots(local_peer())
  var index := slots.find(selected_slot)
  index = posmod(index+(1 if event.is_action_pressed("next_slot") else -1),slots.size())
  hotbar_page = index/10
  select_quick(index)

func select_quick(index: int) -> void:
 var slots := registry.slots(local_peer())
 if index >= slots.size(): return
 selected_slot = slots[index]
 var id := registry.at(selected_slot)
 if not id.is_empty(): submit("equip",id)
 else: note("Empty quick slot")

func smoke_tick(dt: float) -> void:
 smoke_time += dt
 probe.tick(self)
 if smoke_time > smoke_duration and not smoke_done:
  smoke_done = true
  var errors := registry.invariants()
  print("SMOKE_RESULT peer=",local_peer()," players=",avatars.size()," items=",registry.items.size()," epoch=",registry.epoch," invariants=",errors," ammo=",registry.ammo_total())
  get_tree().quit(0 if errors.is_empty() and probe.result(self) else 1)
