class_name LodgeVisitor
extends CharacterBody3D

## First-person walking controller for the 3D Trophy Lodge.

@export var speed: float = 4.0
@export var mouse_sensitivity: float = 0.0025

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -deg_to_rad(75.0), deg_to_rad(75.0))
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	
	move_and_slide()
