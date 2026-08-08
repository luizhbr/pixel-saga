extends "res://scripts/LevelBase.gd"
## Level 2 — Vila Japonesa ao Pôr do Sol
## Puzzles de troca + primeiro chef

func _ready() -> void:
	bg_far = "res://assets/backgrounds/bg_japanese_village_far.png"
	bg_mid = "res://assets/backgrounds/bg_japanese_village_mid.png"
	bg_near = "res://assets/backgrounds/bg_japanese_village_near.png"
	super._ready()

func get_platforms() -> Array:
	return [
		# Ground
		[0, 160, 200, 40, "stone"],
		[240, 160, 120, 40, "stone"],
		# Gap with vine bridge (Mossy needed)
		[200, 160, 40, 10, "wood"],
		# Floating platforms
		[40, 130, 50, 10, "wood"],
		[110, 115, 45, 10, "wood"],
		[180, 100, 50, 10, "grass"],
		[260, 80, 45, 10, "wood"],
		[310, 110, 40, 10, "stone"],
		# High path
		[80, 60, 40, 10, "wood"],
		[160, 40, 40, 10, "ice"],
		[240, 50, 40, 10, "metal"],
		# Roof platforms
		[50, 90, 30, 10, "wood"],
		[300, 50, 40, 10, "metal"],
	]

func get_enemy_positions() -> Array:
	return [
		[60, 145],
		[120, 145],
		[280, 145],
		[265, 65],
		[310, 95],
	]

func get_crystal_positions() -> Array:
	return [
		[55, 115],
		[130, 95],
		[195, 80],
		[280, 60],
		[95, 45],
		[255, 35],
	]

func get_checkpoint_positions() -> Array:
	return [[100, 140], [260, 90]]

func get_player_start() -> Vector2:
	return Vector2(30, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)