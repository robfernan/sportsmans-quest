class_name MapCanvasDrawer
extends Control

## Draws Topographic Reserve features, Lake contours, Player needle, Dog icon, and animal sign.

var parent_map: HuntermateMap = null

func _ready() -> void:
	parent_map = get_parent().get_parent() as HuntermateMap

func _draw() -> void:
	var rect_size = size
	var center = rect_size * 0.5
	var map_scale = (rect_size.x * 0.46) / HuntermateMap.RESERVE_EXTENT
	
	# 1. Background Reserve Terrain Fill (Grid & Contour styling)
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.12, 0.16, 0.12, 0.95), true)
	
	# Draw topographic elevation rings
	var topo_color := Color(0.22, 0.28, 0.20, 0.6)
	for r in [60.0, 120.0, 180.0, 240.0]:
		draw_circle(center, r * map_scale, topo_color, false, 1.2)
	
	# Grid Lines (every 50 meters)
	var grid_col := Color(0.2, 0.25, 0.2, 0.35)
	for d in range(-250, 300, 50):
		var x_pos = center.x + d * map_scale
		var y_pos = center.y + d * map_scale
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, rect_size.y), grid_col, 1.0)
		draw_line(Vector2(0, y_pos), Vector2(rect_size.x, y_pos), grid_col, 1.0)

	# 2. Draw Whispering Pines Lake Basin
	# Lake center is around (10.0, -10.0), radius ~95.0m
	var lake_c = center + Vector2(10.0 * map_scale, -10.0 * map_scale)
	var lake_r = 95.0 * map_scale
	draw_circle(lake_c, lake_r, Color(0.15, 0.28, 0.38, 0.8), true)
	draw_circle(lake_c, lake_r, Color(0.25, 0.45, 0.55, 0.9), false, 2.0)
	
	# 3. Draw Discovered Tracks / Spoor if available
	var world = parent_map.world if parent_map else null
	if world and world.tracks and world.tracks.has_node("Tracks"):
		var tracks_node = world.tracks.get_node("Tracks")
		var clue_col := Color(0.9, 0.8, 0.3, 0.8)
		for child in tracks_node.get_children():
			if child is Node3D:
				var m_pos = center + Vector2(child.global_position.x * map_scale, child.global_position.z * map_scale)
				draw_circle(m_pos, 2.5, clue_col, true)

	# 4. Draw Dog Companion Position
	var dog = parent_map.dog if parent_map else null
	if dog and is_instance_valid(dog):
		var dog_pos = center + Vector2(dog.global_position.x * map_scale, dog.global_position.z * map_scale)
		draw_circle(dog_pos, 4.0, Color(0.9, 0.65, 0.2), true)

	# 4b. Birds marked in brass on the paper map. Not a radar sweep.
	if world and world.animals:
		var bird_col := Color(0.72, 0.55, 0.28, 0.82)
		for a in world.animals:
			if is_instance_valid(a) and a is Duck and a.state != Animal.State.DEAD:
				var b_pos = center + Vector2(a.global_position.x * map_scale, a.global_position.z * map_scale)
				var flying: bool = a.dstate == Duck.DuckState.FLY
				draw_circle(b_pos, 3.4 if flying else 2.2, bird_col, true)

	# 5. Draw Player / Hunter Marker (Arrow pointer)
	var hunter = parent_map.hunter if parent_map else null
	if hunter and is_instance_valid(hunter):
		var p_pos = center + Vector2(hunter.global_position.x * map_scale, hunter.global_position.z * map_scale)
		var yaw = hunter.rotation.y
		var forward = Vector2(-sin(yaw), -cos(yaw))
		var right = Vector2(-forward.y, forward.x)
		
		# Draw Hunter Field-of-View Cone
		var cone_len = 45.0 * map_scale
		var left_ray = forward.rotated(deg_to_rad(-25)) * cone_len
		var right_ray = forward.rotated(deg_to_rad(25)) * cone_len
		draw_line(p_pos, p_pos + left_ray, Color(1, 0.9, 0.3, 0.35), 1.5)
		draw_line(p_pos, p_pos + right_ray, Color(1, 0.9, 0.3, 0.35), 1.5)
		
		# Draw Arrow Tri
		var pt_tip = p_pos + forward * 8.0
		var pt_l = p_pos - forward * 5.0 + right * 5.0
		var pt_r = p_pos - forward * 5.0 - right * 5.0
		draw_colored_polygon(PackedVector2Array([pt_tip, pt_l, pt_r]), Color(0.95, 0.25, 0.2, 1.0))
		draw_circle(p_pos, 2.0, Color.WHITE, true)
