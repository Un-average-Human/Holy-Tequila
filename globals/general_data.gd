extends Node

var rng = RandomNumberGenerator.new()

var menu = "uid://yo1ornr2fnjs"
var current_world
var current_boss: String = ""

var boss_data: Dictionary = {
	"Spaceship Boss": {
		"losing_quote":
			"Zirp zorp gloop-glorp?! Blip bleep ZURP!
			
			[i](How am I supposed to land a hit when I don't even have a Z axis?! Don Ramon said the corporate restructuring would affect everyone equally!)[/i]",
		
		"winning_quote":
			"Zorp zurp? Zarp glarp glorp. Gloobglob bleep-!
			
			[i](Wait what? I won...? The developers didn't add a winning animation for me nor tested what would happen if I won. The game is gonna cra-!)[/i]"
	}
}
