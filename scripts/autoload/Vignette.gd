extends CanvasLayer
## Vignette — vinheta dinâmica nas bordas da tela
## Aumenta em: pouca vida, boss, transições, morte

var overlay: ColorRect
var vignette_texture: ImageTexture
var current_intensity: float = 0.15  # Base subtle vignette
var target_intensity: float = 0.15
var pulse_timer: float = 0.0

func _ready() -> void:
	layer = 30
	
	# Create radial vignette texture
	overlay = ColorRect.new()
	overlay.size = Vector2(320, 180)
	overlay.color = Color(0, 0, 0, current_intensity)
	overlay.z_index = 30
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	set_process(true)

func _process(delta: float) -> void:
	# Smooth lerp toward target
	current_intensity = lerp(current_intensity, target_intensity, 2.0 * delta)
	overlay.color.a = current_intensity
	
	# Low health pulse
	var hp_ratio: float = float(GameManager.health) / float(GameManager.MAX_HEALTH)
	if hp_ratio <= 0.33:
		# Red pulse on low health
		pulse_timer += delta
		var pulse: float = sin(pulse_timer * 4.0) * 0.15
		overlay.color = Color(0.3, 0.0, 0.0, current_intensity + pulse)
	elif hp_ratio <= 0.66:
		overlay.color = Color(0.0, 0.0, 0.0, current_intensity)
	else:
		overlay.color = Color(0.0, 0.0, 0.0, current_intensity)

func set_intensity(intensity: float) -> void:
	target_intensity = clamp(intensity, 0.0, 0.8)

func boss_mode(enabled: bool) -> void:
	if enabled:
		set_intensity(0.35)

func death_flash() -> void:
	set_intensity(0.7)
	await get_tree().create_timer(0.5).timeout
	set_intensity(0.15)

func transition_pulse() -> void:
	set_intensity(0.5)
	await get_tree().create_timer(0.3).timeout
	set_intensity(0.15)

func reset() -> void:
	target_intensity = 0.15
	current_intensity = 0.15
	pulse_timer = 0.0