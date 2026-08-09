extends CanvasLayer
## TouchControls v3 — Controles estilo Game Boy Advance
## D-pad como unidade visual única, A/B separados, START/SELECT discretos
## Multi-touch com pointer IDs, feedback visual, touch targets maiores que visual
## Input abstraction: alimenta o InputMap do Godot (teclado/gamepad/touch = mesmo sistema)

# Estado de input (alimenta InputMap)
var left_pressed: bool = false
var right_pressed: bool = false
var up_pressed: bool = false
var down_pressed: bool = false
var jump_pressed: bool = false
var ability_pressed: bool = false
var dash_pressed: bool = false
var switch_pressed: bool = false
var soul_link_pressed: bool = false

# Nodes
var dpad: Control
var btn_a: Control
var btn_b: Control
var btn_start: Control
var btn_select: Control

# Config
var is_touch_device: bool = false
var control_scale: float = 1.0
var control_opacity: float = 0.45

# Paleta GBA (interpretação própria, não cópia)
const COL_DPAD := Color(0.30, 0.30, 0.38, 1.0)
const COL_DPAD_EDGE := Color(0.18, 0.18, 0.24, 1.0)
const COL_DPAD_HILITE := Color(0.42, 0.42, 0.52, 1.0)
const COL_A := Color(0.75, 0.20, 0.25, 1.0)   # A = vermelho (pulo/ação principal)
const COL_B := Color(0.25, 0.45, 0.80, 1.0)   # B = azul (ação secundária)
const COL_SYS := Color(0.55, 0.55, 0.65, 1.0)  # START/SELECT

# Touch target (maior que o visual)
const TOUCH_PAD: float = 40.0
const TOUCH_BTN: float = 44.0

func _ready() -> void:
	layer = 20
	is_touch_device = DisplayServer.is_touchscreen_available()
	if not is_touch_device and OS.has_feature("web"):
		is_touch_device = _check_mobile_browser()
	visible = is_touch_device
	if is_touch_device:
		_create_controls()

func _check_mobile_browser() -> bool:
	if not DisplayServer.is_touchscreen_available():
		return false
	var screen_size := DisplayServer.screen_get_size()
	return screen_size.x <= 900 or screen_size.y <= 900

func _create_controls() -> void:
	# === D-PAD (unidade visual única) ===
	dpad = Control.new()
	dpad.name = "Dpad"
	dpad.custom_minimum_size = Vector2(TOUCH_PAD * 3, TOUCH_PAD * 3)
	dpad.position = Vector2(TOUCH_PAD * 0.5, SCREEN_H - TOUCH_PAD * 3.5)
	dpad.mouse_filter = Control.MOUSE_FILTER_STOP
	dpad.gui_input.connect(_on_dpad_input)
	dpad.draw.connect(_draw_dpad)
	add_child(dpad)
	
	# === BOTÃO A (pulo/ação principal — maior, vermelho) ===
	btn_a = _make_action_btn("A", COL_A, Vector2(SCREEN_W - TOUCH_BTN * 1.6, SCREEN_H - TOUCH_BTN * 1.5), "jump")
	
	# === BOTÃO B (ação secundária — menor, azul) ===
	btn_b = _make_action_btn("B", COL_B, Vector2(SCREEN_W - TOUCH_BTN * 2.9, SCREEN_H - TOUCH_BTN * 1.1), "ability")
	
	# === START / SELECT (discretos, centro-inferior) ===
	btn_start = _make_sys_btn("START", Vector2(SCREEN_W * 0.5 + 8, SCREEN_H - 14), "pause")
	btn_select = _make_sys_btn("SELECT", Vector2(SCREEN_W * 0.5 - 40, SCREEN_H - 14), "switch_character")

# === D-PAD DRAW (cruz única) ===
func _draw_dpad() -> void:
	var w: float = TOUCH_PAD
	var cx: float = w * 1.5
	var cy: float = w * 1.5
	
	# Corpo da cruz (2 braços + centro)
	var body := Rect2(cx - w * 0.5, cy - w * 1.5, w, w * 3)  # vertical
	var body_h := Rect2(cx - w * 1.5, cy - w * 0.5, w * 3, w)  # horizontal
	
	# Sombra (deslocada 1px para baixo/direita)
	dpad.draw_rect(Rect2(body.position + Vector2(1, 1), body.size), COL_DPAD_EDGE)
	dpad.draw_rect(Rect2(body_h.position + Vector2(1, 1), body_h.size), COL_DPAD_EDGE)
	
	# Corpo principal
	dpad.draw_rect(body, COL_DPAD)
	dpad.draw_rect(body_h, COL_DPAD)
	
	# Centro (círculo)
	dpad.draw_circle(Vector2(cx, cy), w * 0.28, COL_DPAD_HILITE)
	
	# Setas direcionais (triângulos)
	_draw_arrow(Vector2(cx, cy - w * 0.9), Vector2.UP, COL_DPAD_HILITE)
	_draw_arrow(Vector2(cx, cy + w * 0.9), Vector2.DOWN, COL_DPAD_HILITE)
	_draw_arrow(Vector2(cx - w * 0.9, cy), Vector2.LEFT, COL_DPAD_HILITE)
	_draw_arrow(Vector2(cx + w * 0.9, cy), Vector2.RIGHT, COL_DPAD_HILITE)

func _draw_arrow(center: Vector2, dir: Vector2, color: Color) -> void:
	var size: float = 5.0
	var perp := Vector2(-dir.y, dir.x)
	var tip := center + dir * size
	var base1 := center - dir * size * 0.5 + perp * size * 0.6
	var base2 := center - dir * size * 0.5 - perp * size * 0.6
	dpad.draw_colored_polygon(PackedVector2Array([tip, base1, base2]), color)

# === D-PAD INPUT (multi-touch com pointer IDs) ===
var dpad_touches: Dictionary = {}  # pointer_id -> direction

func _on_dpad_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var dir := _dpad_direction(event.position)
			if dir != Vector2.ZERO:
				dpad_touches[event.index] = dir
				_apply_dpad_state()
		else:
			if dpad_touches.has(event.index):
				dpad_touches.erase(event.index)
				_apply_dpad_state()
	elif event is InputEventScreenDrag:
		if dpad_touches.has(event.index):
			var dir := _dpad_direction(event.position)
			if dir != Vector2.ZERO:
				dpad_touches[event.index] = dir
			else:
				dpad_touches.erase(event.index)
			_apply_dpad_state()

func _dpad_direction(pos: Vector2) -> Vector2:
	var w: float = TOUCH_PAD
	var cx: float = w * 1.5
	var cy: float = w * 1.5
	var rel := pos - Vector2(cx, cy)
	# Zona morta no centro
	if rel.length() < w * 0.3:
		return Vector2.ZERO
	# Direção dominante
	if abs(rel.x) > abs(rel.y):
		return Vector2(sign(rel.x), 0)
	else:
		return Vector2(0, sign(rel.y))

func _apply_dpad_state() -> void:
	# Soma de todas as direções ativas (multi-touch)
	var total := Vector2.ZERO
	for dir in dpad_touches.values():
		total += dir
	left_pressed = total.x < 0
	right_pressed = total.x > 0
	up_pressed = total.y < 0
	down_pressed = total.y > 0
	dpad.queue_redraw()

# === BOTÕES DE AÇÃO (A/B) ===
func _make_action_btn(label: String, color: Color, pos: Vector2, action: String) -> Control:
	var ctrl := Control.new()
	ctrl.name = "Btn_" + label
	ctrl.position = pos
	ctrl.size = Vector2(TOUCH_BTN, TOUCH_BTN)
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.gui_input.connect(func(event): _on_action_input(event, action, label, color))
	ctrl.draw.connect(func(): _draw_action_btn(ctrl, label, color))
	add_child(ctrl)
	return ctrl

func _draw_action_btn(ctrl: Control, label: String, color: Color) -> void:
	var size: float = TOUCH_BTN
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	var radius: float = size * 0.38
	
	# Sombra
	ctrl.draw_circle(Vector2(cx + 1, cy + 1), radius, Color(0, 0, 0, 0.3))
	# Corpo
	ctrl.draw_circle(Vector2(cx, cy), radius, color)
	# Borda interna (anel)
	ctrl.draw_arc(Vector2(cx, cy), radius * 0.7, 0, TAU, 16, color.lightened(0.3), 1.0)
	# Label
	var font := ThemeDB.fallback_font
	ctrl.draw_string(font, Vector2(cx - 4, cy + 3), label, HORIZONTAL_ALIGNMENT_CENTER, 8, 8, Color.WHITE)

func _on_action_input(event: InputEvent, action: String, label: String, color: Color) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_action(action, label, color)
		else:
			_release_action(action, label, color)

func _press_action(action: String, label: String, color: Color) -> void:
	match action:
		"jump": jump_pressed = true
		"ability": ability_pressed = true
	# Feedback visual: escala menor
	var ctrl := get_node("Btn_" + label)
	if ctrl:
		ctrl.scale = Vector2(0.9, 0.9)
		ctrl.modulate = Color(1.2, 1.2, 1.2, 1.0)
	# Haptic
	_haptic(10)

func _release_action(action: String, label: String, color: Color) -> void:
	match action:
		"jump": jump_pressed = false
		"ability": ability_pressed = false
	var ctrl := get_node("Btn_" + label)
	if ctrl:
		ctrl.scale = Vector2(1.0, 1.0)
		ctrl.modulate = Color(1.0, 1.0, 1.0, 1.0)

# === START / SELECT ===
func _make_sys_btn(label: String, pos: Vector2, action: String) -> Control:
	var ctrl := Control.new()
	ctrl.name = "Btn_" + label
	ctrl.position = pos
	ctrl.size = Vector2(32, 12)
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.gui_input.connect(func(event): _on_sys_input(event, action, label))
	ctrl.draw.connect(func(): _draw_sys_btn(ctrl, label))
	add_child(ctrl)
	return ctrl

func _draw_sys_btn(ctrl: Control, label: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.28, 0.5)
	sb.border_color = COL_SYS
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	ctrl.draw_style_box(sb, Rect2(Vector2.ZERO, ctrl.size))
	var font := ThemeDB.fallback_font
	ctrl.draw_string(font, Vector2(2, 9), label, HORIZONTAL_ALIGNMENT_CENTER, ctrl.size.x - 4, 4, Color(0.8, 0.8, 0.9, 0.7))

func _on_sys_input(event: InputEvent, action: String, label: String) -> void:
	if event is InputEventScreenTouch and event.pressed:
		match action:
			"pause": _toggle_pause()
			"switch_character": switch_pressed = true
		_haptic(5)

func _toggle_pause() -> void:
	var pause_menu := get_tree().get_nodes_in_group("level")
	if pause_menu.size() > 0:
		var level = pause_menu[0]
		var pm := level.get_node_or_null("PauseMenu")
		if pm and pm.has_method("_pause"):
			pm._pause()

# === HAPTIC ===
func _haptic(_duration_ms: int) -> void:
	# Haptic feedback — no-op (API não disponível nesta versão do Godot)
	# Em builds web, poderia usar navigator.vibrate() via JavaScriptBridge
	pass

# === FEED INPUT AO INPUTMAP ===
func _process(_delta: float) -> void:
	if not is_touch_device:
		return
	_feed("move_left", left_pressed)
	_feed("move_right", right_pressed)
	_feed("move_up", up_pressed)
	_feed("move_down", down_pressed)
	_feed("jump", jump_pressed)
	_feed("ability", ability_pressed)
	_feed("switch_character", switch_pressed)
	_feed("dash", dash_pressed)
	_feed("soul_link", soul_link_pressed)

func _feed(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

# Constantes de tela (viewport 320x180)
const SCREEN_W: float = 320.0
const SCREEN_H: float = 180.0