extends Node

# === MUSIC SYSTEM ===
var music_player: AudioStreamPlayer
const MIX_RATE = 22050
const BPM = 68.0
var beat_dur = 60.0 / BPM

# Oscillator phases
var drone_ph1 = 0.0
var drone_ph2 = 0.0
var pad_ph = [0.0, 0.0, 0.0]
var arp_ph = 0.0
var sparkle_ph = 0.0

# Music state
var pad_freqs = [110.0, 130.81, 164.81]  # Am chord
var arp_notes = [220.0, 261.63, 329.63, 392.0, 440.0, 329.63, 261.63, 196.0]
var arp_idx = 0
var arp_freq = 220.0
var arp_env = 0.0
var sparkle_freq = 880.0
var sparkle_env = 0.0
var sparkle_timer = 0.0
var music_time = 0.0
var music_volume = 1.0
var battle_mode = false

# === SFX SYSTEM ===
var sfx_pool = []
var sfx_streams = {}
const SFX_POOL_SIZE = 8
const SFX_RATE = 22050


func _ready():
	_init_music()
	_init_sfx()


func _process(delta):
	if not music_player.playing:
		return
	_update_music_state(delta)
	_fill_music_buffer()


# ── Music Init ──

func _init_music():
	music_player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.25
	music_player.stream = gen
	music_player.volume_db = -8.0
	music_player.bus = "Master"
	add_child(music_player)
	music_player.play()


func _update_music_state(delta):
	music_time += delta

	# Arpeggio timing
	var step = beat_dur * (0.5 if battle_mode else 0.75)
	var beat_pos = fmod(music_time, step * arp_notes.size())
	var new_idx = int(beat_pos / step) % arp_notes.size()
	if new_idx != arp_idx:
		arp_idx = new_idx
		arp_freq = arp_notes[arp_idx]
		arp_env = 0.25 if battle_mode else 0.15

	# Arpeggio decay
	arp_env = max(arp_env - delta * (0.6 if battle_mode else 0.4), 0.0)

	# Sparkle (random high notes)
	sparkle_timer -= delta
	if sparkle_timer <= 0:
		sparkle_timer = randf_range(1.5, 4.0)
		var sparkle_notes = [523.25, 659.26, 783.99, 880.0, 1046.5, 1318.5]
		sparkle_freq = sparkle_notes[randi() % sparkle_notes.size()]
		sparkle_env = randf_range(0.05, 0.12)
	sparkle_env = max(sparkle_env - delta * 0.3, 0.0)


func _fill_music_buffer():
	var playback = music_player.get_stream_playback()
	if not playback:
		return
	var frames = playback.get_frames_available()
	if frames <= 0:
		return
	for i in frames:
		var s = _gen_sample()
		playback.push_frame(Vector2(s, s))


func _gen_sample() -> float:
	var s = 0.0
	var inv = 1.0 / MIX_RATE

	# Sub drone 55Hz
	drone_ph1 = fmod(drone_ph1 + 55.0 * inv, 1.0)
	s += sin(drone_ph1 * TAU) * 0.07

	# Fifth drone 82Hz
	drone_ph2 = fmod(drone_ph2 + 82.41 * inv, 1.0)
	s += sin(drone_ph2 * TAU) * 0.05

	# Pad chord (Am)
	for j in 3:
		pad_ph[j] = fmod(pad_ph[j] + pad_freqs[j] * inv, 1.0)
		# Slow tremolo per voice
		var trem = 0.5 + 0.5 * sin(music_time * (0.3 + j * 0.17) + j * 2.0)
		s += sin(pad_ph[j] * TAU) * 0.035 * trem

	# Arpeggio
	arp_ph = fmod(arp_ph + arp_freq * inv, 1.0)
	# Triangle wave for softer sound
	var arp_wave = 2.0 * abs(2.0 * arp_ph - 1.0) - 1.0
	s += arp_wave * 0.04 * arp_env

	# Sparkle
	sparkle_ph = fmod(sparkle_ph + sparkle_freq * inv, 1.0)
	s += sin(sparkle_ph * TAU) * sparkle_env * 0.5

	return clampf(s * music_volume, -0.95, 0.95)


func set_battle_mode(enabled: bool):
	battle_mode = enabled
	if enabled:
		music_volume = 1.2
	else:
		music_volume = 1.0


func set_music_volume(vol: float):
	# vol: 0.0 - 1.0
	if vol <= 0.01:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = lerpf(-30.0, -2.0, vol)


func set_sfx_volume(vol: float):
	# vol: 0.0 - 1.0
	var db = -80.0
	if vol > 0.01:
		db = lerpf(-30.0, 0.0, vol)
	for p in sfx_pool:
		p.volume_db = db


# ── SFX System ──

func _init_sfx():
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.volume_db = -4.0
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

	sfx_streams["hit"] = _gen_hit()
	sfx_streams["fire"] = _gen_fire()
	sfx_streams["ice"] = _gen_ice()
	sfx_streams["arcane"] = _gen_arcane()
	sfx_streams["orb"] = _gen_orb()
	sfx_streams["dodge"] = _gen_dodge()
	sfx_streams["select"] = _gen_select()
	sfx_streams["win"] = _gen_win()
	sfx_streams["death"] = _gen_death()
	sfx_streams["defend"] = _gen_defend()
	sfx_streams["melee"] = _gen_melee()
	sfx_streams["confirm_power"] = _gen_confirm_power()
	sfx_streams["stage_clear"] = _gen_stage_clear()
	sfx_streams["campaign_win"] = _gen_campaign_win()


func play_sfx(sfx_name: String):
	var stream = sfx_streams.get(sfx_name)
	if not stream:
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All busy - steal first
	sfx_pool[0].stop()
	sfx_pool[0].stream = stream
	sfx_pool[0].play()


# ── SFX Generators ──

func _samples_to_wav(samples: Array, rate: int = SFX_RATE) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var val = clampf(samples[i], -1.0, 1.0)
		var int_val = int(val * 32767.0)
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
	wav.data = data
	return wav


func _gen_hit() -> AudioStreamWAV:
	var samples = []
	var dur = 0.12
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur)
		var noise = randf_range(-1.0, 1.0)
		var tone = sin(t * 180.0 * TAU) * 0.3
		samples.append((noise * 0.6 + tone) * env * 0.7)
	return _samples_to_wav(samples)


func _gen_melee() -> AudioStreamWAV:
	var samples = []
	var dur = 0.15
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var sweep = sin(t * (300.0 + t * 800.0) * TAU) * 0.4
		var noise = randf_range(-1.0, 1.0) * 0.3
		samples.append((sweep + noise) * env * 0.5)
	return _samples_to_wav(samples)


func _gen_fire() -> AudioStreamWAV:
	var samples = []
	var dur = 0.3
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = sin(t / dur * PI) * (1.0 - t / dur)
		var freq = 200.0 + t * 600.0
		var wave = sin(t * freq * TAU) * 0.5
		var noise = randf_range(-1.0, 1.0) * 0.3 * (1.0 - t / dur)
		samples.append((wave + noise) * env * 0.6)
	return _samples_to_wav(samples)


func _gen_ice() -> AudioStreamWAV:
	var samples = []
	var dur = 0.25
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur)
		var high = sin(t * 1200.0 * TAU) * 0.3
		var mid = sin(t * 600.0 * TAU) * 0.2
		var shimmer = sin(t * 2400.0 * TAU) * 0.1 * sin(t * 15.0 * TAU)
		samples.append((high + mid + shimmer) * env * 0.6)
	return _samples_to_wav(samples)


func _gen_arcane() -> AudioStreamWAV:
	var samples = []
	var dur = 0.45
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = sin(t / dur * PI * 0.5) * (1.0 - t / dur)
		var boom = sin(t * 60.0 * TAU) * 0.5 * max(0.0, 1.0 - t * 5.0)
		var sweep = sin(t * (400.0 + t * 300.0) * TAU) * 0.3
		var sparkle = sin(t * 1500.0 * TAU) * 0.15 * max(0.0, t / dur - 0.3)
		samples.append((boom + sweep + sparkle) * env * 0.7)
	return _samples_to_wav(samples)


func _gen_orb() -> AudioStreamWAV:
	var samples = []
	var dur = 0.1
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var chime = sin(t * 880.0 * TAU) * 0.4 + sin(t * 1320.0 * TAU) * 0.2
		samples.append(chime * env * 0.5)
	return _samples_to_wav(samples)


func _gen_dodge() -> AudioStreamWAV:
	var samples = []
	var dur = 0.1
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var sweep = sin(t * (600.0 - t * 2000.0) * TAU) * 0.4
		var noise = randf_range(-1.0, 1.0) * 0.2
		samples.append((sweep + noise) * env * 0.4)
	return _samples_to_wav(samples)


func _gen_select() -> AudioStreamWAV:
	var samples = []
	var dur = 0.08
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var tone = sin(t * 660.0 * TAU) * 0.5
		samples.append(tone * env * 0.4)
	return _samples_to_wav(samples)


func _gen_win() -> AudioStreamWAV:
	var samples = []
	var dur = 0.6
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		# Major chord arpeggio: C E G C'
		var note = 0.0
		if t < 0.15:
			note = 523.25
		elif t < 0.3:
			note = 659.26
		elif t < 0.45:
			note = 783.99
		else:
			note = 1046.5
		var tone = sin(t * note * TAU) * 0.4
		samples.append(tone * env * 0.5)
	return _samples_to_wav(samples)


func _gen_death() -> AudioStreamWAV:
	var samples = []
	var dur = 0.4
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var freq = 300.0 - t * 500.0
		var tone = sin(t * max(freq, 50.0) * TAU) * 0.5
		var noise = randf_range(-1.0, 1.0) * 0.15
		samples.append((tone + noise) * env * 0.6)
	return _samples_to_wav(samples)


func _gen_defend() -> AudioStreamWAV:
	var samples = []
	var dur = 0.08
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur)
		var tone = sin(t * 440.0 * TAU) * 0.3 + sin(t * 550.0 * TAU) * 0.2
		samples.append(tone * env * 0.35)
	return _samples_to_wav(samples)


func _gen_confirm_power() -> AudioStreamWAV:
	# Impacto grave + brillo ascendente
	var samples = []
	var dur = 0.4
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur)
		# Impacto grave
		var bass = sin(t * 80.0 * TAU) * 0.5 * maxf(0, 1.0 - t * 8.0)
		# Brillo ascendente
		var sweep_freq = 200.0 + t * 1200.0
		var sweep = sin(t * sweep_freq * TAU) * 0.3 * env
		# Shimmer
		var shimmer = sin(t * 1500.0 * TAU) * 0.1 * env * t * 3.0
		samples.append((bass + sweep + shimmer) * 0.6)
	return _samples_to_wav(samples)


func _gen_stage_clear() -> AudioStreamWAV:
	# Fanfarria corta ascendente
	var samples = []
	var dur = 0.6
	var n = int(SFX_RATE * dur)
	var notes = [261.63, 329.63, 392.0, 523.25]  # C E G C
	for i in n:
		var t = float(i) / SFX_RATE
		var note_idx = mini(int(t / dur * 4.0), 3)
		var note_t = fmod(t, dur / 4.0) / (dur / 4.0)
		var env = (1.0 - note_t * 0.6)
		var tone = sin(t * notes[note_idx] * TAU) * 0.3
		var harm = sin(t * notes[note_idx] * 2.0 * TAU) * 0.15
		samples.append((tone + harm) * env * 0.5)
	return _samples_to_wav(samples)


func _gen_campaign_win() -> AudioStreamWAV:
	# Fanfarria epica - acorde mayor con barrido
	var samples = []
	var dur = 1.0
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = minf(t * 5.0, 1.0) * maxf(0, 1.0 - (t - 0.7) * 3.33)
		# Acorde C major
		var c = sin(t * 261.63 * TAU) * 0.2
		var e = sin(t * 329.63 * TAU) * 0.15
		var g = sin(t * 392.0 * TAU) * 0.15
		var c2 = sin(t * 523.25 * TAU) * 0.1
		# Brillo
		var shimmer = sin(t * 1046.5 * TAU) * 0.05 * sin(t * 8.0)
		samples.append((c + e + g + c2 + shimmer) * env * 0.7)
	return _samples_to_wav(samples)
