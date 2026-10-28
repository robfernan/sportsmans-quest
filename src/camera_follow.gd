extends Camera3D

## Smooth follow camera for the kayak
@export var target_node: NodePath
@export var follow_distance: float = 6.0
@export var follow_height: float = 2.5
@export var smooth_speed: float = 5.0

var target: Node3D

func _ready() -> void:
	if target_node:
		target = get_node(target_node)

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	# Position behind the kayak based on its facing direction
	var target_transform = target.global_transform
	var desired_pos = target_transform.origin + (target_transform.basis.z * follow_distance) + Vector3(0, follow_height, 0)
	
	global_position = global_position.lerp(desired_pos, smooth_speed * delta)
	look_at(target_transform.origin + Vector3(0, 0.5, 0), Vector3.UP)
