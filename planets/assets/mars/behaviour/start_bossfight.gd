extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	if !blackboard.get_value("boss_intro_started", false):
		
		#animation stuff
		actor.boss_sprite.play("idle")
		actor.boss_animation.play("pop_up")
		
		#adds this value to the enemy's dictionary
		blackboard.set_value("boss_intro_started", true)
	return SUCCESS
