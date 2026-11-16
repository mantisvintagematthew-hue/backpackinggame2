extends CogitoContainer
## Attach to a RigidBody3D: COGITO owns its inventory and carrying interaction.
var worn := false
var wearer: CogitoPlayer
var original_layer := 0
var original_mask := 0
var lab: Node

func _ready() -> void:
 super._ready()
 interaction_nodes.assign(find_children("","InteractionComponent",true,false))
 lab = get_tree().current_scene
 original_layer = get("collision_layer")
 original_mask = get("collision_mask")

func interact(component: PlayerInteractionComponent) -> void:
 if worn: return
 super.interact(component)

func wear(player: CogitoPlayer) -> bool:
 if worn or player.is_showing_ui: return false
 var carry := get_node("Carry") as CogitoCarryableComponent
 if carry.is_being_carried: carry.leave()
 wearer = player
 worn = true
 set("freeze",true)
 set("collision_layer",0)
 set("collision_mask",0)
 visible = false
 remove_from_group("interactable")
 return true

func set_down() -> bool:
 if not worn: return false
 var forward := -wearer.camera.global_basis.z
 forward.y = 0
 forward = forward.normalized()
 var pos := wearer.global_position+forward*1.1+Vector3.UP*0.6
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = get_node("CollisionShape3D").shape
 query.transform = Transform3D(Basis.IDENTITY,pos+get_node("CollisionShape3D").position)
 query.exclude = [wearer.get_rid(),call("get_rid")]
 if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
 global_position = pos
 rotation = Vector3.ZERO
 visible = true
 set("collision_layer",original_layer)
 set("collision_mask",original_mask)
 set("freeze",false)
 set("sleeping",false)
 add_to_group("interactable")
 worn = false
 return true
