extends "res://scripts/LevelBase.gd"
## Level 1 — Beco Cyberpunk (tutorial de movimento + troca)
## Inimigos: walkers e jumpers (introdução fácil)

func _ready() -> void:
	bg_far = "res://assets/backgrounds/bg_cyberpunk_far.png"
	bg_mid = "res://assets/backgrounds/bg_cyberpunk_mid.png"
	bg_near = "res://assets/backgrounds/bg_cyberpunk_near.png"
	super._ready()

# [x, y, type, patrol_distance]
# Type: 0=walker, 1=jumper, 2=flyer, 3=chaser, 4=shooter, 5=tank, 6=ambusher, 7=shield
func get_enemy_positions() -> Array:
	return [
		[80, 145, 0, 60],    # Walker — patrulha simples
		[220, 100, 0, 50],    # Walker
		[165, 90, 1, 40],     # Jumper — pula periodicamente
		[300, 140, 0, 40],    # Walker
	]

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

func get_crystal_positions() -> Array:
	return [[90, 115], [165, 95], [235, 75], [120, 55]]

func get_checkpoint_positions() -> Array:
	return [[120, 140], [250, 100]]

func get_player_start() -> Vector2:
	return Vector2(40, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)