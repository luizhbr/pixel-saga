extends Camera2D
## Smooth camera that follows the player with lerp

@export var lerp_speed: float = 5.0
@export var offset_y: float = -20.0

var target: Node2D

func _ready() -> void:
	# Find player
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if target:
		var desired := target.global_position + Vector2(0, offset_y)
		global_position = global_position.lerp(desired, lerp_speed * delta)