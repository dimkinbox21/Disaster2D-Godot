extends GMNode
var nid := 0
var owner_id: int = -1
var slot := 0
var nickname := ""


func _ready():
	gm_name = "obj_exeller_clone"
	sprite_name = "spr_exeller_clone"
	depth = 8
	pixel_snap = true
	if Net.lvlId == 8:
		image_blend = Color.BLACK
	super._ready()


func _gm_step():
	if Net.state != Net.STATE_GAME and Net.lvlId == 6:
		# Resolve intersections by bounds, not by thousands of one-pixel scans.
		var start_y := position.y
		for attempts in 128:
			var floor_node := GMFloor.rect_floor_inst(
				Rect2(position - Vector2(7, 20), Vector2(15, 39))
			)
			if floor_node == null:
				break
			var next_y := minf(position.y - 1, floor_node.cached_bbox().position.y - 19)
			if start_y - next_y > 4096:
				break
			position.y = next_y
	var supported := GMFloor.point_meeting_group(position.x, position.y + 18, "gm_floor") != null
	var idle := false
	if owner_id == Net.nid and Globals.character == 0 and is_instance_valid(Globals.player):
		idle = Globals.player.state == 0
	else:
		for puppet in GMNode.all_of("obj_player_puppet"):
			if puppet.master_id == owner_id:
				idle = puppet.pstate == 0
				break
	var next: String = (
		("spr_exeller_idle" if idle else "spr_exeller_clone") if supported else "spr_exeller_clone2"
	)
	if sprite_name != next:
		sprite_name = next
		image_index = 0
		_anim_accum = 0


func nearest_survivor() -> GMNode:
	var best: GMNode = null
	var distance := 240.0
	var box := bbox_rect()
	for target in GMNode.all_of("obj_player_puppet"):
		if (
			target.pcharacter <= 0
			or target.hp <= 0
			or target.revivalTimes >= 2
			or target.isInactive
		):
			continue
		var other: Rect2 = target.bbox_rect()
		var gap := (
			Vector2(
				maxf(0, maxf(box.position.x - other.end.x, other.position.x - box.end.x)),
				maxf(0, maxf(box.position.y - other.end.y, other.position.y - box.end.y))
			)
			. length()
		)
		if gap < distance:
			distance = gap
			best = target
	return best


func frame_texture() -> Texture2D:
	if owner_id == Net.nid:
		return Unlockables.actor_texture(
			sprite_name, int(image_index), 0, Globals.EXE_EXELLER, 0, self
		)
	var pal: Dictionary = Net.players.get(owner_id, {}).get("palette", {})
	return VisualEffects.actor_texture(self, pal)


func _gm_draw():
	draw_self()
