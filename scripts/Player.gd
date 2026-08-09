extends CharacterBody2D
## Player — Pixel Saga
## Arquitetura modular: movement, combat, abilities, animation, energy
## Estado de energia centralizado no GameManager (single source of truth)

const GRAVITY: float = 800.0
const MOVE_SPEED: float = 120.0
const RUN_SPEED: float = 180.0
const JUMP_VELOCITY: float = -280.0
const JUMP_CUT: float = 0.4
const DOUBLE_JUMP_VELOCITY: float = -250.0
const MAX_FALL_SPEED: float = 400.0
const WALL_SLIDE_SPEED: float = 60.0
const WALL_JUMP_VX: float = 200.0
const WALL_JUMP_VY: float = -260.0
const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.3
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.15
const WALL_JUMP_LOCK: float = 0.12
const BASH_RANGE: float = 40.0
const BASH_DURATION: float = 0.08
const BASH_KICKBACK: float = 350.0
const SPIRIT_FLAME_SPEED: float = 300.0
const SPIRIT_FLAME_COST: float = 1.0
const SPIRIT_FLAME_CD: float = 0.3
const SOUL_LINK_COST: float = 2.0
const SOUL_LINK_CD: float = 1.0
const SHIELD_DURATION: float = 0.5
const VINE_DURATION: float = 0.8
const FRAMES_PER_ANIM: int = 4
const ANIM_NAMES: Array = ["idle", "walk", "jump", "ability"]
const INVINCIBLE_TIME: float = 1.0

# State flags
var is_dashing: bool = false
var is_bashing: bool = false
var is_shielding: bool = false
var is_vining: bool = false
var is_wall_sliding: bool = false
var can_double_jump: bool = true
var can_dash: bool = true
var jump_held: bool = false

# Timers
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_dir: int = 0
var wall_jump_timer: float = 0.0
var bash_timer: float = 0.0
var bash_target: Node2D = null
var spirit_flame_cooldown: float = 0.0
var soul_link_cooldown: float = 0.0
var shield_timer: float = 0.0
var vine_timer: float = 0.0
var invincible_timer: float = 0.0

# Visual
var character_index: int = 0
var sprite: Sprite2D
var glow: PointLight2D
var animation_timer: float = 0.0
var current_anim: String = "idle"
var anim_frame: int = 0
var facing: int = 1

# Abilities
var unlocked: Dictionary = {
	"double_jump": true,
	"dash": true,
	"wall_jump": true,
	"bash": true,
	"spirit_flame": true,
	"soul_link": true,
}

# Level reference (set by LevelBase)
var level: Node2D = null

func _ready() -> void:
	_create_visual()
	character_index = GameManager.current_character
	_update_sprite_sheet()
	GameManager.character_changed.connect(_on_character_changed)

func _create_visual() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/amarelo.png")
	sprite.hframes = FRAMES_PER_ANIM
	sprite.vframes = FRAMES_PER_ANIM
	sprite.frame = 0
	sprite.centered = true
	add_child(sprite)
	
	glow = PointLight2D.new()
	glow.texture = load("res://assets/characters/amarelo_idle.png")
	glow.texture_scale = 0.3
	glow.color = Color(1.0, 0.9, 0.5, 0.4)
	glow.energy = 0.6
	add_child(glow)

func _on_character_changed(idx: int) -> void:
	character_index = idx
	_update_sprite_sheet()

func _update_sprite_sheet() -> void:
	var textures: Array = [
		load("res://assets/characters/amarelo.png"),
		load("res://assets/characters/urso.png"),
		load("res://assets/characters/gato.png"),
	]
	sprite.texture = textures[character_index]
	# Update glow color per character
	var glow_colors: Array = [
		Color(1.0, 0.9, 0.5, 0.4),   # Mossy — warm yellow
		Color(0.6, 0.8, 1.0, 0.4),   # Polo — ice blue
		Color(1.0, 0.5, 0.2, 0.4),   # Garrax — orange
	]
	glow.color = glow_colors[character_index]

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_regenerate_energy(delta)
	
	var input_x: float = Input.get_axis("move_left", "move_right")
	
	_handle_character_switch()
	_handle_abilities()
	_handle_bash()
	
	_handle_movement(delta, input_x)
	_check_wall_slide()
	_handle_jump(input_x)
	
	# Fall protection
	_check_fall_protection()
	
	move_and_slide()
	_update_animation(input_x)

func _update_timers(delta: float) -> void:
	coyote_timer = max(0.0, coyote_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	shield_timer = max(0.0, shield_timer - delta)
	vine_timer = max(0.0, vine_timer - delta)
	invincible_timer = max(0.0, invincible_timer - delta)
	wall_jump_timer = max(0.0, wall_jump_timer - delta)
	bash_timer = max(0.0, bash_timer - delta)
	spirit_flame_cooldown = max(0.0, spirit_flame_cooldown - delta)
	soul_link_cooldown = max(0.0, soul_link_cooldown - delta)
	
	if is_dashing and dash_timer <= 0.0:
		is_dashing = false
	if is_shielding and shield_timer <= 0.0:
		is_shielding = false
	if is_vining and vine_timer <= 0.0:
		is_vining = false
	if is_bashing and bash_timer <= 0.0:
		_execute_bash()

func _regenerate_energy(delta: float) -> void:
	GameManager.add_energy(0.5 * delta)

func _handle_character_switch() -> void:
	if Input.is_action_just_pressed("switch_character"):
		GameManager.switch_character()
		AudioManager.play("switch")

func _handle_abilities() -> void:
	# Garrax: Bash (priority) or Dash
	if character_index == 2:
		if unlocked["bash"] and Input.is_action_just_pressed("ability"):
			_try_bash()
		elif Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0.0 and unlocked["dash"]:
			_start_dash()
	else:
		# Mossy: Vine grow
		if character_index == 0 and Input.is_action_just_pressed("ability") and not is_vining:
			is_vining = true
			vine_timer = VINE_DURATION
		# Polo: Ice shield
		if character_index == 1 and Input.is_action_just_pressed("ability") and not is_shielding:
			is_shielding = true
			shield_timer = SHIELD_DURATION
		# Spirit Flame (Mossy + Polo)
		if unlocked["spirit_flame"] and Input.is_action_just_pressed("ability") and spirit_flame_cooldown <= 0.0:
			if GameManager.spend_energy(SPIRIT_FLAME_COST):
				_spirit_flame()
		# Dash (universal)
		if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0.0 and unlocked["dash"]:
			_start_dash()
	
	# Soul Link (universal)
	if unlocked["soul_link"] and Input.is_action_just_pressed("soul_link") and soul_link_cooldown <= 0.0:
		if GameManager.spend_energy(SOUL_LINK_COST):
			_soul_link()

func _handle_bash() -> void:
	# Bash is handled in _update_timers when bash_timer expires
	pass

func _handle_movement(delta: float, input_x: float) -> void:
	if is_bashing:
		velocity = Vector2.ZERO
		return
	
	if is_dashing:
		velocity.x = DASH_SPEED * facing
		velocity.y = 0.0
		return
	
	# Horizontal
	if wall_jump_timer > 0.0:
		pass  # Locked during wall jump
	elif input_x != 0.0:
		var speed: float = MOVE_SPEED
		velocity.x = move_toward(velocity.x, input_x * speed, speed * 0.3)
		facing = int(sign(input_x))
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * 0.2)
	
	# Gravity
	if not is_on_floor():
		if is_wall_sliding and velocity.y > 0.0:
			velocity.y = min(velocity.y + GRAVITY * delta * 0.3, WALL_SLIDE_SPEED)
		else:
			velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		is_wall_sliding = false
		wall_dir = 0
		can_double_jump = true
		can_dash = true
	
	# Coyote time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	# NOTE: coyote_timer is decremented in _update_timers() above — do NOT decrement here

func _check_wall_slide() -> void:
	if is_on_floor():
		is_wall_sliding = false
		wall_dir = 0
		return
	
	var left_wall: bool = false
	var right_wall: bool = false
	
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var normal = col.get_normal()
			if normal.x > 0.5:
				left_wall = true
			elif normal.x < -0.5:
				right_wall = true
	
	if left_wall and not right_wall:
		wall_dir = -1
		is_wall_sliding = true
	elif right_wall and not left_wall:
		wall_dir = 1
		is_wall_sliding = true
	else:
		is_wall_sliding = false
		wall_dir = 0

func _handle_jump(input_x: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		jump_held = true
	if not Input.is_action_pressed("jump"):
		jump_held = false
	
	# Variable jump height — cut velocity ONCE when jump is released
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	
	# Ground jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		can_double_jump = true
		can_dash = true
		AudioManager.play("jump")
		_spawn_dust()
	
	# Double jump
	elif jump_buffer_timer > 0.0 and not is_on_floor() and can_double_jump and unlocked["double_jump"]:
		velocity.y = DOUBLE_JUMP_VELOCITY
		jump_buffer_timer = 0.0
		can_double_jump = false
		AudioManager.play("jump")
		_spawn_dust()
	
	# Wall jump
	elif jump_buffer_timer > 0.0 and is_wall_sliding and unlocked["wall_jump"]:
		velocity.x = -wall_dir * WALL_JUMP_VX
		velocity.y = WALL_JUMP_VY
		wall_jump_timer = WALL_JUMP_LOCK
		jump_buffer_timer = 0.0
		can_double_jump = true
		can_dash = true
		AudioManager.play("jump")
		_spawn_dust()

func _check_fall_protection() -> void:
	# If player falls below a safe threshold, trigger respawn
	if global_position.y > 500.0:
		take_damage()
		_respawn()

func _respawn() -> void:
	# Reset Engine.time_scale in case Bash was interrupted
	Engine.time_scale = 1.0
	var cp_pos: Variant = GameManager.get_meta("checkpoint_pos", null)
	if cp_pos == null or not (cp_pos is Vector2):
		if level and level.has_method("get_player_start"):
			cp_pos = level.get_player_start()
		else:
			cp_pos = Vector2(40, 140)
	global_position = cp_pos
	velocity = Vector2.ZERO
	is_dashing = false
	is_bashing = false
	is_wall_sliding = false
	can_double_jump = true
	can_dash = true
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	wall_jump_timer = 0.0
	invincible_timer = 0.0
	Engine.time_scale = 1.0

func _exit_tree() -> void:
	# Safety: always reset time_scale when Player is destroyed
	Engine.time_scale = 1.0

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	velocity.y = 0.0
	can_dash = false
	AudioManager.play("dash")
	_spawn_dust()

func _try_bash() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var projectiles := get_tree().get_nodes_in_group("projectile")
	var targets: Array = enemies + projectiles
	var closest: Node2D = null
	var closest_dist: float = BASH_RANGE
	for t in targets:
		if is_instance_valid(t):
			var d: float = global_position.distance_to(t.global_position)
			if d < closest_dist:
				closest = t
				closest_dist = d
	if closest:
		bash_target = closest
		is_bashing = true
		bash_timer = BASH_DURATION
		AudioManager.play("dash")
		Engine.time_scale = 0.1

func _execute_bash() -> void:
	is_bashing = false
	Engine.time_scale = 1.0
	
	if bash_target and is_instance_valid(bash_target):
		var aim: Vector2 = Vector2(facing, 0.0)
		var input_x: float = Input.get_axis("move_left", "move_right")
		var input_y: float = Input.get_axis("move_up", "move_down")
		if input_x != 0.0 or input_y != 0.0:
			aim = Vector2(input_x, input_y).normalized()
		
		if bash_target.is_in_group("enemy"):
			if bash_target.has_method("bash_launch"):
				bash_target.bash_launch(aim, BASH_KICKBACK)
			else:
				bash_target.velocity = aim * BASH_KICKBACK
		elif bash_target.is_in_group("projectile"):
			bash_target.velocity = aim * BASH_KICKBACK
		
		velocity = -aim * BASH_KICKBACK
		AudioManager.play("stomp")
		_spawn_dust()
	
	bash_target = null

func _spirit_flame() -> void:
	spirit_flame_cooldown = SPIRIT_FLAME_CD
	AudioManager.play("crystal")
	
	var flame := Area2D.new()
	flame.add_to_group("projectile")
	flame.add_to_group("player_flame")
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	flame.add_child(col)
	
	var vis := ColorRect.new()
	vis.size = Vector2(6, 6)
	vis.position = Vector2(-3, -3)
	vis.color = Color(1.0, 0.9, 0.3, 0.9)
	flame.add_child(vis)
	
	var aim: Vector2 = Vector2(facing, 0.0)
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_y: float = Input.get_axis("move_up", "move_down")
	if input_x != 0.0 or input_y != 0.0:
		aim = Vector2(input_x, input_y).normalized()
	
	flame.set_script(load("res://scripts/SpiritFlame.gd"))
	flame.set("direction", aim)
	flame.set("speed", SPIRIT_FLAME_SPEED)
	flame.global_position = global_position
	get_parent().add_child(flame)

func _soul_link() -> void:
	soul_link_cooldown = SOUL_LINK_CD
	AudioManager.play("checkpoint")
	GameManager.set_meta("checkpoint_pos", global_position)
	GameManager.set_meta("soul_link_active", true)
	_spawn_soul_link_effect()

func _spawn_soul_link_effect() -> void:
	var marker := Node2D.new()
	marker.global_position = global_position
	var mglow := PointLight2D.new()
	mglow.color = Color(0.3, 0.9, 1.0, 0.6)
	mglow.energy = 1.5
	mglow.texture_scale = 0.4
	marker.add_child(mglow)
	var vis := ColorRect.new()
	vis.size = Vector2(4, 20)
	vis.position = Vector2(-2, -10)
	vis.color = Color(0.3, 0.9, 1.0, 0.5)
	marker.add_child(vis)
	marker.add_to_group("soul_link_marker")
	get_parent().add_child(marker)

func _spawn_dust() -> void:
	if level and level.has_method("spawn_particles"):
		level.spawn_particles(global_position + Vector2(0, 10), Color(0.7, 0.7, 0.8, 0.6), 4)

func _update_animation(input_x: float) -> void:
	var new_anim: String = "idle"
	
	if is_dashing or is_bashing or is_shielding or is_vining:
		new_anim = "ability"
	elif is_wall_sliding or not is_on_floor():
		new_anim = "jump"
	elif abs(velocity.x) > 10.0:
		new_anim = "walk"
	
	if new_anim != current_anim:
		current_anim = new_anim
		anim_frame = 0
		animation_timer = 0.0
	
	animation_timer += get_physics_process_delta_time()
	var fps: float = 8.0
	match current_anim:
		"idle": fps = 4.0
		"walk": fps = 10.0
		"jump": fps = 6.0
		"ability": fps = 12.0
	
	if animation_timer >= 1.0 / fps:
		animation_timer = 0.0
		anim_frame = (anim_frame + 1) % FRAMES_PER_ANIM
	
	var anim_row: int = ANIM_NAMES.find(current_anim)
	sprite.frame = anim_row * FRAMES_PER_ANIM + anim_frame
	sprite.flip_h = facing < 0
	
	if invincible_timer > 0.0:
		sprite.visible = int(invincible_timer * 20) % 2 == 0
	else:
		sprite.visible = true

func take_damage() -> bool:
	if invincible_timer > 0.0:
		return false
	if is_shielding:
		return false
	if is_dashing:
		return false
	GameManager.take_damage(1)
	invincible_timer = INVINCIBLE_TIME
	velocity.y = -150.0
	velocity.x = -facing * 100.0
	return true

func unlock_ability(name: String) -> void:
	unlocked[name] = true