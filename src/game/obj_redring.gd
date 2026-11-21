extends GMNode
## Port of obj_redring — the red ring.
## Picking it up (survivor, not demonized, hp > 0, no frenzy running) starts
## the 10-second "mindfuck" frenzy: redRingTimer = 60*10, snd_redring,
## mus_mindfuck + obj_redring_screen. Red rings never break (no ringBreak, no
## projectile branch — the attacker branches live in obj_ring only) and fade
## in slower than a normal ring (1/180 per step).

var iid := 0
var nid := 0
var used := false
var on_despawn: Callable = Callable()


func _ready() -> void:
	sprite_name = "spr_redring"  # obj_redring.yy spriteId
	if Net.lvlId == 8:
		image_blend = Color("404040")
	super._ready()
	image_alpha = 0.0
	depth = 2


func _gm_step() -> void:
	# obj_redring Step_0: image_alpha += 1/180 (a slower fade than obj_ring)
	if image_alpha < 1:
		image_alpha += 1.0 / 180.0
	image_index = Globals.ringFrame
	if used:
		return
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	# the original: global.character != CHARACTER_EXE, redRingTimer > 0 → return
	if Globals.character == Globals.CHARACTER_EXE or player.revivalTimes >= 2:
		return
	if visible and image_alpha >= 1 and bbox_rect().intersects(player.bbox_rect()):
		if player.hp <= 0 or player.redRingTimer > 0:
			return
		# CLIENT_RING_COLLECTED (_redRing) — solo: apply the effect locally
		if Net.state == Net.STATE_GAME:
			used = true
			Net.report_ring_collected(iid, nid)
			return
		player.take_red_ring()
		used = true
		if on_despawn.is_valid():
			on_despawn.call()  # the spawner restarts its respawn timer
		queue_free()


func net_destroy() -> void:
	queue_free()
