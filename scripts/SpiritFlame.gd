extends Area2D
## SpiritFlame — projétil de energia do jogador (Ori-style)
## Move em linha reta, some ao colidir com inimigo ou parede

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var lifetime: float = 1.5
var damage: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Add collision shape if not present
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 4.0
		col.shape = shape
		add_child(col)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		# Damage enemy
		if body.has_method("take_damage_from_flame"):
			body.take_damage_from_flame(damage)
		elif body.has_method("queue_free"):
			body.queue_free()
		# Spawn hit particles
		_spawn_hit()
		queue_free()
	elif body is StaticBody2D:
		# Hit wall
		_spawn_hit()
		queue_free()

func _spawn_hit() -> void:
	# Small spark effect
	var spark := ColorRect.new()
	spark.size = Vector2(4, 4)
	spark.position = global_position
	spark.color = Color(1.0, 0.9, 0.3, 0.8)
	spark.set("lifetime", 0.2)
	get_parent().add_child(spark)