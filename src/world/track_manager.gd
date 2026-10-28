class_name TrackManager
extends Node3D

## Footprints and blood drops left by animals (pooled MultiMeshes), plus a clue reader
## similar to theHunter's Huntermate: look at the ground near a track to identify it.

const MAX_TRACKS := 600
const MAX_BLOOD := 300

var terrain: Terrain
var tracks: Array = []      # [{pos, yaw, species, gait, time, animal}]
var blood: Array = []       # [{pos, organ, time}]
var _track_mm: MultiMesh
var _blood_mm: MultiMesh
var _track_i := 0
var _blood_i := 0

func setup(t: Terrain) -> void:
	terrain = t
	_track_mm = _make_mm(Vector2(0.09, 0.13), Color(0.12, 0.09, 0.06, 0.85), MAX_TRACKS)
	_blood_mm = _make_mm(Vector2(0.12, 0.12), Color(0.45, 0.02, 0.02, 0.95), MAX_BLOOD)

func _make_mm(size: Vector2, color: Color, count: int) -> MultiMesh:
	var q := QuadMesh.new()
	q.size = size
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	mm.instance_count = count
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm

func _ground_xf(pos: Vector3, yaw: float, offset := 0.0) -> Transform3D:
	var p := pos + Vector3(cos(yaw), 0, -sin(yaw)) * offset
	p.y = terrain.height_at(p.x, p.z) + 0.03
	var n := terrain.normal_at(p.x, p.z)
	var b := Basis(Vector3.UP, yaw)
	var axis := Vector3.UP.cross(n)
	if axis.length() > 0.001:
		b = Basis(axis.normalized(), Vector3.UP.angle_to(n)) * b
	return Transform3D(b, p)

func add_track(pos: Vector3, yaw: float, species: String, gait: String, animal: Node) -> void:
	if pos.y < Terrain.WATER_LEVEL + 0.05:
		return
	for side in [-0.12, 0.12]:
		_track_mm.set_instance_transform(_track_i, _ground_xf(pos, yaw, side))
		_track_i = (_track_i + 1) % MAX_TRACKS
	_track_mm.visible_instance_count = max(_track_mm.visible_instance_count, min(_track_i if _track_i > 0 else MAX_TRACKS, MAX_TRACKS))
	tracks.append({"pos": pos, "yaw": yaw, "species": species, "gait": gait, "time": Time.get_ticks_msec(), "animal": animal})
	if tracks.size() > int(MAX_TRACKS / 2.0):
		tracks.pop_front()

func add_blood(pos: Vector3, organ: String) -> void:
	var p := pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	_blood_mm.set_instance_transform(_blood_i, _ground_xf(p, randf() * TAU))
	_blood_i = (_blood_i + 1) % MAX_BLOOD
	_blood_mm.visible_instance_count = max(_blood_mm.visible_instance_count, min(_blood_i if _blood_i > 0 else MAX_BLOOD, MAX_BLOOD))
	blood.append({"pos": p, "organ": organ, "time": Time.get_ticks_msec()})
	if blood.size() > MAX_BLOOD:
		blood.pop_front()

## Returns a clue description for the nearest sign within radius, or "".
func read_clue(at: Vector3, radius: float) -> String:
	var best := ""
	var best_d := radius
	var now := Time.get_ticks_msec()
	for b in blood:
		var d: float = at.distance_to(b.pos)
		if d < best_d:
			best_d = d
			var kind := "Bright, frothy blood (LUNG hit)"
			match b.organ:
				"Heart": kind = "Heavy bright-red spray (HEART hit)"
				"Liver": kind = "Dark red blood (LIVER hit)"
				"Stomach": kind = "Blood with stomach matter (GUT shot)"
				"Flesh": kind = "Sparse drops (MUSCLE wound)"
			best = "BLOOD: %s  -  %s old" % [kind, _age(now - b.time)]
	for t in tracks:
		var d: float = at.distance_to(t.pos)
		if d < best_d:
			best_d = d
			best = "TRACK: %s  -  %s, heading %s  -  %s old" % [t.species, t.gait, _heading(t.yaw), _age(now - t.time)]
	return best

func _age(ms: int) -> String:
	var s: int = int(ms / 1000.0)
	return "%d s" % s if s < 60 else "%d min" % int(s / 60.0)

func _heading(yaw: float) -> String:
	var deg := fposmod(rad_to_deg(-yaw), 360.0)
	var names := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	return names[int(round(deg / 45.0)) % 8]
