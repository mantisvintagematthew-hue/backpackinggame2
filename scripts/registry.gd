class_name ItemRegistry
extends RefCounted

signal changed
var items: Dictionary = {}
var players: Dictionary = {}
var reloads: Dictionary = {}
var epoch: int = 1
var serial: int = 0
var revision: int = 0
var clock: float = 0.0
var fired: int = 0
var seen: Dictionary = {}
var near_check: Callable

func spawn(kind: String, pos := Vector3.ZERO, location := "world") -> String:
 serial += 1
 var id := "%d-%d" % [epoch, serial]
 items[id] = {"id":id, "def":kind, "loc":location, "pos":pos, "rev":0, "state":Catalog.initial(kind)}
 return id

func add_player(peer: int) -> void:
 players[peer] = {"hunger":45.0, "thirst":45.0, "rest": "", "hand":"hand0"}

func at(location: String) -> String:
 for id: String in items:
  if items[id].loc == location: return id
 return ""

func pslot(peer: int, slot: String) -> String:
 return "p:%d:%s" % [peer, slot]

func socket(id: String, slot: String) -> String:
 return "i:%s:%s" % [id, slot]

func slots(peer: int) -> Array[String]:
 var out: Array[String] = [pslot(peer,"hand0"), pslot(peer,"hand1")]
 for i in 4: out.append(pslot(peer,"belt%d" % i))
 for i in 4: out.append(pslot(peer,"pocket%d" % i))
 var pack := at(pslot(peer,"pack"))
 if not pack.is_empty():
  for i in 4: out.append(socket(pack,"ext%d" % i))
 return out

func active(peer: int) -> String:
 return at(pslot(peer, players[peer].hand)) if players.has(peer) else ""

func held(peer: int, id: String) -> bool:
 return items.has(id) and items[id].loc in [pslot(peer,"hand0"), pslot(peer,"hand1")]

func root_item(id: String) -> String:
 var cursor := id
 var visited: Dictionary = {}
 while items.has(cursor) and String(items[cursor].loc).begins_with("i:"):
  if visited.has(cursor): return ""
  visited[cursor] = true
  cursor = String(items[cursor].loc).split(":")[1]
 return cursor

func nearby(peer: int, id: String) -> bool:
 if not items.has(id): return false
 var root := root_item(id)
 if root.is_empty() or not items.has(root): return false
 if items[root].loc != "world": return false
 return near_check.call(peer, items[root].pos) if near_check.is_valid() else true

func accessible(peer: int, id: String) -> bool:
 if not items.has(id): return false
 var loc: String = items[id].loc
 if loc == "world": return nearby(peer,id)
 var parts := loc.split(":")
 if parts[0] == "p": return int(parts[1]) == peer
 var parent: String = parts[1]
 if not items.has(parent): return false
 var tag: String = Catalog.DEFS[items[parent].def].tag
 if tag == "pack":
  if items[parent].loc == pslot(peer,"pack"): return parts[2].begins_with("ext")
  return held(peer,parent) or nearby(peer,parent)
 if tag == "crate": return nearby(peer,parent)
 return accessible(peer,parent)

func touch(id: String) -> void:
 if items.has(id): items[id].rev += 1

func compatible(id: String, dest: String) -> bool:
 if not items.has(id): return false
 if dest == "world": return true
 var d: Dictionary = Catalog.DEFS[items[id].def]
 var parts := dest.split(":")
 if parts.size() != 3: return false
 var slot: String = parts[2]
 if parts[0] == "p":
  if not players.has(int(parts[1])): return false
  if slot == "pack": return d.tag == "pack"
  if slot in ["hand0","hand1"]: return d.tag != "crate"
  if slot in ["belt0","belt1","belt2","belt3"]: return d.size <= 2
  if slot in ["pocket0","pocket1","pocket2","pocket3"]: return d.size <= 1
  return false
 var parent: String = parts[1]
 if not items.has(parent) or parent == id: return false
 var pd: Dictionary = Catalog.DEFS[items[parent].def]
 if pd.tag == "pack":
  if d.tag in ["pack","crate"]: return false
  if Catalog.EXTERNAL.has(slot): return d.tag == Catalog.EXTERNAL[slot]
  return slot.begins_with("in") and slot.substr(2).is_valid_int() and int(slot.substr(2)) in range(12) and d.size <= 2
 if pd.tag == "crate": return slot.begins_with("in") and slot.substr(2).is_valid_int() and int(slot.substr(2)) in range(32)
 if pd.tag == "stove": return (slot == "fuel" and d.tag == "fuel") or (slot == "cook" and d.tag == "meal")
 if Catalog.gun(items[parent].def): return slot == "mag" and d.tag == "mag" and d.ammo == pd.ammo
 return false

func destination_access(peer: int, dest: String) -> bool:
 if dest == "world": return true
 var parts := dest.split(":")
 if parts.size() != 3: return false
 if parts[0] == "p": return int(parts[1]) == peer
 if parts[0] != "i" or not items.has(parts[1]): return false
 var parent: String = parts[1]
 if items[parent].def == "pack" and items[parent].loc == pslot(peer,"pack"):
  return parts[2].begins_with("ext")
 return accessible(peer,parent)

func storage(peer: int, id: String, extra := "") -> String:
 var candidates := slots(peer)
 if not extra.is_empty(): candidates.append(extra)
 for loc: String in candidates:
  if loc.ends_with("hand0") or loc.ends_with("hand1"): continue
  if at(loc).is_empty() and compatible(id,loc): return loc
 return ""

func movable(id: String) -> bool:
 var it: Dictionary = items[id]
 return not (it.def == "stove" and it.state.burning) and not (it.def == "bag" and it.state.occupant != 0)

func transfer(peer: int, id: String, dest: String, pos: Vector3) -> String:
 if not accessible(peer,id): return "Item is out of reach or inside a worn pack"
 if not movable(id): return "Extinguish the stove / exit the sleeping bag first"
 if not destination_access(peer,dest): return "Destination is not accessible"
 if not compatible(id,dest): return "Incompatible slot"
 if dest != "world" and not at(dest).is_empty(): return "Slot is occupied"
 if dest.begins_with("i:"):
  var parent: String = dest.split(":")[1]
  if root_item(parent) == id: return "Containment cycle rejected"
  if Catalog.gun(items[parent].def): return "Use Insert / Reload for firearm sockets"
 if String(items[id].loc).begins_with("i:"):
  var old_parent: String = String(items[id].loc).split(":")[1]
  if Catalog.gun(items[old_parent].def): return "Use Remove magazine"
 if dest.begins_with("p:") and dest.split(":")[2].begins_with("hand"):
  var other := at(pslot(peer,"hand1" if dest.ends_with("hand0") else "hand0"))
  if not other.is_empty() and (Catalog.DEFS[items[id].def].hands == 2 or Catalog.DEFS[items[other].def].hands == 2): return "Both hands are required; stow or drop the other item"
 cancel_reload(id)
 items[id].loc = dest
 items[id].pos = pos
 touch(id)
 return ""

func equip(peer: int, id: String) -> String:
 if held(peer,id):
  players[peer].hand = String(items[id].loc).split(":")[2]
  return ""
 var backup: Dictionary = items.duplicate(true)
 var dest := pslot(peer,players[peer].hand)
 var hands: Array[String] = [dest]
 var other := pslot(peer,"hand1" if players[peer].hand == "hand0" else "hand0")
 var other_id := at(other)
 if Catalog.DEFS[items[id].def].hands == 2 or (not other_id.is_empty() and Catalog.DEFS[items[other_id].def].hands == 2): hands.append(other)
 for h: String in hands:
  var old := at(h)
  if old.is_empty(): continue
  var stow := storage(peer,old)
  if stow.is_empty():
   items = backup
   return "Hands occupied; explicitly stow or drop equipment first"
  items[old].loc = stow
  touch(old)
 var error := transfer(peer,id,dest,Vector3.ZERO)
 if not error.is_empty(): items = backup
 else:
  for h: String in hands:
   for old: String in backup:
    if backup[old].loc == h: cancel_reload(old)
 return error

func cancel_reload(id: String) -> void:
 reloads.erase(id)

func command(peer: int, request: Dictionary) -> String:
 if not players.has(peer): return "Unknown player"
 if int(request.get("epoch",-1)) != epoch: return "Arena reset: stale epoch"
 var seq: int = int(request.get("seq",0))
 if seq <= int(seen.get(peer,0)): return "Duplicate request"
 seen[peer] = seq
 var id: String = request.get("id", "")
 var op: String = request.get("op", "")
 if not items.has(id): return "Item no longer exists"
 if int(request.get("rev",-1)) != int(items[id].rev): return "Stale revision; refresh and retry"
 if not accessible(peer,id): return "Item inaccessible or out of reach"
 var result := act(peer,op,id,request)
 if result.is_empty():
  revision += 1
  changed.emit()
 return result

func act(peer: int, op: String, id: String, req: Dictionary) -> String:
 var it: Dictionary = items[id]
 var s: Dictionary = it.state
 var kind: String = it.def
 var target: String = req.get("target", "")
 match op:
  "equip": return equip(peer,id)
  "transfer", "drop", "place", "wear":
   var dest: String = req.get("dest","world")
   if op == "wear": dest = pslot(peer,"pack")
   if op in ["drop","place"] and not held(peer,id): return "Hold the item first"
   return transfer(peer,id,dest,req.get("pos",Vector3.ZERO))
  "stow":
   var dest := storage(peer,id)
   if dest.is_empty(): return "No compatible accessible storage"
   return transfer(peer,id,dest,Vector3.ZERO)
  "roll":
   if kind != "bag" or it.loc != "world": return "Place a sleeping bag first"
   if s.occupant != 0: return "Sleeping bag is occupied"
   s.unrolled = not s.unrolled
  "rest":
   if kind != "bag" or it.loc != "world" or not s.unrolled: return "Place and unroll the sleeping bag"
   if s.occupant == peer:
    s.occupant = 0
    players[peer].rest = ""
   elif s.occupant == 0 and players[peer].rest.is_empty():
    s.occupant = peer
    players[peer].rest = id
   else: return "Sleeping bag is occupied"
  "ignite":
   if kind != "stove" or it.loc != "world": return "Place the stove first"
   var fuel := at(socket(id,"fuel"))
   if not s.burning and (fuel.is_empty() or items[fuel].state.fuel <= 0): return "Attach a canister with fuel first"
   s.burning = not s.burning
  "fill", "drink":
   if kind != "bottle": return "Select a bottle"
   if op == "fill": s.water = 1000
   else:
    if s.water < 100: return "Bottle needs 100 mL"
    s.water -= 100
    players[peer].thirst = minf(100,players[peer].thirst + 15)
  "hydrate":
   if kind != "meal" or s.phase != "dry": return "Select a dry meal"
   var bottle := ""
   for loc: String in slots(peer):
    var candidate := at(loc)
    if not candidate.is_empty() and items[candidate].def == "bottle" and items[candidate].state.water >= 250:
     bottle = candidate
     break
   if bottle.is_empty(): return "Need an accessible bottle with 250 mL"
   items[bottle].state.water -= 250
   touch(bottle)
   s.phase = "hydrated"
  "eat":
   if kind != "meal" or s.phase != "cooked": return "Meal must be cooked first"
   players[peer].hunger = minf(100,players[peer].hunger + 40)
   items.erase(id)
   return ""
  "load", "unload":
   if Catalog.DEFS[kind].tag != "mag" or String(it.loc).ends_with(":mag"): return "Select a detached magazine"
   var ammo_kind := "p_ammo" if kind == "p_mag" else "r_ammo"
   var stack := ""
   for loc: String in slots(peer):
    var candidate := at(loc)
    if not candidate.is_empty() and items[candidate].def == ammo_kind:
     stack = candidate
     break
   if op == "load":
    if s.rounds >= Catalog.DEFS[kind].capacity: return "Magazine is full"
    if stack.is_empty() or items[stack].state.count <= 0: return "No accessible compatible loose rounds"
    items[stack].state.count -= 1
    s.rounds += 1
    touch(stack)
    if items[stack].state.count == 0: items.erase(stack)
   else:
    if s.rounds == 0: return "Magazine is empty"
    if stack.is_empty():
     # Allocate only after capacity is proven.
     var free := ""
     for loc: String in slots(peer):
      if not loc.contains("hand") and at(loc).is_empty() and not loc.contains(":ext"): free = loc; break
     if free.is_empty(): return "No slot for ejected ammunition"
     stack = spawn(ammo_kind,Vector3.ZERO,free)
     items[stack].state.count = 0
    items[stack].state.count += 1
    s.rounds -= 1
    touch(stack)
  "reload", "insert":
   if not Catalog.gun(kind) or not held(peer,id): return "Hold a firearm first"
   if reloads.has(id): return "Reload already in progress"
   var best := target
   if best.is_empty():
    var count := -1
    var candidates := slots(peer)
    candidates.sort()
    for loc: String in candidates:
     if loc.contains("hand"): continue
     var candidate := at(loc)
     if not candidate.is_empty() and compatible(candidate,socket(id,"mag")) and items[candidate].state.rounds > count:
      best = candidate
      count = items[candidate].state.rounds
   if best.is_empty() or not items.has(best) or not slots(peer).has(String(items[best].loc)) or not compatible(best,socket(id,"mag")): return "No accessible compatible magazine"
   var old := at(socket(id,"mag"))
   var dest: String = items[best].loc
   if not old.is_empty() and not compatible(old,dest): return "No space for old magazine"
   reloads[id] = {"peer":peer,"mag":best,"loc":dest,"rev":items[best].rev,"end":clock + 1.2}
  "remove_mag", "drop_mag":
   if not Catalog.gun(kind) or not held(peer,id): return "Hold a firearm first"
   if reloads.has(id): return "Reload in progress"
   var mag := at(socket(id,"mag"))
   if mag.is_empty(): return "No magazine inserted"
   var dest := "world" if op == "drop_mag" else storage(peer,mag)
   if dest.is_empty(): return "No accessible slot for magazine"
   items[mag].loc = dest
   if op == "drop_mag": items[mag].pos = req.get("pos",Vector3.ZERO)
   touch(mag)
  "cycle":
   if not Catalog.gun(kind) or not held(peer,id): return "Hold a firearm first"
   if reloads.has(id): return "Reload in progress"
   if s.chamber:
    var loose := spawn("p_ammo" if kind == "pistol" else "r_ammo", req.get("pos",Vector3.ZERO))
    items[loose].state.count = 1
   s.chamber = false
   feed(id)
  "mode":
   if kind != "rifle" or not held(peer,id): return "Hold the rifle first"
   s.mode = "auto" if s.mode == "semi" else "semi"
  "fire":
   if not Catalog.gun(kind) or not held(peer,id): return "Hold a firearm first"
   if reloads.has(id): return "Reload in progress"
   if clock < s.next_fire: return "Fire rate limited"
   if not s.chamber: return "Empty chamber — reload or cycle action"
   s.chamber = false
   s.next_fire = clock + Catalog.DEFS[kind].rate
   fired += 1
   feed(id)
  _: return "Unknown action"
 touch(id)
 return ""

func feed(gun: String) -> void:
 var mag := at(socket(gun,"mag"))
 if not mag.is_empty() and items[mag].state.rounds > 0:
  items[mag].state.rounds -= 1
  items[gun].state.chamber = true
  touch(mag)

func tick(dt: float) -> void:
 clock += dt
 for gun: String in reloads.keys():
  var r: Dictionary = reloads[gun]
  if not items.has(gun) or not held(r.peer,gun) or not items.has(r.mag) or items[r.mag].loc != r.loc or items[r.mag].rev != r.rev:
   reloads.erase(gun)
   continue
  if clock < r.end: continue
  var old := at(socket(gun,"mag"))
  if not old.is_empty():
   items[old].loc = r.loc
   touch(old)
  items[r.mag].loc = socket(gun,"mag")
  touch(r.mag)
  if not items[gun].state.chamber: feed(gun)
  touch(gun)
  reloads.erase(gun)
 for id: String in items.keys():
  var it: Dictionary = items[id]
  if it.def != "stove" or not it.state.burning: continue
  var fuel := at(socket(id,"fuel"))
  if fuel.is_empty() or items[fuel].state.fuel <= 0:
   it.state.burning = false
   touch(id)
   continue
  var burned := minf(dt, items[fuel].state.fuel)
  items[fuel].state.fuel -= burned
  var meal := at(socket(id,"cook"))
  if not meal.is_empty() and items[meal].state.phase == "hydrated":
   items[meal].state.heat += burned
   if items[meal].state.heat >= 10:
    items[meal].state.phase = "cooked"
    touch(meal)
  if items[fuel].state.fuel <= 0: it.state.burning = false; touch(id)

func disconnect_player(peer: int, pos: Vector3) -> void:
 if not players.has(peer): return
 var bag: String = players[peer].rest
 if items.has(bag): items[bag].state.occupant = 0; touch(bag)
 var crate := ""
 var n := 0
 for id: String in items.keys():
  if String(items[id].loc).begins_with("p:%d:" % peer):
   if crate.is_empty(): crate = spawn("crate",pos)
   items[id].loc = socket(crate,"in%d" % n)
   n += 1
   touch(id)
   cancel_reload(id)
 players.erase(peer)
 seen.erase(peer)

func reset() -> void:
 epoch += 1
 items.clear()
 reloads.clear()
 seen.clear()
 serial = 0
 for peer: int in players: players[peer].rest = ""
 revision += 1

func snapshot() -> Dictionary:
 return {"items":items.duplicate(true), "players":players.duplicate(true), "reloads":reloads.duplicate(true), "epoch":epoch,"revision":revision,"clock":clock,"fired":fired}

func restore(data: Dictionary) -> void:
 items = data.items
 players = data.players
 reloads = data.reloads
 epoch = data.epoch
 revision = data.revision
 clock = data.clock
 fired = data.fired

func invariants() -> Array[String]:
 var errors: Array[String] = []
 var occupied: Dictionary = {}
 for id: String in items:
  var it: Dictionary = items[id]
  if it.id != id: errors.append("Identity mismatch")
  if root_item(id).is_empty(): errors.append("Cycle")
  if it.loc != "world":
   if occupied.has(it.loc): errors.append("Duplicate slot " + it.loc)
   occupied[it.loc] = id
   if not compatible(id,it.loc): errors.append("Invalid location " + it.loc)
  for key: String in ["rounds","count","water","fuel","heat"]:
   if it.state.has(key) and it.state[key] < 0: errors.append("Negative " + key)
  if Catalog.DEFS[it.def].tag == "mag" and it.state.rounds > Catalog.DEFS[it.def].capacity: errors.append("Magazine over capacity")
 for peer: int in players:
  var a := at(pslot(peer,"hand0"))
  var b := at(pslot(peer,"hand1"))
  if not a.is_empty() and not b.is_empty() and (Catalog.DEFS[items[a].def].hands == 2 or Catalog.DEFS[items[b].def].hands == 2): errors.append("Two handed conflict")
 return errors

func ammo_total() -> int:
 var total := fired
 for it: Dictionary in items.values():
  total += int(it.state.get("rounds",0)) + int(it.state.get("count",0)) + int(it.state.get("chamber",false))
 return total
