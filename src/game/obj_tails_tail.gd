extends GMNode
## Port of obj_tails_tail — Tails' tail, a follower drawn behind the player.
## Create_0: visible = false, image_speed = 0.2. Step_2 repositions it per the
## player's state (the balancing/idle/air variants) and palette-swaps in Draw_0.

var tails: GMNode = null


func _ready() -> void:
	pixel_snap = true
	gm_name = "obj_tails_tail"  # spawned dynamically — must self-stamp its group
	super._ready()
	visible = false
	sprite_rotation = 0.0
	image_speed = 0.2


func _gm_step() -> void:
	if OS.get_environment("TAILTRACE") == "1" and Engine.get_physics_frames() % 5 == 0:
		print(
			(
				"TAIL f=%d t=(%.0f,%.0f) rot=%.0f vis=%d | T=(%.0f,%.0f) st=%d g=%d xs=%.0f"
				% [
					Engine.get_physics_frames(),
					position.x,
					position.y,
					sprite_rotation,
					int(visible),
					tails.position.x,
					tails.position.y,
					tails.state,
					int(tails.isGrounded),
					tails.image_xscale
				]
			)
		)
	visible = false
	sprite_rotation = 0.0
	if tails == null or not is_instance_valid(tails):
		# the local player IS Tails when the character is Tails (Globals.player
		# is stamped by the player's _ready)
		if Globals.character == Globals.CHARACTER_TAILS:
			for p in GMNode.all_of("obj_player"):
				tails = p
				break
	if not is_instance_valid(tails):
		queue_free()
		return

	position.x = tails.position.x
	position.y = tails.position.y
	depth = tails.depth + 1.0
	z_index = clampi(-int(depth), -4096, 4096)  # _ready already ran — keep it in sync

	if tails.sprite_name == "spr_tails_hurt":
		return

	if tails.state == tails.BALANCING:
		image_xscale = float(tails.get("edgeDir"))
		position.x += image_xscale * 4.0
		position.y += 8.0
		visible = true
		sprite_name = "spr_etails_tail1" if tails.revivalTimes >= 2 else "spr_tails_tail1"
		return

	if (
		tails.state == tails.IDLE
		or tails.emotion
		or tails.state == tails.LOOKDOWN
		or tails.state == tails.LOOKUP
	):
		image_xscale = tails.image_xscale
		position.x += image_xscale * 2.0
		position.y += 4.0
		visible = true
		sprite_name = "spr_etails_tail2" if tails.revivalTimes >= 2 else "spr_tails_tail2"
		return

	if OS.get_environment("TAILTRACE") == "1" and Engine.get_physics_frames() % 30 == 0:
		print(
			"TAILSTATE f=",
			Engine.get_physics_frames(),
			" state=",
			tails.state,
			" grounded=",
			tails.isGrounded,
			" isJumping=",
			tails.isJumping
		)
	if tails.state == tails.JUMP or tails.state == tails.SPIN:
		position.y += 6.0
		image_xscale = 1.0
		visible = true
		var vx: float = tails.gspd if tails.isGrounded else tails.xspd
		# GM: image_angle = -radtodeg(atan2(yspd, vx)) → Godot: negate it back
		sprite_rotation = rad_to_deg(atan2(tails.yspd, vx))
		sprite_name = "spr_etails_tail1" if tails.revivalTimes >= 2 else "spr_tails_tail1"
		if OS.get_environment("TAILTRACE") == "1" and Engine.get_physics_frames() % 30 == 0:
			print(
				"TAILJUMP f=",
				Engine.get_physics_frames(),
				" state=",
				tails.state,
				" pos=",
				position,
				" rot=",
				sprite_rotation,
				" spr=",
				sprite_name,
				" yspd=",
				tails.yspd,
				" vx=",
				vx,
				" vis=",
				visible
			)


func frame_texture() -> Texture2D:
	if is_instance_valid(tails):
		return Unlockables.actor_texture(
			sprite_name, int(image_index), 1, 0, tails.revivalTimes, self
		)
	return super.frame_texture()


func _gm_draw() -> void:
	# Draw_72: image_alpha = (player.hurttime > 0 || player.isHiding) ? 0.5 : obj_tails.image_alpha
	# — alpha set BEFORE the single draw_self (a stale first draw made the tail
	# look almost opaque while the owner flickered at 0.5)
	if tails != null and is_instance_valid(tails):
		image_alpha = 0.5 if (tails.hurttime > 0 or tails.isHiding) else tails.image_alpha
		image_blend = tails.image_blend
	draw_self()
