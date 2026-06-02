extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor:
		return FAILURE
	if actor.bossfight_started == true:
		return SUCCESS
	return FAILURE
