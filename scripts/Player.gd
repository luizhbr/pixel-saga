extends CharacterBody2D
## Player — Pixel Saga com mecânicas inspiradas em Ori
## Movimento: andar, pular variavel, double jump, dash aéreo, wall jump/slide
## Bash: agarra inimigo/projétil e redireciona
## Spirit Flame: ataque à distância com mira
## Soul Link: save point manual (gasta energia)
## Habilidades dos 3 personagens mantidas

const GRAVITY: float = 800.0
const MOVE_SPEED: float = 120.0
const RUN_SPEED: float = 200.0
const JUMP_VELOCITY: float = -280.0
const JUMP_CUT: float = 0.4  # Multiplicador ao soltar pulo (pulo variável)
const DOUBLE_JUMP_VELOCITY: float = -250.0
const MAX_FALL_SPEED: float = 400.0
const WALL_SLIDE_SPEED: float = 60.0
const WALL_JUMP_VX: float = 200.0
const WALL_JUMP_VY: float = -260.0

# Dash (aéreo + solo, estilo Ori)
const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.3
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var can_double_jump: bool = true
var can_dash: bool = true

# Coyote time
const COYOTE_TIME: float = 0.1
var coyote_timer: float = 0.0

# Input buffer
const JUMP_BUFFER_TIME: float = 0.15
var jump_buffer_timer: float = 0.0
var jump_held: bool = false

# Wall slide/jump
var is_wall_sliding: bool = false
var wall_dir: int = 0  # -1 = left wall, 1 = right wall, 0 = none
const WALL_JUMP_LOCK: float = 0.15
var wall_jump_timer: float = 0.0

# Bash (Ori signature: agarra inimigo/projétil e redireciona)
const BASH_RANGE: float = 40.0
const BASH_DURATION: float = 0.08
const BASH_KICKBACK: float = 350.0
var is_bashing: bool = false
var bash_timer: float = 0.0
var bash_target: Node2D = null
var bash_aim_dir: Vector2 = Vector2.ZERO

# Spirit Flame (ataque à distância)
const SPIRIT_FLAME_SPEED: float = 300.0
const SPIRIT_FLAME_COST: float = 1.0
var spirit_flame_cooldown: float = 0.0
const SPIRIT_FLAME_CD: float = 0.3

# Soul Link (save point manual)
const SOUL_LINK_COST: float = 2.0
var soul_link_cooldown: float = 0.0
const SOUL_LINK_CD: float = 1.0

# Ice shield (Polo ability)
const SHIELD_DURATION: float = 0.5
var shield_timer: float = 0.0
var is_shielding: bool = false

# Vine grow (Mossy ability)
const VINE_DURATION: float = 0.8
var vine_timer: float = 0.0
var is_vining: bool = false

# Sprite
const FRAMES_PER_ANIM: int = 4
const ANIM_NAMES: Array = ["idle", "walk", "jump", "ability"]

var character_index: int = 0
var sprite: Sprite2D
var animation_timer: float = 0.0
var current_anim: String = "idle"
var anim_frame: int = 0
var facing: int = 1

var invincible_timer: float = 0.0
const INVINCIBLE_TIME: float = 1.0

# Spirit energy
var spirit_energy: float = 5.0
const MAX_SPIRIT_ENERGY: float = 10.0

# Ability unlocks (árvore de habilidades)
var unlocked: Dictionary = {
	"double_jump": true,
	"dash": true,
	"wall_jump": true,
	"bash": true,
	"spirit_flame": true,
	"soul_link": true,
}

# Particles
var particle_layer: Node2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/amarelo.png")
	sprite.hframes = FRAMES_PER_ANIM
	sprite.vframes = FRAMES_PER_ANIM
	sprite.frame = 0
	sprite.centered = true
	add_child(sprite)
	
	# Light glow (Ori-style aura)
	var glow := PointLight2D.new()
	glow.texture = load("res://assets/characters/amarelo_idle.png")
	glow.texture_scale = 0.3
	glow.color = Color(1.0, 0.9, 0.5, 0.4)
	glow.energy = 0.6
	add_child(glow)
	
	character_index = GameManager.current_character
	_update_sprite_sheet()
	GameManager.character_changed.connect(_on_character_changed)

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

func _physics_process(delta: float) -> void:
	# Timers
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
	
	# End states
	if is_dashing and dash_timer <= 0.0:
		is_dashing = false
	if is_shielding and shield_timer <= 0.0:
		is_shielding = false
	if is_vining and vine_timer <= 0.0:
		is_vining = false
	if is_bashing and bash_timer <= 0.0:
		_execute_bash()
	
	# Regenerate spirit energy slowly
	spirit_energy = min(MAX_SPIRIT_ENERGY, spirit_energy + 0.5 * delta)
	
	# Input
	var input_x: float = Input.get_axis("move_left", "move_right")
	var is_running: bool = Input.is_action_pressed("jump") and is_on_floor()  # Placeholder; could use a run key
	var speed: float = RUN_SPEED if is_running else MOVE_SPEED
	
	# Switch character
	if Input.is_action_just_pressed("switch_character"):
		GameManager.switch_character()
		AudioManager.play("switch")
	
	# --- BASH (Ori signature mechanic) ---
	if unlocked["bash"] and Input.is_action_just_pressed("ability") and character_index == 2:
		_try_bash()
	
	# --- Character abilities ---
	if character_index == 2 and Input.is_action_just_pressed("ability") and dash_cooldown_timer <= 0.0 and not unlocked["bash"]:
		_start_dash()
	if character_index == 1 and Input.is_action_just_pressed("ability") and not is_shielding:
		is_shielding = true
		shield_timer = SHIELD_DURATION
	if character_index == 0 and Input.is_action_just_pressed("ability") and not is_vining:
		is_vining = true
		vine_timer = VINE_DURATION
	
	# --- DASH (aéreo + solo, Ori-style) ---
	if unlocked["dash"] and Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0.0:
		_start_dash()
	
	# --- SPIRIT FLAME (ataque à distância) ---
	if unlocked["spirit_flame"] and Input.is_action_just_pressed("ability") and character_index != 2 and spirit_flame_cooldown <= 0.0 and spirit_energy >= SPIRIT_FLAME_COST:
		_spirit_flame()
	
	# --- SOUL LINK (save point manual) ---
	if unlocked["soul_link"] and Input.is_action_just_pressed("soul_link") and soul_link_cooldown <= 0.0 and spirit_energy >= SOUL_LINK_COST:
		_soul_link()
	
	# --- MOVEMENT ---
	if is_bashing:
		# Freeze during bash aim
		velocity = Vector2.ZERO
	elif is_dashing:
		velocity.x = DASH_SPEED * facing
		velocity.y = 0.0
	else:
		# Horizontal
		if wall_jump_timer > 0.0:
			# Locked direction during wall jump
			pass
		elif input_x != 0.0:
			velocity.x = move_toward(velocity.x, input_x * speed, speed * 0.3)
			facing = int(sign(input_x))
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 0.2)
		
		# Gravity
		if not is_on_floor():
			# Wall slide
			_check_wall_slide()
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
		else:
			coyote_timer -= delta
		
		# Jump buffer
		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = JUMP_BUFFER_TIME
			jump_held = true
		if not Input.is_action_pressed("jump"):
			jump_held = false
		
		# Variable jump height (cut velocity when released)
		if not jump_held and velocity.y < 0.0:
			velocity.y *= JUMP_CUT
		
		# Execute jump (ground)
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
	
	# Apply movement
	move_and_slide()
	
	# Animation
	_update_animation(input_x)

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	velocity.y = 0.0
	can_dash = false
	AudioManager.play("dash")
	_spawn_dust()

func _check_wall_slide() -> void:
	# Check for wall on left or right
	var left_wall: bool = false
	var right_wall: bool = false
	
	# RayCast approach: check collision normals
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

# --- BASH (Ori signature) ---
func _try_bash() -> void:
	# Find nearby enemy or projectile
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = global_position
	params.collision_mask = 0xFFFF
	var hits := space.intersect_point(params, 1)
	# Check enemies in range
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
		# Freeze time during aim
		Engine.time_scale = 0.1

func _execute_bash() -> void:
	is_bashing = false
	Engine.time_scale = 1.0
	
	if bash_target and is_instance_valid(bash_target):
		# Direction: from player toward aim (input direction or facing)
		var aim: Vector2 = Vector2(facing, 0.0)
		var input_x: float = Input.get_axis("move_left", "move_right")
		var input_y: float = Input.get_axis("move_up", "move_down")
		if input_x != 0.0 or input_y != 0.0:
			aim = Vector2(input_x, input_y).normalized()
		
		# Launch enemy in aim direction
		if bash_target.is_in_group("enemy"):
			if bash_target.has_method("bash_launch"):
				bash_target.bash_launch(aim, BASH_KICKBACK)
			else:
				bash_target.velocity = aim * BASH_KICKBACK
		elif bash_target.is_in_group("projectile"):
			bash_target.velocity = aim * BASH_KICKBACK
		
		# Player gets launched in opposite direction
		velocity = -aim * BASH_KICKBACK
		AudioManager.play("stomp")
		_spawn_dust()
	
	bash_target = null

# --- SPIRIT FLAME ---
func _spirit_flame() -> void:
	spirit_energy -= SPIRIT_FLAME_COST
	spirit_flame_cooldown = SPIRIT_FLAME_CD
	AudioManager.play("crystal")
	
	# Create projectile
	var flame := Area2D.new()
	flame.add_to_group("projectile")
	flame.add_to_group("player_flame")
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	flame.add_child(col)
	
	# Visual
	var vis := ColorRect.new()
	vis.size = Vector2(6, 6)
	vis.position = Vector2(-3, -3)
	vis.color = Color(1.0, 0.9, 0.3, 0.9)
	flame.add_child(vis)
	
	# Aim: input direction or facing
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

# --- SOUL LINK ---
func _soul_link() -> void:
	spirit_energy -= SOUL_LINK_COST
	soul_link_cooldown = SOUL_LINK_CD
	AudioManager.play("checkpoint")
	GameManager.set_meta("checkpoint_pos", global_position)
	GameManager.set_meta("soul_link_active", true)
	# Visual effect
	_spawn_soul_link_effect()

func _spawn_soul_link_effect() -> void:
	# Create a glowing save point marker
	var marker := Node2D.new()
	marker.global_position = global_position
	var glow := PointLight2D.new()
	glow.color = Color(0.3, 0.9, 1.0, 0.6)
	glow.energy = 1.5
	glow.texture_scale = 0.4
	marker.add_child(glow)
	var vis := ColorRect.new()
	vis.size = Vector2(4, 20)
	vis.position = Vector2(-2, -10)
	vis.color = Color(0.3, 0.9, 1.0, 0.5)
	marker.add_child(vis)
	marker.add_to_group("soul_link_marker")
	get_parent().add_child(marker)

func _spawn_dust() -> void:
	if particle_layer:
		pass  # LevelBase handles particles

func _update_animation(input_x: float) -> void:
	var new_anim: String = "idle"
	
	if is_dashing:
		new_anim = "ability"
	elif is_bashing:
		new_anim = "ability"
	elif is_shielding:
		new_anim = "ability"
	elif is_vining:
		new_anim = "ability"
	elif is_wall_sliding:
		new_anim = "jump"
	elif not is_on_floor():
		new_anim = "jump"
	elif abs(velocity.x) > 10.0:
		new_anim = "walk"
	
	if new_anim != current_anim:
		current_anim = new_anim
		anim_frame = 0
		animation_timer = 0.0
	
	animation_timer += get_physics_process_delta_time()
	var fps: float = 8.0
	if current_anim == "idle":
		fps = 4.0
	elif current_anim == "walk":
		fps = 10.0
	elif current_anim == "jump":
		fps = 6.0
	elif current_anim == "ability":
		fps = 12.0
	
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
		return false  # Dash has i-frames
	GameManager.take_damage(1)
	invincible_timer = INVINCIBLE_TIME
	velocity.y = -150.0
	velocity.x = -facing * 100.0
	return true

func heal_energy(amount: float) -> void:
	spirit_energy = min(MAX_SPIRIT_ENERGY, spirit_energy + amount)

func unlock_ability(name: String) -> void:
	unlocked[name] = true