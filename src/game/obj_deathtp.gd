extends GMNode


## obj_deathtp: recover a downed body from the map's recesses; living players
## are unaffected. The original checks the left foot sensor twice.
func _ready() -> void:
	process_physics_priority = 20
	super._ready()


func _gm_step() -> void:
	var player: GMNode = Globals.player
	if not is_instance_valid(player) or player.state != player.DEAD or player.hp > 0:
		return
	if not bbox_rect().has_point(player._sens_BL):
		return
	var nearest: GMNode = null
	var best := INF
	for target in GMNode.all_of("obj_deathtp_point"):
		var distance: float = player.position.distance_squared_to(target.position)
		if distance < best:
			best = distance
			nearest = target
	if nearest == null:
		return
	player.position = nearest.position + Vector2(0, -2)
	player.gspd = 0
	player.xspd = 0
	player.yspd = 0


func _gm_draw() -> void:
	pass
