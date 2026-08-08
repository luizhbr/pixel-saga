extends Node
## GameManager (Autoload Singleton)
## Gerencia estado global: vida, personagem ativo, cristais

signal health_changed(new_health: int, max_health: int)
signal character_changed(char_index: int)
signal crystals_changed(amount: int)
signal player_died

const MAX_HEALTH: int = 3
const CHARACTERS: Array = ["mossy", "polo", "garrax"]
const CHAR_NAMES: Array = ["Mossy", "Capitão Polo", "Garrax"]
const CHAR_ABILITIES: Array = ["Florir", "Escudo Gélido", "Dash Sombrio"]

var health: int = MAX_HEALTH
var current_character: int = 0
var crystals: int = 0
var current_level: int = 0

func take_damage(amount: int = 1) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		player_died.emit()

func heal(amount: int = 1) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

func switch_character() -> int:
	current_character = (current_character + 1) % CHARACTERS.size()
	character_changed.emit(current_character)
	return current_character

func add_crystal() -> void:
	crystals += 1
	crystals_changed.emit(crystals)

func reset() -> void:
	health = MAX_HEALTH
	current_character = 0
	crystals = 0
	current_level = 0