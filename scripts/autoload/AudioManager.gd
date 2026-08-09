extends Node
## AudioManager v2 — SFX procedural + música ambiente + mixagem
## Bus groups: Master, Music, SFX, UI
## SFX: tone synthesis com variações de pitch para evitar repetição
## Música: pads ambientais gerados proceduralmente por mundo

const SAMPLE_RATE := 22050
var bus_initialized := false

# Bus indices
var bus_master: int = 0
var bus_music: int = 0
var bus_sfx: int = 0

# Music state
var music_player: AudioStreamGenerator
var music_playback: AudioStreamGeneratorPlayback
var music_phase: float = 0.0
var music_is_playing: bool = false
var music_track: String = ""
var music_volume: float = 0.15

# SFX variation seed
var sfx_counter: int = 0

func _ready() -> void:
	if not bus_initialized:
		_init_buses()
		bus_initialized = true

func _init_buses() -> void:
	# Ensure buses exist
	bus_master = AudioServer.get_bus_index("Master")
	if bus_master == -1:
		AudioServer.add_bus()
		bus_master = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_master, "Master")
	
	bus_music = AudioServer.get_bus_index("Music")
	if bus_music == -1:
		AudioServer.add_bus(bus_master)
		bus_music = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_music, "Music")
	
	bus_sfx = AudioServer.get_bus_index("SFX")
	if bus_sfx == -1:
		AudioServer.add_bus(bus_master)
		bus_sfx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_sfx, "SFX")
	
	AudioServer.set_bus_volume_db(bus_master, -6.0)
	AudioServer.set_bus_volume_db(bus_music, -12.0)
	AudioServer.set_bus_volume_db(bus_sfx, -3.0)

# === SFX ===
func play(sfx_name: String) -> void:
	# Pitch variation for non-repetitive feel
	var pitch_var: float = 1.0 + (sfx_counter % 3 - 1) * 0.03
	sfx_counter += 1
	
	match sfx_name:
		"jump": _play_tone(440.0 * pitch_var, 660.0 * pitch_var, 0.12, 0.3)
		"hit": _play_noise(0.15, 0.4)
		"stomp": _play_tone(200.0 * pitch_var, 80.0 * pitch_var, 0.1, 0.35)
		"dash": _play_sweep(800.0 * pitch_var, 200.0, 0.15, 0.3)
		"switch": _play_tone(523.0 * pitch_var, 784.0 * pitch_var, 0.08, 0.25)
		"crystal": _play_chord([523.0, 659.0, 784.0], 0.15, 0.25)
		"checkpoint": _play_chord([392.0, 523.0, 659.0], 0.2, 0.3)
		"menu_move": _play_tone(440.0, 440.0, 0.05, 0.15)
		"menu_select": _play_chord([523.0, 784.0], 0.1, 0.25)
		"boss_hit": _play_tone(150.0, 50.0, 0.2, 0.5)
		_: pass

func _play_tone(freq_start: float, freq_end: float, duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.05
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.bus = "SFX"
	add_child(player)
	
	var frames := int(duration * SAMPLE_RATE)
	player.play()
	var playback := player.get_stream_playback()
	
	var filled := 0
	while filled < frames:
		var to_fill := mini(frames - filled, playback.get_frames_available())
		if to_fill == 0:
			await get_tree().process_frame
			continue
		var buf := PackedVector2Array()
		buf.resize(to_fill)
		for i in to_fill:
			var t := float(filled + i) / SAMPLE_RATE
			var freq := lerpf(freq_start, freq_end, float(filled + i) / frames)
			var sample := sin(t * freq * TAU)
			var env := 1.0 - float(filled + i) / frames
			buf[i] = Vector2(sample * env, sample * env)
		playback.push_buffer(buf)
		filled += to_fill
	
	await get_tree().create_timer(duration + 0.2).timeout
	player.queue_free()

func _play_noise(duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.05
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.bus = "SFX"
	add_child(player)
	
	var frames := int(duration * SAMPLE_RATE)
	player.play()
	var playback := player.get_stream_playback()
	
	var filled := 0
	while filled < frames:
		var to_fill := mini(frames - filled, playback.get_frames_available())
		if to_fill == 0:
			await get_tree().process_frame
			continue
		var buf := PackedVector2Array()
		buf.resize(to_fill)
		for i in to_fill:
			var sample := randf_range(-1.0, 1.0)
			var env := 1.0 - float(filled + i) / frames
			buf[i] = Vector2(sample * env, sample * env)
		playback.push_buffer(buf)
		filled += to_fill
	
	await get_tree().create_timer(duration + 0.2).timeout
	player.queue_free()

func _play_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> void:
	_play_tone(freq_start, freq_end, duration, volume)

func _play_chord(freqs: Array, duration: float, volume: float) -> void:
	for f in freqs:
		_play_tone(float(f), float(f), duration, volume * 0.5)

# === MUSIC ===
func start_music(track_name: String) -> void:
	if music_is_playing and music_track == track_name:
		return  # Already playing this track
	stop_music()
	music_track = track_name
	music_is_playing = true
	music_phase = 0.0
	
	music_player = AudioStreamGenerator.new()
	music_player.mix_rate = SAMPLE_RATE
	music_player.buffer_length = 0.5
	
	var player := AudioStreamPlayer.new()
	player.stream = music_player
	player.volume_db = linear_to_db(music_volume)
	player.bus = "Music"
	player.name = "MusicPlayer"
	add_child(player)
	player.play()
	music_playback = player.get_stream_playback()
	set_process(true)

func stop_music() -> void:
	music_is_playing = false
	set_process(false)
	var player := get_node_or_null("MusicPlayer")
	if player:
		player.queue_free()
	music_playback = null

func _process(_delta: float) -> void:
	if not music_is_playing or not music_playback:
		return
	
	# Generate ambient pad music procedurally
	# Each track has different chord progression + arpeggios
	var chords: Dictionary = {
		"menu": [[0, 7, 12], [5, 9, 12], [7, 11, 14], [2, 7, 11]],
		"cyberpunk": [[0, 3, 7], [0, 5, 7], [-2, 3, 7], [0, 3, 10]],
		"japanese": [[0, 5, 7], [3, 7, 12], [5, 9, 14], [2, 5, 9]],
		"swamp": [[0, 3, 7], [-2, 3, 7], [-4, 0, 3], [-2, 3, 7]],
		"boss": [[0, 3, 6], [1, 4, 7], [0, 3, 6], [-1, 2, 5]],
	}
	
	var base_freq: float = 110.0  # A2
	var progression: Array = chords.get(music_track, chords["menu"])
	
	while music_playback.get_frames_available() > 256:
		var buf := PackedVector2Array()
		buf.resize(256)
		for i in 256:
			music_phase += 1.0 / SAMPLE_RATE
			# Slow chord progression (every 4 seconds)
			var chord_idx: int = int(music_phase / 4.0) % progression.size()
			var chord: Array = progression[chord_idx]
			
			# Pad: sum of 3 sine waves
			var sample: float = 0.0
			for note in chord:
				var freq: float = base_freq * pow(2.0, float(note) / 12.0)
				sample += sin(music_phase * freq * TAU) * 0.15
			
			# Add gentle arpeggio
			var arp_note: int = chord[int(music_phase * 2.0) % chord.size()]
			var arp_freq: float = base_freq * 2.0 * pow(2.0, float(arp_note) / 12.0)
			var arp_env: float = max(0.0, 1.0 - (fmod(music_phase * 2.0, 1.0)))
			sample += sin(music_phase * arp_freq * TAU) * arp_env * 0.08
			
			# Soft volume envelope
			sample *= music_volume
			buf[i] = Vector2(sample, sample)
		music_playback.push_buffer(buf)

func set_music_volume(vol: float) -> void:
	music_volume = vol
	var player := get_node_or_null("MusicPlayer")
	if player:
		player.volume_db = linear_to_db(vol)

func set_sfx_volume(vol: float) -> void:
	if bus_sfx >= 0:
		AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(vol))

func set_master_volume(vol: float) -> void:
	if bus_master >= 0:
		AudioServer.set_bus_volume_db(bus_master, linear_to_db(vol))