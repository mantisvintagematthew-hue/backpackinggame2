class_name FieldSupply
extends InventoryItemPD
## Mutable data on the actual COGITO item resource, shared across transfers.
@export_enum("water", "meal", "fuel") var kind := "water"
@export var item_id := ""
@export var water_ml := 1000
@export var fuel_seconds := 120.0
@export_enum("dry", "hydrated", "cooked", "consumed") var phase := "dry"
@export var heat_seconds := 0.0
static var next_id := 0

static func make(type: String) -> FieldSupply:
 var item := FieldSupply.new()
 next_id += 1
 item.item_id = "supply-%d" % next_id
 item.kind = type
 item.item_size = Vector2i(1,2) if type == "water" else Vector2i(1,1)
 item.is_stackable = false
 item.is_droppable = false # Foundation preserves supplies inside real containers; physical pickup/drop is next.
 var icons := {"water":"bottle", "meal":"box", "fuel":"resource-wood"}
 item.icon = load("res://fieldlab/assets/survival/"+icons[type]+".png")
 item.refresh()
 return item

func refresh() -> void:
 match kind:
  "water": name = "Water · %d mL" % water_ml
  "meal": name = "Meal · "+phase.capitalize()
  "fuel": name = "Fuel · %d s" % ceili(fuel_seconds)
 description = "ID: %s\n%s" % [item_id, {"water":"Use to drink 100 mL. Refill at the water station.","meal":"Hydrate and cook at the stove; use when cooked to eat.","fuel":"Attach to the stove. Remaining burn time stays with this canister."}[kind]]

func use(player: CogitoPlayer) -> bool:
 var lab := player.get_tree().current_scene
 if kind == "water":
  if water_ml < 100: player.player_interaction_component.send_hint(icon,"The bottle is empty."); return false
  water_ml -= 100
  lab.thirst = minf(100,lab.thirst+15)
 elif kind == "meal":
  if phase != "cooked": player.player_interaction_component.send_hint(icon,"Cook the hydrated meal first."); return false
  phase = "consumed"
  lab.hunger = minf(100,lab.hunger+40)
  for slot: InventorySlotPD in player.inventory_data.inventory_slots:
   if slot and slot.inventory_item == self: player.inventory_data.remove_slot_data(slot); break
 else: return false
 refresh()
 player.player_interaction_component.send_hint(icon,"Drank water." if kind == "water" else "Meal eaten.")
 return true
