extends "res://scripts/LevelBase.gd"
## Level 3 — Pântano do Rosto Gigante
## Inimigos: ambusher, tank, shield, chaser (dificuldade alta) + BOSS

func _ready() -> void:
	bg_far = "res://assets/backgrounds/bg_swamp_far.png"
	bg_mid = "res://assets/backgrounds/bg_swamp_mid.png"
	bg_near = "res://assets/backgrounds/bg_swamp_near.png"
	super._ready()
	_spawn_boss()

func _spawn_boss() -> void:
	var boss := CharacterBody2D.new()
	boss.set_script(load("res://scripts/Boss.gd"))
	boss.global_position = Vector2(320, 120)
	boss.collision_layer = 2
	boss.collision_mask = 1
	add_child(boss)
	# Boss music
	AudioManager.start_music("boss")
	# Vignette boss mode
	Vignette.boss_mode(true)
	# Save game when boss appears
	SaveSystem.save_game()
	# When boss is defeated, open exit
	boss.boss_defeated.connect(func():
		Vignette.boss_mode(false)
		AudioManager.start_music("swamp")
		# Open portal / show victory
		_next_level()
	)

func get_enemy_positions() -> Array:
	return [
		[30, 145, 0, 40],     # Walker
		[108, 125, 6, 60],    # Ambusher — escondido
		[203, 95, 3, 120],    # Chaser
		[273, 80, 2, 50],     # Flyer
		[108, 65, 6, 50],     # Ambusher
		[220, 35, 5, 30],     # Tank — lento e resistente
		[325, 125, 7, 40],    # Shield — vulnerável só por trás
		[150, 50, 1, 30],    # Jumper
	]

func get_platforms() -> Array:
	return [
		[0, 160, 80, 40, "stone"],
		[100, 140, 35, 10, "wood"],
		[155, 125, 30, 10, "stone"],
		[200, 110, 35, 10, "wood"],
		[250, 125, 30, 10, "stone"],
		[295, 100, 35, 10, "wood"],
		[100, 80, 30, 10, "grass"],
		[150, 60, 35, 10, "wood"],
		[210, 50, 40, 10, "stone"],
		[270, 65, 35, 10, "wood"],
		[310, 140, 50, 40, "stone"],
		[135, 140, 20, 8, "wood"],
		[230, 110, 20, 8, "wood"],
		[180, 30, 40, 10, "ice"],
	]

func get_crystal_positions() -> Array:
	return [[115, 125], [167, 110], [210, 95], [260, 110], [308, 85], [165, 50], [225, 40], [195, 20]]

func get_checkpoint_positions() -> Array:
	return [[40, 140], [160, 95], [280, 55]]

func get_player_start() -> Vector2:
	return Vector2(20, 140)

func get_exit_position() -> Vector2:
	return Vector2(340, 140)