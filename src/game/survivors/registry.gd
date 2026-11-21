extends RefCounted
## One controller per survivor; no actor/factory cycle or scene replacement.
const Tails = preload("res://src/game/survivors/tails.gd")
const Knuckles = preload("res://src/game/survivors/knuckles.gd")
const Eggman = preload("res://src/game/survivors/eggman.gd")
const Amy = preload("res://src/game/survivors/amy.gd")
const Cream = preload("res://src/game/survivors/cream.gd")
const Sally = preload("res://src/game/survivors/sally.gd")
const CONTROLLERS := {1: Tails, 2: Knuckles, 3: Eggman, 4: Amy, 5: Cream, 6: Sally}


static func create(id: int, actor: GMNode) -> RefCounted:
	return CONTROLLERS[id].new(actor) if CONTROLLERS.has(id) else null
