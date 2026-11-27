extends GMNode
## Port of obj_player_puppet — the OTHER players on the map.
## The original is fully server-relayed: every client sends CLIENT_PLAYER_DATA
## (UDP, every physics frame) and the server forwards it to the others; the
## receiver moves the matching puppet (net_udpprocess). This port keeps the
## same packet shape and the same per-frame cadence.
## Stage A: spawn/move/animate/draw. The Step_0 attack interactions land with
## the damage sync; the exe puppets draw with the EXE_ORIGINAL table (the other
## exe characters' tables land with their ports).

## scr_survivors global.player_anims — state-indexed sprite tables (1 tails…6 sally)
const ANIMS := {
	1:
	[
		"spr_tails_idle",
		"spr_tails_walk",
		"spr_tails_run",
		"spr_tails_jump",
		"spr_tails_fall",
		"spr_tails_hurt",
		"spr_tails_dead",
		"spr_tails_lookup",
		"spr_tails_lookdown",
		"spr_tails_emotion1",
		"spr_tails_emotion2",
		"spr_tails_emotion3",
		"spr_tails_jump",
		"spr_tails_balancing",
		"spr_tails_fly",
		"spr_tails_attack1",
		"spr_tails_zipline"
	],
	2:
	[
		"spr_knux_idle",
		"spr_knux_walk",
		"spr_knux_run",
		"spr_knux_jump",
		"spr_knux_fall",
		"spr_knux_hurt",
		"spr_knux_dead",
		"spr_knux_lookup",
		"spr_knux_lookdown",
		"spr_knux_emotion1",
		"spr_knux_emotion2",
		"spr_knux_emotion3",
		"spr_knux_jump",
		"spr_knux_balancing",
		"spr_knux_attack2",
		"spr_knux_attack1",
		"spr_knux_glide",
		"spr_knux_zipline",
		"spr_knux_stuck"
	],
	3:
	[
		"spr_egg_idle",
		"spr_egg_walk",
		"spr_egg_run",
		"spr_egg_jump",
		"spr_egg_fall",
		"spr_egg_hurt",
		"spr_egg_dead",
		"spr_egg_lookup",
		"spr_egg_lookdown",
		"spr_egg_emotion1",
		"spr_egg_emotion2",
		"spr_egg_emotion3",
		"spr_egg_jump",
		"spr_egg_balancing",
		"spr_egg_djump",
		"spr_egg_zipline"
	],
	4:
	[
		"spr_amy_idle",
		"spr_amy_walk",
		"spr_amy_run",
		"spr_amy_jump",
		"spr_amy_fall",
		"spr_amy_hurt",
		"spr_amy_dead",
		"spr_amy_lookup",
		"spr_amy_lookdown",
		"spr_amy_emotion1",
		"spr_amy_emotion2",
		"spr_amy_emotion3",
		"spr_amy_jump",
		"spr_amy_balancing",
		"spr_amy_attack1",
		"spr_amy_attack2",
		"spr_none",
		"spr_amy_zipline"
	],
	5:
	[
		"spr_cream_idle",
		"spr_cream_walk",
		"spr_cream_run",
		"spr_cream_jump",
		"spr_cream_fall",
		"spr_cream_hurt",
		"spr_cream_dead",
		"spr_cream_lookup",
		"spr_cream_lookdown",
		"spr_cream_emotion1",
		"spr_cream_emotion2",
		"spr_cream_emotion3",
		"spr_cream_jump",
		"spr_cream_balancing",
		"spr_cream_fly",
		"spr_cream_srings",
		"spr_cream_zipline"
	],
	6:
	[
		"spr_sally_idle",
		"spr_sally_walk",
		"spr_sally_run",
		"spr_sally_jump",
		"spr_sally_fall",
		"spr_sally_hurt",
		"spr_sally_dead",
		"spr_sally_lookup",
		"spr_sally_lookdown",
		"spr_sally_emotion1",
		"spr_sally_emotion2",
		"spr_sally_emotion3",
		"spr_sally_jump",
		"spr_sally_balancing",
		"spr_sally_attack",
		"spr_sally_slide",
		"spr_none",
		"spr_sally_zipline"
	],
}

## scr_survivors player_eanims — ported demon tables.
const ANIMS_EANIMS := {
	4:
	[
		"spr_eamy_idle",
		"spr_eamy_walk",
		"spr_eamy_run",
		"spr_eamy_jump",
		"spr_eamy_fall",
		"spr_eamy_hurt",
		"spr_eamy_stun",
		"spr_eamy_lookup",
		"spr_eamy_lookdown",
		"spr_eamy_emotion1",
		"spr_eamy_emotion2",
		"spr_eamy_emotion3",
		"spr_eamy_jump",
		"spr_eamy_balancing",
		"spr_eamy_attack1",
		"spr_eamy_attack2",
		"spr_none",
		"spr_eamy_zipline"
	],
	6:
	[
		"spr_esally_idle",
		"spr_esally_walk",
		"spr_esally_run",
		"spr_esally_jump",
		"spr_esally_fall",
		"spr_esally_hurt",
		"spr_esally_stun",
		"spr_esally_lookup",
		"spr_esally_lookdown",
		"spr_esally_emotion1",
		"spr_esally_emotion2",
		"spr_esally_emotion3",
		"spr_esally_jump",
		"spr_esally_balancing",
		"spr_esally_attack",
		"spr_esally_slide",
		"spr_none",
		"spr_esally_zipline"
	],
	2:
	[
		"spr_eknux_idle",
		"spr_eknux_walk",
		"spr_eknux_run",
		"spr_eknux_jump",
		"spr_eknux_fall",
		"spr_eknux_hurt",
		"spr_eknux_stun",
		"spr_eknux_lookup",
		"spr_eknux_lookdown",
		"spr_eknux_emotion1",
		"spr_eknux_emotion2",
		"spr_eknux_emotion3",
		"spr_eknux_jump",
		"spr_eknux_balancing",
		"spr_eknux_attack2",
		"spr_eknux_attack1",
		"spr_eknux_glide",
		"spr_eknux_zipline",
		"spr_eknux_stuck"
	],
	3:
	[
		"spr_eegg_idle",
		"spr_eegg_walk",
		"spr_eegg_run",
		"spr_eegg_jump",
		"spr_eegg_fall",
		"spr_eegg_hurt",
		"spr_eegg_stun",
		"spr_eegg_lookup",
		"spr_eegg_lookdown",
		"spr_eegg_emotion1",
		"spr_eegg_emotion2",
		"spr_eegg_emotion3",
		"spr_eegg_jump",
		"spr_eegg_balancing",
		"spr_eegg_djump",
		"spr_eegg_zipline"
	],
	5:
	[
		"spr_ecream_idle",
		"spr_ecream_walk",
		"spr_ecream_run",
		"spr_ecream_jump",
		"spr_ecream_fall",
		"spr_ecream_hurt",
		"spr_ecream_stun",
		"spr_ecream_lookup",
		"spr_ecream_lookdown",
		"spr_ecream_emotion1",
		"spr_ecream_emotion2",
		"spr_ecream_emotion3",
		"spr_ecream_jump",
		"spr_ecream_balancing",
		"spr_ecream_fly",
		"spr_ecream_srings",
		"spr_ecream_zipline"
	],
	1:
	[
		"spr_etails_idle",
		"spr_etails_walk",
		"spr_etails_run",
		"spr_etails_jump",
		"spr_etails_fall",
		"spr_etails_hurt",
		"spr_etails_stun",
		"spr_etails_lookup",
		"spr_etails_lookdown",
		"spr_etails_emotion1",
		"spr_etails_emotion2",
		"spr_etails_emotion3",
		"spr_etails_jump",
		"spr_etails_balancing",
		"spr_etails_fly",
		"spr_etails_attack1",
		"spr_etails_zipline"
	],
}

## global.player_exesanims[? EXE_ORIGINAL] — the exe puppet's table (stage A:
## EXE_ORIGINAL only; the others' tables land with their ports). State-indexed
## like anims_visible in player.gd (DEAD slot = spr_exe_jump there).
const EXE_ANIMS := [
	"spr_exe_idle",
	"spr_exe_walk",
	"spr_exe_run",
	"spr_exe_jump",
	"spr_exe_fall",
	"spr_exe_hurt",
	"spr_exe_jump",
	"spr_exe_lookup",
	"spr_exe_lookdown",
	"spr_exe_emotion2",
	"spr_exe_emotion3",
	"spr_exe_emotion",
	"spr_exe_jump",
	"spr_exe_balancing",
	"spr_exe_attack1",
	"spr_exe_attack2",
	"spr_exe_shocked",
	"spr_exe_emotion",
	"spr_exe_lost",
	"spr_exe_zipline",
]

## obj_player_puppet Create_0
var master_id := 0
var is_cheating := 0
var pcharacter := -1
var pexe_character := 0
var pstate := 0
var hp := 5
var deadTimer := 31
var deadColor := Color.WHITE
var nickname := ""
var nicknameWidth := 0.0
var rings := 0
var shards := 0
var isDemonized := false
var isAttacking := false
var isHurt := false
var revivalTimes := 0
var xspd := 0.0
var yspd := 0.0
var pX := 0.0
var pY := 0.0
var isHiding := false
var hasRedRing := false
var tailsCharge := 0
var tail_angle := 0.0
var isInactive := true
var angle := 0.0
var effect := false
var effectTimer := 0
var sallyShield := false
var slimeMode := false
const ExellerArt = preload("res://src/game/hunters/exeller_anims.gd")
const ExetiorArt = preload("res://src/game/hunters/exetior_anims.gd")
const ChaosArt = preload("res://src/game/hunters/chaos_anims.gd")

## the glide: after a packet the puppet drifts xspd/yspd for 5 frames
## (net_udpprocess sets alarm[2] = 5; GMNode has no alarms — a frame counter)
var _glide := 0


func _ready() -> void:
	pixel_snap = true
	gm_name = "obj_player_puppet"  # spawned dynamically — must self-stamp its group
	# Create_0: depth = obj_spawnpoint.depth + 2 (the spawnpoint sits at 0)
	depth = 2
	super._ready()
	sprite_name = ""
	image_speed = 0.0
	Net.health.attach(self, master_id)
	Net.motion.attach(self, master_id)


func _gm_step() -> void:
	if hp <= 0 and revivalTimes < 2 and pcharacter > 0:
		pstate = 6
	if pcharacter != Globals.CHARACTER_EXE:
		isHiding = (
			pstate == 8 and GMFloor.rect_meeting_group(bbox_rect(), "obj_hiding_parent") != null
		)
	image_alpha = 0.5 if isHurt or isHiding else 1.0
	isDemonized = revivalTimes >= 2 or pcharacter == Globals.CHARACTER_EXE
	# Step_0: while alarm[2] > 0 the puppet drifts on its packet speed
	if _glide > 0:
		position.x += xspd
		position.y += yspd
		_glide -= 1
	# Step_0: the inactive puppet draws dark (c_dkgray)
	image_blend = Color("555555") if isInactive else Color.WHITE
	if Net.lvlId == 8:
		image_blend = Color.BLACK
	if pcharacter == -1 or Net.gameEnds:
		return
	_step_visual_effects()
	# Step_0's first branch: a demonized puppet touching the LOCAL survivor —
	# the victim's client applies the hit for responsiveness and reports it;
	# the SERVER validates (hurttime/dead) and owns the hp
	var lp: GMNode = Globals.player
	if (
		is_instance_valid(lp)
		and pcharacter in [2, 3, 4, 6]
		and isAttacking
		and not isDemonized
		and visible
		and not isInactive
		and not lp.isDead
		and (Globals.character == 0 or lp.revivalTimes >= 2)
		and lp.shockedTimer <= 0
		and lp.hurttime <= 0
		and (Globals.character != 0 or lp.invisTimer <= 0)
		and lp.bbox_rect().intersects(bbox_rect())
	):
		if pcharacter in [2, 6] and Globals.character not in [3, 4] and lp.isAttacking:
			counter_attack(lp, 2)
			return
		if Globals.character == 4 and lp.isAttacking:
			return
		if Globals.character == 6 and lp.shieldTimer > 0:
			Net.report_player_hurt(master_id, int(position.x), int(position.y), 180)
			lp.survivor.absorb_damage()
			lp.isGrounded = false
			lp.isHurt = true
			lp.xspd = signf(lp.position.x - position.x) * 2
			lp.yspd = -2
			return
		var electro := pcharacter == 3
		var duration := 120 if electro else 180
		Net.report_player_hurt(master_id, int(position.x), int(position.y), duration)
		lp.shockedTimer = duration
		lp.hurttime = duration + 120
		lp.xspd = 0 if electro else -signf(position.x - lp.position.x) * 4
		lp.yspd = -2
		lp.isGrounded = false
		GameAudio.play_sound("snd_electroshock" if electro else "snd_exe_stun")
		if electro:
			lp.quick_effect(lp.position.x, lp.position.y, "spr_shockparticle")
		elif Globals.character == 0:
			GameAudio.play_exe_stun(Globals.exeCharacter)
	if (
		pcharacter == 0
		and pexe_character == Globals.EXE_CHAOS
		and effect
		and Engine.get_physics_frames() % 5 == 0
	):
		var drop := GMNode.new()
		drop.set_script(load("res://src/game/hunters/chaos_drop.gd"))
		drop.position = position
		drop.image_blend = image_blend
		get_parent().add_child(drop)
	if effect and Engine.get_physics_frames() % 3 == 0:
		var ghost := GMNode.new()
		ghost.set_script(load("res://src/game/obj_quickfx.gd"))
		ghost.position = position
		ghost.sprite_name = sprite_name
		ghost.image_index = image_index
		ghost.image_speed = 0
		ghost.image_xscale = image_xscale
		get_parent().add_child(ghost)
		ghost.z_index = z_index - 10
	if pcharacter == 3 and pstate == 14 and floori(position.y) % 10 == 0 and is_instance_valid(lp):
		lp.quick_effect(position.x, position.y, "spr_eggpack", false)
	if (
		pcharacter == 6
		and pstate == 15
		and floori(position.x) % 5 == 0
		and visible
		and not isInactive
		and is_instance_valid(lp)
	):
		lp.quick_effect(position.x - 8 * signf(xspd), position.y + 20, "spr_dust")
		GameAudio.play_sound_at("snd_sally_slide", position)
	if not is_instance_valid(lp) or not isDemonized or not visible or isInactive:
		return
	if (
		Globals.character == Globals.CHARACTER_EXE
		or lp.revivalTimes >= 2
		or lp.isDead
		or lp.hp <= 0
		or lp.hurttime > 0
	):
		return
	if pcharacter == 0 and pexe_character == Globals.EXE_CHAOS and slimeMode:
		return
	var spin_hit := pstate in [3, 12] and pcharacter not in [3, 4, 6]
	if not isAttacking and not spin_hit:
		return
	if lp.survivor != null and lp.survivor.blocks_melee(spin_hit and not isAttacking):
		return
	if spin_hit and not isAttacking and (lp.isJumping or lp.isSpinning or lp.bounceTimer > 0):
		return
	if spin_hit and not isAttacking and Globals.character in [2, 6] and lp.isAttacking:
		return
	if lp.bbox_rect().intersects(bbox_rect()):
		if (
			isAttacking
			and pcharacter not in [3, 4]
			and Globals.character in [2, 6]
			and lp.isAttacking
		):
			counter_attack(lp, 3)
			return
		if Globals.character == 3 and lp.isAttacking and pcharacter != 4:
			return
		var dmg := 1
		if isAttacking and pcharacter == Globals.CHARACTER_EXE and pexe_character in [0, 2, 3]:
			dmg = 2
		Net.report_player_hurt(master_id, int(position.x), int(position.y), 0)
		if Globals.character == 6 and lp.shieldTimer > 0:
			lp.survivor.absorb_damage()
			lp.isGrounded = false
			lp.isHurt = true
			lp.xspd = signf(lp.position.x - position.x) * (3 if spin_hit and not isAttacking else 2)
			lp.yspd = -4 if spin_hit and not isAttacking else -2
			return
		if pcharacter == 3:
			lp.apply_slow(180)
		lp.player_hurt(dmg, image_xscale * 3.0, -3.0, "snd_hurt", "spr_blood3", true)


## Original Step_0: meeting punches cancel each other without damage or stun.
func counter_attack(player: GMNode, push: float) -> void:
	Net.report_parry(master_id)
	player.apply_parry(signf(player.position.x - position.x) * push, 60)


## Draw_72 — sprite_index from the per-character table
func apply_anim() -> void:
	if pcharacter == -1:
		return
	if pcharacter == Globals.CHARACTER_EXE:
		if pexe_character == Globals.EXE_EXELLER:
			if pstate >= 0 and pstate < ExellerArt.NORMAL.size():
				sprite_name = ExellerArt.NORMAL[pstate]
			return
		if pexe_character == Globals.EXE_EXETIOR:
			if pstate >= 0 and pstate < ExetiorArt.NORMAL.size():
				sprite_name = ExetiorArt.NORMAL[pstate]
			return
		if pexe_character == Globals.EXE_CHAOS:
			var table: Array = ChaosArt.SLIME if slimeMode else ChaosArt.NORMAL
			if pstate >= 0 and pstate < table.size():
				sprite_name = table[pstate]
			return
		if pstate >= EXE_ANIMS.size():
			return
		sprite_name = EXE_ANIMS[pstate]
		return
	var table: Array = (ANIMS_EANIMS if revivalTimes >= 2 else ANIMS).get(pcharacter, [])
	if pstate >= table.size():
		return
	var sn: String = table[pstate]
	sprite_name = "" if sn == "spr_none" else sn


## the map-entry spawn helper (Other_4 field assignment)
func setup(nid: int, nick: String, ch: int, exe_ch: int) -> void:
	pcharacter = ch
	pexe_character = exe_ch
	pstate = 0
	master_id = nid
	nickname = nick
	position = Vector2.ZERO
	pX = 0.0
	pY = 0.0


## net_udpprocess CLIENT_PLAYER_DATA — move + state from the relay
func net_update(rb: StreamPeerBuffer) -> void:
	isInactive = false
	_glide = 5  # alarm[2] = 5
	pX = position.x
	pY = position.y
	position.x = rb.get_16()
	position.y = rb.get_16()
	xspd = Net.get_f16(rb)
	yspd = Net.get_f16(rb)
	pstate = rb.get_u8()
	angle = float(rb.get_16())
	image_index = float(rb.get_u8())
	image_xscale = clampf(float(rb.get_8()), -1.0, 1.0)
	if pcharacter == Globals.CHARACTER_EXE:
		var bitflags := rb.get_u8()
		isAttacking = bitflags & Net.PLAYER_ATTACKING != 0
		isHurt = bitflags & Net.PLAYER_HURT != 0
		effect = bitflags & Net.PLAYER_EFFECT != 0
		# PLAYER_INVIS (exeCharacter 0) — the exe puppet vanishes while invisible
		slimeMode = pexe_character == Globals.EXE_CHAOS and bitflags & Net.PLAYER_SLIME != 0
		isHiding = pexe_character == Globals.EXE_ORIGINAL and bitflags & Net.PLAYER_INVIS != 0
		visible = not isHiding
	else:
		var bitflags := rb.get_u8()
		if pcharacter == Globals.CHARACTER_TAILS:
			tailsCharge = rb.get_u8()
			tail_angle = float(rb.get_16())
		if (
			pcharacter
			in [
				Globals.CHARACTER_KNUX,
				Globals.CHARACTER_EGGMAN,
				Globals.CHARACTER_AMY,
				Globals.CHARACTER_SALLY
			]
		):
			isAttacking = bitflags & Net.PLAYER_ATTACKING != 0
		isHurt = bitflags & Net.PLAYER_HURT != 0
		hasRedRing = bitflags & Net.PLAYER_REDRING != 0
		sallyShield = pcharacter == 6 and bitflags & Net.PLAYER_SALLYSHIELD != 0
		effect = bitflags & Net.PLAYER_EFFECT != 0


func frame_texture() -> Texture2D:
	var pal: Dictionary = Net.players.get(master_id, {}).get("palette", {})
	return VisualEffects.actor_texture(self, pal)


func _step_visual_effects():
	if not effect or isInactive or not visible:
		effectTimer = 0
		return
	effectTimer += 1
	var pal: Dictionary = Net.players.get(master_id, {}).get("palette", {})
	if effectTimer % 3 == 0:
		var ghost = load("res://src/game/obj_quickfx.gd").new()
		ghost.position = position
		ghost.sprite_name = sprite_name
		ghost.image_index = image_index
		ghost.image_xscale = image_xscale
		ghost.image_speed = 0
		ghost.image_blend = image_blend
		ghost.depth = depth + 1
		ghost.palette_from = pal.get("from", [])
		ghost.palette_to = pal.get("to", [])
		get_parent().add_child(ghost)
	if pcharacter == 0 and pexe_character == Globals.EXE_CHAOS and effectTimer % 5 == 0:
		var drop = load("res://src/game/hunters/chaos_drop.gd").new()
		drop.position = position + Vector2(randf_range(-8, 8), 0)
		drop.owner_id = master_id
		drop.depth = depth + 10
		get_parent().add_child(drop)


func _gm_draw() -> void:
	draw_self()
	Net.draw_profile_interaction(self, master_id)
	if (
		pstate
		== (
			{
				0: 20 if pexe_character == Globals.EXE_CHAOS else 19,
				1: 16,
				2: 17,
				3: 15,
				4: 17,
				5: 16,
				6: 17
			}
			. get(pcharacter, -1)
		)
	):
		draw_sprite(
			"spr_aiz_zipline",
			0,
			floorf(position.x) - 12,
			(
				floorf(position.y)
				- {0: 41, 1: 30, 2: 41, 3: 44, 4: 40, 5: 27, 6: 37}.get(pcharacter, 41)
			)
		)
	if pcharacter == 3 and isAttacking:
		draw_sprite(
			"spr_electroshield",
			int(Time.get_ticks_msec() / 30) % 41,
			floorf(position.x),
			floorf(position.y)
		)
		queue_redraw()
	if pcharacter == 6 and sallyShield:
		draw_sprite(
			"spr_sallyshield2" if revivalTimes >= 2 else "spr_sallyshield",
			int(Time.get_ticks_msec() / 30) % 41,
			floorf(position.x),
			floorf(position.y)
		)
		queue_redraw()
