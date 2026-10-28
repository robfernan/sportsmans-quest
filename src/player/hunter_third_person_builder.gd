class_name HunterThirdPersonBuilder
extends RefCounted

## Builds a 3D Hunter Character Model for Sportsman's Quest.
## Supports multiple photo poses: Ground Kneeling, Victory Thumbs-up, Gun-on-Shoulder,
## and Ground Lounging / Head-on-Hand.

enum Pose { STAND_HERO, GROUND_KNEEL, GROUND_LOUNGE, VICTORY_THUMBS_UP, GUN_ON_SHOULDER }

static func build_hunter_mesh() -> Node3D:
	var root := Node3D.new()
	root.name = "HunterVisualMesh"
	
	var mat_jacket := StandardMaterial3D.new()
	mat_jacket.albedo_color = Color(0.20, 0.26, 0.18) # Deep olive drab field jacket
	mat_jacket.roughness = 0.85
	
	var mat_vest := StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.88, 0.40, 0.08) # Blaze Orange hunting vest
	mat_vest.roughness = 0.8
	
	var mat_belt := StandardMaterial3D.new()
	mat_belt.albedo_color = Color(0.14, 0.10, 0.08) # Leather belt & pouches
	mat_belt.roughness = 0.7
	
	var mat_pants := StandardMaterial3D.new()
	mat_pants.albedo_color = Color(0.28, 0.25, 0.20) # Field trousers
	mat_pants.roughness = 0.9
	
	var mat_boots := StandardMaterial3D.new()
	mat_boots.albedo_color = Color(0.12, 0.09, 0.07) # Heavy leather hunting boots
	mat_boots.roughness = 0.8
	
	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.82, 0.68, 0.58) # Face & hands
	mat_skin.roughness = 0.7
	
	var mat_cap := StandardMaterial3D.new()
	mat_cap.albedo_color = Color(0.88, 0.40, 0.08) # Blaze Orange cap
	mat_cap.roughness = 0.8
	
	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.15, 0.15, 0.15) # Dark cap brim / sunglasses
	
	var mat_gun := StandardMaterial3D.new()
	mat_gun.albedo_color = Color(0.18, 0.12, 0.08) # Walnut stock
	mat_gun.roughness = 0.6
	
	var box := BoxMesh.new()
	
	# Model Anchor Node (for shifting overall height/tilt on ground)
	var body_anchor := Node3D.new()
	body_anchor.name = "BodyAnchor"
	root.add_child(body_anchor)
	
	# 1. Torso, Jacket & Blaze Vest
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	torso.mesh = box
	torso.scale = Vector3(0.46, 0.60, 0.28)
	torso.position = Vector3(0, 1.15, 0)
	torso.material_override = mat_jacket
	body_anchor.add_child(torso)
	
	# Blaze Orange Vest Front & Back Overlay
	var vest_front := MeshInstance3D.new()
	vest_front.mesh = box
	vest_front.scale = Vector3(0.48, 0.52, 0.14)
	vest_front.position = Vector3(0, 1.18, -0.08)
	vest_front.material_override = mat_vest
	body_anchor.add_child(vest_front)
	
	var vest_back := MeshInstance3D.new()
	vest_back.mesh = box
	vest_back.scale = Vector3(0.48, 0.52, 0.14)
	vest_back.position = Vector3(0, 1.18, 0.08)
	vest_back.material_override = mat_vest
	body_anchor.add_child(vest_back)
	
	# Leather Ammo Belt & Waist Pouches
	var belt := MeshInstance3D.new()
	belt.mesh = box
	belt.scale = Vector3(0.49, 0.10, 0.30)
	belt.position = Vector3(0, 0.88, 0)
	belt.material_override = mat_belt
	body_anchor.add_child(belt)
	
	for sx in [-1, 1]:
		var pouch := MeshInstance3D.new()
		pouch.mesh = box
		pouch.scale = Vector3(0.10, 0.12, 0.10)
		pouch.position = Vector3(0.24 * sx, 0.88, -0.12)
		pouch.material_override = mat_belt
		body_anchor.add_child(pouch)
	
	# 2. Head, Cap & Visor
	var head_node := Node3D.new()
	head_node.name = "HeadNode"
	head_node.position = Vector3(0, 1.58, 0)
	body_anchor.add_child(head_node)
	
	var head := MeshInstance3D.new()
	head.name = "HeadMesh"
	head.mesh = box
	head.scale = Vector3(0.22, 0.24, 0.22)
	head.material_override = mat_skin
	head_node.add_child(head)
	
	# Hunting Cap Crown
	var cap := MeshInstance3D.new()
	cap.name = "CapMesh"
	cap.mesh = box
	cap.scale = Vector3(0.24, 0.10, 0.24)
	cap.position = Vector3(0, 0.14, 0.0)
	cap.material_override = mat_cap
	head_node.add_child(cap)
	
	# Front Visor / Brim
	var visor := MeshInstance3D.new()
	visor.mesh = box
	visor.scale = Vector3(0.22, 0.03, 0.14)
	visor.position = Vector3(0, 0.11, -0.16)
	visor.material_override = mat_visor
	head_node.add_child(visor)
	
	# 3. Arms & Hands
	for sx in [-1, 1]:
		var side = "Left" if sx == -1 else "Right"
		var arm_pivot := Node3D.new()
		arm_pivot.name = "%sArmPivot" % side
		arm_pivot.position = Vector3(0.32 * sx, 1.35, 0)
		body_anchor.add_child(arm_pivot)
		
		var arm := MeshInstance3D.new()
		arm.name = "%sArm" % side
		arm.mesh = box
		arm.scale = Vector3(0.12, 0.54, 0.14)
		arm.position = Vector3(0, -0.27, -0.05)
		arm.material_override = mat_jacket
		arm_pivot.add_child(arm)
		
		var hand := MeshInstance3D.new()
		hand.name = "%sHand" % side
		hand.mesh = box
		hand.scale = Vector3(0.1, 0.12, 0.1)
		hand.position = Vector3(0, -0.56, -0.08)
		hand.material_override = mat_skin
		arm_pivot.add_child(hand)

	# 4. Legs & Boots
	for sx in [-1, 1]:
		var side = "Left" if sx == -1 else "Right"
		var leg_pivot := Node3D.new()
		leg_pivot.name = "%sLegPivot" % side
		leg_pivot.position = Vector3(0.14 * sx, 0.84, 0)
		body_anchor.add_child(leg_pivot)
		
		var leg := MeshInstance3D.new()
		leg.name = "%sLeg" % side
		leg.mesh = box
		leg.scale = Vector3(0.18, 0.68, 0.20)
		leg.position = Vector3(0, -0.34, 0)
		leg.material_override = mat_pants
		leg_pivot.add_child(leg)
		
		var boot := MeshInstance3D.new()
		boot.name = "%sBoot" % side
		boot.mesh = box
		boot.scale = Vector3(0.19, 0.18, 0.28)
		boot.position = Vector3(0, -0.72, -0.05)
		boot.material_override = mat_boots
		leg_pivot.add_child(boot)

	# 5. Prop Hunting Rifle (for photo pose)
	var prop_rifle := MeshInstance3D.new()
	prop_rifle.name = "PropRifle"
	prop_rifle.mesh = box
	prop_rifle.scale = Vector3(0.06, 0.95, 0.12)
	prop_rifle.position = Vector3(0.24, 0.9, -0.2)
	prop_rifle.rotation.z = deg_to_rad(-18)
	prop_rifle.material_override = mat_gun
	body_anchor.add_child(prop_rifle)

	return root

static func apply_pose(mesh_root: Node3D, pose: Pose) -> void:
	if not mesh_root:
		return
	var anchor = mesh_root.find_child("BodyAnchor", true, false)
	var l_arm = mesh_root.find_child("LeftArmPivot", true, false)
	var r_arm = mesh_root.find_child("RightArmPivot", true, false)
	var l_leg = mesh_root.find_child("LeftLegPivot", true, false)
	var r_leg = mesh_root.find_child("RightLegPivot", true, false)
	var head = mesh_root.find_child("HeadNode", true, false)
	var rifle = mesh_root.find_child("PropRifle", true, false)
	
	if not anchor or not l_arm or not r_arm or not l_leg or not r_leg:
		return

	# Reset base transforms
	anchor.position = Vector3.ZERO
	anchor.rotation = Vector3.ZERO
	if head:
		head.rotation = Vector3.ZERO
	if rifle:
		rifle.visible = true
		rifle.position = Vector3(0.24, 0.9, -0.2)
		rifle.rotation = Vector3(0, 0, deg_to_rad(-18))

	match pose:
		Pose.STAND_HERO:
			# Classic heroic trophy stand holding rifle
			anchor.position = Vector3.ZERO
			l_arm.rotation = Vector3(deg_to_rad(-15), 0, deg_to_rad(-10))
			r_arm.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-20), deg_to_rad(15))
			l_leg.rotation = Vector3.ZERO
			r_leg.rotation = Vector3(0, deg_to_rad(-15), 0)

		Pose.GROUND_KNEEL:
			# Respectful one-knee ground kneel next to harvest
			anchor.position = Vector3(0, -0.42, 0)
			r_leg.rotation = Vector3(deg_to_rad(75), deg_to_rad(-10), 0)
			l_leg.rotation = Vector3(deg_to_rad(-45), deg_to_rad(10), 0)
			l_arm.rotation = Vector3(deg_to_rad(-45), deg_to_rad(20), deg_to_rad(-15))
			r_arm.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-15), deg_to_rad(15))
			if head:
				head.rotation = Vector3(deg_to_rad(12), deg_to_rad(-10), 0)
			if rifle:
				rifle.position = Vector3(0.25, 0.2, 0.05)
				rifle.rotation = Vector3(deg_to_rad(65), 0, deg_to_rad(-15))

		Pose.GROUND_LOUNGE:
			# Relaxed ground lounge: hunter reclining comfortably on one hip with elbow propping up
			anchor.position = Vector3(0, -0.65, 0)
			anchor.rotation = Vector3(deg_to_rad(-10), deg_to_rad(20), deg_to_rad(25))
			# Left arm resting on ground supporting torso
			l_arm.rotation = Vector3(deg_to_rad(15), 0, deg_to_rad(65))
			# Right arm resting relaxed across knee
			r_arm.rotation = Vector3(deg_to_rad(-35), deg_to_rad(-15), deg_to_rad(15))
			# Legs bent naturally sitting on the grass
			l_leg.rotation = Vector3(deg_to_rad(65), deg_to_rad(25), deg_to_rad(-10))
			r_leg.rotation = Vector3(deg_to_rad(40), deg_to_rad(-15), deg_to_rad(10))
			if head:
				head.rotation = Vector3(deg_to_rad(-8), deg_to_rad(-15), deg_to_rad(-15))
			if rifle:
				rifle.position = Vector3(0.2, -0.2, -0.3)
				rifle.rotation = Vector3(deg_to_rad(75), deg_to_rad(45), deg_to_rad(15))

		Pose.VICTORY_THUMBS_UP:
			# Standing victory thumbs up with wide grin pose
			anchor.position = Vector3.ZERO
			l_arm.rotation = Vector3(deg_to_rad(-85), 0, deg_to_rad(-20)) # Thumbs up forward
			r_arm.rotation = Vector3(deg_to_rad(15), 0, deg_to_rad(35))   # On hip
			l_leg.rotation = Vector3(deg_to_rad(-5), 0, deg_to_rad(-10))
			r_leg.rotation = Vector3(deg_to_rad(5), 0, deg_to_rad(10))
			if head:
				head.rotation = Vector3(deg_to_rad(-8), deg_to_rad(-12), deg_to_rad(5))

		Pose.GUN_ON_SHOULDER:
			# Gun resting across shoulder, looking at camera
			anchor.position = Vector3.ZERO
			r_arm.rotation = Vector3(deg_to_rad(-125), deg_to_rad(20), deg_to_rad(35))
			l_arm.rotation = Vector3(deg_to_rad(10), 0, deg_to_rad(-15))
			l_leg.rotation = Vector3.ZERO
			r_leg.rotation = Vector3.ZERO
			if rifle:
				rifle.position = Vector3(0.22, 1.45, 0.05)
				rifle.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), deg_to_rad(35))
