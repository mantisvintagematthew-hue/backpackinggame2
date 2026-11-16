extends Node3D
## Level assembly only. Movement, interaction, inventory, carry and weapons are COGITO.
const COGITO := "res://addons/cogito/"
const ART := "res://fieldlab/assets/"
var player: CogitoPlayer
var pack: Node3D
var stove: Node3D
var camp_ui: CanvasLayer
var hunger := 45.0
var thirst := 45.0
var shots_hit := 0
var evaluation_time := 0.0

func _enter_tree() -> void:
 CogitoSceneManager._current_scene_root_node = self

func _ready() -> void:
 name = "Basecamp"
 build_landscape()
 build_equipment()
 player = load(COGITO+"PackedScenes/cogito_player.tscn").instantiate()
 player.name = "Hiker"
 player.inventory_data = inventory(Vector2i(6,3))
 player.inventory_data.apply_initial_inventory()
 player.INVERT_Y_AXIS = false
 player.CAN_BUNNYHOP = false
 player.disable_roll_anim = true
 player.WIGGLE_ON_WALKING_INTENSITY = 0
 player.WIGGLE_ON_SPRINTING_INTENSITY = 0
 player.WIGGLE_ON_CROUCHING_INTENSITY = 0
 player.WALKING_SPEED = 4.5
 player.SPRINTING_SPEED = 7.0
 player.CROUCHING_SPEED = 2.2
 player.fall_damage = 0
 # Remove unrelated sample RPG attributes/currencies before entering the tree.
 for child_name in ["SanityAttribute","LightMeterAttribute","CogtoTestCurrency","StrengthAttribute","HealthAutoConsume","StaminaAutoConsume"]:
  var child := player.get_node_or_null(child_name)
  if child: player.remove_child(child); child.free()
 player.position = Vector3(0,0.2,8)
 add_child(player)
 var flashlight := slot(load(COGITO+"InventoryPD/Items/Cogito_Flashlight.tres").duplicate(true))
 player.inventory_data.pick_up_slot_data(flashlight)
 # Separate project settings from the upstream demos. Save/load of generated camp is disabled below.
 camp_ui = load("res://fieldlab/scripts/camp_ui.gd").new()
 camp_ui.lab = self
 add_child(camp_ui)
 configure_pause.call_deferred()
 if "--capture" in OS.get_cmdline_user_args(): capture_tour.call_deferred()

func configure_pause() -> void:
 var pause := player.get_node(player.pause_menu)
 for child_name in ["SaveButton","LoadButton","BackToMenuButton"]:
  for child: Node in pause.find_children(child_name,"Button",true,false):
   child.disabled = true
   child.tooltip_text = "Foundation evaluation: restart the scene for a fresh session."

func inventory(size: Vector2i) -> CogitoInventory:
 var inv := CogitoInventory.new()
 inv.grid = true
 inv.inventory_size = size
 return inv

func slot(item: InventoryItemPD, quantity := 1) -> InventorySlotPD:
 var s := InventorySlotPD.new()
 s.inventory_item = item
 s.quantity = quantity
 return s

func material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.9
 return m

func block(pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
 var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
 root.position = pos
 add_child(root)
 var mesh := MeshInstance3D.new()
 var b := BoxMesh.new()
 b.size = size
 mesh.mesh = b
 mesh.material_override = material(color)
 root.add_child(mesh)
 if solid:
  var c := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  c.shape = shape
  root.add_child(c)
 return root

func model(path: String, parent: Node3D, height: float) -> Node3D:
 var m := (load(path) as PackedScene).instantiate() as Node3D
 parent.add_child(m)
 var bounds := AABB()
 for mesh: MeshInstance3D in m.find_children("*","MeshInstance3D",true,false):
  var local: Transform3D = m.global_transform.affine_inverse()*mesh.global_transform
  bounds = bounds.merge(local*mesh.get_aabb())
 var factor := height/maxf(bounds.size.y,0.01)
 m.scale = Vector3.ONE*factor
 m.position.y -= bounds.position.y*factor
 return m

func prop(path: String, pos: Vector3, height: float, yaw := 0.0) -> Node3D:
 var root := Node3D.new()
 add_child(root)
 root.position = pos
 root.rotation.y = yaw
 model(path,root,height)
 return root

func signboard(title: String, subtitle: String, pos: Vector3, width := 3.1) -> void:
 block(pos+Vector3(0,-0.7,0),Vector3(0.11,1.6,0.11),Color("6a5942"))
 block(pos,Vector3(width,0.8,0.09),Color("1b3432"))
 var label := Label3D.new()
 label.text = title+"\n"+subtitle
 label.font = load(COGITO+"Assets/Fonts/Montserrat/Montserrat-Medium.ttf")
 label.font_size = 34
 label.pixel_size = 0.004
 label.modulate = Color("f2e4c5")
 label.position = pos+Vector3(0,0,0.06)
 add_child(label)

func build_landscape() -> void:
 var world := WorldEnvironment.new()
 var environment := Environment.new()
 var sky := Sky.new()
 var sky_mat := ProceduralSkyMaterial.new()
 sky_mat.sky_top_color = Color("7296aa")
 sky_mat.sky_horizon_color = Color("c9d8cb")
 sky_mat.ground_horizon_color = Color("c9d8cb")
 sky_mat.ground_bottom_color = Color("4e644f")
 sky.sky_material = sky_mat
 environment.background_mode = Environment.BG_SKY
 environment.sky = sky
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("d4e3d5")
 environment.ambient_light_energy = 0.25
 environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
 world.environment = environment
 add_child(world)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-42,-28,0)
 sun.light_color = Color("ffe0ac")
 sun.light_energy = 0.65
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 65
 add_child(sun)
 block(Vector3(0,-0.3,0),Vector3(64,0.6,64),Color("68794f"))
 # Deliberately arranged clearing, paths and tree line; no procedural world generation.
 block(Vector3(0,0.012,2),Vector3(4,0.025,22),Color("b5ad88"),false)
 block(Vector3(-4,0.014,-1),Vector3(14,0.025,4),Color("b5ad88"),false)
 block(Vector3(7,0.014,-5),Vector3(6,0.025,20),Color("b5ad88"),false)
 var trees := [Vector3(-14,0,9),Vector3(-12,0,3),Vector3(-15,0,-4),Vector3(-13,0,-13),Vector3(-8,0,-16),Vector3(-1,0,-18),Vector3(7,0,-20),Vector3(14,0,-17),Vector3(17,0,-8),Vector3(16,0,1),Vector3(13,0,9),Vector3(8,0,16),Vector3(-9,0,16)]
 for i in trees.size():
  prop(ART+"nature/"+("tree_pineTallA.glb" if i%2==0 else "tree_pineDefaultA.glb"),trees[i],6.5+float(i%3),float(i))
  block(trees[i]+Vector3(0,1.2,0),Vector3(0.5,2.4,0.5),Color("665440"))
 for i in 18:
  var a := float(i)*TAU/18
  var pos := Vector3(cos(a)*20,0,sin(a)*20)
  prop(ART+"nature/rock_largeA.glb",pos,0.8+float(i%4)*0.3,a)
 prop(ART+"survival/tent.glb",Vector3(-7,0,-6),2.5,0.3)
 prop(ART+"survival/tent-canvas.glb",Vector3(-7,0,-6),2.5,0.3)
 prop(ART+"survival/bedroll.glb",Vector3(-6,0,-3.8),0.12,0.3)
 prop(ART+"nature/log_stack.glb",Vector3(-10,0,-6),0.8)
 prop(ART+"survival/workbench.glb",Vector3(-5,0,-0.2),0.88)
 # Readable collision under the detailed workbench.
 block(Vector3(-5,0.43,-0.2),Vector3(2.2,0.86,0.75),Color("75654a"))
 signboard("01  /  PACK & CAMP","Open · transfer · carry · set down",Vector3(-5,1.9,-2),3.8)
 signboard("02  /  HANDLING RANGE","Collect a weapon · aim · reload",Vector3(6,1.9,-3.5),3.6)
 signboard("FIELD LAB","COGITO FOUNDATION  /  SOLO EVALUATION",Vector3(0,2,-7),4.4)
 signboard("03  /  MOVEMENT","Stairs · slopes · physical objects",Vector3(10,1.9,4),3.8)
 for i in 6: block(Vector3(11,0.1*float(i+1),1.5-i*0.45),Vector3(2,0.2*float(i+1),0.45),Color("9c997f"))
 block(Vector3(11,0.6,-2.5),Vector3(2,1.2,2),Color("9c997f"))
 var ramp := block(Vector3(14,0.65,-2),Vector3(2,0.2,4),Color("aa9c77"))
 ramp.rotation_degrees.x = 20
 for i in 3:
  var crate := load(COGITO+"DemoScenes/DemoPrefabs/cardboard_box_closed.tscn").instantiate() as RigidBody3D
  crate.position = Vector3(8+i*0.8,0.8,3)
  add_child(crate)

func interaction(parent: Node, text: String, carry := false) -> Node:
 var path := "CarryableComponent.tscn" if carry else "BasicInteraction.tscn"
 var node: Node = load(COGITO+"Components/Interactions/"+path).instantiate()
 node.name = "Carry" if carry else "Use"
 node.interaction_text = text
 node.ignore_open_gui = false
 parent.add_child(node)
 return node

func collider(root: Node, size: Vector3, offset := Vector3.ZERO) -> void:
 var collision := CollisionShape3D.new()
 collision.name = "CollisionShape3D"
 var shape := BoxShape3D.new()
 shape.size = size
 collision.shape = shape
 collision.position = offset
 root.add_child(collision)

func build_equipment() -> void:
 # All inventory operations below use COGITO resources and its native container UI.
 pack = RigidBody3D.new()
 pack.set_script(load("res://fieldlab/scripts/pack.gd"))
 pack.name = "ExpeditionPack"
 pack.display_name = "Expedition pack"
 pack.text_when_closed = "Open pack"
 pack.text_when_open = "Close pack"
 pack.inventory_data = inventory(Vector2i(4,3))
 for kind: String in ["water","fuel","meal"]: pack.inventory_data.starter_inventory.append(slot(FieldSupply.make(kind)))
 pack.add_child(AnimationPlayer.new())
 pack.get_child(0).name = "AnimationPlayer"
 collider(pack,Vector3(0.6,0.65,0.4),Vector3(0,0.325,0))
 interaction(pack,"Open pack")
 interaction(pack,"Carry pack",true)
 pack.position = Vector3(-4.2,0.9,0)
 add_child(pack)
 model(COGITO+"Assets/Models/Kenney/bag.glb",pack,0.65)
 stove = RigidBody3D.new()
 stove.set_script(load("res://fieldlab/scripts/stove.gd"))
 stove.name = "CampStove"
 stove.display_name = "Camp stove"
 collider(stove,Vector3(0.55,0.3,0.55),Vector3(0,0.15,0))
 interaction(stove,"Prepare / cook")
 interaction(stove,"Carry stove",true)
 var light := OmniLight3D.new()
 light.name = "HeatLight"
 light.position = Vector3(0,0.35,0)
 light.light_color = Color("ff9f43")
 light.light_energy = 1.6
 light.omni_range = 2
 stove.add_child(light)
 stove.position = Vector3(-3,0.2,-1)
 add_child(stove)
 model(ART+"survival/campfire-pit.glb",stove,0.25)
 model(ART+"survival/campfire-stand.glb",stove,0.5)
 var water := StaticBody3D.new()
 water.set_script(load("res://fieldlab/scripts/water_station.gd"))
 water.display_name = "Water refill"
 collider(water,Vector3(0.7,1,0.7),Vector3(0,0.5,0))
 interaction(water,"Refill bottle")
 water.position = Vector3(-9,0,0)
 add_child(water)
 model(ART+"survival/bottle-large.glb",water,1)
 signboard("WATER","Bring a bottle from your pack",Vector3(-9,1.8,-0.8),2.7)
 # Existing COGITO weapons: animations, sounds, recoil and reloads remain upstream.
 for i in 3:
  var path: String = ["pickup_pistol","pickup_laser_rifle","pickup_laser_ammo"][i]
  var pickup := load(COGITO+"PackedScenes/Pickups/"+path+".tscn").instantiate() as Node3D
  pickup.position = Vector3(4.8+i*0.9,1,-1.5)
  add_child(pickup)
 block(Vector3(6,0.42,-1.5),Vector3(3.8,0.84,0.8),Color("75654a"))
 # Supply chest uses the upstream animated container intact.
 var chest := load(COGITO+"PackedScenes/container.tscn").instantiate() as CogitoContainer
 chest.name = "RangeSupplies"
 chest.display_name = "Range supplies"
 chest.inventory_data = inventory(Vector2i(6,3))
 chest.inventory_data.starter_inventory.append(slot(load(COGITO+"InventoryPD/Items/Cogito_FoamBullets.tres").duplicate(true),40))
 chest.inventory_data.starter_inventory.append(slot(load(COGITO+"InventoryPD/Items/Cogito_LaserAmmo.tres").duplicate(true),40))
 chest.position = Vector3(3.5,0,-1.5)
 chest.scale = Vector3.ONE*2
 add_child(chest)
 for i in 4:
  var target := load(COGITO+"PackedScenes/target_destructable.tscn").instantiate() as RigidBody3D
  target.name = "Target%d" % i
  var quest := target.get_node_or_null("QuestUpdater")
  if quest: target.remove_child(quest); quest.free()
  var loot := target.get_node_or_null("LootComponent")
  if loot: target.remove_child(loot); loot.free()
  target.position = Vector3(4.5+i*1.7,0.5,-10-float(i%2)*2)
  add_child(target)

func hydrate() -> String:
 var bottle: FieldSupply
 var meal: FieldSupply
 for s: InventorySlotPD in player.inventory_data.inventory_slots:
  if not s or not s.inventory_item is FieldSupply: continue
  var item := s.inventory_item as FieldSupply
  if item.kind == "water" and item.water_ml>=250: bottle = item
  if item.kind == "meal" and item.phase=="dry": meal = item
 if not bottle or not meal: return "Carry a dry meal and at least 250 mL of water in personal inventory."
 bottle.water_ml -= 250
 meal.phase = "hydrated"
 bottle.refresh()
 meal.refresh()
 player.inventory_data.inventory_updated.emit(player.inventory_data)
 return "250 mL transferred into the meal."

func open_stove(target: Node) -> void:
 camp_ui.open_stove(target)

func _process(dt: float) -> void:
 evaluation_time += dt
 if is_instance_valid(player) and player.position.y < -8:
  player.global_position = Vector3(0,1,8)
  player.velocity = Vector3.ZERO
 if is_instance_valid(pack) and not pack.worn and pack.position.y < -8:
  pack.position = Vector3(-4.2,1,0)
  pack.set("linear_velocity",Vector3.ZERO)
 if is_instance_valid(stove) and stove.position.y < -8:
  stove.position = Vector3(-3,1,-1)
  stove.set("linear_velocity",Vector3.ZERO)

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("mount_pack") and not player.is_showing_ui:
  if pack.worn:
   if not pack.set_down(): player.player_interaction_component.send_hint(null,"Clear space in front of you before setting the pack down.")
  elif player.global_position.distance_to(pack.global_position)<2.5 and (player.player_interaction_component.interactable==pack or player.player_interaction_component.carried_object==pack.get_node("Carry")):
   pack.wear(player)
  else: player.player_interaction_component.send_hint(null,"Look at a nearby pack or carry it first.")

func capture_tour() -> void:
 await get_tree().create_timer(2).timeout
 var directory := OS.get_environment("FIELDLAB_CAPTURE_DIR")
 if directory.is_empty(): directory = "/tmp/fieldlab-captures"
 DirAccess.make_dir_recursive_absolute(directory)
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(directory+"/basecamp.png")
 player.global_position = Vector3(-4.2,0.05,1.8)
 player.body.rotation.y = 0
 await get_tree().create_timer(1).timeout
 player.get_node(player.player_hud).toggle_inventory_interface(pack)
 await get_tree().create_timer(0.5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(directory+"/inventory.png")
 player.get_node(player.player_hud).toggle_inventory_interface()
 player.global_position = Vector3(-3,0.05,1)
 camp_ui.open_stove(stove)
 await get_tree().create_timer(0.5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(directory+"/stove.png")
 print("CAPTURE_RESULT ",directory)
 get_tree().quit()
