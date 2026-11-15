class_name LabPlayer
extends CharacterBody3D
var peer_id: int
var spawn_index := 0
var camera: Camera3D
var head: Node3D
var body_mesh: MeshInstance3D
var collider: CollisionShape3D
var intent: Dictionary = {}
var target_position := Vector3.ZERO
var target_yaw := 0.0
var yaw := 0.0
var pitch := 0.0
var crouched := false
var surface := "Firm ground"
var coyote := 0.0
var jump_buffer := 0.0
var walk_speed := 4.5
var sprint_speed := 7.0
var crouch_speed := 2.2
var jump_velocity := 4.5
var resting := false
var safe_position := Vector3.ZERO
var equipment_root: Node3D
var equipment_signature := ""

func _ready() -> void:
 floor_max_angle = deg_to_rad(45)
 floor_snap_length = 0.25
 collider = CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.32
 shape.height = 1.8
 collider.shape = shape
 collider.position.y = 0.9
 add_child(collider)
 body_mesh = MeshInstance3D.new()
 var capsule := CapsuleMesh.new()
 capsule.radius = 0.32
 capsule.height = 1.8
 body_mesh.mesh = capsule
 body_mesh.position.y = 0.9
 body_mesh.material_override = LabArena.material(Color.from_hsv(fmod(peer_id*0.19,1.0),0.4,0.85))
 add_child(body_mesh)
 head = Node3D.new()
 head.position.y = 1.6
 add_child(head)
 camera = Camera3D.new()
 camera.near = 0.05
 head.add_child(camera)
 var tag := Label3D.new()
 tag.text = "HIKER %d" % peer_id
 tag.position.y = 2.2
 tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 tag.font_size = 24
 add_child(tag)
 equipment_root = Node3D.new()
 add_child(equipment_root)

func local_view(enabled: bool) -> void:
 camera.current = enabled
 body_mesh.visible = not enabled

func simulate(dt: float, arena: LabArena) -> void:
 var terrain := arena.terrain(position)
 surface = terrain.name
 yaw = float(intent.get("yaw",yaw))
 pitch = clampf(float(intent.get("pitch",pitch)),-1.5,1.5)
 rotation.y = yaw
 head.rotation.x = pitch
 var wants_crouch: bool = intent.get("crouch",false)
 if crouched and not wants_crouch:
  var query := PhysicsShapeQueryParameters3D.new()
  var shape := CapsuleShape3D.new()
  shape.radius = 0.31
  shape.height = 1.8
  query.shape = shape
  query.transform = Transform3D(Basis.IDENTITY,global_position+Vector3(0,0.91,0))
  query.exclude = [get_rid()]
  wants_crouch = not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
 crouched = wants_crouch
 collider.shape.height = 1.1 if crouched else 1.8
 collider.position.y = 0.55 if crouched else 0.9
 head.position.y = 0.95 if crouched else 1.6
 if is_on_floor(): coyote = 0.1; safe_position = position
 else: coyote -= dt
 if intent.get("jump",false): jump_buffer = 0.12
 else: jump_buffer -= dt
 intent["jump"] = false
 var movement: Vector2 = intent.get("move",Vector2.ZERO)
 movement = movement.limit_length(1)
 if resting: movement = Vector2.ZERO; jump_buffer = 0
 var direction := Basis(Vector3.UP,yaw) * Vector3(movement.x,0,movement.y)
 var speed := crouch_speed if crouched else walk_speed
 if intent.get("sprint",false) and not crouched and not terrain.water: speed = sprint_speed
 speed *= float(terrain.speed)
 velocity.x = direction.x*speed
 velocity.z = direction.z*speed
 if not is_on_floor(): velocity.y -= 20*dt
 if jump_buffer > 0 and coyote > 0 and not crouched:
  velocity.y = (2.0 if terrain.water else jump_velocity)*float(terrain.speed)
  jump_buffer = 0
  coyote = 0
 move_and_slide()
 if position.y < -8 or absf(position.x) > 65 or absf(position.z) > 65: recover()

func recover() -> void:
 position = Vector3(-1.5+float(spawn_index)*1.0,1,3)
 safe_position = position
 velocity = Vector3.ZERO

func interpolate(dt: float, local: bool) -> void:
 position = position.lerp(target_position,1.0-exp(-18.0*dt))
 if not local: rotation.y = lerp_angle(rotation.y,target_yaw,1.0-exp(-15.0*dt))

func show_equipment(registry: ItemRegistry, local: bool) -> void:
 var signature := ""
 var ids: Array[String] = []
 for slot: String in ["hand0","hand1","pack"]:
  var id := registry.at(registry.pslot(peer_id,slot))
  signature += id+":"
  ids.append(id)
 if signature == equipment_signature: return
 equipment_signature = signature
 for child: Node in equipment_root.get_children(): child.queue_free()
 for i in 3:
  if ids[i].is_empty(): continue
  var kind: String = registry.items[ids[i]].def
  var mesh := MeshInstance3D.new()
  var box := BoxMesh.new()
  box.size = Vector3(0.35,0.5,0.25) if kind == "pack" else Vector3(0.15,0.18,0.55)
  mesh.mesh = box
  mesh.material_override = LabArena.material(Color(Catalog.DEFS[kind].color))
  mesh.position = Vector3((-0.38 if i==0 else 0.38),0.95,-0.55) if i<2 else Vector3(0,1.1,0.38)
  mesh.visible = not local or i<2
  equipment_root.add_child(mesh)
