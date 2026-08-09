extends CanvasLayer
## HUD — exibe vida, cristais, personagem ativo e barra de energia (spirit)

var health_icons: Array = []
var crystal_label: Label
var char_label: Label
var energy_bar: ColorRect
var energy_bg: ColorRect
var energy_label: Label

func _ready() -> void:
	layer = 10
	
	# Health hearts (top-left)
	for i in range(GameManager.MAX_HEALTH):
		var heart := ColorRect.new()
		heart.size = Vector2(12, 12)
		heart.position = Vector2(8 + i * 16, 8)
		heart.color = Color(0.9, 0.2, 0.2, 1.0)
		add_child(heart)
		health_icons.append(heart)
	
	# Energy bar (below hearts)
	energy_bg = ColorRect.new()
	energy_bg.size = Vector2(60, 4)
	energy_bg.position = Vector2(8, 24)
	energy_bg.color = Color(0.15, 0.15, 0.2, 0.8)
	add_child(energy_bg)
	
	energy_bar = ColorRect.new()
	energy_bar.size = Vector2(30, 4)
	energy_bar.position = Vector2(8, 24)
	energy_bar.color = Color(0.3, 0.9, 1.0, 1.0)
	add_child(energy_bar)
	
	energy_label = Label.new()
	energy_label.position = Vector2(8, 28)
	energy_label.text = "E"
	energy_label.add_theme_font_size_override("font_size", 4)
	energy_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	add_child(energy_label)
	
	# Crystals (top-right)
	crystal_label = Label.new()
	crystal_label.position = Vector2(270, 6)
	crystal_label.text = "◆ 0"
	crystal_label.add_theme_font_size_override("font_size", 6)
	crystal_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	add_child(crystal_label)
	
	# Character name (bottom-left)
	char_label = Label.new()
	char_label.position = Vector2(8, 160)
	char_label.text = GameManager.CHAR_NAMES[GameManager.current_character]
	char_label.add_theme_font_size_override("font_size", 6)
	char_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	add_child(char_label)
	
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.crystals_changed.connect(_on_crystals_changed)
	GameManager.character_changed.connect(_on_character_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.ability_unlocked.connect(_on_ability_unlocked)

func _on_health_changed(new_hp: int, max_hp: int) -> void:
	for i in range(max_hp):
		if i < health_icons.size():
			health_icons[i].color = Color(0.9, 0.2, 0.2, 1.0) if i < new_hp else Color(0.2, 0.1, 0.1, 0.4)

func _on_crystals_changed(amount: int) -> void:
	crystal_label.text = "◆ %d" % amount

func _on_character_changed(idx: int) -> void:
	char_label.text = GameManager.CHAR_NAMES[idx]

func _on_energy_changed(new_energy: float, max_energy: float) -> void:
	var ratio: float = new_energy / max_energy
	energy_bar.size.x = 60.0 * ratio
	# Color shift: blue (full) → purple (low)
	if ratio > 0.5:
		energy_bar.color = Color(0.3, 0.9, 1.0, 1.0)
	elif ratio > 0.25:
		energy_bar.color = Color(0.5, 0.5, 1.0, 1.0)
	else:
		energy_bar.color = Color(0.8, 0.3, 0.5, 1.0)

func _on_ability_unlocked(ability_name: String) -> void:
	# Show unlock notification
	var notif := Label.new()
	notif.text = "Habilidade: %s!" % ability_name
	notif.position = Vector2(80, 70)
	notif.add_theme_font_size_override("font_size", 6)
	notif.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	add_child(notif)
	
	# Fade out
	var tw := create_tween()
	tw.tween_property(notif, "modulate:a", 0.0, 2.0)
	tw.tween_callback(notif.queue_free)