extends RefCounted
var setup := false
var attempted := false
var tested_reset := false
var peak_players := 0
var saw_hot_meal := false
var saw_pack_contents := false
var saw_loaded_gun := false
var saw_recovery := false
var saw_movement := false
var first_positions: Dictionary = {}

func tick(app: Node3D) -> void:
 var r: ItemRegistry = app.registry
 peak_players = maxi(peak_players,app.avatars.size())
 if app.authority() and not setup:
  setup = true
  var pack := r.spawn("pack",Vector3(0,0.3,1.5))
  r.items[pack].state["probe"] = "contested"
  var bottle := r.spawn("bottle",Vector3.ZERO,r.socket(pack,"in0"))
  r.items[bottle].state.water = 650
  var stove := r.spawn("stove",Vector3(-2,0.3,3))
  r.spawn("fuel",Vector3.ZERO,r.socket(stove,"fuel"))
  var meal := r.spawn("meal",Vector3.ZERO,r.socket(stove,"cook"))
  r.items[meal].state.phase = "hydrated"
  r.items[stove].state.burning = true
  var gun := r.spawn("pistol",Vector3(0,0.3,6))
  r.items[gun].state.chamber = true
  var mag := r.spawn("p_mag",Vector3.ZERO,r.socket(gun,"mag"))
  r.items[mag].state.rounds = 7
 for id: String in r.items:
  var it: Dictionary = r.items[id]
  if it.def == "meal" and it.state.heat > 0: saw_hot_meal = true
  if it.def == "bottle" and it.state.water == 650: saw_pack_contents = true
  if it.def == "pistol" and it.state.chamber: saw_loaded_gun = true
  if it.def == "crate": saw_recovery = true
  if not app.authority() and not attempted and app.smoke_time > 1 and it.state.get("probe","")=="contested":
   attempted = true
   app.submit("equip",id)
 if not app.authority() and not tested_reset and app.smoke_time > 2:
  tested_reset = true
  app.submit("reset")
 for peer: int in app.avatars:
  if not first_positions.has(peer): first_positions[peer] = app.avatars[peer].position
  elif first_positions[peer].distance_to(app.avatars[peer].position) > 0.3: saw_movement = true

func result(app: Node3D) -> bool:
 var r: ItemRegistry = app.registry
 var contested := 0
 for it: Dictionary in r.items.values():
  if it.state.get("probe","")=="contested": contested += 1
 var passed := peak_players==4 and saw_hot_meal and saw_pack_contents and saw_loaded_gun and contested==1 and r.epoch==2 and (saw_recovery if app.authority() else true)
 print("PROBE_RESULT passed=",passed," peak_players=",peak_players," cooking=",saw_hot_meal," contents=",saw_pack_contents," chamber=",saw_loaded_gun," contested_count=",contested," recovery=",saw_recovery," epoch=",r.epoch)
 return passed
