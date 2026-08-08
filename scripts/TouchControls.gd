extends CanvasLayer
## TouchControls — botões virtuais para mobile (com mecânicas Ori)
## Alimenta o InputMap do Godot

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

const BTN_ALPHA: float = 0.35
const BTN_ALPHA_PRESSED: float = 0.6
const SCREEN_W: float = 320.0
const SCREEN_H: float = 180.0

func _ready() -> void:
	layer = 20
	is_touch_device = DisplayServer.is_touchscreen_available()
	if not is_touch_device and OS.has_feature("web"):
		is_touch_device = _check_mobile_browser()
	visible = is_touch_device
	if is_touch_device:
		_create_buttons()

func _check_mobile_browser() -> bool:
	var screen_size := DisplayServer.screen_get_size()
	return screen_size.x <= 900 or screen_size.y <= 900

func _create_buttons() -> void:
	# Left side: D-pad
	buttons["left"] = _make_button("◀", Vector2(8, SCREEN_H - 50), 32)
	buttons["right"] = _make_button("▶", Vector2(44, SCREEN_H - 50), 32)
	buttons["up"] = _make_button("▲", Vector2(26, SCREEN_H - 82), 28, Color(0.3, 0.8, 0.3))
	buttons["down"] = _make_button("▼", Vector2(26, SCREEN_H - 18), 28, Color(0.3, 0.8, 0.3))
	
	# Right side: Actions
	buttons["jump"] = _make_button("J", Vector2(SCREEN_W - 42, SCREEN_H - 50), 36, Color(0.2, 0.6, 1.0))
	buttons["ability"] = _make_button("✦", Vector2(SCREEN_W - 42, SCREEN_H - 90), 28, Color(0.8, 0.3, 1.0))
	buttons["dash"] = _make_button(">>", Vector2(SCREEN_W - 78, SCREEN_H - 70), 28, Color(1.0, 0.6, 0.2))
	buttons["switch"] = _make_button("⟳", Vector2(SCREEN_W - 78, SCREEN_H - 40), 24, Color(0.6, 0.6, 0.8))
	buttons["soul_link"] = _make_button("S", Vector2(SCREEN_W - 110, SCREEN_H - 55), 24, Color(0.2, 0.9, 0.5))

func _make_button(label: String, pos: Vector2, size: float, accent: Color = Color(0.4, 0.4, 0.5, 1.0)) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", max(4, int(size * 0.3)))
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, BTN_ALPHA)
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
	sbp.bg_color.a = BTN_ALPHA_PRESSED
	btn.add_theme_stylebox_override("pressed", sbp)
	btn.add_theme_color_override("font_color", accent.lightened(0.3))
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
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
		"J": jump_pressed = true
		"⟳": switch_pressed = true
		"✦": ability_pressed = true
		">>": dash_pressed = true
		"S": soul_link_pressed = true

func _on_btn_up(label: String) -> void:
	match label:
		"◀": left_pressed = false
		"▶": right_pressed = false
		"▲": up_pressed = false
		"▼": down_pressed = false
		"J": jump_pressed = false
		"⟳": switch_pressed = false
		"✦": ability_pressed = false
		">>": dash_pressed = false
		"S": soul_link_pressed = false

func _process(_delta: float) -> void:
	if not is_touch_device:
		return
	_feed_action("move_left", left_pressed)
	_feed_action("move_right", right_pressed)
	_feed_action("move_up", up_pressed)
	_feed_action("move_down", down_pressed)
	_feed_action("jump", jump_pressed)
	_feed_action("switch_character", switch_pressed)
	_feed_action("ability", ability_pressed)
	_feed_action("dash", dash_pressed)
	_feed_action("soul_link", soul_link_pressed)

func _feed_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)