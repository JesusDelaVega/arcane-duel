extends Node

# === MUSIC SYSTEM - Astral / Tech / Mythological ===
var music_player: AudioStreamPlayer
const MIX_RATE = 44100
const BPM = 72.0
var beat_dur = 60.0 / BPM

# Oscillator phases
var drone_ph1 = 0.0
var drone_ph2 = 0.0
var drone_ph3 = 0.0
var pad_ph = [0.0, 0.0, 0.0, 0.0]
var pad_ph2 = [0.0, 0.0, 0.0, 0.0]
var arp_ph = 0.0
var arp_ph2 = 0.0
var sparkle_ph = 0.0
var pulse_ph = 0.0
var atmo_ph = 0.0

# Chord progressions (mystical/modal)
var menu_chords = [
	[220.0, 261.63, 329.63],   # Am
	[174.61, 220.0, 261.63],   # Fmaj
	[146.83, 174.61, 220.0],   # Dm
	[164.81, 196.0, 246.94],   # Em
]
var menu_bass = [55.0, 43.65, 36.71, 41.20]

var battle_chords = [
	[220.0, 261.63, 329.63],   # Am
	[146.83, 174.61, 220.0],   # Dm
	[164.81, 207.65, 246.94],  # E (tension)
	[220.0, 277.18, 329.63],   # Am(b9) dark
]
var battle_bass = [55.0, 36.71, 41.20, 55.0]

# Arp patterns (pentatonic minor - mythological feel)
var menu_arp = [440.0, 523.25, 659.26, 783.99, 659.26, 523.25, 440.0, 329.63]
var battle_arp = [440.0, 523.25, 587.33, 659.26, 783.99, 880.0, 783.99, 659.26,
				  587.33, 523.25, 440.0, 523.25, 659.26, 783.99, 523.25, 440.0]

# Music state
var chord_idx = 0
var chord_timer = 0.0
var cur_pad_freqs = [220.0, 261.63, 329.63]
var target_pad_freqs = [220.0, 261.63, 329.63]
var cur_bass_freq = 55.0
var target_bass_freq = 55.0

var arp_idx = 0
var arp_freq = 440.0
var arp_env = 0.0
var arp_echo_env = 0.0
var arp_echo_freq = 440.0

var sparkle_freq = 880.0
var sparkle_env = 0.0
var sparkle_timer = 0.0

var atmo_freq = 1760.0
var atmo_env = 0.0
var atmo_timer = 2.0

var music_time = 0.0
var music_volume = 0.8
var battle_mode = false

# === SFX SYSTEM ===
var sfx_pool = []
var sfx_streams = {}
const SFX_POOL_SIZE = 8
const SFX_RATE = 44100


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
	music_player.volume_db = -12.0
	music_player.bus = "Master"
	add_child(music_player)
	music_player.play()


func _update_music_state(delta):
	music_time += delta

	# Chord progression - change every 4 beats
	chord_timer += delta
	var chord_len = beat_dur * 4.0
	if chord_timer >= chord_len:
		chord_timer -= chord_len
		var chords = battle_chords if battle_mode else menu_chords
		var basses = battle_bass if battle_mode else menu_bass
		chord_idx = (chord_idx + 1) % chords.size()
		target_pad_freqs = chords[chord_idx].duplicate()
		target_bass_freq = basses[chord_idx]

	# Smooth chord transitions (glide)
	for j in 3:
		cur_pad_freqs[j] = lerpf(cur_pad_freqs[j], target_pad_freqs[j], delta * 3.0)
	cur_bass_freq = lerpf(cur_bass_freq, target_bass_freq, delta * 3.0)

	# Arpeggio timing
	var arp_pattern = battle_arp if battle_mode else menu_arp
	var step = beat_dur * (0.25 if battle_mode else 0.5)
	var beat_pos = fmod(music_time, step * arp_pattern.size())
	var new_idx = int(beat_pos / step) % arp_pattern.size()
	if new_idx != arp_idx:
		# Echo: save old note before changing
		arp_echo_freq = arp_freq
		arp_echo_env = arp_env * 0.4
		arp_idx = new_idx
		arp_freq = arp_pattern[arp_idx]
		arp_env = 0.2 if battle_mode else 0.14

	# Arpeggio decay
	arp_env = maxf(arp_env - delta * (0.8 if battle_mode else 0.5), 0.0)
	arp_echo_env = maxf(arp_echo_env - delta * 0.6, 0.0)

	# Sparkle (astral chimes - pentatonic high)
	sparkle_timer -= delta
	if sparkle_timer <= 0:
		sparkle_timer = randf_range(1.2, 3.5) if battle_mode else randf_range(2.0, 5.0)
		var sparkle_notes = [880.0, 1046.5, 1174.66, 1318.5, 1567.98, 1760.0]
		sparkle_freq = sparkle_notes[randi() % sparkle_notes.size()]
		sparkle_env = randf_range(0.04, 0.09)
	sparkle_env = maxf(sparkle_env - delta * 0.25, 0.0)

	# Atmospheric whispers (very high, ethereal)
	atmo_timer -= delta
	if atmo_timer <= 0:
		atmo_timer = randf_range(3.0, 8.0)
		var atmo_notes = [1760.0, 2093.0, 2349.32, 2637.02, 3135.96]
		atmo_freq = atmo_notes[randi() % atmo_notes.size()]
		atmo_env = randf_range(0.02, 0.04)
	atmo_env = maxf(atmo_env - delta * 0.08, 0.0)


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

	# === Layer 1: Deep sub bass drone (follows chord root) ===
	drone_ph1 = fmod(drone_ph1 + cur_bass_freq * inv, 1.0)
	s += sin(drone_ph1 * TAU) * 0.06

	# Sub-octave for depth
	drone_ph2 = fmod(drone_ph2 + cur_bass_freq * 0.5 * inv, 1.0)
	s += sin(drone_ph2 * TAU) * 0.04

	# Fifth drone (mystical interval) - slowly detuned
	var fifth_freq = cur_bass_freq * 1.498  # slightly flat fifth = tension
	drone_ph3 = fmod(drone_ph3 + fifth_freq * inv, 1.0)
	s += sin(drone_ph3 * TAU) * 0.025

	# === Layer 2: Ethereal pad (chord tones + detuned copy) ===
	for j in 3:
		var f = cur_pad_freqs[j]
		# Main voice
		pad_ph[j] = fmod(pad_ph[j] + f * inv, 1.0)
		var trem = 0.55 + 0.45 * sin(music_time * (0.2 + j * 0.13) + j * 1.7)
		s += sin(pad_ph[j] * TAU) * 0.03 * trem

		# Detuned copy (width/shimmer) - slightly sharp
		var f2 = f * 1.003 + sin(music_time * 0.1) * 0.5
		pad_ph2[j] = fmod(pad_ph2[j] + f2 * inv, 1.0)
		s += sin(pad_ph2[j] * TAU) * 0.02 * trem

	# === Layer 3: Arpeggio (pentatonic, tech pulse) ===
	arp_ph = fmod(arp_ph + arp_freq * inv, 1.0)
	# Soft sine with gentle harmonic
	var arp_tone = sin(arp_ph * TAU) * 0.8 + sin(arp_ph * TAU * 2.0) * 0.15
	s += arp_tone * 0.035 * arp_env

	# Echo/delay of previous note (spacious feel)
	arp_ph2 = fmod(arp_ph2 + arp_echo_freq * inv, 1.0)
	s += sin(arp_ph2 * TAU) * 0.025 * arp_echo_env

	# === Layer 4: Rhythmic pulse (battle only - tech feel) ===
	if battle_mode:
		var beat_pos = fmod(music_time, beat_dur)
		var pulse_env = maxf(0.0, 1.0 - beat_pos / (beat_dur * 0.3))
		pulse_env = pulse_env * pulse_env
		pulse_ph = fmod(pulse_ph + 45.0 * inv, 1.0)
		s += sin(pulse_ph * TAU) * pulse_env * 0.04

	# === Layer 5: Astral sparkles (high pentatonic chimes) ===
	sparkle_ph = fmod(sparkle_ph + sparkle_freq * inv, 1.0)
	s += sin(sparkle_ph * TAU) * sparkle_env * 0.25

	# === Layer 6: Atmospheric whisper (ultra high, barely audible) ===
	atmo_ph = fmod(atmo_ph + atmo_freq * inv, 1.0)
	var atmo_wave = sin(atmo_ph * TAU) * 0.6 + sin(atmo_ph * TAU * 3.0) * 0.3
	s += atmo_wave * atmo_env * sin(music_time * 0.5 + 0.7) * 0.15

	# Soft clip
	s = s * music_volume
	return tanh(s * 1.4) * 0.65


func set_battle_mode(enabled: bool):
	battle_mode = enabled
	chord_idx = 0
	chord_timer = 0.0
	if enabled:
		music_volume = 0.95
		cur_pad_freqs = battle_chords[0].duplicate()
		target_pad_freqs = battle_chords[0].duplicate()
		cur_bass_freq = battle_bass[0]
		target_bass_freq = battle_bass[0]
	else:
		music_volume = 0.8
		cur_pad_freqs = menu_chords[0].duplicate()
		target_pad_freqs = menu_chords[0].duplicate()
		cur_bass_freq = menu_bass[0]
		target_bass_freq = menu_bass[0]


func set_music_volume(vol: float):
	if vol <= 0.01:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = lerpf(-36.0, -8.0, vol)


func set_sfx_volume(vol: float):
	var db = -80.0
	if vol > 0.01:
		db = lerpf(-36.0, -8.0, vol)
	for p in sfx_pool:
		p.volume_db = db


# ── SFX System ──

func _init_sfx():
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.volume_db = -10.0
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
		var int_val = int(val * 32000.0)
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
	wav.data = data
	return wav


func _fade_env(t: float, dur: float, fade_in: float = 0.005, fade_out: float = 0.01) -> float:
	var env = 1.0
	if t < fade_in:
		env = t / fade_in
	elif t > dur - fade_out:
		env = maxf(0.0, (dur - t) / fade_out)
	return env


func _gen_hit() -> AudioStreamWAV:
	var samples = []
	var dur = 0.12
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur) * _fade_env(t, dur)
		var noise = sin(t * 3500.0 + sin(t * 800.0) * 2.0) * 0.3
		var tone = sin(t * 180.0 * TAU) * 0.25
		samples.append((noise + tone) * env * 0.5)
	return _samples_to_wav(samples)


func _gen_melee() -> AudioStreamWAV:
	var samples = []
	var dur = 0.14
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur)
		var sweep_freq = 250.0 + t * 600.0
		var sweep = sin(t * sweep_freq * TAU) * 0.35
		var noise = sin(t * 2200.0 + sin(t * 400.0) * 3.0) * 0.15
		samples.append((sweep + noise) * env * 0.4)
	return _samples_to_wav(samples)


func _gen_fire() -> AudioStreamWAV:
	var samples = []
	var dur = 0.28
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = sin(t / dur * PI) * (1.0 - t / dur) * _fade_env(t, dur)
		var freq = 180.0 + t * 400.0
		var wave = sin(t * freq * TAU) * 0.4
		var noise = sin(t * 1500.0 + sin(t * 300.0) * 4.0) * 0.2 * (1.0 - t / dur)
		samples.append((wave + noise) * env * 0.4)
	return _samples_to_wav(samples)


func _gen_ice() -> AudioStreamWAV:
	var samples = []
	var dur = 0.22
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur) * _fade_env(t, dur)
		var high = sin(t * 1200.0 * TAU) * 0.2
		var mid = sin(t * 600.0 * TAU) * 0.15
		var shimmer = sin(t * 2400.0 * TAU) * 0.08 * sin(t * 12.0 * TAU)
		samples.append((high + mid + shimmer) * env * 0.4)
	return _samples_to_wav(samples)


func _gen_arcane() -> AudioStreamWAV:
	var samples = []
	var dur = 0.4
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = sin(t / dur * PI * 0.5) * (1.0 - t / dur) * _fade_env(t, dur)
		var bass = sin(t * 60.0 * TAU) * 0.3 * maxf(0.0, 1.0 - t * 6.0)
		var sweep = sin(t * (350.0 + t * 250.0) * TAU) * 0.2
		var sparkle = sin(t * 1200.0 * TAU) * 0.1 * maxf(0.0, t / dur - 0.3)
		samples.append((bass + sweep + sparkle) * env * 0.5)
	return _samples_to_wav(samples)


func _gen_orb() -> AudioStreamWAV:
	var samples = []
	var dur = 0.1
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur)
		var chime = sin(t * 880.0 * TAU) * 0.3 + sin(t * 1320.0 * TAU) * 0.15
		samples.append(chime * env * 0.35)
	return _samples_to_wav(samples)


func _gen_dodge() -> AudioStreamWAV:
	var samples = []
	var dur = 0.09
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur)
		var sweep = sin(t * (500.0 - t * 1500.0) * TAU) * 0.3
		samples.append(sweep * env * 0.3)
	return _samples_to_wav(samples)


func _gen_select() -> AudioStreamWAV:
	var samples = []
	var dur = 0.07
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur, 0.003, 0.008)
		var tone = sin(t * 660.0 * TAU) * 0.35
		samples.append(tone * env * 0.3)
	return _samples_to_wav(samples)


func _gen_win() -> AudioStreamWAV:
	var samples = []
	var dur = 0.6
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur)
		var note = 523.25
		if t < 0.15:
			note = 523.25
		elif t < 0.3:
			note = 659.26
		elif t < 0.45:
			note = 783.99
		else:
			note = 1046.5
		var tone = sin(t * note * TAU) * 0.3
		var harm = sin(t * note * 2.0 * TAU) * 0.08
		samples.append((tone + harm) * env * 0.35)
	return _samples_to_wav(samples)


func _gen_death() -> AudioStreamWAV:
	var samples = []
	var dur = 0.35
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur)
		var freq = 280.0 - t * 400.0
		var tone = sin(t * maxf(freq, 60.0) * TAU) * 0.35
		var noise = sin(t * 800.0 + sin(t * 200.0) * 3.0) * 0.1
		samples.append((tone + noise) * env * 0.4)
	return _samples_to_wav(samples)


func _gen_defend() -> AudioStreamWAV:
	var samples = []
	var dur = 0.07
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * _fade_env(t, dur, 0.003, 0.008)
		var tone = sin(t * 440.0 * TAU) * 0.25 + sin(t * 550.0 * TAU) * 0.15
		samples.append(tone * env * 0.3)
	return _samples_to_wav(samples)


func _gen_confirm_power() -> AudioStreamWAV:
	var samples = []
	var dur = 0.35
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur) * _fade_env(t, dur)
		var bass = sin(t * 80.0 * TAU) * 0.3 * maxf(0.0, 1.0 - t * 6.0)
		var sweep_freq = 180.0 + t * 800.0
		var sweep = sin(t * sweep_freq * TAU) * 0.2 * env
		var shimmer = sin(t * 1200.0 * TAU) * 0.06 * env * t * 3.0
		samples.append((bass + sweep + shimmer) * 0.4)
	return _samples_to_wav(samples)


func _gen_stage_clear() -> AudioStreamWAV:
	var samples = []
	var dur = 0.55
	var n = int(SFX_RATE * dur)
	var notes = [261.63, 329.63, 392.0, 523.25]
	for i in n:
		var t = float(i) / SFX_RATE
		var fade = _fade_env(t, dur)
		var note_idx = mini(int(t / dur * 4.0), 3)
		var note_t = fmod(t, dur / 4.0) / (dur / 4.0)
		var env = (1.0 - note_t * 0.5) * fade
		var tone = sin(t * notes[note_idx] * TAU) * 0.25
		var harm = sin(t * notes[note_idx] * 2.0 * TAU) * 0.08
		samples.append((tone + harm) * env * 0.35)
	return _samples_to_wav(samples)


func _gen_campaign_win() -> AudioStreamWAV:
	var samples = []
	var dur = 0.9
	var n = int(SFX_RATE * dur)
	for i in n:
		var t = float(i) / SFX_RATE
		var env = minf(t * 4.0, 1.0) * maxf(0.0, 1.0 - (t - 0.6) * 3.33)
		env *= _fade_env(t, dur)
		var c = sin(t * 261.63 * TAU) * 0.15
		var e = sin(t * 329.63 * TAU) * 0.12
		var g = sin(t * 392.0 * TAU) * 0.12
		var c2 = sin(t * 523.25 * TAU) * 0.08
		var shimmer = sin(t * 1046.5 * TAU) * 0.03 * sin(t * 6.0)
		samples.append((c + e + g + c2 + shimmer) * env * 0.5)
	return _samples_to_wav(samples)
