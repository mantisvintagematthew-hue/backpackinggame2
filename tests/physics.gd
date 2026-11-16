extends SceneTree
var app: Node3D
var p: LabPlayer
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
 checks += 1
 if ok: print("PASS: ",text)
 else: failures += 1; printerr("FAIL: ",text)
func _initialize() -> void:
 call_deferred("run")
func step(frames: int, input: Dictionary = {}) -> void:
 for i in frames:
  p.intent = input.duplicate()
  p.simulate(1.0/60,app.arena)
  await physics_frame
func run() -> void:
 app = load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 app.start_solo()
 app.set_physics_process(false)
 p = app.avatars[1]
 await step(40)
 check(p.is_on_floor(),"Player settles on arena floor")
 p.position = Vector3(0,0.01,12)
 await step(2)
 var start: Vector3 = p.position
 await step(30,{"move":Vector2(0,-1)})
 var straight := start.distance_to(p.position)
 check(absf(straight-2.25)<0.1,"Walking at 4.5 m/s")
 p.position = Vector3(0,0.01,12)
 start = p.position
 await step(30,{"move":Vector2(1,-1)})
 check(absf(start.distance_to(p.position)-straight)<0.1,"Diagonal movement normalized")
 p.position = Vector3(0,0.01,12)
 start = p.position
 await step(30,{"move":Vector2(0,-1),"sprint":true})
 check(absf(start.distance_to(p.position)-3.5)<0.1,"Sprint at 7 m/s")
 p.position = Vector3(-21,0.01,18)
 await step(2)
 start = p.position
 await step(30,{"move":Vector2(0,-1),"sprint":true})
 check(absf(start.distance_to(p.position)-1.2375)<0.1 and p.surface=="Wading","Water penalty applies and sprint disabled")
 p.position = Vector3(-21,0.01,5)
 await step(2)
 start = p.position
 await step(30,{"move":Vector2(0,-1)})
 check(absf(start.distance_to(p.position)-1.4625)<0.1,"Brush penalty applies")
 p.position = Vector3(-21,0.01,-8)
 await step(2)
 start = p.position
 await step(30,{"move":Vector2(0,-1)})
 check(absf(start.distance_to(p.position)-1.8)<0.1,"Rough ground penalty applies")
 p.position = Vector3(25,0.01,9)
 await step(5,{"crouch":true})
 await step(2)
 check(p.crouched,"Low ceiling blocks uncrouch")
 p.position = Vector3(0,0.01,12)
 await step(3)
 await step(1,{"jump":true})
 check(p.velocity.y>0,"Jump creates upward velocity on ground")
 var pack: String = app.registry.spawn("pack",Vector3.ZERO,app.registry.pslot(1,"pack"))
 p.position = Vector3(0,-10,0)
 await step(1)
 check(p.position.y>0 and app.registry.at(app.registry.pslot(1,"pack"))==pack,"Fall recovery preserves carried identity")
 p.position = Vector3(0,0.01,12)
 p.yaw = 0
 p.pitch = -0.9
 await step(2,{"pitch":-0.9})
 var placement: Dictionary = app.placement_for(1)
 check(placement.valid,"Level ground within reach accepts placement")
 p.pitch = 0
 await step(2)
 check(not app.placement_for(1).valid,"Empty forward space rejects placement")
 p.position = Vector3(0,0.01,-48)
 await step(2)
 check(not app.can_reach(1,Vector3(0,1,-51)),"Wall blocks reach")
 app.ui.show_inventory(pack)
 await process_frame
 check(app.ui.is_open() and app.ui.selected==pack,"Equipment panel opens with stable item selection")
 app.ui.show_settings()
 await process_frame
 check(app.ui.mode=="settings","Settings UI renders without script errors")
 check(app.registry.invariants().is_empty(),"Scene integration maintains item invariants")
 print("PHYSICS_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
