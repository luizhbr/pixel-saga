extends CharacterBody2D
## Boss — estrutura reutilizável para chefes
## Fases: 3 (100-66% HP, 66-33% HP, 33-0% HP)
## Padrões de ataque com telegrafia, invulnerabilidade temporária, screen shake, sons

signal boss_defeated
signal boss_health_changed(hp: int, max_hp: int)
signal boss_phase_changed(phase: int)

enum Attack { CHARGE, PROJECTILE_SPREAD, GROUND_POUND, DASH_SLASH }
enum Phase { ONE, TWO, THREE }

@export var max_health: int = 10
@export var speed: float = 60.0
@export var detect_range: float = 200.0

var health: int = 10
var current_phase: Phase = Phase.ONE
var is_attacking: bool = false
var is_invulnerable: bool = false
var attack_timer: float = 2.0
var telegraph_timer: float = 0.0
var current_attack: Attack = Attack.CHARGE
var hit_flash_timer: float = 0.0
var is_dead: bool = false
var player_ref: CharacterBody2D
var start_pos: Vector2
var direction: float = -1.0

var sprite: ColorRect
var health_bar_bg: ColorRect
var health_bar: ColorRect
var health_bar_label: Label
var telegraph_visual: ColorRect

const GRAVITY: float = 800.0
const TELEGRAPH_TIME: float = 0.6
const ATTACK_COOLDOWN: float = 1.5
const CHARGE_SPEED: float = 200.0
const PROJECTILE_SPEED: float = 180.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	health = max_health
	start_pos = global_position
	_create_visual()
	_create_health_bar()
	_create_telegraph()
	_find_player()

func _create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = Vector2(24, 28)
	sprite.position = Vector2(-12, -14)
	sprite.color = Color(0.6, 0.15, 0.2, 1.0)  # Dark red boss
	add_child(sprite)
	
	# Outline
	var outline := ColorRect.new()
	outline.size = Vector2(26, 30)
	outline.position = Vector2(-13, -15)
	outline.color = Color(0.2, 0.05, 0.08, 0.5)
	add_child(outline)
	move_child(outline, 0)
	
	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 24)
	col.shape = shape
	add_child(col)

func _create_health_bar() -> void:
	# Boss health bar at top of screen
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(200, 6)
	health_bar_bg.position = Vector2(-100, -30)
	health_bar_bg.color = Color(0.2, 0.05, 0.05, 0.8)
	add_child(health_bar_bg)
	
	health_bar = ColorRect.new()
	health_bar.size = Vector2(200, 6)
	health_bar.position = Vector2(-100, -30)
	health_bar.color = Color(0.8, 0.2, 0.2, 1.0)
	add_child(health_bar)
	
	health_bar_label = Label.new()
	health_bar_label.position = Vector2(-30, -42)
	health_bar_label.size = Vector2(60, 8)
	health_bar_label.text = "CHEFE"
	health_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_bar_label.add_theme_font_size_override("font_size", 5)
	health_bar_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	add_child(health_bar_label)

func _create_telegraph() -> void:
	telegraph_visual = ColorRect.new()
	telegraph_visual.size = Vector2(30, 30)
	telegraph_visual.position = Vector2(-15, -15)
	telegraph_visual.color = Color(1.0, 0.8, 0.0, 0.0)
	telegraph_visual.visible = false
	add_child(telegraph_visual)

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_instance_valid(player_ref):
		_find_player()
		return
	
	# Hit flash
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		sprite.modulate = Color.WHITE if int(hit_flash_timer * 20) % 2 == 0 else Color(1.0, 0.5, 0.5)
	else:
		sprite.modulate = Color.WHITE
	
	# Telegraph
	if telegraph_timer > 0:
		telegraph_timer -= delta
		telegraph_visual.visible = true
		telegraph_visual.color.a = 0.3 + sin(telegraph_timer * 20) * 0.2
		if telegraph_timer <= 0:
			telegraph_visual.visible = false
			_execute_attack()
		return
	
	# Attack timer
	if is_attacking:
		return
	
	attack_timer -= delta
	if attack_timer <= 0:
		_choose_attack()
	
	# Movement: hover near player
	velocity.y = min(velocity.y + GRAVITY * delta, 300.0)
	var to_player := player_ref.global_position - global_position
	if abs(to_player.x) > 40:
		velocity.x = sign(to_player.x) * speed * 0.5
		direction = sign(to_player.x)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 0.2)
	
	sprite.flip_h = direction > 0
	
	move_and_slide()
	
	# Update health bar
	health_bar.size.x = 200.0 * (float(health) / float(max_health))

func _choose_attack() -> void:
	var attacks: Array
	match current_phase:
		Phase.ONE:
			attacks = [Attack.CHARGE, Attack.PROJECTILE_SPREAD]
		Phase.TWO:
			attacks = [Attack.CHARGE, Attack.PROJECTILE_SPREAD, Attack.GROUND_POUND]
		Phase.THREE:
			attacks = [Attack.CHARGE, Attack.PROJECTILE_SPREAD, Attack.GROUND_POUND, Attack.DASH_SLASH]
	
	current_attack = attacks[randi() % attacks.size()]
	
	# Telegraph
	telegraph_timer = TELEGRAPH_TIME
	is_attacking = true
	
	var telegraph_colors: Dictionary = {
		Attack.CHARGE: Color(1.0, 0.3, 0.0, 0.5),
		Attack.PROJECTILE_SPREAD: Color(1.0, 0.8, 0.0, 0.5),
		Attack.GROUND_POUND: Color(0.8, 0.0, 0.5, 0.5),
		Attack.DASH_SLASH: Color(0.0, 0.5, 1.0, 0.5),
	}
	telegraph_visual.color = telegraph_colors[current_attack]
	
	AudioManager.play("menu_move")  # Warning sound

func _execute_attack() -> void:
	match current_attack:
		Attack.CHARGE: _attack_charge()
		Attack.PROJECTILE_SPREAD: _attack_projectile_spread()
		Attack.GROUND_POUND: _attack_ground_pound()
		Attack.DASH_SLASH: _attack_dash_slash()

func _attack_charge() -> void:
	var to_player := player_ref.global_position - global_position
	velocity = to_player.normalized() * CHARGE_SPEED
	await get_tree().create_timer(0.3).timeout
	velocity = Vector2.ZERO
	_end_attack()

func _attack_projectile_spread() -> void:
	var count := 3 if current_phase == Phase.ONE else 5
	var spread := PI / 4.0
	var to_player := (player_ref.global_position - global_position).normalized()
	var base_angle := to_player.angle()
	
	for i in count:
		var angle: float = base_angle + lerp(-spread, spread, float(i) / max(1, count - 1))
		var dir := Vector2(cos(angle), sin(angle))
		_spawn_boss_projectile(dir)
	
	await get_tree().create_timer(0.2).timeout
	_end_attack()

func _attack_ground_pound() -> void:
	# Jump up then slam down
	velocity.y = -300.0
	await get_tree().create_timer(0.4).timeout
	velocity.y = 400.0
	# Shake on landing
	await get_tree().create_timer(0.3).timeout
	# Screen shake
	var level := get_parent()
	if level and level.has_method("screen_shake"):
		level.screen_shake(6.0, 0.4)
	AudioManager.play("boss_hit")
	_end_attack()

func _attack_dash_slash() -> void:
	var to_player := player_ref.global_position - global_position
	velocity = to_player.normalized() * CHARGE_SPEED * 1.5
	await get_tree().create_timer(0.25).timeout
	velocity = Vector2.ZERO
	_end_attack()

func _end_attack() -> void:
	is_attacking = false
	is_invulnerable = false
	attack_timer = ATTACK_COOLDOWN + randf() * 0.5

func _spawn_boss_projectile(dir: Vector2) -> void:
	var proj := Area2D.new()
	proj.add_to_group("enemy_projectile")
	proj.add_to_group("projectile")
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	proj.add_child(col)
	
	var vis := ColorRect.new()
	vis.size = Vector2(6, 6)
	vis.position = Vector2(-3, -3)
	vis.color = Color(1.0, 0.3, 0.1, 0.9)
	proj.add_child(vis)
	
	proj.set_script(load("res://scripts/EnemyProjectile.gd"))
	proj.set("direction", dir)
	proj.set("speed", PROJECTILE_SPEED)
	proj.global_position = global_position
	get_parent().add_child(proj)

func take_damage_from_flame(dmg: int) -> void:
	if is_invulnerable or is_dead:
		return
	health -= dmg
	hit_flash_timer = 0.2
	boss_health_changed.emit(health, max_health)
	_check_phase()
	if health <= 0:
		_die()

func bash_launch(dir: Vector2, force: float) -> void:
	if is_invulnerable or is_dead:
		return
	velocity = dir * force * 0.5  # Boss is heavy
	health -= 1
	hit_flash_timer = 0.3
	boss_health_changed.emit(health, max_health)
	_check_phase()
	if health <= 0:
		_die()

func stomp_kill() -> void:
	# Boss takes 1 damage from stomps but isn't one-shot killed
	take_damage_from_flame(1)

func _check_phase() -> void:
	var hp_ratio := float(health) / float(max_health)
	var new_phase: Phase
	if hp_ratio > 0.66:
		new_phase = Phase.ONE
	elif hp_ratio > 0.33:
		new_phase = Phase.TWO
	else:
		new_phase = Phase.THREE
	
	if new_phase != current_phase:
		current_phase = new_phase
		boss_phase_changed.emit(current_phase)
		is_invulnerable = true
		# Brief invulnerability + effect on phase change
		var level := get_parent()
		if level and level.has_method("screen_shake"):
			level.screen_shake(5.0, 0.5)
		if level and level.has_method("spawn_particles"):
			level.spawn_particles(global_position, Color(1.0, 0.4, 0.4), 12)
		AudioManager.play("boss_hit")
		await get_tree().create_timer(0.5).timeout
		is_invulnerable = false

func _die() -> void:
	is_dead = true
	boss_defeated.emit()
	AudioManager.play("stomp")
	# Explosion particles
	var level := get_parent()
	if level and level.has_method("spawn_particles"):
		for _i in range(3):
			level.spawn_particles(global_position, Color(1.0, 0.3, 0.2), 10)
			await get_tree().create_timer(0.1).timeout
	if level and level.has_method("screen_shake"):
		level.screen_shake(12.0, 0.6)
	# Drop reward: restore health + energy
	GameManager.heal(1)
	GameManager.add_energy(5.0)
	AudioManager.play("checkpoint")
	queue_free()