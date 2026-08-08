extends Node
## AudioManager (Autoload) — gera SFX procedural com AudioStreamGenerator
## Não precisa de arquivos de áudio — cria ondas em tempo real

const SAMPLE_RATE := 22050

var bus_initialized := false

func _ready() -> void:
	if not bus_initialized:
		var idx := AudioServer.get_bus_index("Master")
		if idx == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, "Master")
			idx = AudioServer.bus_count - 1
		AudioServer.set_bus_volume_db(idx, -6.0)
		bus_initialized = true

func play(sfx_name: String) -> void:
	match sfx_name:
		"jump": _play_tone(440.0, 660.0, 0.12, 0.3)
		"hit": _play_noise(0.15, 0.4)
		"stomp": _play_tone(200.0, 80.0, 0.1, 0.35)
		"dash": _play_sweep(800.0, 200.0, 0.15, 0.3)
		"switch": _play_tone(523.0, 784.0, 0.08, 0.25)
		"crystal": _play_chord([523.0, 659.0, 784.0], 0.15, 0.25)
		"checkpoint": _play_chord([392.0, 523.0, 659.0], 0.2, 0.3)
		"menu_move": _play_tone(440.0, 440.0, 0.05, 0.15)
		"menu_select": _play_chord([523.0, 784.0], 0.1, 0.25)
		_: pass

func _play_tone(freq_start: float, freq_end: float, duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.05
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	add_child(player)
	
	var frames := int(duration * SAMPLE_RATE)
	var playback: AudioStreamGeneratorPlayback = null
	player.play()
	playback = player.get_stream_playback()
	
	var filled := 0
	while filled < frames:
		var to_fill := mini(frames - filled, playback.get_frames_available())
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
	
	# Cleanup
	await get_tree().create_timer(duration + 0.2).timeout
	player.queue_free()

func _play_noise(duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.05
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	add_child(player)
	
	var frames := int(duration * SAMPLE_RATE)
	player.play()
	var playback := player.get_stream_playback()
	
	var filled := 0
	while filled < frames:
		var to_fill := mini(frames - filled, playback.get_frames_available())
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