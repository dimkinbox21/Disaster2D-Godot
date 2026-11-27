extends RefCounted
## Only SERVER_PLAYER_HEALTH may change network HP, death or revival state.
var net: Node
var states := {}
var hints := {}


func _init(client: Node):
	net = client


func clear():
	states.clear()
	hints.clear()


func receive(b: StreamPeerBuffer):
	if b.get_available_bytes() < 31:
		return
	if b.get_u32() != net.round_id:
		return
	var data := {
		"revision": b.get_u32(),
		"id": b.get_u16(),
		"hp": b.get_u8(),
		"revival": b.get_u8(),
		"rings": b.get_u16(),
		"dead": b.get_u8() != 0,
		"invul": b.get_u16(),
		"timer": b.get_u16(),
		"near": b.get_u8() != 0,
		"red": b.get_u16(),
		"impact": b.get_u8(),
		"push": b.get_float(),
		"lift": b.get_float()
	}
	if (
		data.hp > 5
		or data.revival > 2
		or data.revision <= states.get(data.id, {}).get("revision", -1)
	):
		return
	states[data.id] = data
	if net.players.has(data.id):
		for key in ["hp", "revival", "rings", "dead"]:
			net.players[data.id][key] = data[key]
	if net.state != net.STATE_GAME or not net.active_game_map():
		return
	var globals = net.get_node("/root/Globals")
	if data.id == net.nid and is_instance_valid(globals.player):
		apply(globals.player, data, true)
	for puppet in net.get_tree().get_nodes_in_group("obj_player_puppet"):
		if puppet.master_id == data.id:
			apply(puppet, data, true)


func attach(actor: Node, id: int):
	if net.state == net.STATE_GAME and states.has(id):
		apply(actor, states[id], false)


func apply(actor: Node, data: Dictionary, feedback: bool):
	var globals = net.get_node("/root/Globals")
	var local: bool = actor == globals.player
	var old_hp: int = actor.hp
	var old_revival: int = actor.revivalTimes
	actor.revivalTimes = data.revival
	if local:
		var was_dead: bool = actor.isDead
		var hint: Dictionary = hints.get(data.id, {})
		if data.dead and not was_dead:
			actor.player_instakill(true)
		elif data.revival >= 2 and old_revival < 2:
			actor.isDead = false
			actor.server_death = false
			globals.cameraMode = 0
			actor.reset_character_abilities()
			GameAudio.play_sound("snd_demonization")
			Achievements.rules.event("demon")
		elif not data.dead and was_dead:
			actor.isDead = false
			actor.server_death = false
			globals.cameraMode = 0
			actor.isHurt = false
			actor.isAttacking = false
			actor.reset_character_abilities()
		elif feedback and data.hp < old_hp:
			if int(hint.get("mode", 0)) == 3:
				GameAudio.play_sound("snd_blackring")
				for level in net.get_tree().get_nodes_in_group("obj_level"):
					level.bloodFade = 0.4
			else:
				var lava: bool = int(hint.get("mode", 0)) == 6
				var sound := (
					"snd_lavahit" if lava else "snd_hurt" if data.impact in [2, 3] else "snd_spike"
				)
				actor.player_hurt(
					old_hp - data.hp,
					float(hint.get("push", data.push)),
					-2.0 if lava else data.lift,
					sound,
					"spr_blood3" if data.impact == 2 else "spr_blood1",
					true,
					true
				)
		elif feedback and data.impact > 0 and data.hp == old_hp and not data.dead:
			# Hunters and demons take knockback from hazards without losing HP.
			actor.player_hurt(
				1,
				data.push,
				data.lift,
				"snd_spike" if data.impact == 1 else "snd_hurt",
				"spr_blood1",
				true,
				true
			)
		elif feedback and data.hp > old_hp and old_revival == data.revival:
			GameAudio.play_sound("snd_heal")
			actor.quick_effect(actor.position.x, actor.position.y - 10, "spr_heal_part")
		actor.hp = data.hp
		actor.isDead = data.dead
		actor.server_death = data.dead
		actor.deadTimer = ceili(data.timer / 60.0)
		actor.deadColor = Color.RED if data.near else Color.WHITE
		actor.hurttime = data.invul
		if data.red > 0 and actor.redRingTimer <= 0:
			actor.take_red_ring()
		if data.red == 0 and actor.redRingTimer > 0:
			GameAudio.crossfade_music("mus_mindfuck", 0.0)
			for screen in net.get_tree().get_nodes_in_group("obj_redring_screen"):
				screen.queue_free()
		actor.redRingTimer = data.red
		hints.erase(data.id)
	else:
		actor.hp = data.hp
		actor.isHurt = data.invul > 0
		actor.deadTimer = ceili(data.timer / 60.0)
		actor.deadColor = Color.RED if data.near else Color.WHITE
		actor.hasRedRing = data.red > 0
		if data.dead:
			actor.pstate = 6
		elif actor.pstate == 6:
			actor.pstate = 4
		actor.isDemonized = actor.pcharacter == 0 or data.revival >= 2
	actor.revivalTimes = data.revival
	actor.rings = data.rings
	actor.queue_redraw()
	net.draw_profile_interaction(actor, data.id)
