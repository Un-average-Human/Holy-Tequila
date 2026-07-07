extends Node

var player_won: bool = false

var rng = RandomNumberGenerator.new()

var current_world
var current_boss: String = ""

var boss_data: Dictionary = {
	"Spaceship Boss": {
		"losing_quote":
			"Zirp zorp gloop-glorp?! Blip bleep ZURP!\n\n[i](How am I supposed to land a hit when I don't even have a Z axis?! Don Ramon said the corporate restructuring would affect everyone equally!)[/i]",
		
		"winning_quote":
			"Zorp zurp? Zarp glarp glorp. Gloobglob bleep-!\n\n[i](Wait what? I won...? The developers didn't add a winning animation for me nor tested what would happen if I won. The game is gonna cra-!)[/i]"
	}
}
