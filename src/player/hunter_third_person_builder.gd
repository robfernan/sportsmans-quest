class_name HunterThirdPersonBuilder
extends RefCounted

## Builds an articulated 3D Low-Poly Hunter Character Model for Sportsman's Quest.
## Supports realistic anatomical photo poses with 2-segment knee and elbow joints:
## Ground Kneeling, Victory Thumbs-up, Gun-on-Shoulder, Ground Lounging, and Hero Stand.

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
	
	# Model Anchor Node (for overall height/tilt on ground)
	var body_anchor := Node3D.new()
	body_anchor.name = "BodyAnchor"
	root.add_child(body_anchor)
	
	# 1. Torso, Jacket & Blaze Vest
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	torso.mesh = box
	torso.scale = Vector3(0.44, 0.54, 0.26)
	torso.position = Vector3(0, 1.12, 0)
	torso.material_override = mat_jacket
	body_anchor.add_child(torso)
	
	# Blaze Orange Vest Front & Back Overlay
	var vest_front := MeshInstance3D.new()
	vest_front.name = "VestFront"
	vest_front.mesh = box
	vest_front.scale = Vector3(0.46, 0.48, 0.13)
	vest_front.position = Vector3(0, 1.13, -0.07)
	vest_front.material_override = mat_vest
	body_anchor.add_child(vest_front)
	
	var vest_back := MeshInstance3D.new()
	vest_back.name = "VestBack"
	vest_back.mesh = box
	vest_back.scale = Vector3(0.46, 0.48, 0.13)
	vest_back.position = Vector3(0, 1.13, 0.07)
	vest_back.material_override = mat_vest
	body_anchor.add_child(vest_back)
	
	# Leather Ammo Belt & Waist Pouches
	var belt := MeshInstance3D.new()
	belt.name = "Belt"
	belt.mesh = box
	belt.scale = Vector3(0.47, 0.08, 0.28)
	belt.position = Vector3(0, 0.85, 0)
	belt.material_override = mat_belt
	body_anchor.add_child(belt)
	
	for sx in [-1, 1]:
		var pouch := MeshInstance3D.new()
		pouch.name = ("Left" if sx == -1 else "Right") + "Pouch"
		pouch.mesh = box
		pouch.scale = Vector3(0.10, 0.10, 0.09)
		pouch.position = Vector3(0.24 * sx, 0.85, -0.11)
		pouch.material_override = mat_belt
		body_anchor.add_child(pouch)
	
	# 2. Head, Cap & Visor
	var head_node := Node3D.new()
	head_node.name = "HeadNode"
	head_node.position = Vector3(0, 1.48, 0)
	body_anchor.add_child(head_node)
	
	var head := MeshInstance3D.new()
	head.name = "HeadMesh"
	head.mesh = box
	head.scale = Vector3(0.20, 0.22, 0.20)
	head.position = Vector3(0, 0.02, 0)
	head.material_override = mat_skin
	head_node.add_child(head)
	
	var cap := MeshInstance3D.new()
	cap.name = "CapMesh"
	cap.mesh = box
	cap.scale = Vector3(0.22, 0.08, 0.22)
	cap.position = Vector3(0, 0.14, 0.0)
	cap.material_override = mat_cap
	head_node.add_child(cap)
	
	var visor := MeshInstance3D.new()
	visor.name = "VisorMesh"
	visor.mesh = box
	visor.scale = Vector3(0.20, 0.03, 0.12)
	visor.position = Vector3(0, 0.11, -0.15)
	visor.material_override = mat_visor
	head_node.add_child(visor)
	
	# 3. Articulated Arms (Shoulder Pivot -> UpperArm -> Elbow Pivot -> Forearm -> Hand)
	for sx in [-1, 1]:
		var side = "Left" if sx == -1 else "Right"
		var arm_pivot := Node3D.new()
		arm_pivot.name = "%sArmPivot" % side
		arm_pivot.position = Vector3(0.28 * sx, 1.34, 0)
		body_anchor.add_child(arm_pivot)
		
		var upper_arm := MeshInstance3D.new()
		upper_arm.name = "%sUpperArm" % side
		upper_arm.mesh = box
		upper_arm.scale = Vector3(0.12, 0.26, 0.12)
		upper_arm.position = Vector3(0, -0.13, 0)
		upper_arm.material_override = mat_jacket
		arm_pivot.add_child(upper_arm)
		
		var elbow_pivot := Node3D.new()
		elbow_pivot.name = "%sElbowPivot" % side
		elbow_pivot.position = Vector3(0, -0.26, 0)
		arm_pivot.add_child(elbow_pivot)
		
		var forearm := MeshInstance3D.new()
		forearm.name = "%sForearm" % side
		forearm.mesh = box
		forearm.scale = Vector3(0.11, 0.24, 0.11)
		forearm.position = Vector3(0, -0.12, 0)
		forearm.material_override = mat_jacket
		elbow_pivot.add_child(forearm)
		
		var hand := MeshInstance3D.new()
		hand.name = "%sHand" % side
		hand.mesh = box
		hand.scale = Vector3(0.09, 0.10, 0.09)
		hand.position = Vector3(0, -0.26, 0)
		hand.material_override = mat_skin
		elbow_pivot.add_child(hand)

	# 4. Articulated Legs (Hip Pivot -> Thigh -> Knee Pivot -> Calf -> Boot Pivot -> Boot)
	for sx in [-1, 1]:
		var side = "Left" if sx == -1 else "Right"
		var leg_pivot := Node3D.new()
		leg_pivot.name = "%sLegPivot" % side
		leg_pivot.position = Vector3(0.14 * sx, 0.82, 0)
		body_anchor.add_child(leg_pivot)
		
		var thigh := MeshInstance3D.new()
		thigh.name = "%sThigh" % side
		thigh.mesh = box
		thigh.scale = Vector3(0.17, 0.38, 0.18)
		thigh.position = Vector3(0, -0.19, 0)
		thigh.material_override = mat_pants
		leg_pivot.add_child(thigh)
		
		var knee_pivot := Node3D.new()
		knee_pivot.name = "%sKneePivot" % side
		knee_pivot.position = Vector3(0, -0.38, 0)
		leg_pivot.add_child(knee_pivot)
		
		var calf := MeshInstance3D.new()
		calf.name = "%sCalf" % side
		calf.mesh = box
		calf.scale = Vector3(0.15, 0.36, 0.16)
		calf.position = Vector3(0, -0.18, 0)
		calf.material_override = mat_pants
		knee_pivot.add_child(calf)
		
		var boot_pivot := Node3D.new()
		boot_pivot.name = "%sBootPivot" % side
		boot_pivot.position = Vector3(0, -0.36, 0)
		knee_pivot.add_child(boot_pivot)
		
		var boot := MeshInstance3D.new()
		boot.name = "%sBoot" % side
		boot.mesh = box
		boot.scale = Vector3(0.17, 0.14, 0.26)
		boot.position = Vector3(0, 0.07, -0.05)
		boot.material_override = mat_boots
		boot_pivot.add_child(boot)

	# 5. Prop Hunting Rifle (for photo pose)
	var prop_rifle := MeshInstance3D.new()
	prop_rifle.name = "PropRifle"
	prop_rifle.mesh = box
	prop_rifle.scale = Vector3(0.06, 0.95, 0.12)
	prop_rifle.position = Vector3(0.24, 0.85, -0.15)
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
	var l_elbow = mesh_root.find_child("LeftElbowPivot", true, false)
	var r_elbow = mesh_root.find_child("RightElbowPivot", true, false)
	var l_leg = mesh_root.find_child("LeftLegPivot", true, false)
	var r_leg = mesh_root.find_child("RightLegPivot", true, false)
	var l_knee = mesh_root.find_child("LeftKneePivot", true, false)
	var r_knee = mesh_root.find_child("RightKneePivot", true, false)
	var l_boot = mesh_root.find_child("LeftBootPivot", true, false)
	var r_boot = mesh_root.find_child("RightBootPivot", true, false)
	var head = mesh_root.find_child("HeadNode", true, false)
	var rifle = mesh_root.find_child("PropRifle", true, false)
	
	if not anchor or not l_arm or not r_arm or not l_leg or not r_leg:
		return

	# Reset base transforms
	anchor.position = Vector3.ZERO
	anchor.rotation = Vector3.ZERO
	l_arm.rotation = Vector3.ZERO
	r_arm.rotation = Vector3.ZERO
	if l_elbow: l_elbow.rotation = Vector3.ZERO
	if r_elbow: r_elbow.rotation = Vector3.ZERO
	l_leg.rotation = Vector3.ZERO
	r_leg.rotation = Vector3.ZERO
	if l_knee: l_knee.rotation = Vector3.ZERO
	if r_knee: r_knee.rotation = Vector3.ZERO
	if l_boot: l_boot.rotation = Vector3.ZERO
	if r_boot: r_boot.rotation = Vector3.ZERO
	if head: head.rotation = Vector3.ZERO
	if rifle:
		rifle.visible = true
		rifle.position = Vector3(0.24, 0.85, -0.15)
		rifle.rotation = Vector3(0, 0, deg_to_rad(-18))

	match pose:
		Pose.STAND_HERO:
			# Classic heroic trophy stand holding rifle upright
			anchor.position = Vector3.ZERO
			l_arm.rotation = Vector3(deg_to_rad(-12), 0, deg_to_rad(-10))
			if l_elbow: l_elbow.rotation = Vector3(deg_to_rad(-25), 0, 0) # Left hand resting on belt
			r_arm.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-15), deg_to_rad(12))
			if r_elbow: r_elbow.rotation = Vector3(deg_to_rad(-20), 0, 0)
			l_leg.rotation = Vector3(0, 0, deg_to_rad(-3))
			r_leg.rotation = Vector3(0, deg_to_rad(-12), deg_to_rad(3))
			if rifle:
				rifle.position = Vector3(0.28, 0.45, -0.12)
				rifle.rotation = Vector3(0, 0, deg_to_rad(-8))

		Pose.GROUND_KNEEL:
			# Respectful one-knee ground kneel next to harvest:
			# Left knee bent up (90 deg), left foot planted flat on ground
			# Right knee on ground, right calf folded flat backward
			anchor.position = Vector3(0, -0.42, 0)
			
			# Left leg (planted knee-up)
			l_leg.rotation = Vector3(deg_to_rad(85), deg_to_rad(8), 0)
			if l_knee: l_knee.rotation = Vector3(deg_to_rad(-85), 0, 0)
			if l_boot: l_boot.rotation = Vector3(deg_to_rad(5), 0, 0)
			
			# Right leg (knee down on ground)
			r_leg.rotation = Vector3(deg_to_rad(-10), deg_to_rad(-5), 0)
			if r_knee: r_knee.rotation = Vector3(deg_to_rad(95), 0, 0)
			if r_boot: r_boot.rotation = Vector3(deg_to_rad(30), 0, 0)
			
			# Arms resting respectfully across knee and harvest
			l_arm.rotation = Vector3(deg_to_rad(-45), deg_to_rad(15), deg_to_rad(-10))
			if l_elbow: l_elbow.rotation = Vector3(deg_to_rad(-35), 0, 0)
			r_arm.rotation = Vector3(deg_to_rad(-35), deg_to_rad(-12), deg_to_rad(12))
			if r_elbow: r_elbow.rotation = Vector3(deg_to_rad(-25), 0, 0)
			
			if head:
				head.rotation = Vector3(deg_to_rad(12), deg_to_rad(-10), 0)
			if rifle:
				rifle.position = Vector3(0.24, 0.22, -0.10)
				rifle.rotation = Vector3(deg_to_rad(55), 0, deg_to_rad(-15))

		Pose.GROUND_LOUNGE:
			# Natural relaxed ground sit / lounge beside trophy:
			# Pelvis resting flat on grass, upper body leaning back comfortably.
			# Both knees naturally bent with calves and boots resting along the ground!
			anchor.position = Vector3(0, -0.76, 0)
			anchor.rotation = Vector3(deg_to_rad(-12), deg_to_rad(15), deg_to_rad(4))
			
			# Left leg: thigh forward/outward, knee bent so lower leg rests along grass
			l_leg.rotation = Vector3(deg_to_rad(65), deg_to_rad(18), deg_to_rad(-8))
			if l_knee: l_knee.rotation = Vector3(deg_to_rad(-55), 0, 0)
			if l_boot: l_boot.rotation = Vector3(deg_to_rad(-10), deg_to_rad(10), 0)
			
			# Right leg: thigh forward, knee bent comfortably upward, boot near ground
			r_leg.rotation = Vector3(deg_to_rad(55), deg_to_rad(-14), deg_to_rad(8))
			if r_knee: r_knee.rotation = Vector3(deg_to_rad(-65), 0, 0)
			if r_boot: r_boot.rotation = Vector3(deg_to_rad(10), 0, 0)
			
			# Left arm reaching behind propping up torso on grass
			l_arm.rotation = Vector3(deg_to_rad(18), 0, deg_to_rad(38))
			if l_elbow: l_elbow.rotation = Vector3(deg_to_rad(15), 0, 0)
			
			# Right arm resting comfortably across raised right thigh
			r_arm.rotation = Vector3(deg_to_rad(-38), deg_to_rad(-15), deg_to_rad(15))
			if r_elbow: r_elbow.rotation = Vector3(deg_to_rad(-40), 0, 0)
			
			if head:
				head.rotation = Vector3(deg_to_rad(8), deg_to_rad(-18), deg_to_rad(-4))
			if rifle:
				rifle.position = Vector3(0.20, 0.12, -0.22)
				rifle.rotation = Vector3(deg_to_rad(68), deg_to_rad(25), deg_to_rad(8))

		Pose.VICTORY_THUMBS_UP:
			# Standing victory thumbs up with wide grin pose
			anchor.position = Vector3.ZERO
			l_arm.rotation = Vector3(deg_to_rad(-85), 0, deg_to_rad(-18))
			if l_elbow: l_elbow.rotation = Vector3(deg_to_rad(-25), 0, 0)
			r_arm.rotation = Vector3(deg_to_rad(12), 0, deg_to_rad(32))
			if r_elbow: r_elbow.rotation = Vector3(deg_to_rad(-45), 0, 0)
			l_leg.rotation = Vector3(deg_to_rad(-4), 0, deg_to_rad(-8))
			r_leg.rotation = Vector3(deg_to_rad(4), 0, deg_to_rad(8))
			if head:
				head.rotation = Vector3(deg_to_rad(-6), deg_to_rad(-10), deg_to_rad(4))
			if rifle:
				rifle.position = Vector3(0.32, 0.50, -0.10)
				rifle.rotation = Vector3(0, 0, deg_to_rad(-12))

		Pose.GUN_ON_SHOULDER:
			# Gun resting across shoulder, looking at camera
			anchor.position = Vector3.ZERO
			r_arm.rotation = Vector3(deg_to_rad(-120), deg_to_rad(18), deg_to_rad(32))
			if r_elbow: r_elbow.rotation = Vector3(deg_to_rad(-60), 0, 0)
			l_arm.rotation = Vector3(deg_to_rad(10), 0, deg_to_rad(-15))
			if l_elbow: l_elbow.rotation = Vector3(deg_to_rad(-20), 0, 0)
			l_leg.rotation = Vector3(0, 0, deg_to_rad(-4))
			r_leg.rotation = Vector3(0, 0, deg_to_rad(4))
			if rifle:
				rifle.position = Vector3(0.20, 1.38, 0.05)
				rifle.rotation = Vector3(deg_to_rad(-42), deg_to_rad(28), deg_to_rad(32))
