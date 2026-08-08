extends Node2D
## Main / Test Level — cena de teste do protótipo
## Cria tudo via código: plataformas, inimigos, cristais, checkpoints

var tile_layer: Node2D
var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var enemies: Array = []
var crystals: Array = []
var checkpoints: Array = []

# Level layout — simple test level
# Each platform: [x, y, w, h, type]
const PLATFORMS: Array = [
	[0, 160, 320, 40, "stone"],     # Ground
	[60, 130, 60, 10, "grass"],     # Platform 1
	[140, 110, 50, 10, "wood"],     # Platform 2
	[210, 90, 50, 10, "metal"],     # Platform 3
	[280, 120, 40, 10, "grass"],   # Platform 4
	[100, 70, 40, 10, "wood"],      # Platform 5 (high)
	[180, 50, 40, 10, "ice"],      # Platform 6 (ice)
]

const ENEMY_POSITIONS: Array = [
	[80, 145],
	[220, 100],
	[300, 140],
]

const CRYSTAL_POSITIONS: Array = [
	[90, 115],
	[165, 95],
	[235, 75],
	[120, 55],
]

const CHECKPOINT_POSITIONS: Array = [
	[120, 140],
	[250, 100],
]

func _ready() -> void:
	# Create tile layer
	tile_layer = Node2D.new()
	tile_layer.name = "Tiles"
	add_child(tile_layer)
	_create_platforms()
	_create_background()
	
	# Player
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/Player.gd"))
	player.add_to_group("player")
	player.global_position = Vector2(40, 140)
	
	# Player collision
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 20.0
	col.shape = shape
	player.add_child(col)
	add_child(player)
	
	# Camera
	var cam_script := load("res://scripts/SmoothCamera.gd")
	camera = Camera2D.new()
	camera.set_script(cam_script)
	camera.zoom = Vector2(1, 1)
	player.add_child(camera)
	
	# Enemies
	for pos in ENEMY_POSITIONS:
		var enemy := CharacterBody2D.new()
		enemy.set_script(load("res://scripts/Enemy.gd"))
		enemy.global_position = Vector2(pos[0], pos[1])
		enemy.add_to_group("enemy")
		# Collision layer
		enemy.collision_layer = 2
		enemy.collision_mask = 1
		add_child(enemy)
		enemies.append(enemy)
	
	# Crystals
	for pos in CRYSTAL_POSITIONS:
		var crystal := Area2D.new()
		crystal.set_script(load("res://scripts/Crystal.gd"))
		crystal.global_position = Vector2(pos[0], pos[1])
		add_child(crystal)
		crystals.append(crystal)
	
	# Checkpoints
	for i in range(CHECKPOINT_POSITIONS.size()):
		var cp := Node2D.new()
		cp.set_script(load("res://scripts/Checkpoint.gd"))
		cp.set("checkpoint_id", i)
		cp.global_position = Vector2(CHECKPOINT_POSITIONS[i][0], CHECKPOINT_POSITIONS[i][1])
		add_child(cp)
		checkpoints.append(cp)
	
	# HUD
	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/HUD.gd"))
	add_child(hud)
	
	# Death signal
	GameManager.player_died.connect(_on_player_died)
	
	# Damage zone (bottom of screen)
	var danger_zone := Area2D.new()
	danger_zone.name = "DangerZone"
	var dcol := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(400, 20)
	dcol.shape = drect
	danger_zone.add_child(dcol)
	danger_zone.position = Vector2(160, 200)
	danger_zone.collision_mask = 4
	add_child(danger_zone)
	danger_zone.body_entered.connect(func(body):
		if body.is_in_group("player"):
			body.take_damage()
			body.global_position = Vector2(40, 140)
	)
	
	# Player-enemy collision detection
	set_process(true)

func _process(_delta: float) -> void:
	# Check enemy collisions
	for enemy in enemies:
		if is_instance_valid(enemy) and is_instance_valid(player):
			var dist := player.global_position.distance_to(enemy.global_position)
			if dist < 16.0:
				# Stomp from above
				if player.velocity.y > 0 and player.global_position.y < enemy.global_position.y - 4:
					enemy.queue_free()
					enemies.erase(enemy)
					player.velocity.y = -200.0
				else:
					player.take_damage()

func _create_platforms() -> void:
	for p in PLATFORMS:
		var x: int = p[0]
		var y: int = p[1]
		var w: int = p[2]
		var h: int = p[3]
		
		# StaticBody2D for collision
		var body := StaticBody2D.new()
		body.position = Vector2(x + w / 2.0, y + h / 2.0)
		
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(w, h)
		col.shape = rect
		body.add_child(col)
		
		# Visual
		var colors: Dictionary = {
			"stone": Color(0.55, 0.55, 0.59, 1.0),
			"grass": Color(0.35, 0.63, 0.24, 1.0),
			"metal": Color(0.35, 0.37, 0.41, 1.0),
			"wood": Color(0.63, 0.43, 0.24, 1.0),
			"ice": Color(0.63, 0.82, 1.0, 1.0),
		}
		var vis := ColorRect.new()
		vis.size = Vector2(w, h)
		vis.position = Vector2(-w / 2.0, -h / 2.0)
		vis.color = colors.get(p[4], Color(0.5, 0.5, 0.5, 1.0))
		body.add_child(vis)
		
		# Top highlight
		var top := ColorRect.new()
		top.size = Vector2(w, 2)
		top.position = Vector2(-w / 2.0, -h / 2.0)
		var highlight: Dictionary = {
			"stone": Color(0.67, 0.67, 0.71, 1.0),
			"grass": Color(0.47, 0.78, 0.31, 1.0),
			"metal": Color(0.51, 0.53, 0.57, 1.0),
			"wood": Color(0.75, 0.55, 0.31, 1.0),
			"ice": Color(0.78, 0.94, 1.0, 1.0),
		}
		top.color = highlight.get(p[4], Color(0.7, 0.7, 0.7, 1.0))
		body.add_child(top)
		
		tile_layer.add_child(body)

func _create_background() -> void:
	# Parallax background using the cyberpunk bg
	var bg_tex := load("res://assets/backgrounds/bg_cyberpunk_far.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex
		bg.centered = false
		bg.position = Vector2(-50, -20)
		bg.scale = Vector2(1.5, 1.5)
		bg.modulate = Color(0.6, 0.6, 0.6, 1.0)  # Dimmed far layer
		add_child(bg)
		# Move behind everything
		bg.z_index = -10
		
		var bg_mid_tex := load("res://assets/backgrounds/bg_cyberpunk_mid.png")
		if bg_mid_tex:
			var bg_mid := Sprite2D.new()
			bg_mid.texture = bg_mid_tex
			bg_mid.centered = false
			bg_mid.position = Vector2(-30, -10)
			bg_mid.scale = Vector2(1.5, 1.5)
			bg_mid.z_index = -9
			add_child(bg_mid)

func _on_player_died() -> void:
	# Respawn at checkpoint
	var cp_pos: Variant = GameManager.get_meta("checkpoint_pos", Vector2(40, 140))
	player.global_position = cp_pos
	GameManager.heal(GameManager.MAX_HEALTH)