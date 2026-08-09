extends Area2D
## EnemyProjectile — projétil de inimigo (shooter)
## Pode ser redirecionado pelo Bash do Garrax

var direction: Vector2 = Vector2.RIGHT
var speed: float = 150.0
var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 3.0
		col.shape = shape
		add_child(col)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage()
		queue_free()
	elif body is StaticBody2D:
		queue_free()