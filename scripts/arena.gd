class_name LabArena
extends Node3D
const STATIONS := {"camp":Vector3(-6,0,-4),"weapons":Vector3(6,0,-4),"water":Vector3(-6,0,7)}
var targets: Array[StaticBody3D] = []

static func material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.86
 return m

func box(pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
 var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
 add_child(root)
 root.position = pos
 var mesh := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = size
 mesh.mesh = shape
 mesh.material_override = material(color)
 root.add_child(mesh)
 if solid:
  var collision := CollisionShape3D.new()
  var b := BoxShape3D.new()
  b.size = size
  collision.shape = b
  root.add_child(collision)
 return root

func sign_at(text: String, pos: Vector3, color := Color("c5ded7"), size := 26) -> void:
 var label := Label3D.new()
 label.text = text
 label.font_size = size
 label.pixel_size = 0.008
 label.position = pos
 label.modulate = color
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 add_child(label)

func _ready() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("839ca9")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("c8dfef")
 e.ambient_light_energy = 0.3
 e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,-30,0)
 sun.light_color = Color("fff0d5")
 sun.light_energy = 0.65
 sun.shadow_enabled = true
 add_child(sun)
 box(Vector3(0,-0.3,0),Vector3(100,0.6,100),Color("475955"))
 for x in range(-48,49,4):
  box(Vector3(x,0.008,0),Vector3(0.025,0.01,98),Color("62736a"),false)
  box(Vector3(0,0.008,x),Vector3(98,0.01,0.025),Color("62736a"),false)
 for x in [-50,50]: box(Vector3(x,1,0),Vector3(0.4,2,100),Color("667970"))
 box(Vector3(0,1,-50),Vector3(100,2,0.4),Color("667970"))
 # South edge intentionally open for fall recovery tests.
 box(Vector3(0,0.025,0),Vector3(3,0.04,36),Color("839184"),false)
 box(Vector3(0,0.025,-4),Vector3(22,0.04,3),Color("839184"),false)
 sign_at("FIELD LAB\nCOOPERATIVE BACKPACKING",Vector3(0,4,-10),Color("f3db9b"),40)
 sign_at("01  /  CAMP & SUPPLIES\nApproach station · interact",Vector3(-6,2.4,-4))
 sign_at("02  /  EQUIPMENT RANGE\nApproach station · interact",Vector3(6,2.4,-4))
 sign_at("03  /  WATER SOURCE\nBottle refill",Vector3(-6,2.4,7))
 for key: String in STATIONS:
  var station := box(STATIONS[key]+Vector3(0,0.5,0),Vector3(1.2,1,1),Color("d9aa62"))
  station.set_meta("station",key)
 box(Vector3(-10,0.05,-10),Vector3(12,0.1,8),Color("89957b"))
 sign_at("CAMPING SURFACE",Vector3(-10,0.2,-14),Color("e9d7ab"))
 for i in 4:
  var t := box(Vector3(4+i*3,1.5,-18-i*2),Vector3(1.1,2,0.3),Color("d99163")) as StaticBody3D
  t.set_meta("target",i+1)
  targets.append(t)
  box(t.position+Vector3(0,0,0.17),Vector3(0.4,0.4,0.03),Color("fff1bf"),false)
  sign_at("TARGET %d" % (i+1),t.position+Vector3(0,1.6,0),Color("f1d4a0"),24)
 # Three genuine collider slopes.
 for i in 3:
  var slope := box(Vector3(20+i*7,1.5,-3),Vector3(5,0.4,8),Color("8d9c8c"))
  slope.rotation_degrees.x = [20,40,60][i]
  sign_at("%d° SLOPE" % [20,40,60][i],Vector3(20+i*7,5,-3))
 for i in 6: box(Vector3(20,0.2*(i+1),9-i),Vector3(4,0.4*(i+1),1),Color("96a293"))
 box(Vector3(20,1.2,2),Vector3(4,2.4,4),Color("96a293"))
 box(Vector3(25,1.35,9),Vector3(3,0.2,4),Color("a5ac91"))
 sign_at("STAIRS / CROUCH CLEARANCE",Vector3(22,3,10))
 box(Vector3(-21,0.035,4),Vector3(9,0.05,10),Color("3f7156"),false)
 for i in 35:
  var x := -25.0 + float(i%7)*1.3
  var z := float(i/7)*2.0
  box(Vector3(x,0.4,z),Vector3(0.18,0.8,0.18),Color("76a46a"),false)
 sign_at("BRUSH · 65% SPEED",Vector3(-21,2.4,4))
 box(Vector3(-21,0.04,-9),Vector3(9,0.06,10),Color("8a8065"),false)
 sign_at("ROUGH TERRAIN · 80% SPEED",Vector3(-21,2.4,-9))
 box(Vector3(-21,0.05,18),Vector3(9,0.07,10),Color("579ca5"),false)
 box(Vector3(-21,0.09,26),Vector3(9,0.12,6),Color("234b69"),false)
 box(Vector3(-21,0.6,23),Vector3(9,1.2,0.25),Color("dfb45a"))
 sign_at("SHALLOW WATER · 55% SPEED\nDEEP WATER CLOSED / NO SWIMMING",Vector3(-21,2.6,20))
 sign_at("SOUTH EDGE / AUTOMATIC FALL RECOVERY",Vector3(0,2,46))

func terrain(pos: Vector3) -> Dictionary:
 if pos.x >= -25.5 and pos.x <= -16.5:
  if pos.z >= -1 and pos.z <= 9: return {"name":"Brush", "speed":0.65, "water":false}
  if pos.z >= -14 and pos.z <= -4: return {"name":"Rough", "speed":0.8, "water":false}
  if pos.z >= 13 and pos.z <= 23: return {"name":"Wading", "speed":0.55, "water":true}
 return {"name":"Firm ground", "speed":1.0, "water":false}
