extends CharacterBody2D
## Player — controla os 3 personagens com troca simples
## Movimento: andar, pular com coyote time + input buffer
## Habilidades: Florir (Mossy), Escudo Gélido (Polo), Dash Sombrio (Garrax)

const GRAVITY: float = 800.0
const MOVE_SPEED: float = 120.0
const JUMP_VELOCITY: float = -280.0
const MAX_FALL_SPEED: float = 400.0

# Coyote time
const COYOTE_TIME: float = 0.1
var coyote_timer: float = 0.0

# Input buffer
const JUMP_BUFFER_TIME: float = 0.15
var jump_buffer_timer: float = 0.0

# Dash (Garrax ability)
const DASH_SPEED: float = 350.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.4
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false

# Ice shield (Polo ability)
const SHIELD_DURATION: float = 0.5
var shield_timer: float = 0.0
var is_shielding: bool = false

# Vine grow (Mossy ability)
const VINE_DURATION: float = 0.8
var vine_timer: float = 0.0
var is_vining: bool = false

# Sprite sheets
const SPRITE_SIZE: int = 48
const FRAMES_PER_ANIM: int = 4
const ANIM_NAMES: Array = ["idle", "walk", "jump", "ability"]

var character_index: int = 0
var sprite: Sprite2D
var animation_timer: float = 0.0
var current_anim: String = "idle"
var anim_frame: int = 0
var facing: int = 1  # 1 = right, -1 = left

var invincible_timer: float = 0.0
const INVINCIBLE_TIME: float = 1.0

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/amarelo.png")
	sprite.hframes = FRAMES_PER_ANIM
	sprite.vframes = FRAMES_PER_ANIM
	sprite.frame = 0
	sprite.centered = true
	add_child(sprite)
	
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
	
	if is_dashing and dash_timer <= 0.0:
		is_dashing = false
	if is_shielding and shield_timer <= 0.0:
		is_shielding = false
	if is_vining and vine_timer <= 0.0:
		is_vining = false
	
	# Input
	var input_x: float = Input.get_axis("move_left", "move_right")
	
	# Handle dash (Garrax)
	if character_index == 2 and Input.is_action_just_pressed("ability") and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		velocity.y = 0.0
	
	# Handle shield (Polo)
	if character_index == 1 and Input.is_action_just_pressed("ability") and not is_shielding:
		is_shielding = true
		shield_timer = SHIELD_DURATION
	
	# Handle vine (Mossy)
	if character_index == 0 and Input.is_action_just_pressed("ability") and not is_vining:
		is_vining = true
		vine_timer = VINE_DURATION
	
	# Switch character
	if Input.is_action_just_pressed("switch_character"):
		GameManager.switch_character()
		AudioManager.play("switch")
	
	# Movement
	if is_dashing:
		velocity.x = DASH_SPEED * facing
		velocity.y = 0.0
	else:
		# Horizontal
		if input_x != 0.0:
			velocity.x = input_x * MOVE_SPEED
			facing = int(sign(input_x))
		else:
			velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * 0.2)
		
		# Gravity
		if not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		
		# Coyote time
		if is_on_floor():
			coyote_timer = COYOTE_TIME
		else:
			coyote_timer -= delta
		
		# Jump buffer
		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = JUMP_BUFFER_TIME
		
		# Execute jump
		if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			AudioManager.play("jump")
	
	# Apply movement
	move_and_slide()
	
	# Animation
	_update_animation(input_x)

func _update_animation(input_x: float) -> void:
	var new_anim: String = "idle"
	
	if is_dashing or (character_index == 2 and dash_timer > 0):
		new_anim = "ability"
	elif is_shielding or (character_index == 1 and shield_timer > 0):
		new_anim = "ability"
	elif is_vining or (character_index == 0 and vine_timer > 0):
		new_anim = "ability"
	elif not is_on_floor():
		new_anim = "jump"
	elif abs(velocity.x) > 10.0:
		new_anim = "walk"
	
	if new_anim != current_anim:
		current_anim = new_anim
		anim_frame = 0
		animation_timer = 0.0
	
	# Advance frame
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
	
	# Set sprite frame: row = anim index, col = frame
	var anim_row: int = ANIM_NAMES.find(current_anim)
	sprite.frame = anim_row * FRAMES_PER_ANIM + anim_frame
	sprite.flip_h = facing < 0
	
	# Invincibility flash
	if invincible_timer > 0.0:
		sprite.visible = int(invincible_timer * 20) % 2 == 0

func take_damage() -> bool:
	if invincible_timer > 0.0:
		return false
	if is_shielding:
		return false  # Shield blocks damage
	GameManager.take_damage(1)
	invincible_timer = INVINCIBLE_TIME
	# Knockback
	velocity.y = -150.0
	velocity.x = -facing * 100.0
	return true