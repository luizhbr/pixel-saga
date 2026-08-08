extends Area2D
## Crystal — coletável que adiciona ao score

func _ready() -> void:
	add_to_group("crystal")
	# Visual
	var sprite := ColorRect.new()
	sprite.size = Vector2(6, 6)
	sprite.position = Vector2(-3, -3)
	sprite.color = Color(0.3, 0.9, 1.0, 0.9)
	add_child(sprite)
	
	# Collision
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 8)
	col.shape = rect
	add_child(col)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.add_crystal()
		AudioManager.play("crystal")
		queue_free()