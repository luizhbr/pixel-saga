extends Node2D
## LevelBase — classe base para todos os níveis
## Gerencia plataformas, inimigos, cristais, checkpoints, background, juice

const GRAVITY: float = 800.0

var tile_layer: Node2D
var bg_layer: Node2D
var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var enemies: Array = []
var crystals: Array = []
var checkpoints: Array = []

# Screen shake
var shake_amount: float = 0.0
var shake_timer: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO

# Particles
var particle_layer: Node2D

@export var bg_far: String = "res://assets/backgrounds/bg_cyberpunk_far.png"
@export var bg_mid: String = "res://assets/backgrounds/bg_cyberpunk_mid.png"
@export var bg_near: String = "res://assets/backgrounds/bg_cyberpunk_near.png"
@export var bg_scale: float = 1.5

# Platform colors
const PLAT_COLORS: Dictionary = {
	"stone": Color(0.55, 0.55, 0.59, 1.0),
	"grass": Color(0.35, 0.63, 0.24, 1.0),
	"metal": Color(0.35, 0.37, 0.41, 1.0),
	"wood": Color(0.63, 0.43, 0.24, 1.0),
	"ice": Color(0.63, 0.82, 1.0, 1.0),
}
const PLAT_HIGHLIGHT: Dictionary = {
	"stone": Color(0.67, 0.67, 0.71, 1.0),
	"grass": Color(0.47, 0.78, 0.31, 1.0),
	"metal": Color(0.51, 0.53, 0.57, 1.0),
	"wood": Color(0.75, 0.55, 0.31, 1.0),
	"ice": Color(0.78, 0.94, 1.0, 1.0),
}

func _ready() -> void:
	tile_layer = Node2D.new()
	tile_layer.name = "Tiles"
	add_child(tile_layer)
	
	bg_layer = Node2D.new()
	bg_layer.name = "Background"
	bg_layer.z_index = -10
	add_child(bg_layer)
	
	particle_layer = Node2D.new()
	particle_layer.name = "Particles"
	add_child(particle_layer)
	
	_create_background()
	_create_platforms()
	_create_enemies()
	_create_crystals()
	_create_checkpoints()
	_create_player()
	_create_hud()
	_create_danger_zone()
	
	GameManager.player_died.connect(_on_player_died)
	set_process(true)

func _create_background() -> void:
	var far_tex := load(bg_far)
	if far_tex:
		var bg := Sprite2D.new()
		bg.texture = far_tex
		bg.centered = false
		bg.position = Vector2(-50, -20)
		bg.scale = Vector2(bg_scale, bg_scale)
		bg.modulate = Color(0.6, 0.6, 0.6, 1.0)
		bg.z_index = -10
		bg_layer.add_child(bg)
	
	var mid_tex := load(bg_mid)
	if mid_tex:
		var bg2 := Sprite2D.new()
		bg2.texture = mid_tex
		bg2.centered = false
		bg2.position = Vector2(-30, -10)
		bg2.scale = Vector2(bg_scale, bg_scale)
		bg2.z_index = -9
		bg_layer.add_child(bg2)
	
	var near_tex := load(bg_near)
	if near_tex:
		var bg3 := Sprite2D.new()
		bg3.texture = near_tex
		bg3.centered = false
		bg3.position = Vector2(-20, 0)
		bg3.scale = Vector2(bg_scale, bg_scale)
		bg3.z_index = -8
		bg_layer.add_child(bg3)

func _create_platforms() -> void:
	for p in get_platforms():
		var x: int = p[0]
		var y: int = p[1]
		var w: int = p[2]
		var h: int = p[3]
		var type: String = p[4]
		
		var body := StaticBody2D.new()
		body.position = Vector2(x + w / 2.0, y + h / 2.0)
		
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(w, h)
		col.shape = rect
		body.add_child(col)
		
		var vis := ColorRect.new()
		vis.size = Vector2(w, h)
		vis.position = Vector2(-w / 2.0, -h / 2.0)
		vis.color = PLAT_COLORS.get(type, Color(0.5, 0.5, 0.5, 1.0))
		body.add_child(vis)
		
		var top := ColorRect.new()
		top.size = Vector2(w, 2)
		top.position = Vector2(-w / 2.0, -h / 2.0)
		top.color = PLAT_HIGHLIGHT.get(type, Color(0.7, 0.7, 0.7, 1.0))
		body.add_child(top)
		
		tile_layer.add_child(body)

func _create_enemies() -> void:
	for enemy_data in get_enemy_positions():
		var enemy := CharacterBody2D.new()
		enemy.set_script(load("res://scripts/EnemyBase.gd"))
		enemy.global_position = Vector2(enemy_data[0], enemy_data[1])
		# Set type if provided
		if enemy_data.size() > 2:
			enemy.set("type", enemy_data[2])
		if enemy_data.size() > 3:
			enemy.set("patrol_distance", enemy_data[3])
		enemy.collision_layer = 2
		enemy.collision_mask = 1
		add_child(enemy)
		enemies.append(enemy)

func _create_crystals() -> void:
	for pos in get_crystal_positions():
		var crystal := Area2D.new()
		crystal.set_script(load("res://scripts/Crystal.gd"))
		crystal.global_position = Vector2(pos[0], pos[1])
		add_child(crystal)
		crystals.append(crystal)

func _create_checkpoints() -> void:
	var cp_positions := get_checkpoint_positions()
	for i in range(cp_positions.size()):
		var cp := Node2D.new()
		cp.set_script(load("res://scripts/Checkpoint.gd"))
		cp.set("checkpoint_id", i)
		cp.global_position = Vector2(cp_positions[i][0], cp_positions[i][1])
		add_child(cp)
		checkpoints.append(cp)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/Player.gd"))
	player.add_to_group("player")
	var start := get_player_start()
	player.global_position = start
	
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 20.0
	col.shape = shape
	player.add_child(col)
	add_child(player)
	
	# Set level reference so Player can call level methods
	player.set("level", self)
	
	# Camera com screen shake
	camera = Camera2D.new()
	camera.set_script(load("res://scripts/SmoothCamera.gd"))
	camera.zoom = Vector2(1, 1)
	player.add_child(camera)

func _create_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/HUD.gd"))
	add_child(hud)
	# Touch controls (auto-shows on mobile, hidden on desktop)
	var touch := CanvasLayer.new()
	touch.set_script(load("res://scripts/TouchControls.gd"))
	add_child(touch)
	# Pause menu
	var pause := CanvasLayer.new()
	pause.set_script(load("res://scripts/PauseMenu.gd"))
	pause.name = "PauseMenu"
	add_child(pause)
	add_to_group("level")

func _create_danger_zone() -> void:
	# Danger zone — large area below the level
	var danger_zone := Area2D.new()
	danger_zone.name = "DangerZone"
	var dcol := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(2000, 60)
	dcol.shape = drect
	danger_zone.add_child(dcol)
	danger_zone.position = Vector2(500, 350)
	danger_zone.collision_mask = 4
	add_child(danger_zone)
	danger_zone.body_entered.connect(func(body):
		if body.is_in_group("player"):
			body.take_damage()
			body._respawn()
			screen_shake(8.0, 0.3)
	)
	
	# Level exit portal
	var exit_portal := Area2D.new()
	exit_portal.name = "ExitPortal"
	var ecol := CollisionShape2D.new()
	var erect := RectangleShape2D.new()
	erect.size = Vector2(16, 20)
	ecol.shape = erect
	exit_portal.add_child(ecol)
	exit_portal.global_position = get_exit_position()
	add_child(exit_portal)
	
	# Portal visual
	var portal_visual := ColorRect.new()
	portal_visual.size = Vector2(10, 16)
	portal_visual.position = Vector2(-5, -8)
	portal_visual.color = Color(0.2, 1.0, 0.5, 0.6)
	exit_portal.add_child(portal_visual)
	
	exit_portal.body_entered.connect(func(body):
		if body.is_in_group("player"):
			AudioManager.play("checkpoint")
			_next_level()
	)

func _process(_delta: float) -> void:
	# Enemy collision
	for enemy in enemies:
		if is_instance_valid(enemy) and is_instance_valid(player):
			var dist := player.global_position.distance_to(enemy.global_position)
			if dist < 16.0:
				if player.velocity.y > 0 and player.global_position.y < enemy.global_position.y - 4:
					enemy.queue_free()
					enemies.erase(enemy)
					player.velocity.y = -200.0
					spawn_particles(player.global_position + Vector2(0, 8), Color(0.7, 0.2, 0.8), 8)
					screen_shake(3.0, 0.15)
					play_sfx("stomp")
				else:
					if player.take_damage():
						screen_shake(5.0, 0.25)
						spawn_particles(player.global_position, Color(1.0, 0.3, 0.3), 6)
						play_sfx("hit")
	
	# Screen shake
	if shake_timer > 0:
		shake_timer -= _delta
		shake_amount *= 0.9
		camera_offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		if camera:
			camera.offset = camera_offset
	else:
		shake_amount = 0.0
		if camera:
			camera.offset = camera_offset.lerp(Vector2.ZERO, 0.2)
	
	# Particles update
	for child in particle_layer.get_children():
		var p = child
		p["lifetime"] -= _delta
		if p["lifetime"] <= 0:
			p.queue_free()
		else:
			var vel: Vector2 = p["velocity"]
			vel.y += 200.0 * _delta
			p["velocity"] = vel
			p.position += vel * _delta
			p.modulate.a = max(0.0, p["lifetime"] / p["max_lifetime"])

func screen_shake(amount: float, duration: float) -> void:
	shake_amount = max(shake_amount, amount)
	shake_timer = max(shake_timer, duration)

func spawn_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var p := ColorRect.new()
		p.size = Vector2(2, 2)
		p.position = pos
		p.color = color
		var angle := randf() * TAU
		var speed := randf_range(30.0, 100.0)
		p.set("velocity", Vector2(cos(angle) * speed, sin(angle) * speed - 50.0))
		p.set("lifetime", randf_range(0.3, 0.6))
		p.set("max_lifetime", p["lifetime"])
		particle_layer.add_child(p)

func play_sfx(name: String) -> void:
	AudioManager.play(name)

func _on_player_died() -> void:
	# Show game over screen
	var pause_menu := get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("show_game_over"):
		pause_menu.show_game_over()
	screen_shake(10.0, 0.5)
	AudioManager.play("hit")

func get_respawn_position() -> Vector2:
	var cp_pos: Variant = GameManager.get_meta("checkpoint_pos", get_player_start())
	return cp_pos

# Override these in child levels
func get_platforms() -> Array:
	return []

func get_enemy_positions() -> Array:
	return []

func get_crystal_positions() -> Array:
	return []

func get_checkpoint_positions() -> Array:
	return []

func get_player_start() -> Vector2:
	return Vector2(40, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)

func _next_level() -> void:
	GameManager.current_level += 1
	var levels := [
		"res://scenes/Level1.tscn",
		"res://scenes/Level2.tscn",
		"res://scenes/Level3.tscn",
	]
	var level_names := [
		"Beco Cyberpunk",
		"Vila Japonesa",
		"Pântano do Rosto Gigante",
	]
	if GameManager.current_level < levels.size():
		var text: String = level_names[GameManager.current_level] if GameManager.current_level < level_names.size() else ""
		SceneTransition.transition_to_scene(levels[GameManager.current_level], text)
	else:
		GameManager.reset()
		SceneTransition.transition_to_scene("res://scenes/MainMenu.tscn", "FIM")