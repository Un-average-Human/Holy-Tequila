extends Node

var player_won: bool = false
var health: int = 3
var rng = RandomNumberGenerator.new()

var mini_bosses_available: Array[String] = ["burger"]
var selected_mini_boss_name: String = ""

var worlds: Dictionary[String, String] = { 
	"food" : "mars", 
	"mega_market" : "food",
	"brainrot" : "mega_market",
	"water" : "brainrot",
	"pirate" : "water",
	"database" : "pirate",
	"?" : "pirate",
	"tequila" : "?"
	}
var worlds_available: Array[String] = []
var world_beaten: String:
	set(value):
		world_beaten = value
		_update_beaten_worlds()

var current_world
var current_boss: String = ""

var boss_data: Dictionary = {
	"Spaceship Boss": {
		"losing_quote":
			"Zirp zorp gloop-glorp?! Blip bleep ZURP!\n\n[i](How am I supposed to land a hit when I don't even have a Z axis?! Don Ramon said the corporate restructuring would affect everyone equally!)[/i]",
		
		"winning_quote":
			"Zorp zurp? Zarp glarp glorp. Gloobglob bleep-!\n\n[i](Wait what? I won...? The developers didn't add a winning animation for me nor tested what would happen if I won. The game is gonna cra-!)[/i]"}
			}

func _update_beaten_worlds():
	for world_to_beat in worlds.values():
		if world_beaten == world_to_beat:
			var next_world = worlds.find_key(world_to_beat)
			worlds_available.append(next_world)
