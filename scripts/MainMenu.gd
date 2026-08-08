extends Control
## MainMenu — menu principal + seleção de personagem + transição de níveis

var title: Label
var subtitle: Label
var buttons: Array = []
var selected: int = 0
var state: String = "main"  # main, select, credits

var char_names := ["Mossy", "Capitão Polo", "Garrax"]
var char_desc := [
	"Criatura amarela curiosa\nHabilidade: Florir (cipós)",
	"Urso polar valente\nHabilidade: Escudo Gélido",
	"Gato aventureiro audaz\nHabilidade: Dash Sombrio",
]
var char_colors := [
	Color(1.0, 0.86, 0.24, 1.0),
	Color(0.96, 0.96, 0.98, 1.0),
	Color(0.94, 0.59, 0.20, 1.0),
]
var char_index_selected := 0

func _ready() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.size = Vector2(320, 180)
	add_child(bg)
	
	# Touch controls for menu navigation
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web"):
		_touch_controls()
	
	# Title
	title = Label.new()
	title.text = "PIXEL SAGA"
	title.position = Vector2(80, 20)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(title)
	
	subtitle = Label.new()
	subtitle.text = "Trio da Tempestade"
	subtitle.position = Vector2(95, 40)
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	add_child(subtitle)
	
	# Neon underline
	var neon := ColorRect.new()
	neon.color = Color(0.2, 0.8, 1.0, 0.8)
	neon.size = Vector2(160, 1)
	neon.position = Vector2(80, 50)
	add_child(neon)
	
	_show_main_menu()

func _show_main_menu() -> void:
	state = "main"
	_clear_buttons()
	
	var items := ["Jogar", "Selecionar Personagem", "Créditos", "Sair"]
	for i in range(items.size()):
		var btn := _make_button(items[i], Vector2(90, 65 + i * 14))
		buttons.append({"label": items[i], "btn": btn, "index": i})
	
	selected = 0
	_update_selection()

func _show_select_screen() -> void:
	state = "select"
	_clear_buttons()
	
	# Character info display
	var info_bg := ColorRect.new()
	info_bg.color = Color(0.1, 0.08, 0.2, 0.9)
	info_bg.size = Vector2(180, 60)
	info_bg.position = Vector2(70, 80)
	info_bg.name = "InfoBG"
	add_child(info_bg)
	
	var info := Label.new()
	info.text = char_desc[char_index_selected]
	info.position = Vector2(75, 85)
	info.add_theme_font_size_override("font_size", 5)
	info.add_theme_color_override("font_color", char_colors[char_index_selected])
	info.name = "CharInfo"
	add_child(info)
	
	# Character preview circle
	var preview := ColorRect.new()
	preview.color = char_colors[char_index_selected]
	preview.size = Vector2(12, 12)
	preview.position = Vector2(155, 70)
	preview.name = "CharPreview"
	add_child(preview)
	
	# Arrows
	var left := _make_button("<", Vector2(60, 100))
	var right := _make_button(">", Vector2(250, 100))
	buttons.append({"label": "<", "btn": left, "index": 0})
	buttons.append({"label": ">", "btn": right, "index": 1})
	
	var confirm := _make_button("Confirmar", Vector2(120, 120))
	buttons.append({"label": "Confirmar", "btn": confirm, "index": 2})
	
	var back := _make_button("Voltar", Vector2(120, 140))
	buttons.append({"label": "Voltar", "btn": back, "index": 3})
	
	selected = 2
	_update_selection()

func _show_credits() -> void:
	state = "credits"
	_clear_buttons()
	
	var credits_text := Label.new()
	credits_text.text = "PIXEL SAGA: Trio da Tempestade\n\nEstúdio Indie de Pixel Art\nGodot 4 + GDScript\n\n< Voltar"
	credits_text.position = Vector2(40, 30)
	credits_text.add_theme_font_size_override("font_size", 6)
	credits_text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	credits_text.name = "CreditsText"
	add_child(credits_text)
	
	var back := _make_button("Voltar", Vector2(120, 140))
	buttons.append({"label": "Voltar", "btn": back, "index": 0})
	selected = 0
	_update_selection()

func _make_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(140, 12)
	btn.add_theme_font_size_override("font_size", 6)
	btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.1, 0.08, 0.2, 0.9)))
	btn.add_theme_stylebox_override("hover", _make_stylebox(Color(0.2, 0.15, 0.35, 1.0)))
	btn.add_theme_stylebox_override("focus", _make_stylebox(Color(0.3, 0.2, 0.5, 1.0)))
	btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5))
	add_child(btn)
	return btn

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Color(0.4, 0.3, 0.6, 0.8)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	return sb

func _clear_buttons() -> void:
	for b in buttons:
		if is_instance_valid(b["btn"]):
			b["btn"].queue_free()
	buttons.clear()
	# Remove info/credits nodes
	for name in ["InfoBG", "CharInfo", "CharPreview", "CreditsText"]:
		var n := get_node_or_null(name)
		if n:
			n.queue_free()

func _update_selection() -> void:
	for i in range(buttons.size()):
		var btn: Button = buttons[i]["btn"]
		if i == selected:
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.25, 0.15, 0.4, 1.0)))
		else:
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
			btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.1, 0.08, 0.2, 0.9)))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if state == "main":
			if event.keycode == KEY_UP or event.keycode == KEY_W:
				selected = (selected - 1 + buttons.size()) % buttons.size()
				_update_selection()
				AudioManager.play("menu_move")
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				selected = (selected + 1) % buttons.size()
				_update_selection()
				AudioManager.play("menu_move")
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_activate_main(selected)
		
		elif state == "select":
			if event.keycode == KEY_LEFT or event.keycode == KEY_A:
				if selected == 0:  # left arrow
					char_index_selected = (char_index_selected - 1 + 3) % 3
					_refresh_select()
					AudioManager.play("menu_move")
				else:
					selected = 0
					_update_selection()
					AudioManager.play("menu_move")
			elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
				if selected == 1:  # right arrow
					char_index_selected = (char_index_selected + 1) % 3
					_refresh_select()
					AudioManager.play("menu_move")
				else:
					selected = 1
					_update_selection()
					AudioManager.play("menu_move")
			elif event.keycode == KEY_UP or event.keycode == KEY_W:
				selected = (selected - 1 + buttons.size()) % buttons.size()
				if selected == 0 or selected == 1:
					selected = 2
				_update_selection()
				AudioManager.play("menu_move")
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				selected = (selected + 1) % buttons.size()
				if selected == 0 or selected == 1:
					selected = 2
				_update_selection()
				AudioManager.play("menu_move")
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_activate_select(selected)
		
		elif state == "credits":
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
				_show_main_menu()
				AudioManager.play("menu_select")

func _activate_main(idx: int) -> void:
	AudioManager.play("menu_select")
	match idx:
		0:  # Jogar
			_start_game()
		1:  # Selecionar personagem
			_show_select_screen()
		2:  # Créditos
			_show_credits()
		3:  # Sair
			get_tree().quit()

func _activate_select(idx: int) -> void:
	AudioManager.play("menu_select")
	match idx:
		0:  # Left
			char_index_selected = (char_index_selected - 1 + 3) % 3
			_refresh_select()
		1:  # Right
			char_index_selected = (char_index_selected + 1) % 3
			_refresh_select()
		2:  # Confirm
			GameManager.current_character = char_index_selected
			_start_game()
		3:  # Back
			_show_main_menu()

func _refresh_select() -> void:
	# Update info display
	var info := get_node_or_null("CharInfo")
	if info:
		info.text = char_desc[char_index_selected]
		info.add_theme_color_override("font_color", char_colors[char_index_selected])
	
	var preview := get_node_or_null("CharPreview")
	if preview:
		preview.color = char_colors[char_index_selected]

func _start_game() -> void:
	GameManager.reset()
	GameManager.current_character = char_index_selected
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

# --- Touch controls for menu ---
var touch_up: Button
var touch_down: Button
var touch_confirm: Button
var touch_left: Button
var touch_right: Button

func _touch_controls() -> void:
	# Up/Down for menu navigation
	touch_up = _make_touch_btn("▲", Vector2(280, 120), 28)
	touch_down = _make_touch_btn("▼", Vector2(280, 150), 28)
	touch_confirm = _make_touch_btn("OK", Vector2(245, 135), 28, Color(0.2, 0.8, 0.4))
	touch_left = _make_touch_btn("◀", Vector2(10, 135), 28)
	touch_right = _make_touch_btn("▶", Vector2(40, 135), 28)
	
	# Simulate key presses
	touch_up.button_down.connect(func(): _touch_key(KEY_UP))
	touch_down.button_down.connect(func(): _touch_key(KEY_DOWN))
	touch_confirm.button_down.connect(func(): _touch_key(KEY_ENTER))
	touch_left.button_down.connect(func(): _touch_key(KEY_LEFT))
	touch_right.button_down.connect(func(): _touch_key(KEY_RIGHT))

func _make_touch_btn(label: String, pos: Vector2, size: float, accent: Color = Color(0.4, 0.4, 0.5, 1.0)) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", int(size * 0.35))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.4)
	sb.border_color = accent
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = int(size / 2)
	sb.corner_radius_top_right = int(size / 2)
	sb.corner_radius_bottom_left = int(size / 2)
	sb.corner_radius_bottom_right = int(size / 2)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	var sbp := sb.duplicate()
	sbp.bg_color = accent.darkened(0.3)
	btn.add_theme_stylebox_override("pressed", sbp)
	btn.add_theme_color_override("font_color", accent.lightened(0.3))
	add_child(btn)
	return btn

func _touch_key(keycode: Key) -> void:
	# Simulate a key press by sending InputEventKey
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	# Release after a frame
	await get_tree().process_frame
	ev.pressed = false
	Input.parse_input_event(ev)