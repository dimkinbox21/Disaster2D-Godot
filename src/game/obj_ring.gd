extends GMNode
## Port of obj_ring — collectible ring.
## The original is fully server-driven (SERVER_RING_STATE spawns/collects/
## destroys them); solo emulates the cycle locally (map_controller's spawners
## re-spawn each ring after RESPAWN_DELAY, see map_controller.gd).

var nid := 0
var iid := 0
var used := false
## Callable(spawn record) invoked once before the ring despawns (collected or
## broken) — the spawner restarts its respawn timer
var on_despawn: Callable = Callable()


func _ready() -> void:
	# obj_ring.yy spriteId — the map_controller never sets sprite_name, and
	# nothing calls default_sprite_name(), so the rings were invisible
	sprite_name = "spr_ring"
	if Net.lvlId == 8:
		image_blend = Color("404040")
	super._ready()
	image_alpha = 0.0
	depth = 2


func _gm_step() -> void:
	if image_alpha < 1:
		image_alpha += 1.0 / 30.0
	image_index = Globals.ringFrame
	if used:
		return
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	# obj_ring Step_0: the exe and the demonized survivors never collect —
	# and only a non-Tails/Cream attacker breaks rings (demon Tails' ATTACKS
	# never do; HIS projectile does — the instance_place check below)
	if Globals.character == Globals.CHARACTER_EXE or player.revivalTimes >= 2:
		if (
			Globals.character != Globals.CHARACTER_TAILS
			and Globals.character != Globals.CHARACTER_CREAM
			and player.isAttacking
			and visible
			and image_alpha >= 1
			and bbox_rect().intersects(player.bbox_rect())
		):
			ring_break()
			return
	# place_meeting uses both masks: a 16x16 ring, not only its top-left point.
	if (
		Globals.character != Globals.CHARACTER_EXE
		and player.revivalTimes < 2
		and visible
		and image_alpha >= 1
		and bbox_rect().intersects(player.bbox_rect())
	):
		if player.hp <= 0:
			return
		if Net.state == Net.STATE_GAME:
			# netplay: the SERVER owns the pickup — report and hold until the
			# SERVER_RING_STATE(1) destroy broadcast frees this ring everywhere
			if not used:
				used = true
				Net.report_ring_collected(iid, nid)
			return
		# solo practice: local collect (obj_net's SERVER_RING_COLLECTED type 0 → +1)
		player.ring_collected(1)
		_despawn()
		return
	# obj_ring Step_0: instance_place(x, y, obj_tails_projectile) with
	# isOwner && isExe — a demon Tails' shot breaks rings on contact.
	# (obj_redring has no such branch — red rings never break.)
	for pr in GMNode.all_of("obj_tails_projectile"):
		var prn: GMNode = pr
		if not bool(prn.get("is_owner")) or not bool(prn.get("is_exe")):
			continue
		if bbox_rect().intersects(prn.bbox_rect()):
			ring_break()
			return


func ring_break() -> void:
	if used:
		return
	used = true
	GameAudio.play_sound("snd_exe_ringshutter")
	Net.spawn_ring_parts(position, player_xspd())
	if Net.state == Net.STATE_GAME:
		# netplay: broadcast the break — the others spawn the particles from
		# CLIENT_RING_BROKE and every client's copy dies via RING_STATE(1)
		Net.report_ring_broke(iid, nid, int(position.x), int(position.y), player_xspd())
		_despawn()
		return

	_despawn()


## SERVER_RING_STATE(1) — the server confirmed the collection; every client
## frees its copy (the sparkle is the original's destroy effect)
func net_destroy() -> void:
	var e := GMNode.new()
	e.set_script(load("res://src/game/obj_quickfx.gd"))
	e.position = position
	e.sprite_name = "spr_ring_sparkle"
	e.z_index = z_index - 1
	get_parent().add_child(e)
	_despawn()


func _despawn() -> void:
	if on_despawn.is_valid():
		on_despawn.call()  # the spawner restarts its respawn timer
	queue_free()


func player_xspd() -> float:
	for p in GMNode.all_of("obj_player"):
		return p.xspd
	return 0.0
