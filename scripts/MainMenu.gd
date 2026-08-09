extends Control
## MainMenu — menu principal profissional do Pixel Saga
## Estrutura: Main → Select → Settings → How to Play → Credits
## Navegação: teclado + touch + mouse

enum MenuState { MAIN, SELECT, SETTINGS, HOWTO, CREDITS }

var state: MenuState = MenuState.MAIN
var selected: int = 0
var buttons: Array = []

var title: Label
var subtitle: Label
var content_container: Control
var settings: Dictionary = {
	"master_vol": 80,
	"music_vol": 70,
	"sfx_vol": 90,
	"fullscreen": false,
	"reduce_shake": false,
	"vibration": true,
}

var char_names := ["Mossy", "Capitão Polo", "Garrax"]
var char_desc := [
	"Criatura amarela curiosa\nHabilidade: Florir (cipós)",
	"Urso polar valente\nHabilidade: Escudo Gélido",
	"Gato aventureiro audaz\nHabilidade: Dash Sombrio + Bash",
]
var char_colors := [
	Color(1.0, 0.86, 0.24, 1.0),
	Color(0.96, 0.96, 0.98, 1.0),
	Color(0.94, 0.59, 0.20, 1.0),
]
var char_index_selected := 0

func _ready() -> void:
	# Load saved settings
	_load_settings()
	
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.size = Vector2(320, 180)
	add_child(bg)
	
	# Title
	title = Label.new()
	title.text = "PIXEL SAGA"
	title.position = Vector2(70, 18)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(title)
	
	subtitle = Label.new()
	subtitle.text = "Trio da Tempestade"
	subtitle.position = Vector2(88, 38)
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	add_child(subtitle)
	
	# Neon underline
	var neon := ColorRect.new()
	neon.color = Color(0.2, 0.8, 1.0, 0.6)
	neon.size = Vector2(180, 1)
	neon.position = Vector2(70, 48)
	add_child(neon)
	
	# Content container (where menus appear)
	content_container = Control.new()
	content_container.position = Vector2(0, 50)
	content_container.size = Vector2(320, 130)
	add_child(content_container)
	
	# Touch buttons (if mobile)
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web"):
		_setup_touch_nav()
	
	_show_main_menu()
	set_process_input(true)

# === STATE MANAGEMENT ===

func _clear_content() -> void:
	for child in content_container.get_children():
		child.queue_free()
	buttons.clear()

func _show_main_menu() -> void:
	state = MenuState.MAIN
	_clear_content()
	
	var items := ["JOGAR", "SELECIONAR PERSONAGEM", "CONFIGURAÇÕES", "COMO JOGAR", "CRÉDITOS"]
	for i in range(items.size()):
		var btn := _make_menu_button(items[i], Vector2(60, 5 + i * 16))
		buttons.append({"label": items[i], "btn": btn, "index": i})
	
	selected = 0
	_update_selection()

func _show_select_screen() -> void:
	state = MenuState.SELECT
	_clear_content()
	
	# Character display
	var char_bg := ColorRect.new()
	char_bg.color = Color(0.1, 0.08, 0.2, 0.7)
	char_bg.size = Vector2(200, 50)
	char_bg.position = Vector2(60, 0)
	content_container.add_child(char_bg)
	
	var char_name := Label.new()
	char_name.text = char_names[char_index_selected]
	char_name.position = Vector2(70, 3)
	char_name.add_theme_font_size_override("font_size", 7)
	char_name.add_theme_color_override("font_color", char_colors[char_index_selected])
	content_container.add_child(char_name)
	
	var char_info := Label.new()
	char_info.text = char_desc[char_index_selected]
	char_info.position = Vector2(70, 14)
	char_info.add_theme_font_size_override("font_size", 5)
	char_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	content_container.add_child(char_info)
	
	# Preview circle
	var preview := ColorRect.new()
	preview.color = char_colors[char_index_selected]
	preview.size = Vector2(12, 12)
	preview.position = Vector2(228, 15)
	content_container.add_child(preview)
	
	# Nav buttons
	var left := _make_menu_button("◀", Vector2(40, 60))
	var right := _make_menu_button("▶", Vector2(250, 60))
	var confirm := _make_menu_button("CONFIRMAR", Vector2(90, 80))
	var back := _make_menu_button("VOLTAR", Vector2(90, 100))
	buttons.append({"label": "◀", "btn": left, "index": 0})
	buttons.append({"label": "▶", "btn": right, "index": 1})
	buttons.append({"label": "CONFIRMAR", "btn": confirm, "index": 2})
	buttons.append({"label": "VOLTAR", "btn": back, "index": 3})
	selected = 2
	_update_selection()

func _show_settings_screen() -> void:
	state = MenuState.SETTINGS
	_clear_content()
	
	var labels := ["VOLUME GERAL", "VOLUME MÚSICA", "VOLUME SFX", "TELA CHEIA", "REDUZIR SHAKE", "VIBRAÇÃO"]
	for i in range(labels.size()):
		var btn := _make_menu_button(labels[i], Vector2(40, 5 + i * 16))
		buttons.append({"label": labels[i], "btn": btn, "index": i})
	
	var back := _make_menu_button("VOLTAR", Vector2(90, 105))
	buttons.append({"label": "VOLTAR", "btn": back, "index": 6})
	selected = 6
	_update_selection()

func _show_howto_screen() -> void:
	state = MenuState.HOWTO
	_clear_content()
	
	var text := Label.new()
	text.text = "COMO JOGAR\n\nSetas/WASD: Mover\nEspaço/K: Pular (segurar = mais alto)\nShift: Dash\nJ/E: Habilidade\nQ: Trocar personagem\nF: Soul Link (save)\n\nPule em inimigos para derrotá-los\nUse Bash (Garrax) para redirecionar\nSpirit Flame (Mossy/Polo) ataca à distância"
	text.position = Vector2(30, 0)
	text.add_theme_font_size_override("font_size", 5)
	text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	content_container.add_child(text)
	
	var back := _make_menu_button("VOLTAR", Vector2(90, 105))
	buttons.append({"label": "VOLTAR", "btn": back, "index": 0})
	selected = 0
	_update_selection()

func _show_credits_screen() -> void:
	state = MenuState.CREDITS
	_clear_content()
	
	var text := Label.new()
	text.text = "PIXEL SAGA\nTrio da Tempestade\n\nEstúdio Indie de Pixel Art\nGodot 4.3 + GDScript\n\nInspirado por:\nOri, Hollow Knight, Celeste\n\nEquipamento:\nKenney (CC0)\nPillow (programmatic art)"
	text.position = Vector2(50, 0)
	text.add_theme_font_size_override("font_size", 5)
	text.add_theme_color_override("font_color", Color(0.6, 0.6, 0.85))
	content_container.add_child(text)
	
	var back := _make_menu_button("VOLTAR", Vector2(90, 105))
	buttons.append({"label": "VOLTAR", "btn": back, "index": 0})
	selected = 0
	_update_selection()

# === BUTTON FACTORY ===

func _make_menu_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(200, 14)
	btn.add_theme_font_size_override("font_size", 6)
	btn.focus_mode = Control.FOCUS_NONE
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.2, 0.6)
	sb.border_color = Color(0.3, 0.2, 0.5, 0.6)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	
	var sb_sel := StyleBoxFlat.new()
	sb_sel.bg_color = Color(0.2, 0.15, 0.4, 0.9)
	sb_sel.border_color = Color(0.4, 0.6, 1.0, 1.0)
	sb_sel.border_width_left = 1
	sb_sel.border_width_right = 1
	sb_sel.border_width_top = 1
	sb_sel.border_width_bottom = 1
	sb_sel.corner_radius_top_left = 2
	sb_sel.corner_radius_top_right = 2
	sb_sel.corner_radius_bottom_left = 2
	sb_sel.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("pressed", sb_sel)
	
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.5))
	
	content_container.add_child(btn)
	return btn

func _update_selection() -> void:
	for i in range(buttons.size()):
		var btn: Button = buttons[i]["btn"]
		if i == selected:
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.15, 0.4, 0.9)
			sb.border_color = Color(0.4, 0.6, 1.0, 1.0)
			sb.border_width_left = 1
			sb.border_width_right = 1
			sb.border_width_top = 1
			sb.border_width_bottom = 1
			sb.corner_radius_top_left = 2
			sb.corner_radius_top_right = 2
			sb.corner_radius_bottom_left = 2
			sb.corner_radius_bottom_right = 2
			btn.add_theme_stylebox_override("normal", sb)
		else:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
			var sb2 := StyleBoxFlat.new()
			sb2.bg_color = Color(0.1, 0.08, 0.2, 0.4)
			sb2.border_color = Color(0.3, 0.2, 0.5, 0.4)
			sb2.border_width_left = 1
			sb2.border_width_right = 1
			sb2.border_width_top = 1
			sb2.border_width_bottom = 1
			sb2.corner_radius_top_left = 2
			sb2.corner_radius_top_right = 2
			sb2.corner_radius_bottom_left = 2
			sb2.corner_radius_bottom_right = 2
			btn.add_theme_stylebox_override("normal", sb2)

# === INPUT ===

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed:
		# Mouse click — find clicked button
		for b in buttons:
			var btn: Button = b["btn"]
			if btn.get_global_rect().has_point(event.position):
				selected = b["index"]
				_update_selection()
				_activate()

func _handle_key(keycode: int) -> void:
	match state:
		MenuState.MAIN:
			if keycode == KEY_UP or keycode == KEY_W:
				selected = (selected - 1 + buttons.size()) % buttons.size()
				_update_selection()
				AudioManager.play("menu_move")
			elif keycode == KEY_DOWN or keycode == KEY_S:
				selected = (selected + 1) % buttons.size()
				_update_selection()
				AudioManager.play("menu_move")
			elif keycode == KEY_ENTER or keycode == KEY_SPACE:
				_activate()
		MenuState.SELECT:
			if keycode == KEY_LEFT or keycode == KEY_A:
				if selected <= 1:
					char_index_selected = (char_index_selected - 1 + 3) % 3
					_show_select_screen()
					AudioManager.play("menu_move")
				else:
					selected = max(0, selected - 1)
					_update_selection()
			elif keycode == KEY_RIGHT or keycode == KEY_D:
				if selected <= 1:
					char_index_selected = (char_index_selected + 1) % 3
					_show_select_screen()
					AudioManager.play("menu_move")
				else:
					selected = min(buttons.size() - 1, selected + 1)
					_update_selection()
			elif keycode == KEY_UP or keycode == KEY_W:
				selected = max(0, selected - 1)
				if selected < 2:
					selected = 2
				_update_selection()
			elif keycode == KEY_DOWN or keycode == KEY_S:
				selected = min(buttons.size() - 1, selected + 1)
				_update_selection()
			elif keycode == KEY_ENTER or keycode == KEY_SPACE:
				_activate()
			elif keycode == KEY_ESCAPE:
				_show_main_menu()
		MenuState.SETTINGS:
			if keycode == KEY_UP or keycode == KEY_W:
				selected = max(0, selected - 1)
				_update_selection()
			elif keycode == KEY_DOWN or keycode == KEY_S:
				selected = min(buttons.size() - 1, selected + 1)
				_update_selection()
			elif keycode == KEY_LEFT or keycode == KEY_A:
				_adjust_setting(selected, -10)
			elif keycode == KEY_RIGHT or keycode == KEY_D:
				_adjust_setting(selected, 10)
			elif keycode == KEY_ENTER or keycode == KEY_SPACE:
				if selected == 6:
					_show_main_menu()
				else:
					_toggle_setting(selected)
			elif keycode == KEY_ESCAPE:
				_show_main_menu()
		_:
			if keycode == KEY_ENTER or keycode == KEY_SPACE or keycode == KEY_ESCAPE:
				_show_main_menu()
				AudioManager.play("menu_select")

func _activate() -> void:
	AudioManager.play("menu_select")
	match state:
		MenuState.MAIN:
			match selected:
				0: _start_game()
				1: _show_select_screen()
				2: _show_settings_screen()
				3: _show_howto_screen()
				4: _show_credits_screen()
		MenuState.SELECT:
			match selected:
				0: char_index_selected = (char_index_selected - 1 + 3) % 3; _show_select_screen()
				1: char_index_selected = (char_index_selected + 1) % 3; _show_select_screen()
				2: _start_game()
				3: _show_main_menu()
		MenuState.SETTINGS:
			if selected == 6:
				_save_settings()
				_show_main_menu()
			else:
				_toggle_setting(selected)
		_:
			_show_main_menu()

func _adjust_setting(idx: int, delta: int) -> void:
	match idx:
		0: settings["master_vol"] = clamp(settings["master_vol"] + delta, 0, 100)
		1: settings["music_vol"] = clamp(settings["music_vol"] + delta, 0, 100)
		2: settings["sfx_vol"] = clamp(settings["sfx_vol"] + delta, 0, 100)
	_show_settings_screen()

func _toggle_setting(idx: int) -> void:
	match idx:
		3: settings["fullscreen"] = not settings["fullscreen"]
		4: settings["reduce_shake"] = not settings["reduce_shake"]
		5: settings["vibration"] = not settings["vibration"]
	_show_settings_screen()

func _start_game() -> void:
	GameManager.reset()
	GameManager.current_character = char_index_selected
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

# === SETTINGS PERSISTENCE ===

func _save_settings() -> void:
	var f := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if f:
		f.store_var(settings)
		f.close()

func _load_settings() -> void:
	var f := FileAccess.open("user://settings.cfg", FileAccess.READ)
	if f:
		settings = f.get_var()
		f.close()

# === TOUCH NAVIGATION ===

var touch_up: Button
var touch_down: Button
var touch_confirm: Button
var touch_left: Button
var touch_right: Button

func _setup_touch_nav() -> void:
	touch_up = _make_touch_btn("▲", Vector2(280, 115), 24)
	touch_down = _make_touch_btn("▼", Vector2(280, 145), 24)
	touch_confirm = _make_touch_btn("OK", Vector2(245, 130), 24, Color(0.2, 0.8, 0.4))
	touch_left = _make_touch_btn("◀", Vector2(10, 130), 24)
	touch_right = _make_touch_btn("▶", Vector2(40, 130), 24)
	
	touch_up.button_down.connect(func(): _handle_key(KEY_UP))
	touch_down.button_down.connect(func(): _handle_key(KEY_DOWN))
	touch_confirm.button_down.connect(func(): _handle_key(KEY_ENTER))
	touch_left.button_down.connect(func(): _handle_key(KEY_LEFT))
	touch_right.button_down.connect(func(): _handle_key(KEY_RIGHT))

func _make_touch_btn(label: String, pos: Vector2, size: float, accent: Color = Color(0.4, 0.4, 0.5, 1.0)) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", int(size * 0.3))
	btn.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.3)
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