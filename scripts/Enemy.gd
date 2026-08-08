extends CharacterBody2D
## Enemy — inimigo simples que patrulha entre dois pontos
## Sai da plataforma e vira automaticamente

const SPEED: float = 50.0
var direction: float = -1.0
var gravity: float = 800.0

@export var patrol_distance: float = 80.0
var start_x: float
var sprite: AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x
	# Create simple visual
	sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("walk")
	# Create a simple red slime sprite at runtime
	var tex := _make_slime_texture()
	for i in range(4):
		frames.add_frame("walk", tex)
	sprite.sprite_frames = frames
	sprite.animation = "walk"
	sprite.play("walk")
	add_child(sprite)
	
	# Collision shape (if not set in scene)
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 14)
		col.shape = rect
		add_child(col)

func _make_slime_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	# Slime body (purple)
	var purple := Color(0.5, 0.2, 0.6, 1.0)
	var dark := Color(0.35, 0.15, 0.45, 1.0)
	var eye := Color(1.0, 1.0, 0.3, 1.0)
	var black := Color(0.1, 0.05, 0.1, 1.0)
	img.fill(Color(0, 0, 0, 0))
	# Body
	for y in range(6, 14):
		for x in range(3, 13):
			img.set_pixel(x, y, purple)
	# Top dome
	for y in range(3, 6):
		var w := 2 + (y - 3)
		for x in range(5, 11):
			img.set_pixel(x, y, purple)
	# Shadow
	for y in range(10, 14):
		for x in range(8, 13):
			img.set_pixel(x, y, dark)
	# Eyes
	img.set_pixel(6, 7, eye)
	img.set_pixel(9, 7, eye)
	img.set_pixel(6, 7, black)
	img.set_pixel(9, 7, black)
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	# Gravity
	velocity.y = min(velocity.y + gravity * delta, 400.0)
	
	# Patrol
	velocity.x = direction * SPEED
	
	# Turn at patrol bounds
	if abs(global_position.x - start_x) > patrol_distance:
		direction *= -1.0
	
	# Turn at ledge
	if is_on_floor():
		var check_pos := global_position + Vector2(direction * 10, 10)
		var space := get_world_2d().direct_space_state
		var params := PhysicsPointQueryParameters2D.new()
		params.position = check_pos
		params.collision_mask = 1
		var hits := space.intersect_point(params, 1)
		if hits.is_empty():
			direction *= -1.0
	
	# Flip sprite
	if sprite:
		sprite.flip_h = direction > 0
	
	move_and_slide()