extends GMNode
## Port of obj_tails_projectile — Tails' charged tail shot.
## The original is fully server-authoritative (the server spawns/moves/destroys it
## and broadcasts TPROJECTILE_STATE). Solo runs it locally: it flies in the facing
## direction, dies on solid collision and plays the charge-tier death sprite.

var owner_id := -1
var is_owner := false
var is_breaking := false
var is_exe := false
var dmg := 0  # Demon shot: health sections; normal shot: stun duration in seconds.
var charge := 0
var xspd := 0.0
var life := 0

const SPEED := 14.0
const MAX_LIFE := 300


func _ready() -> void:
	gm_name = "obj_tails_projectile"  # spawned dynamically — must self-stamp its group
	super._ready()
	sprite_name = "spr_tails_ray"
	image_index = float(charge)  # SERVER_TPROJECTILE_STATE: image_index = _charge —
	# the tier IS the frame (6 pre-colored frames, playbackSpeed 0)
	image_speed = 1.2
	z_index = 5
	xspd = SPEED * image_xscale


func _gm_step() -> void:
	if is_breaking:
		if int(image_index) >= GM.sprite_count(sprite_name) - 1:
			queue_free()
		return
	if _hit_local_player():
		if Net.state == Net.STATE_GAME:
			var packet := Net.cpacket_tcp(Net.PacketType.CLIENT_TPROJECTILE_HIT)
			Net.send_server_tcp(packet)
		_destroy()
		return
	life += 1
	position.x += xspd
	# BetterServer TProjectile update: Majin wraps at the full room edges,
	# independently of the player's inset 240px seam. Lifetime keeps counting.
	if Net.lvlId == 13:
		if position.x < 0.0:
			position.x = 3648.0
		elif position.x > 3648.0:
			position.x = 0.0
	# solid collision or lifetime ends the shot
	var hit := GMFloor.point_meeting_floor(position.x, position.y)
	if hit or life > MAX_LIFE or position.x < 0.0:
		_destroy()


func _hit_local_player() -> bool:
	if Net.state == Net.STATE_GAME:
		return false
	if Net.gameEnds:
		return false
	var player: GMNode = Globals.player
	if not is_instance_valid(player) or player.isDead or player.hurttime > 0:
		return false
	var hunter: bool = Globals.character == Globals.CHARACTER_EXE or player.revivalTimes >= 2
	if hunter == is_exe or not bbox_rect().intersects(player.bbox_rect()):
		return false
	if hunter and Globals.character == Globals.CHARACTER_EXE and player.invisTimer > 0:
		return false
	var push := signf(player.position.x - position.x) * 4.0
	if hunter:
		player.shockedTimer = 60 * clampi(dmg, 1, 6)
		player.canMove = true
		player.isAttacking = false
		player.isFlying = false
		player.isGrounded = false
		player.xspd = push
		player.yspd = -2.0
		GameAudio.play_sound("snd_exe_stun")
		if Globals.character == Globals.CHARACTER_EXE:
			GameAudio.play_exe_stun(Globals.exeCharacter)
		if Net.state == Net.STATE_GAME:
			Net.report_player_hurt(owner_id, int(position.x), int(position.y), player.shockedTimer)
	else:
		if Net.state == Net.STATE_GAME:
			var report := Net.cpacket_tcp(Net.PacketType.CLIENT_STATS_REPORT)
			report.put_u8(2)
			report.put_u16(owner_id)
			report.put_u16(dmg)
			report.put_u16(maxi(0, player.hp - dmg))
			Net.send_server_tcp(report)
		player.player_hurt(dmg, push, 2.0, "snd_hurt", "spr_blood1", Net.state == Net.STATE_GAME)
	return true


func _destroy() -> void:
	if is_breaking:
		return
	is_breaking = true
	match charge:
		0:
			sprite_name = "spr_tail_ray_dead"
		1:
			sprite_name = "spr_tail_ray_dead1"
		2:
			sprite_name = "spr_tail_ray_dead2"
		3:
			sprite_name = "spr_tail_ray_dead3"
		_:
			sprite_name = "spr_tail_ray_dead4"
	image_speed = 1.2
	image_index = 0.0
	queue_redraw()


func _gm_draw() -> void:
	draw_self()
