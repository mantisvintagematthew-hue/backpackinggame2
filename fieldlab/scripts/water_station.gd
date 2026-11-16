extends CogitoObject
func interact(component: PlayerInteractionComponent) -> void:
 for slot: InventorySlotPD in component.player.inventory_data.inventory_slots:
  if slot and slot.inventory_item is FieldSupply and slot.inventory_item.kind == "water":
   slot.inventory_item.water_ml = 1000
   slot.inventory_item.refresh()
   component.player.inventory_data.inventory_updated.emit(component.player.inventory_data)
   component.send_hint(slot.inventory_item.icon,"Bottle refilled to 1 L.")
   return
 component.send_hint(null,"Move a bottle from the pack into your personal inventory first.")

func _ready() -> void:
 super._ready()
 interaction_nodes.assign(find_children("","InteractionComponent",true,false))
