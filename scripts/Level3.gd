extends "res://scripts/LevelBase.gd"
## Level 3 — Pântano do Rosto Gigante
## Sobrevivência + plataforma precisa

func _ready() -> void:
	bg_far = "res://assets/backgrounds/bg_swamp_far.png"
	bg_mid = "res://assets/backgrounds/bg_swamp_mid.png"
	bg_near = "res://assets/backgrounds/bg_swamp_near.png"
	super._ready()

func get_platforms() -> Array:
	return [
		# Starting platform
		[0, 160, 80, 40, "stone"],
		# Scattered platforms over swamp water
		[100, 140, 35, 10, "wood"],
		[155, 125, 30, 10, "stone"],
		[200, 110, 35, 10, "wood"],
		[250, 125, 30, 10, "stone"],
		[295, 100, 35, 10, "wood"],
		# Higher section
		[100, 80, 30, 10, "grass"],
		[150, 60, 35, 10, "wood"],
		[210, 50, 40, 10, "stone"],
		[270, 65, 35, 10, "wood"],
		# Final area
		[310, 140, 50, 40, "stone"],
		# Vine bridges (Mossy)
		[135, 140, 20, 8, "wood"],
		[230, 110, 20, 8, "wood"],
		# Ice platforms (slippery)
		[180, 30, 40, 10, "ice"],
	]

func get_enemy_positions() -> Array:
	return [
		[30, 145],
		[108, 125],
		[203, 95],
		[273, 80],
		[108, 65],
		[220, 35],
		[325, 125],
	]

func get_crystal_positions() -> Array:
	return [
		[115, 125],
		[167, 110],
		[210, 95],
		[260, 110],
		[308, 85],
		[165, 50],
		[225, 40],
		[195, 20],
	]

func get_checkpoint_positions() -> Array:
	return [[40, 140], [160, 95], [280, 55]]

func get_player_start() -> Vector2:
	return Vector2(20, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)