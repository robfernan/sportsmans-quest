class_name AudioSynth
extends RefCounted

## Procedurally synthesized sound effects for Sportsman's Quest.
## 100% Procedural PCM (0 KB external files, zero licensing issues).
## Includes environmental wind, footstep surfaces, gun reverb, breathing, and cryptids.

const RATE := 22050

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
		var noise := randf() * 2.0 - 1.0
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
		var noise := randf() * 2.0 - 1.0
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
		lp = lerp(lp, randf() * 2.0 - 1.0, cutoff_alpha)
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
				var noise := randf() * 2.0 - 1.0
				var crackle := noise if randf() < 0.35 else 0.0
				var env := exp(-t * 55.0)
				s[i] = crackle * env * 0.30 * stance_mult
		1: # MUD: Low thud < 200 Hz
			for i in n:
				var t := float(i) / RATE
				var f: float = lerp(160.0, 55.0, t / dur)
				phase += TAU * f / RATE
				lp = lerp(lp, randf() * 2.0 - 1.0, 0.08)
				var env := exp(-t * 40.0)
				s[i] = (sin(phase) * 0.7 + lp * 0.3) * env * 0.40 * stance_mult
		2: # TURF: Frosted grass/moss crunch
			for i in n:
				var t := float(i) / RATE
				lp = lerp(lp, randf() * 2.0 - 1.0, 0.22)
				var env := exp(-t * 42.0)
				s[i] = lp * env * 0.28 * stance_mult
		3: # WATER: Shallow water splash with bandpass sweep 500Hz -> 2000Hz over 60ms
			for i in n:
				var t := float(i) / RATE
				var f: float = lerp(500.0, 2000.0, clamp(t / 0.06, 0.0, 1.0))
				phase += TAU * f / RATE
				lp = lerp(lp, randf() * 2.0 - 1.0, 0.15)
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
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.04) # ~400Hz lowpass filter
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
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.06 if heavy else 0.03)
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
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.2)
		var env := exp(-t * 1.2) * sin(clamp(t / 1.5, 0.0, 1.0) * PI)
		s[i] = (saw * 0.6 + lp * 0.4) * env * 0.32
	return _to_wav(s)

static func bird_chirp() -> AudioStreamWAV:
	var n := int(RATE * 0.6)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var base := randf_range(2500.0, 4200.0)
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
		s[i] = (saw * 0.5 + (randf() - 0.5) * 0.2) * env * 0.28
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
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.3)
		s[i] = lp * exp(-t * 9.0) * 0.4
	return _to_wav(s)

static func paddle() -> AudioStreamWAV:
	var n := int(RATE * 0.7)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.12)
		s[i] = lp * sin(clamp(t / 0.7, 0.0, 1.0) * PI) * 0.35
	return _to_wav(s)

static func click() -> AudioStreamWAV:
	var n := int(RATE * 0.12)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (randf() * 2.0 - 1.0) * exp(-t * 80.0) * 0.25
	return _to_wav(s)

static func footstep_turf() -> AudioStreamWAV:
	return footstep_surface(2, 1.0)

static func footstep_water() -> AudioStreamWAV:
	return footstep_surface(3, 1.0)

static func footstep_wood() -> AudioStreamWAV:
	return footstep_surface(4, 1.0)
