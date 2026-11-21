extends "res://src/game/hunters/base.gd"
const Art = preload("res://src/game/hunters/exeller_anims.gd")
var clones: Array[int] = [-1, -1]
var cloneTimer := 0
var cloneCount: int:
	get:
		return int(clones[0] >= 0) + int(clones[1] >= 0)
var indicatorTimer := 0
var last_state := -1
var prev_grounded := false
var lost_state := 18


func _init(actor: GMNode):
	p = actor


func setup():
	p.hp = 5
	p.invisTimer = 0
	p.maxYSpeed = 12
	p.canSpin = true
	p.canMove = true
	p.anims_cur = Art.NORMAL
	lost_state = [18, 20].pick_random()
	restore_speed()


func restore_speed():
	p.acc = 0.056875
	p.maxHSpeed = 12


func taunt_key(slot: int) -> String:
	return "texeller0" if slot == 1 else "texeller1"


func emotion_sound(slot: int):
	var names: Array = {
		1: ["snd_exeller_taunt3"],
		2: ["snd_exeller_taunt1", "snd_exeller_taunt2"],
		3: ["snd_exeller_laugh"]
	}[slot]
	for voice in GameAudio._sound_pool:
		if voice.playing:
			for name in names:
				if voice.stream == GameAudio._stream(name):
					return
	Net.character_sound(names.pick_random(), p.position)


func tick():
	if indicatorTimer > 0:
		indicatorTimer -= 1


func incapacitated():
	p.isAttacking = false


func spring():
	incapacitated()


func reconcile(attack_ticks: int, clone_ticks: int, ids: Array, action: int):
	if action == 0:
		p.isAttacking = false
		p.attackTimer = attack_ticks
	cloneTimer = clone_ticks
	clones.assign(ids)


func special():
	if p.won or p.lost:
		p.isAttacking = false
		p.attackTimer = 0
		return
	if Globals.playerControls and p.isJumping and p.kp(Globals.KeyA):
		p.isJumping = false
	if cloneTimer > 0:
		cloneTimer -= 1
	if Globals.playerControls and p.kp(Globals.KeyC):
		var slot: int = 0 if p.kd(Globals.KeyUp) else (1 if p.kd(Globals.KeyDown) else -1)
		if slot >= 0 and clones[slot] >= 0:
			Net.request_clone_teleport(clones[slot])
			return
		if slot < 0 and cloneCount < 2 and cloneTimer <= 0:
			Net.request_exeller_clone()
			cloneTimer = 180
			if randi_range(0, 3) == 0:
				Net.character_sound("snd_exeller_cloneline", p.position)
	if Globals.playerControls and p.kp(Globals.KeyB) and p.attackTimer <= 0:
		if p.kd(Globals.KeyLeft):
			p.image_xscale = -1
		elif p.kd(Globals.KeyRight):
			p.image_xscale = 1
		p.image_index = 0
		p.attackSpeed = p.xspd
		p.attackTimer = 60 if p.isGrounded else 120
		p.isAttacking = true
		p.isJumping = false
		p.isSpinning = false
		if Net.state == Net.STATE_GAME:
			Net._send_player_data()
			var b := Net.cpacket_tcp(Net.PacketType.CLIENT_EXELLER_ATTACK)
			b.put_u8(int(not p.isGrounded))
			Net.send_server_tcp(b)
		Net.character_sound("snd_dash", p.position)
	if p.isAttacking:
		if p.yspd > 0:
			p.yspd = 0 if p.isGrounded else 2.5
		if p.isGrounded and absf(p.xspd) > 0 and int(floor(p.position.x)) % 4 == 0:
			p.quick_effect(p.position.x - 8 * p.image_xscale, p.position.y + 20, "spr_dust")
	if p.attackTimer > 0:
		p.attackTimer -= 1


func before_collision():
	prev_grounded = p.isGrounded


func after_collision():
	pass


func anim_step():
	if not p.emotion:
		p.state = 0
	if p.won and p.isGrounded:
		p.state = 17
	elif p.lost and p.isGrounded:
		p.state = lost_state
	elif p.isHurt:
		p.state = 5
	elif p.shockedTimer > 0:
		p.state = 16 if p.isGrounded else 5
	elif p.isAttacking:
		if prev_grounded != p.isGrounded:
			p.isAttacking = false
		else:
			p.state = 14 if p.isGrounded else 15
	elif p.isZipline:
		p.state = 19
	elif p.isLookingUp:
		p.state = 7
	elif p.isLookingDown:
		p.state = 8
	elif p.isSpinning:
		p.state = 12
	elif p.isOnEdge:
		p.state = 13
	elif not p.isGrounded:
		p.state = 3 if p.isJumping else 4
	elif absf(p.xspd) > 0:
		p.state = 1 if absf(p.xspd) < 8 else 2
	apply_anim()


func apply_anim():
	if last_state != p.state:
		last_state = p.state
		p.image_index = 0
		p._anim_accum = 0
	p.sprite_name = Art.NORMAL[p.state]
	p.image_speed = 1
	var last := GM.sprite_count(p.sprite_name) - 1
	match p.state:
		1:
			p.image_speed = absf(p.xspd) / p.maxHSpeed
		2, 3:
			p.image_speed = maxf(absf(p.xspd) / 20, 0.5)
		4:
			p.image_index = int(p.yspd > 0)
			p.image_speed = 0
		5, 19:
			p.image_index = 0
			p.image_speed = 0
		7, 8:
			p.image_index = minf(p.image_index, 1)
			p.image_speed = 0 if p.image_index >= 1 else 0.2
		9, 10, 11, 17, 18, 20:
			p.image_speed = 0.8
		12:
			p.image_speed = absf(p.xspd) / 5
		13:
			p.image_xscale = p.edgeDir
		14, 15:
			p.image_speed = 2 if p.state == 14 else 0.8
			if p.image_index >= last:
				p.xspd *= 0.7
				p.gspd *= 0.7
				p.isAttacking = false
				p.isJumping = false
		16:
			p.image_speed = 0.5


func animation_end():
	match p.state:
		0:
			p.image_index = maxi(0, GM.sprite_count(p.sprite_name) - 48)
		9, 10, 11:
			var key: int = [Globals.KeyEm1, Globals.KeyEm2, Globals.KeyEm3][p.state - 9]
			if p.kd(key):
				p.image_index = 0
			else:
				p.image_index = 0
				p.state = 0
				p.emotion = false


func draw_abilities(hud):
	var progress := 1.0 - minf(p.attackTimer, 180) / 180.0
	hud._spr_ext(
		"spr_gui_exeattack",
		0,
		progress * 10,
		240,
		1,
		1,
		0,
		Color.WHITE if progress == 1 else Color.RED,
		progress
	)
	var free: bool = Globals.playerControls and p.isJumping
	hud._spr_ext(
		"spr_gui_exefreejump",
		0,
		3,
		218,
		1,
		1,
		0,
		Color.WHITE if free else Color.RED,
		1 if free else 0.5
	)
	progress = 1.0 - cloneTimer / 1800.0
	var sprite := "spr_gui_exellerclone"
	if (p.kd(Globals.KeyDown) or p.kd(Globals.KeyUp)) and cloneCount > 0:
		sprite = "spr_gui_exellerclone2"
		progress = 1
	elif cloneCount >= 2:
		progress = 0
	hud._spr_ext(
		sprite, 0, progress * 4, 250, 1, 1, 0, Color.WHITE if progress == 1 else Color.RED, progress
	)
