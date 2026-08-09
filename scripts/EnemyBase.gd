extends CharacterBody2D
## EnemyBase — classe base para todos os inimigos
## Tipos: walker, jumper, flyer, chaser, shooter, tank, ambusher, shield

enum Type { WALKER, JUMPER, FLYER, CHASER, SHOOTER, TANK, AMBUSHER, SHIELD }

@export var type: Type = Type.WALKER
@export var patrol_distance: float = 80.0
@export var max_health: int = 1
@export var speed: float = 50.0
@export var damage: int = 1
@export var detect_range: float = 100.0

var health: int = 1
var direction: float = -1.0
var start_pos: Vector2
var sprite: ColorRect
var is_dead: bool = false
var hit_flash_timer: float = 0.0
var shoot_timer: float = 0.0
var jump_timer: float = 0.0
var ambush_revealed: bool = false
var player_ref: CharacterBody2D

const GRAVITY: float = 800.0
const SHOOT_INTERVAL: float = 2.0
const JUMP_INTERVAL: float = 1.5
const JUMP_VELOCITY: float = -200.0
const PROJECTILE_SPEED: float = 150.0

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	start_pos = global_position
	_create_visual()
	_create_collision()
	_find_player()

func _create_collision() -> void:
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12, 12)
		col.shape = shape
		add_child(col)

func _create_visual() -> void:
	# Different colors per type
	var colors: Dictionary = {
		Type.WALKER: Color(0.5, 0.2, 0.6, 1.0),     # Purple slime
		Type.JUMPER: Color(0.8, 0.3, 0.2, 1.0),      # Red frog
		Type.FLYER: Color(0.3, 0.6, 0.9, 1.0),       # Blue bird
		Type.CHASER: Color(0.9, 0.2, 0.3, 1.0),      # Red beast
		Type.SHOOTER: Color(0.9, 0.7, 0.2, 1.0),     # Yellow turret
		Type.TANK: Color(0.4, 0.4, 0.5, 1.0),        # Gray heavy
		Type.AMBUSHER: Color(0.2, 0.7, 0.3, 1.0),    # Green lurker
		Type.SHIELD: Color(0.6, 0.5, 0.3, 1.0),     # Brown guard
	}
	sprite = ColorRect.new()
	sprite.size = _get_body_size()
	sprite.position = -sprite.size / 2.0
	sprite.color = colors.get(type, Color(0.5, 0.5, 0.5, 1.0))
	add_child(sprite)

func _get_body_size() -> Vector2:
	match type:
		Type.TANK: return Vector2(14, 14)
		Type.FLYER: return Vector2(10, 8)
		_: return Vector2(12, 12)

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
		sprite.modulate = Color.WHITE if int(hit_flash_timer * 20) % 2 == 0 else Color.RED
	else:
		sprite.modulate = Color.WHITE
	
	match type:
		Type.WALKER: _behavior_walker(delta)
		Type.JUMPER: _behavior_jumper(delta)
		Type.FLYER: _behavior_flyer(delta)
		Type.CHASER: _behavior_chaser(delta)
		Type.SHOOTER: _behavior_shooter(delta)
		Type.TANK: _behavior_tank(delta)
		Type.AMBUSHER: _behavior_ambusher(delta)
		Type.SHIELD: _behavior_shield(delta)
	
	move_and_slide()

func _behavior_walker(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = direction * speed
	
	if abs(global_position.x - start_pos.x) > patrol_distance:
		direction *= -1.0
	
	if is_on_floor():
		var check := global_position + Vector2(direction * 8, 12)
		if not _has_ground_at(check):
			direction *= -1.0
	
	sprite.flip_h = direction > 0

func _behavior_jumper(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = direction * speed * 0.7
	
	jump_timer -= delta
	if jump_timer <= 0 and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_timer = JUMP_INTERVAL + randf() * 0.5
	
	if abs(global_position.x - start_pos.x) > patrol_distance:
		direction *= -1.0

func _behavior_flyer(delta: float) -> void:
	# No gravity — sine wave movement
	var t := Time.get_ticks_msec() / 1000.0
	velocity.x = direction * speed
	velocity.y = sin(t * 3.0) * 40.0
	
	if abs(global_position.x - start_pos.x) > patrol_distance:
		direction *= -1.0
	
	# Dive at player if close
	var to_player := player_ref.global_position - global_position
	if to_player.length() < detect_range:
		velocity = to_player.normalized() * speed * 0.8

func _behavior_chaser(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	var to_player := player_ref.global_position - global_position
	if to_player.length() < detect_range:
		# Chase
		direction = sign(to_player.x)
		velocity.x = direction * speed * 1.5
	else:
		# Patrol
		velocity.x = direction * speed * 0.5
		if abs(global_position.x - start_pos.x) > patrol_distance:
			direction *= -1.0

func _behavior_shooter(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = 0.0  # Stationary
	
	# Face player
	var to_player := player_ref.global_position - global_position
	direction = sign(to_player.x) if abs(to_player.x) > 4 else direction
	sprite.flip_h = direction > 0
	
	# Shoot
	shoot_timer -= delta
	if shoot_timer <= 0 and to_player.length() < detect_range:
		_shoot(to_player.normalized())
		shoot_timer = SHOOT_INTERVAL

func _behavior_tank(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = direction * speed * 0.4  # Slow
	
	if abs(global_position.x - start_pos.x) > patrol_distance:
		direction *= -1.0

func _behavior_ambusher(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	var to_player := player_ref.global_position - global_position
	
	if not ambush_revealed:
		# Hidden — invisible until player gets close
		sprite.modulate.a = 0.2
		velocity.x = 0.0
		if to_player.length() < detect_range:
			ambush_revealed = true
			sprite.modulate.a = 1.0
			# Jump attack
			velocity.y = JUMP_VELOCITY * 0.8
	else:
		# Chase aggressively for a while
		velocity.x = sign(to_player.x) * speed * 1.2
		# Reset after 3 seconds
		shoot_timer -= delta
		if shoot_timer <= 0:
			ambush_revealed = false
			shoot_timer = 3.0

func _behavior_shield(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, 400.0)
	var to_player := player_ref.global_position - global_position
	
	# Face player
	direction = sign(to_player.x) if abs(to_player.x) > 2 else direction
	
	# Shield blocks from front — only vulnerable from behind
	velocity.x = direction * speed * 0.6
	
	if abs(global_position.x - start_pos.x) > patrol_distance:
		direction *= -1.0
	
	# Draw shield indicator
	sprite.flip_h = direction > 0

func _shoot(dir: Vector2) -> void:
	var proj := Area2D.new()
	proj.add_to_group("enemy_projectile")
	proj.add_to_group("projectile")
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	col.shape = shape
	proj.add_child(col)
	
	var vis := ColorRect.new()
	vis.size = Vector2(5, 5)
	vis.position = Vector2(-2.5, -2.5)
	vis.color = Color(1.0, 0.4, 0.2, 0.9)
	proj.add_child(vis)
	
	proj.set_script(load("res://scripts/EnemyProjectile.gd"))
	proj.set("direction", dir)
	proj.set("speed", PROJECTILE_SPEED)
	proj.global_position = global_position
	get_parent().add_child(proj)
	AudioManager.play("hit")

func _has_ground_at(pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = 1
	var hits := space.intersect_point(params, 1)
	return not hits.is_empty()

func take_damage_from_flame(dmg: int) -> void:
	health -= dmg
	hit_flash_timer = 0.2
	if health <= 0:
		_die()

func bash_launch(dir: Vector2, force: float) -> void:
	velocity = dir * force
	health -= 1
	hit_flash_timer = 0.3
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	AudioManager.play("stomp")
	queue_free()

func stomp_kill() -> void:
	_die()