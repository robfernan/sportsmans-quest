class_name AudioSynth
extends RefCounted

## Procedurally synthesized sound effects for Sportsman's Quest.
## 100% procedural PCM (no external samples).
## Footsteps, fabric, rifle tails, and the wendigo screech are pooled:
## take_*() reuses a few takes, and playback varies pitch instead of
## rebuilding PCM on every step. Synthesis uses a private RNG so pools
## do not advance the global random stream used by wildlife.

const RATE := 22050

const _FOOT_TAKES := 4
const _FABRIC_TAKES := 3
const _REVERB_TAKES := 2
const _SCREECH_TAKES := 2
const _REVERB_DISTANCES: Array[float] = [10.0, 40.0, 80.0, 140.0]

static var _rng: RandomNumberGenerator
static var _foot_pools: Dictionary = {}
static var _fabric_pool: Array = []
static var _reverb_pools: Dictionary = {}
static var _screech_pool: Array = []

static func _rng_ref() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = 0x51A7C0DE
	return _rng

static func _rand() -> float:
	return _rng_ref().randf()

static func _rand_range(a: float, b: float) -> float:
	return _rng_ref().randf_range(a, b)

static func _pick(pool: Array) -> AudioStreamWAV:
	return pool[_rng_ref().randi_range(0, pool.size() - 1)]


static func _to_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clamp(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w

## Gunshot direct blast
static func gunshot(heavy := true) -> AudioStreamWAV:
	var n := int(RATE * (2.2 if heavy else 1.4))
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := _rand() * 2.0 - 1.0
		var crack := noise * exp(-t * 60.0)
		lp = lerp(lp, noise, 0.08)
		var boom := lp * exp(-t * 4.0) * 2.5
		lp2 = lerp(lp2, noise, 0.02)
		var echo := 0.0
		if t > 0.45:
			echo = lp2 * exp(-(t - 0.45) * 3.0) * 1.8
		s[i] = (crack * 0.9 + boom + echo) * 0.28
	return _to_wav(s)

## Gunshot environmental tail / acoustic reflection
static func gunshot_reverb(dist_to_water: float = 60.0, dist_to_ridge: float = 120.0) -> AudioStreamWAV:
	var duration: float = clamp(0.4 + (dist_to_ridge / 250.0) * 0.4, 0.4, 0.8)
	var n := int(RATE * duration)
	var s := PackedFloat32Array(); s.resize(n)
	var delay_sec: float = clamp((dist_to_water * 2.0) / 343.0, 0.05, 0.35)
	var delay_samples := int(delay_sec * RATE)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := _rand() * 2.0 - 1.0
		lp = lerp(lp, noise, 0.04) # Low-pass filtered rumble
		var env := exp(-t * 4.5)
		var reflection := 0.0
		if i >= delay_samples:
			reflection = lp * exp(-(t - delay_sec) * 6.0) * 0.7
		s[i] = (lp * env * 0.5 + reflection) * 0.22
	return _to_wav(s)

## Procedural wind loop modulated by altitude, canopy, and night
static func wind_ambient(altitude_m: float = 20.0, canopy_cover: float = 0.5, is_night: bool = false) -> AudioStreamWAV:
	var n := RATE * 5
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	# Higher altitude = faster wind cutoff; thick canopy = muffled low cutoff
	var cutoff_alpha: float = clamp(0.012 + (altitude_m / 60.0) * 0.015 - canopy_cover * 0.008, 0.006, 0.035)
	var base_gain: float = 0.65 + clamp(altitude_m / 40.0, 0.0, 0.35)
	if is_night:
		base_gain *= 0.85
		
	for i in n:
		var t := float(i) / n
		lp = lerp(lp, _rand() * 2.0 - 1.0, cutoff_alpha)
		var gust := 0.6 + 0.4 * sin(t * TAU * 2.0) * sin(t * TAU * 3.0)
		var fade: float = min(1.0, min(t, 1.0 - t) * 20.0)
		s[i] = lp * base_gain * gust * fade
	return _to_wav(s, true)

static func wind_loop() -> AudioStreamWAV:
	return wind_ambient(20.0, 0.4, false)

## Procedural Footstep synthesis with exact spectral variation per surface
static func footstep_surface(surface: int, stance_mult: float = 1.0) -> AudioStreamWAV:
	var dur := 0.08
	var n := int(RATE * dur)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var lp := 0.0
	
	match surface:
		0: # DRY_LEAVES: High-frequency crackle 3kHz - 8kHz
			for i in n:
				var t := float(i) / RATE
				var noise := _rand() * 2.0 - 1.0
				var crackle := noise if _rand() < 0.35 else 0.0
				var env := exp(-t * 55.0)
				s[i] = crackle * env * 0.30 * stance_mult
		1: # MUD: Low thud < 200 Hz
			for i in n:
				var t := float(i) / RATE
				var f: float = lerp(160.0, 55.0, t / dur)
				phase += TAU * f / RATE
				lp = lerp(lp, _rand() * 2.0 - 1.0, 0.08)
				var env := exp(-t * 40.0)
				s[i] = (sin(phase) * 0.7 + lp * 0.3) * env * 0.40 * stance_mult
		2: # TURF: Frosted grass/moss crunch
			for i in n:
				var t := float(i) / RATE
				lp = lerp(lp, _rand() * 2.0 - 1.0, 0.22)
				var env := exp(-t * 42.0)
				s[i] = lp * env * 0.28 * stance_mult
		3: # WATER: Shallow water splash with bandpass sweep 500Hz -> 2000Hz over 60ms
			for i in n:
				var t := float(i) / RATE
				var f: float = lerp(500.0, 2000.0, clamp(t / 0.06, 0.0, 1.0))
				phase += TAU * f / RATE
				lp = lerp(lp, _rand() * 2.0 - 1.0, 0.15)
				var env := exp(-t * 28.0)
				s[i] = (sin(phase) * 0.45 + lp * 0.55) * env * 0.32 * stance_mult
		_: # WOOD: Resonant ladder/stand thud
			for i in n:
				var t := float(i) / RATE
				var f: float = lerp(130.0, 70.0, t / dur)
				phase += TAU * f / RATE
				var env := exp(-t * 38.0)
				s[i] = sin(phase) * env * 0.38 * stance_mult
				
	return _to_wav(s)

## Subtle hunter crouch / clothing fabric shift (low-pass filtered noise burst at 400Hz)
static func fabric_shift() -> AudioStreamWAV:
	var n := int(RATE * 0.12)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerp(lp, _rand() * 2.0 - 1.0, 0.04) # ~400Hz lowpass filter
		var env := sin(clamp(t / 0.12, 0.0, 1.0) * PI)
		s[i] = lp * env * 0.18
	return _to_wav(s)

## Hunter breathing when aiming optics (0.3Hz sine-modulated soft breath)
static func hunter_breathing(heavy := false) -> AudioStreamWAV:
	var dur := 3.33 # ~0.3 Hz cycle
	var n := int(RATE * dur)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerp(lp, _rand() * 2.0 - 1.0, 0.06 if heavy else 0.03)
		# Inhale (first half) and Exhale (second half)
		var breath_mod: float = pow(sin(t * (TAU / dur)), 2.0)
		s[i] = lp * breath_mod * (0.16 if heavy else 0.08)
	return _to_wav(s, true)

## Ghost Buck mythical ethereal chime
static func ghost_chime() -> AudioStreamWAV:
	var n := int(RATE * 1.6)
	var s := PackedFloat32Array(); s.resize(n)
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	for i in n:
		var t := float(i) / RATE
		p1 += TAU * 880.0 / RATE
		p2 += TAU * 1320.0 / RATE
		p3 += TAU * 1760.0 / RATE
		var env := exp(-t * 2.2)
		var chime := sin(p1) * 0.5 + sin(p2) * 0.3 + sin(p3) * 0.2
		s[i] = chime * env * 0.16
	return _to_wav(s)

## Werewolf stalking howl
static func wolf_howl() -> AudioStreamWAV:
	var n := int(RATE * 2.8)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 240.0
		if t < 0.8:
			f = lerp(240.0, 480.0, t / 0.8)
		else:
			f = lerp(480.0, 180.0, (t - 0.8) / 2.0)
		var vibrato := sin(t * 30.0) * 15.0
		phase += TAU * (f + vibrato) / RATE
		var env := sin(clamp(t / 2.8, 0.0, 1.0) * PI)
		var tone := sin(phase) * 0.6 + sin(phase * 2.0) * 0.25
		s[i] = tone * env * 0.35
	return _to_wav(s)

## Wendigo descending screech/howl (400Hz -> 100Hz with vibrato)
static func wendigo_screech() -> AudioStreamWAV:
	var n := int(RATE * 1.5)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f: float = lerp(400.0, 100.0, t / 1.5)
		var vibrato := sin(t * 24.0) * 20.0
		phase += TAU * (f + vibrato) / RATE
		var saw := fmod(phase, 1.0) * 2.0 - 1.0
		lp = lerp(lp, _rand() * 2.0 - 1.0, 0.2)
		var env := exp(-t * 1.2) * sin(clamp(t / 1.5, 0.0, 1.0) * PI)
		s[i] = (saw * 0.6 + lp * 0.4) * env * 0.32
	return _to_wav(s)

static func bird_chirp() -> AudioStreamWAV:
	var n := int(RATE * 0.6)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var base := _rand_range(2500.0, 4200.0)
	for i in n:
		var t := float(i) / RATE
		var seg := fmod(t, 0.15)
		var f := base + 1200.0 * sin(seg * 40.0)
		phase += TAU * f / RATE
		var env: float = sin(clamp(seg / 0.12, 0.0, 1.0) * PI) if seg < 0.12 else 0.0
		s[i] = sin(phase) * env * 0.10
	return _to_wav(s)

static func grunt_call() -> AudioStreamWAV:
	var n := int(RATE * 0.9)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 110.0 - 30.0 * t
		phase += f / RATE
		var saw := fmod(phase, 1.0) * 2.0 - 1.0
		var env := sin(clamp(t / 0.9, 0.0, 1.0) * PI)
		s[i] = (saw * 0.5 + (_rand() - 0.5) * 0.2) * env * 0.28
	return _to_wav(s)

static func quack() -> AudioStreamWAV:
	var n := int(RATE * 0.8)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var seg := fmod(t, 0.27)
		var f := 520.0 - 400.0 * seg
		phase += f / RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.3 else -1.0
		var env: float = exp(-seg * 12.0) if seg < 0.22 else 0.0
		s[i] = sq * env * 0.14
	return _to_wav(s)

static func snort() -> AudioStreamWAV:
	var n := int(RATE * 0.5)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerp(lp, _rand() * 2.0 - 1.0, 0.3)
		s[i] = lp * exp(-t * 9.0) * 0.4
	return _to_wav(s)

static func paddle() -> AudioStreamWAV:
	var n := int(RATE * 0.7)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerp(lp, _rand() * 2.0 - 1.0, 0.12)
		s[i] = lp * sin(clamp(t / 0.7, 0.0, 1.0) * PI) * 0.35
	return _to_wav(s)

static func click() -> AudioStreamWAV:
	var n := int(RATE * 0.12)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (_rand() * 2.0 - 1.0) * exp(-t * 80.0) * 0.25
	return _to_wav(s)


## Hot path. Builds each surface a few times, then rotates those buffers.
static func warm_oneshot_cache() -> void:
	for surface in 5:
		_ensure_foot_pool(surface)
	_ensure_fabric_pool()
	for dist in _REVERB_DISTANCES:
		_ensure_reverb_pool(dist)
	_ensure_screech_pool()

static func take_footstep(surface: int) -> AudioStreamWAV:
	return _pick(_ensure_foot_pool(surface))

static func take_fabric() -> AudioStreamWAV:
	return _pick(_ensure_fabric_pool())

## Nearest prebuilt water distance. Ridge is fixed at the rifle's 120 m call.
static func take_gunshot_reverb(dist_to_water: float, _dist_to_ridge: float = 120.0) -> AudioStreamWAV:
	return _pick(_ensure_reverb_pool(_nearest_reverb_distance(dist_to_water)))

static func take_wendigo_screech() -> AudioStreamWAV:
	return _pick(_ensure_screech_pool())

static func vary_pitch(lo: float = 0.94, hi: float = 1.06) -> float:
	return _rand_range(lo, hi)

static func _ensure_foot_pool(surface: int) -> Array:
	if _foot_pools.has(surface):
		return _foot_pools[surface]
	var pool: Array = []
	for _i in _FOOT_TAKES:
		pool.append(footstep_surface(surface, 1.0))
	_foot_pools[surface] = pool
	return pool

static func _ensure_fabric_pool() -> Array:
	if not _fabric_pool.is_empty():
		return _fabric_pool
	for _i in _FABRIC_TAKES:
		_fabric_pool.append(fabric_shift())
	return _fabric_pool

static func _ensure_reverb_pool(dist_to_water: float) -> Array:
	if _reverb_pools.has(dist_to_water):
		return _reverb_pools[dist_to_water]
	var pool: Array = []
	for _i in _REVERB_TAKES:
		pool.append(gunshot_reverb(dist_to_water, 120.0))
	_reverb_pools[dist_to_water] = pool
	return pool

static func _ensure_screech_pool() -> Array:
	if not _screech_pool.is_empty():
		return _screech_pool
	for _i in _SCREECH_TAKES:
		_screech_pool.append(wendigo_screech())
	return _screech_pool

static func _nearest_reverb_distance(dist_to_water: float) -> float:
	var best := _REVERB_DISTANCES[0]
	var best_delta := absf(dist_to_water - best)
	for dist in _REVERB_DISTANCES:
		var delta := absf(dist_to_water - dist)
		if delta < best_delta:
			best = dist
			best_delta = delta
	return best

static func footstep_turf() -> AudioStreamWAV:
	return take_footstep(2)

static func footstep_water() -> AudioStreamWAV:
	return take_footstep(3)

static func footstep_wood() -> AudioStreamWAV:
	return take_footstep(4)
