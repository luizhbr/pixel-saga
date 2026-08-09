extends CanvasLayer
## TouchControls v2 — botões virtuais elegantes para mobile
## Estilo: circular, semi-transparente, discreto, não atrapalha o jogo

var is_touch_device: bool = false

var left_pressed: bool = false
var right_pressed: bool = false
var up_pressed: bool = false
var down_pressed: bool = false
var jump_pressed: bool = false
var switch_pressed: bool = false
var ability_pressed: bool = false
var dash_pressed: bool = false
var soul_link_pressed: bool = false

var buttons: Dictionary = {}

const SCREEN_W: float = 320.0
const SCREEN_H: float = 180.0

# Cores por tipo de botão
const COL_MOVE := Color(0.5, 0.5, 0.65, 1.0)
const COL_JUMP := Color(0.25, 0.65, 1.0, 1.0)
const COL_ABILITY := Color(0.7, 0.35, 1.0, 1.0)
const COL_DASH := Color(1.0, 0.6, 0.25, 1.0)
const COL_SWITCH := Color(0.55, 0.55, 0.75, 1.0)
const COL_SOUL := Color(0.25, 0.9, 0.55, 1.0)

func _ready() -> void:
	layer = 20
	is_touch_device = DisplayServer.is_touchscreen_available()
	if not is_touch_device and OS.has_feature("web"):
		is_touch_device = _check_mobile_browser()
	visible = is_touch_device
	if is_touch_device:
		_create_buttons()

func _check_mobile_browser() -> bool:
	# Only show touch controls on actual touch devices, not laptops
	if not DisplayServer.is_touchscreen_available():
		return false
	var screen_size := DisplayServer.screen_get_size()
	return screen_size.x <= 900 or screen_size.y <= 900

func _create_buttons() -> void:
	# === LEFT SIDE: D-pad (compacto, diagonal) ===
	buttons["left"]  = _make_btn("◀", Vector2(6, SCREEN_H - 36), 22, COL_MOVE)
	buttons["right"] = _make_btn("▶", Vector2(32, SCREEN_H - 36), 22, COL_MOVE)
	buttons["up"]    = _make_btn("▲", Vector2(19, SCREEN_H - 54), 18, COL_MOVE)
	buttons["down"]  = _make_btn("▼", Vector2(19, SCREEN_H - 18), 18, COL_MOVE)
	
	# === RIGHT SIDE: Actions (empilhados, compactos) ===
	# Jump (maior — principal)
	buttons["jump"] = _make_btn("⬆", Vector2(SCREEN_W - 32, SCREEN_H - 40), 26, COL_JUMP)
	# Ability (menor — acima do jump)
	buttons["ability"] = _make_btn("✦", Vector2(SCREEN_W - 32, SCREEN_H - 72), 20, COL_ABILITY)
	# Dash (esquerda do jump)
	buttons["dash"] = _make_btn("≫", Vector2(SCREEN_W - 58, SCREEN_H - 46), 20, COL_DASH)
	# Switch (menor — canto)
	buttons["switch"] = _make_btn("⟳", Vector2(SCREEN_W - 58, SCREEN_H - 22), 16, COL_SWITCH)
	# Soul Link (menor — isolado)
	buttons["soul_link"] = _make_btn("✚", Vector2(SCREEN_W - 84, SCREEN_H - 34), 16, COL_SOUL)

func _make_btn(label: String, pos: Vector2, size: float, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", max(5, int(size * 0.35)))
	btn.focus_mode = Control.FOCUS_NONE
	
	# Estilo normal: quase invisível, só borda
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.08, 0.15)
	sb.border_color = accent
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = int(size / 2)
	sb.corner_radius_top_right = int(size / 2)
	sb.corner_radius_bottom_left = int(size / 2)
	sb.corner_radius_bottom_right = int(size / 2)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	
	# Estilo pressionado: brilha com a cor do botão
	var sbp := StyleBoxFlat.new()
	sbp.bg_color = Color(accent.r, accent.g, accent.b, 0.35)
	sbp.border_color = accent.lightened(0.3)
	sbp.border_width_left = 1
	sbp.border_width_right = 1
	sbp.border_width_top = 1
	sbp.border_width_bottom = 1
	sbp.corner_radius_top_left = int(size / 2)
	sbp.corner_radius_top_right = int(size / 2)
	sbp.corner_radius_bottom_left = int(size / 2)
	sbp.corner_radius_bottom_right = int(size / 2)
	sbp.content_margin_left = 0
	sbp.content_margin_right = 0
	sbp.content_margin_top = 0
	sbp.content_margin_bottom = 0
	btn.add_theme_stylebox_override("pressed", sbp)
	
	# Cor do texto discreta, brilha ao pressionar
	btn.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.5))
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(accent.r, accent.g, accent.b, 0.8))
	
	add_child(btn)
	btn.button_down.connect(func(): _on_btn_down(label))
	btn.button_up.connect(func(): _on_btn_up(label))
	return btn

func _on_btn_down(label: String) -> void:
	match label:
		"◀": left_pressed = true
		"▶": right_pressed = true
		"▲": up_pressed = true
		"▼": down_pressed = true
		"⬆": jump_pressed = true
		"⟳": switch_pressed = true
		"✦": ability_pressed = true
		"≫": dash_pressed = true
		"✚": soul_link_pressed = true

func _on_btn_up(label: String) -> void:
	match label:
		"◀": left_pressed = false
		"▶": right_pressed = false
		"▲": up_pressed = false
		"▼": down_pressed = false
		"⬆": jump_pressed = false
		"⟳": switch_pressed = false
		"✦": ability_pressed = false
		"≫": dash_pressed = false
		"✚": soul_link_pressed = false

func _process(_delta: float) -> void:
	if not is_touch_device:
		return
	_feed("move_left", left_pressed)
	_feed("move_right", right_pressed)
	_feed("move_up", up_pressed)
	_feed("move_down", down_pressed)
	_feed("jump", jump_pressed)
	_feed("switch_character", switch_pressed)
	_feed("ability", ability_pressed)
	_feed("dash", dash_pressed)
	_feed("soul_link", soul_link_pressed)

func _feed(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)