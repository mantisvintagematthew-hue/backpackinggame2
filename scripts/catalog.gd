class_name Catalog
extends RefCounted

const DEFS := {
 "pack": {"name":"Expedition pack", "size":3, "hands":2, "color":"bd873f", "tag":"pack"},
 "bag": {"name":"Sleeping bag", "size":2, "hands":1, "color":"e1b56c", "tag":"bag"},
 "stove": {"name":"Compact stove", "size":2, "hands":1, "color":"ef805d", "tag":"stove"},
 "fuel": {"name":"Fuel canister", "size":1, "hands":1, "color":"bcd564", "tag":"fuel"},
 "bottle": {"name":"Water bottle", "size":1, "hands":1, "color":"64c6db", "tag":"bottle"},
 "meal": {"name":"Meal pouch", "size":1, "hands":1, "color":"e4c693", "tag":"meal"},
 "pistol": {"name":"9 mm pistol", "size":2, "hands":1, "color":"a9b6ba", "tag":"pistol", "ammo":"9mm", "rate":0.22},
 "rifle": {"name":"AK-style rifle", "size":3, "hands":2, "color":"b89270", "tag":"rifle", "ammo":"rifle", "rate":0.10},
 "p_mag": {"name":"Pistol magazine", "size":1, "hands":1, "color":"7b929e", "tag":"mag", "ammo":"9mm", "capacity":15},
 "r_mag": {"name":"Rifle magazine", "size":1, "hands":1, "color":"899777", "tag":"mag", "ammo":"rifle", "capacity":30},
 "p_ammo": {"name":"9 mm rounds", "size":1, "hands":1, "color":"dbb85d", "tag":"ammo", "ammo":"9mm"},
 "r_ammo": {"name":"Rifle rounds", "size":1, "hands":1, "color":"e3a85b", "tag":"ammo", "ammo":"rifle"},
 "crate": {"name":"Recovery crate", "size":4, "hands":2, "color":"a98f70", "tag":"crate"}
}
const EXTERNAL := {"ext0":"bag", "ext1":"bottle", "ext2":"stove", "ext3":"rifle"}

static func initial(kind: String) -> Dictionary:
 match kind:
  "stove": return {"burning":false}
  "fuel": return {"fuel":120.0}
  "bottle": return {"water":1000}
  "meal": return {"phase":"dry", "heat":0.0}
  "bag": return {"unrolled":false, "occupant":0}
  "pistol", "rifle": return {"chamber":false, "mode":"semi", "next_fire":0.0}
  "p_mag", "r_mag": return {"rounds":0}
  "p_ammo", "r_ammo": return {"count":60}
 return {}

static func gun(kind: String) -> bool:
 return kind in ["pistol", "rifle"]

static func dimensions(kind: String, state: Dictionary = {}) -> Vector3:
 if kind == "rifle": return Vector3(0.18,0.2,0.8)
 if kind in ["pack","crate"]: return Vector3(0.5,0.55,0.4)
 if kind == "bag" and state.get("unrolled",false): return Vector3(0.65,0.15,1.6)
 return Vector3(0.4,0.4,0.4)
