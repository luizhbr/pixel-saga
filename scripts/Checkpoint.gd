extends Node2D
## Checkpoint — ativa quando o player toca

@export var checkpoint_id: int = 0
var activated: bool = false
var sprite: ColorRect

func _ready() -> void:
	add_to_group("checkpoint")
	# Create visual flag
	sprite = ColorRect.new()
	sprite.size = Vector2(4, 24)
	sprite.position = Vector2(-2, -24)
	sprite.color = Color(0.3, 0.3, 0.3, 1.0) if not activated else Color(0.2, 0.8, 0.3, 1.0)
	add_child(sprite)
	
	# Area2D for detection
	var area := Area2D.new()
	area.name = "DetectionArea"
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 28)
	col.shape = rect
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not activated:
		activated = true
		sprite.color = Color(0.2, 0.8, 0.3, 1.0)
		GameManager.set_meta("current_checkpoint", checkpoint_id)
		GameManager.set_meta("checkpoint_pos", global_position)
		AudioManager.play("checkpoint")