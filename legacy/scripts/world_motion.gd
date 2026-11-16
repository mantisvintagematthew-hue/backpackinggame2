class_name WorldMotion
extends RefCounted
# Host-only, modest ballistic drop motion. Collision rays sweep the bottom of each
# object; placed equipment is stable. This is not a general rigid-body simulator.
var velocities: Dictionary = {}
func drop(id: String, velocity: Vector3) -> void:
 velocities[id] = velocity
func tick(app: Node3D, dt: float) -> void:
 for id: String in velocities.keys():
  if not app.registry.items.has(id) or app.registry.items[id].loc != "world": velocities.erase(id); continue
  var it: Dictionary = app.registry.items[id]
  var from: Vector3 = it.pos
  var v: Vector3 = velocities[id]
  v.y -= 12*dt
  var to := from+v*dt
  var q := PhysicsRayQueryParameters3D.create(from-Vector3(0,0.17,0),to-Vector3(0,0.22,0))
  if app.world_views.has(id): q.exclude = [app.world_views[id].get_rid()]
  var hit := app.get_world_3d().direct_space_state.intersect_ray(q)
  if not hit.is_empty():
   it.pos = hit.position+hit.normal*0.23
   velocities.erase(id)
  else:
   it.pos = to
   velocities[id] = v
  if it.pos.y < -5: it.pos = Vector3(0,0.3,3); velocities.erase(id)
