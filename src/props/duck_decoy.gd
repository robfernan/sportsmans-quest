class_name DuckDecoy
extends Node3D

## Floating Mallard Decoy (Sportsman's Quest)
## Deployed from kayak or shoreline. Draws circling ducks down toward the water spread.

var bob_offset: float = 0.0

func _ready() -> void:
	bob_offset = randf() * TAU
	_build_decoy_mesh()

func _build_decoy_mesh() -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	
	# Duck body
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.scale = Vector3(0.24, 0.16, 0.38)
	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.48, 0.38, 0.28)
	body.material_override = mat_body
	add_child(body)
	
	# Green head
	var head := MeshInstance3D.new()
	head.mesh = sphere
	head.scale = Vector3(0.1, 0.1, 0.12)
	head.position = Vector3(0, 0.16, -0.16)
	var mat_head := StandardMaterial3D.new()
	mat_head.albedo_color = Color(0.08, 0.42, 0.18)
	head.material_override = mat_head
	add_child(head)
	
	# Yellow bill
	var bill := MeshInstance3D.new()
	bill.mesh = sphere
	bill.scale = Vector3(0.05, 0.03, 0.08)
	bill.position = Vector3(0, 0.14, -0.25)
	var mat_bill := StandardMaterial3D.new()
	mat_bill.albedo_color = Color(0.9, 0.8, 0.2)
	bill.material_override = mat_bill
	add_child(bill)

func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.002 + bob_offset
	position.y = Terrain.WATER_LEVEL + sin(t) * 0.02
	rotation.z = sin(t * 0.8) * 0.04
	rotation.x = cos(t * 0.7) * 0.03
