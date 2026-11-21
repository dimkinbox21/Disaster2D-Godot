extends GMNode
## obj_eggtrack: activation and identity belong to the server in network play.
var nid := 0
var owner_id := -1
var demon := false
var activated := false


func _ready() -> void:
	gm_name = "obj_eggtrack"
	sprite_name = "spr_eggtrack"
	pixel_snap = true
	depth = -2
	super._ready()


func _gm_step() -> void:
	if activated:
		return
	demon = current_demon()
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or p.isDead or Globals.character == 3:
		return
	if (Globals.character == 0 or p.revivalTimes >= 2) == demon:
		return
	if not bbox_rect().intersects(p.bbox_rect()):
		return
	activated = true
	if Net.state == Net.STATE_GAME:
		var b := Net.cpacket_tcp(Net.PacketType.CLIENT_ETRACKER_ACTIVATED)
		b.put_u16(nid)
		Net.send_server_tcp(b)
	else:
		p.apply_slow(180, 0.7 if Globals.character == 0 else 0.6)
		GameAudio.play_sound("snd_egg_tracker_activate")
		destroy_tracker()


func current_demon() -> bool:
	if owner_id == Net.nid and is_instance_valid(Globals.player):
		return Globals.player.revivalTimes >= 2
	for puppet in GMNode.all_of("obj_player_puppet"):
		if puppet.master_id == owner_id:
			return puppet.revivalTimes >= 2
	return demon


func destroy_tracker() -> void:
	activated = true
	sprite_name = "spr_eggtrack_destroy"
	image_index = 0
	image_speed = 1
	queue_redraw()


func _gm_animation_end() -> void:
	if sprite_name == "spr_eggtrack_destroy":
		queue_free()
