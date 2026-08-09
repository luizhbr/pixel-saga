extends CanvasLayer
## SceneTransition — transições cinematográficas entre cenas
## Fade, vinheta, texto do nível. Singleton autoload.

signal transition_started
signal transition_finished

var overlay: ColorRect
var label: Label
var is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	
	# Full screen overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(320, 180)
	overlay.z_index = 100
	add_child(overlay)
	
	# Level name label
	label = Label.new()
	label.position = Vector2(0, 80)
	label.size = Vector2(320, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	label.visible = false
	add_child(label)

func fade_out(duration: float = 0.4, text: String = "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	transition_started.emit()
	
	if text != "":
		label.text = text
		label.visible = true
		label.modulate.a = 0.0
	
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, duration)
	if text != "":
		tw.parallel().tween_property(label, "modulate:a", 1.0, duration * 0.7)
	
	await tw.finished

func fade_in(duration: float = 0.4, text: String = "") -> void:
	if text != "":
		label.text = text
		label.visible = true
		label.modulate.a = 1.0
		overlay.color.a = 1.0
	
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, duration)
	if text != "":
		tw.parallel().tween_property(label, "modulate:a", 0.0, duration)
	
	await tw.finished
	label.visible = false
	is_transitioning = false
	transition_finished.emit()

func transition_to_scene(scene_path: String, text: String = "", fade_out_time: float = 0.4, fade_in_time: float = 0.4) -> void:
	await fade_out(fade_out_time, text)
	get_tree().change_scene_to_file(scene_path)
	# Fade in happens in the new scene's _ready via call_deferred
	await get_tree().create_timer(0.1).timeout
	await fade_in(fade_in_time)

func vignette_intensity(intensity: float) -> void:
	# Quick vignette pulse (for boss, low health, etc.)
	overlay.color = Color(intensity * 0.3, 0, 0, intensity * 0.4)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.5)