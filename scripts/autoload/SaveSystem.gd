extends Node
## SaveSystem (Autoload) — salva/carrega progresso do jogo
## Salva: nivel atual, cristais, habilidades, personagem, settings
## Local: user://savegame.cfg

const SAVE_PATH := "user://savegame.cfg"

var save_data: Dictionary = {
	"current_level": 0,
	"crystals": 0,
	"abilities": [],
	"current_character": 0,
	"max_health": 3,
	"settings": {
		"master_vol": 80,
		"music_vol": 70,
		"sfx_vol": 90,
		"fullscreen": false,
		"reduce_shake": false,
		"vibration": true,
	},
}

func save_game() -> void:
	# Update from GameManager
	save_data["current_level"] = GameManager.current_level
	save_data["crystals"] = GameManager.crystals
	save_data["current_character"] = GameManager.current_character
	save_data["max_health"] = GameManager.MAX_HEALTH
	
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(save_data)
		f.close()

func load_game() -> Dictionary:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var data = f.get_var()
		f.close()
		if data is Dictionary:
			save_data = data
		return save_data
	return {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func save_settings(settings: Dictionary) -> void:
	save_data["settings"] = settings
	_write()

func load_settings() -> Dictionary:
	var data := load_game()
	return data.get("settings", save_data["settings"])

func _write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(save_data)
		f.close()