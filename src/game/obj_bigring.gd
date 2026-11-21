extends GMNode
var ready_to_escape := false
var requested := false


func _ready() -> void:
	gm_name = "obj_bigring"
	sprite_name = "spr_bigring"
	if Net.lvlId == 8:
		image_blend = Color.BLACK
	depth = 5
	image_alpha = 0.0
	super._ready()


func _gm_step() -> void:
	image_alpha = minf(1.0, image_alpha + 0.01)
	sprite_name = "spr_bigring_ready" if ready_to_escape else "spr_bigring"
	var player: GMNode = Globals.player
	if not ready_to_escape or requested or not is_instance_valid(player):
		return
	if (
		Globals.character == Globals.CHARACTER_EXE
		or player.revivalTimes >= 2
		or player.isDead
		or player.hp <= 0
		or player.redRingTimer > 0
	):
		return
	if (
		Net.lvlId == 1
		and get_tree().current_scene.get("rules") != null
		and get_tree().current_scene.rules.shard_count < 6
	):
		return
	if bbox_rect().intersects(player.bbox_rect()):
		Net.send_server_tcp(Net.cpacket_tcp(Net.PacketType.CLIENT_PLAYER_ESCAPED))
		requested = true
		get_tree().create_timer(1.0).timeout.connect(
			func():
				if is_instance_valid(self):
					requested = false
		)
