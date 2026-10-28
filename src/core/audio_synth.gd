class_name AudioSynth
extends RefCounted

## Procedurally synthesized sound effects (no external audio files required, 100% original).

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

static func wind_loop() -> AudioStreamWAV:
	var n := RATE * 6
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.015)
		var gust := 0.6 + 0.4 * sin(t * TAU * 2.0) * sin(t * TAU * 3.0)
		var fade: float = min(1.0, min(t, 1.0 - t) * 20.0)
		s[i] = lp * 0.8 * gust * fade
	return _to_wav(s, true)

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
	# Subtle, deep turf/moss footsteps crunch
	var n := int(RATE * 0.18)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := randf() * 2.0 - 1.0
		lp = lerp(lp, noise, 0.25)
		var env := exp(-t * 35.0) * sin(clamp(t / 0.18, 0.0, 1.0) * PI)
		s[i] = lp * env * 0.22
	return _to_wav(s)

static func footstep_water() -> AudioStreamWAV:
	# Shallow water splash step
	var n := int(RATE * 0.26)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f: float = lerp(600.0, 180.0, t / 0.26)
		phase += TAU * f / RATE
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.15)
		var env := exp(-t * 22.0)
		s[i] = (sin(phase) * 0.4 + lp * 0.6) * env * 0.25
	return _to_wav(s)

static func footstep_wood() -> AudioStreamWAV:
	# Hollow resonant dock/ladder thud
	var n := int(RATE * 0.16)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f: float = lerp(140.0, 70.0, t / 0.16)
		phase += TAU * f / RATE
		var env := exp(-t * 40.0)
		s[i] = sin(phase) * env * 0.35
	return _to_wav(s)

static func wolf_howl() -> AudioStreamWAV:
	var n := int(RATE * 2.8)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		# Pitch trajectory: rises from 240Hz to 480Hz then descends to 180Hz
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

static func wendigo_screech() -> AudioStreamWAV:
	var n := int(RATE * 1.8)
	var s := PackedFloat32Array(); s.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		# Harsh descending frequency modulation with chaotic jitter
		var f: float = lerp(1200.0, 320.0, t / 1.8) + (randf() * 180.0 - 90.0)
		phase += TAU * f / RATE
		var saw := fmod(phase, 1.0) * 2.0 - 1.0
		lp = lerp(lp, randf() * 2.0 - 1.0, 0.4)
		var env := exp(-t * 1.5) * sin(clamp(t / 1.8, 0.0, 1.0) * PI)
		s[i] = (saw * 0.5 + lp * 0.5) * env * 0.32
	return _to_wav(s)
