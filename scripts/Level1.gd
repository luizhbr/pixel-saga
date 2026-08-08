extends "res://scripts/LevelBase.gd"
## Level 1 — Beco Cyberpunk (tutorial de movimento + troca)

func _ready() -> void:
	bg_far = "res://assets/backgrounds/bg_cyberpunk_far.png"
	bg_mid = "res://assets/backgrounds/bg_cyberpunk_mid.png"
	bg_near = "res://assets/backgrounds/bg_cyberpunk_near.png"
	super._ready()

func get_platforms() -> Array:
	return [
		[0, 160, 320, 40, "stone"],
		[60, 130, 60, 10, "grass"],
		[140, 110, 50, 10, "wood"],
		[210, 90, 50, 10, "metal"],
		[280, 120, 40, 10, "grass"],
		[100, 70, 40, 10, "wood"],
		[180, 50, 40, 10, "ice"],
	]

func get_enemy_positions() -> Array:
	return [[80, 145], [220, 100], [300, 140]]

func get_crystal_positions() -> Array:
	return [[90, 115], [165, 95], [235, 75], [120, 55]]

func get_checkpoint_positions() -> Array:
	return [[120, 140], [250, 100]]

func get_player_start() -> Vector2:
	return Vector2(40, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)