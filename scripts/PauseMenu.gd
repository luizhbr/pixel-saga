extends CanvasLayer
## PauseMenu — tela de pause + game over

var is_paused: bool = false
var is_game_over: bool = false
var overlay: ColorRect
var title_label: Label
var buttons: Array = []
var selected: int = 0
var level: Node2D

func _ready() -> void:
	layer = 50
	
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = Vector2(320, 180)
	overlay.visible = false
	add_child(overlay)
	
	title_label = Label.new()
	title_label.position = Vector2(0, 50)
	title_label.size = Vector2(320, 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.visible = false
	add_child(title_label)
	
	# Find level
	await get_tree().process_frame
	var levels := get_tree().get_nodes_in_group("level")
	if levels.size() > 0:
		level = levels[0]

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("soul_link") and not is_game_over:
		if is_paused:
			_resume()
		else:
			_pause()
	
	if Input.is_key_pressed(KEY_ESCAPE) and not is_game_over:
		if is_paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	overlay.visible = true
	title_label.text = "PAUSADO"
	title_label.visible = true
	_show_buttons(["CONTINUAR", "REINICIAR", "MENU PRINCIPAL"])

func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	overlay.visible = false
	title_label.visible = false
	_clear_buttons()

func show_game_over() -> void:
	is_game_over = true
	overlay.visible = true
	title_label.text = "VOCÊ CAIU"
	title_label.visible = true
	_show_buttons(["TENTAR NOVAMENTE", "VOLTAR AO CHECKPOINT", "MENU"])

func _show_buttons(items: Array) -> void:
	_clear_buttons()
	for i in range(items.size()):
		var btn := Button.new()
		btn.text = items[i]
		btn.position = Vector2(80, 75 + i * 16)
		btn.size = Vector2(160, 14)
		btn.add_theme_font_size_override("font_size", 6)
		btn.focus_mode = Control.FOCUS_NONE
		
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.08, 0.2, 0.8)
		sb.border_color = Color(0.4, 0.3, 0.6, 0.8)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_left = 2
		sb.corner_radius_bottom_right = 2
		btn.add_theme_stylebox_override("normal", sb)
		
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.3))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.3))
		
		btn.pressed.connect(func(): _on_button_pressed(i))
		add_child(btn)
		buttons.append(btn)
	
	selected = 0
	_update_selection()

func _clear_buttons() -> void:
	for b in buttons:
		b.queue_free()
	buttons.clear()

func _update_selection() -> void:
	for i in range(buttons.size()):
		if i == selected:
			buttons[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		else:
			buttons[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))

func _on_button_pressed(idx: int) -> void:
	AudioManager.play("menu_select")
	if is_game_over:
		match idx:
			0:  # Tentar novamente
				is_game_over = false
				overlay.visible = false
				title_label.visible = false
				_clear_buttons()
				if GameManager.health <= 0:
					GameManager.heal(GameManager.MAX_HEALTH)
				# Respawn player
				var players := get_tree().get_nodes_in_group("player")
				if players.size() > 0:
					players[0]._respawn()
			1:  # Voltar ao checkpoint
				is_game_over = false
				overlay.visible = false
				title_label.visible = false
				_clear_buttons()
				GameManager.heal(GameManager.MAX_HEALTH)
				var players := get_tree().get_nodes_in_group("player")
				if players.size() > 0:
					players[0]._respawn()
			2:  # Menu
				get_tree().paused = false
				SceneTransition.transition_to_scene("res://scenes/MainMenu.tscn", "")
	else:
		match idx:
			0:  # Continuar
				_resume()
			1:  # Reiniciar
				get_tree().paused = false
				SceneTransition.transition_to_scene(get_tree().current_scene.scene_file_path, "")
			2:  # Menu
				get_tree().paused = false
				SceneTransition.transition_to_scene("res://scenes/MainMenu.tscn", "")