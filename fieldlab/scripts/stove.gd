extends CogitoObject
var fuel: InventorySlotPD
var meal: InventorySlotPD
var burning := false
var lab: Node

func _ready() -> void:
 super._ready()
 interaction_nodes.assign(find_children("","InteractionComponent",true,false))
 lab = get_tree().current_scene

func interact(_component: PlayerInteractionComponent) -> void:
 lab.open_stove(self)

func attach(kind: String, inventory: CogitoInventory) -> String:
 if (kind == "fuel" and fuel) or (kind == "meal" and meal): return "That socket is occupied."
 for slot: InventorySlotPD in inventory.inventory_slots:
  if slot and slot.inventory_item is FieldSupply and slot.inventory_item.kind == kind:
   if kind == "meal" and slot.inventory_item.phase != "hydrated": continue
   inventory.remove_slot_data(slot)
   if kind == "fuel": fuel = slot
   else: meal = slot
   return "Attached %s." % kind
 return "Carry a %s in your personal inventory first." % ("hydrated meal" if kind=="meal" else "fuel canister")

func detach(kind: String, inventory: CogitoInventory) -> String:
 if burning: return "Extinguish the stove first."
 var slot: InventorySlotPD = fuel if kind == "fuel" else meal
 if not slot: return "Socket is empty."
 if not inventory.pick_up_slot_data(slot): return "No space in personal inventory."
 if kind == "fuel": fuel = null
 else: meal = null
 return "Returned %s with its remaining resources." % kind

func ignite() -> String:
 if burning: burning = false; return "Stove extinguished."
 if get_node("Carry").is_being_carried or global_basis.y.dot(Vector3.UP)<0.9 or get("linear_velocity").length()>0.2: return "Set the stove upright on a stable surface."
 if not fuel or fuel.inventory_item.fuel_seconds <= 0: return "Attach fuel first."
 burning = true
 return "Stove lit. Fuel lasts 120 seconds when full."

func _process(dt: float) -> void:
 get_node("Carry").is_disabled = burning
 get_node("HeatLight").visible = burning
 if not burning: return
 if not fuel or fuel.inventory_item.fuel_seconds<=0: burning = false; return
 var used := minf(dt,fuel.inventory_item.fuel_seconds)
 fuel.inventory_item.fuel_seconds -= used
 fuel.inventory_item.refresh()
 if meal and meal.inventory_item.phase == "hydrated":
  meal.inventory_item.heat_seconds += used
  if meal.inventory_item.heat_seconds >= 10:
   meal.inventory_item.phase = "cooked"
   meal.inventory_item.refresh()
 if fuel.inventory_item.fuel_seconds<=0: burning = false
