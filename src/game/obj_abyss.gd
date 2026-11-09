extends GMNode
## Port of obj_abyss / obj_abyss_target — fall-through zones teleport the
## player to the paired target.

var shouldStun := false

func _gm_step() -> void:
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	if not position_meeting(player.position.x, player.position.y):
		return
	var nearest: GMNode = null
	var best := 1e18
	for tgt in GMNode.all_of("obj_abyss_target"):
		var dist: float = tgt.position.distance_squared_to(player.position)
		if dist < best:
			best = dist
			nearest = tgt
	if nearest:
		player.position = nearest.position
		player.xspd = 0
		player.gspd = 0
		player.yspd = 0
		if shouldStun:
			player.shockedTimer += 30

func _gm_draw() -> void:
	pass
