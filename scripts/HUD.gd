extends CanvasLayer
## HUD — exibe vida, cristais e personagem ativo

var health_icons: Array = []
var crystal_label: Label
var char_label: Label

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
	
	# Crystals (top-right)
	crystal_label = Label.new()
	crystal_label.position = Vector2(280, 6)
	crystal_label.text = "Cristais: 0"
	crystal_label.add_theme_font_size_override("font_size", 6)
	add_child(crystal_label)
	
	# Character name (bottom-left)
	char_label = Label.new()
	char_label.position = Vector2(8, 160)
	char_label.text = "Mossy"
	char_label.add_theme_font_size_override("font_size", 6)
	add_child(char_label)
	
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.crystals_changed.connect(_on_crystals_changed)
	GameManager.character_changed.connect(_on_character_changed)

func _on_health_changed(new_hp: int, max_hp: int) -> void:
	for i in range(max_hp):
		if i < health_icons.size():
			health_icons[i].color = Color(0.9, 0.2, 0.2, 1.0) if i < new_hp else Color(0.2, 0.1, 0.1, 0.4)

func _on_crystals_changed(amount: int) -> void:
	crystal_label.text = "Cristais: %d" % amount

func _on_character_changed(idx: int) -> void:
	char_label.text = GameManager.CHAR_NAMES[idx]