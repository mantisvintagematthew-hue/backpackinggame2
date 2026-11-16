extends Node
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: "+message)
 else: print("PASS: "+message)

func _ready() -> void:
 run.call_deferred()

func run() -> void:
 var lab = load("res://fieldlab/scenes/basecamp.tscn").instantiate()
 get_tree().root.add_child(lab)
 get_tree().current_scene = lab
 await get_tree().create_timer(2).timeout
 check(ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics","Jolt selected")
 check(lab.pack.interaction_nodes.size()==2 and lab.stove.interaction_nodes.size()==2,"generated objects expose native interaction prompts")
 check(lab.player.is_on_floor(),"native controller settles onto ground")
 var start: Vector3 = lab.player.position
 Input.action_press("forward")
 await get_tree().create_timer(0.5).timeout
 Input.action_release("forward")
 check(lab.player.position.distance_to(start)>0.5,"native controller moves through real physics")
 var inv: CogitoInventory = lab.player.inventory_data
 var supplies: Array[InventorySlotPD] = []
 for slot: InventorySlotPD in lab.pack.inventory_data.inventory_slots:
  if slot and not supplies.has(slot): supplies.append(slot)
 check(supplies.size()==3,"pack starts with three actual supply items")
 for slot: InventorySlotPD in supplies:
  lab.pack.inventory_data.remove_slot_data(slot)
  check(inv.pick_up_slot_data(slot),"native inventory accepts transferred "+slot.inventory_item.kind)
 var water: FieldSupply = supplies[0].inventory_item
 var fuel: FieldSupply = supplies[1].inventory_item
 var meal: FieldSupply = supplies[2].inventory_item
 var id := water.item_id
 lab.hydrate()
 check(water.water_ml==750 and meal.phase=="hydrated","hydration conserves 250 mL")
 lab.hydrate()
 check(water.water_ml==750,"repeated hydration cannot spend water twice")
 lab.stove.lab = lab
 lab.stove.attach("fuel",inv)
 lab.stove.attach("meal",inv)
 check(lab.stove.fuel.inventory_item==fuel and lab.stove.meal.inventory_item==meal,"stove owns transferred resources")
 lab.stove.set_process(false)
 lab.stove.ignite()
 check(lab.stove.burning,"settled stove ignites")
 lab.stove._process(10.0)
 check(meal.phase=="cooked" and is_equal_approx(fuel.fuel_seconds,110),"ten seconds cook meal and consume matching fuel")
 check(lab.stove.get_node("Carry").is_disabled,"burning stove blocks carrying")
 lab.stove.detach("fuel",inv)
 check(lab.stove.fuel!=null,"burning stove rejects detach")
 lab.stove.ignite()
 var full: CogitoInventory = lab.inventory(Vector2i(1,1))
 full.apply_initial_inventory()
 full.pick_up_slot_data(lab.slot(FieldSupply.make("meal")))
 lab.stove.detach("meal",full)
 check(lab.stove.meal!=null,"full inventory cannot lose socket item")
 lab.stove.detach("meal",inv)
 lab.stove.detach("fuel",inv)
 check(lab.stove.meal==null and lab.stove.fuel==null,"cooled stove returns both items")
 check(is_equal_approx(fuel.fuel_seconds,110),"fuel remaining preserved after detach")
 lab.pack.lab = lab
 check(lab.pack.wear(lab.player),"pack wears")
 check(lab.pack.worn and lab.pack.get("collision_layer")==0,"worn pack is physically disabled")
 check(lab.pack.set_down(),"pack sets down in clear space")
 check(not lab.pack.worn and lab.pack.get("collision_layer")!=0,"dropped pack restores collisions")
 lab.pack.get_node("Carry").interact(lab.player.player_interaction_component)
 check(lab.pack.get_node("Carry").is_being_carried,"native carry component holds physical pack")
 lab.player.player_interaction_component._handle_interaction("interact")
 check(lab.player.is_showing_ui,"carried pack opens native inventory")
 lab.player.get_node(lab.player.player_hud).toggle_inventory_interface()
 lab.pack.get_node("Carry").leave()
 check(not lab.pack.get_node("Carry").is_being_carried,"native carry releases pack")
 var water_slot: InventorySlotPD
 for slot: InventorySlotPD in inv.inventory_slots:
  if slot and slot.inventory_item==water: water_slot=slot
 inv.remove_slot_data(water_slot)
 lab.pack.inventory_data.pick_up_slot_data(water_slot)
 check(water.item_id==id and water.water_ml==750,"round trip preserves supply identity and amount")
 lab.player.global_position = Vector3(0,0.1,8)
 var pistol: WieldableItemPD = load("res://addons/cogito/InventoryPD/Items/Cogito_Pistol.tres").duplicate(true)
 inv.pick_up_slot_data(lab.slot(pistol))
 var ammo: InventorySlotPD = lab.slot(load("res://addons/cogito/InventoryPD/Items/Cogito_FoamBullets.tres").duplicate(true),20)
 inv.pick_up_slot_data(ammo)
 pistol.use(lab.player)
 await get_tree().create_timer(2).timeout
 var pic: PlayerInteractionComponent = lab.player.player_interaction_component
 check(pic.equipped_wieldable_item==pistol,"native weapon equips")
 if pic.equipped_wieldable_node:
  pic.equipped_wieldable_node.animation_player.stop()
  var before := pistol.charge_current
  pic.attempt_action_primary(false)
  check(pistol.charge_current==before-1,"native weapon fires and spends ammunition")
  await get_tree().create_timer(1).timeout
  pic.equipped_wieldable_node.animation_player.stop()
  var ammo_before := ammo.quantity
  pic.attempt_reload()
  check(pistol.charge_current==pistol.charge_max and ammo.quantity<ammo_before,"native reload transfers reserve ammunition")
 meal.use(lab.player)
 check(meal.phase=="consumed" and lab.hunger==85,"cooked meal can be eaten")
 lab.player.get_node(lab.player.player_hud).toggle_inventory_interface(lab.pack)
 await get_tree().process_frame
 check(lab.player.is_showing_ui,"native container UI opens")
 print("FOUNDATION_RESULT checks=%d failures=%d" % [checks,failures])
 get_tree().quit(1 if failures else 0)
