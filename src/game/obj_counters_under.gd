extends Node2D
## The over-the-head counters (hp pips + ring count) drawn UNDER the red-ring
## frenzy fog: a world-space node at z_index 490 — the fog (obj_redring_screen)
## sits at 500 and washes over them. Pinned to the camera, so its local space
## matches the HUD's screen space and the draw math is identical to
## obj_level_hud._draw_player_counters. The HUD copy skips while redRingTimer
## > 0, so during the frenzy the counters render only here — dimmed under the
## red wash — and the normal HUD copy takes over once it ends.


func _ready() -> void:
	process_physics_priority = 120
	z_as_relative = false
	z_index = 490


func _physics_process(_d: float) -> void:
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	if cam:
		position = cam.render_origin
	queue_redraw()  # the counters follow the player every frame


func _draw() -> void:
	_draw_puppets()
	_draw_clones()
	_draw_local_counters()


func _draw_clones() -> void:
	if Globals.character == 0 or not Globals.showHud:
		return
	for clone in GMNode.all_of("obj_exeller_clone"):
		var skip := false
		for dt in GMNode.all_of("obj_deserttown_i"):
			var inside := false
			for trigger in GMNode.all_of("obj_deserttown_trigger"):
				if (
					trigger.has_method("position_meeting")
					and trigger.position_meeting(clone.position.x, clone.position.y)
				):
					inside = true
					break
			if inside != bool(dt.get("coll")):
				skip = true
		if skip:
			continue
		var col := Color("404040") if Net.lvlId == 8 else Color.RED
		GM.scr_text_spr(
			self,
			floorf(clone.position.x) - GM.scr_text_spr_width(clone.nickname) / 2.0,
			floorf(clone.position.y) - 43,
			GM.plain_text(clone.nickname),
			col
		)


## obj_player_puppet Draw_64 — the OTHER players' hp pips (at -45), nickname
## (at -43) and ring count (at -57), in world space below the red-ring fog and
## below the HUD CanvasLayer (the original's GUI depth order)
func _draw_puppets() -> void:
	var cam := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		cam = c.render_origin
		break
	var dt_i: Array = GMNode.all_of("obj_deserttown_i")
	for pup in GMNode.all_of("obj_player_puppet"):
		if pup.pcharacter == -1:
			continue
		# the original's deserttown guard: skip when the puppet's indoor state
		# differs from the controller's
		var skip := false
		for dt in dt_i:
			var coll := false
			for tr in GMNode.all_of("obj_deserttown_trigger"):
				if (
					tr.has_method("position_meeting")
					and tr.position_meeting(pup.position.x, pup.position.y)
				):
					coll = true
					break
			if coll != bool(dt.get("coll")):
				skip = true
			break
		if skip or pup.isHiding:
			continue
		var positions: Array[Vector2] = [pup.position]
		if Net.lvlId == 13:
			if pup.position.x >= 0 and pup.position.x <= 480:
				positions.append(pup.position + Vector2(3168, 0))
			elif pup.position.x >= 3168 and pup.position.x <= 3648:
				positions.append(pup.position - Vector2(3168, 0))
		for at in positions:
			var sx := floorf(at.x - cam.x)
			var sy := floorf(at.y - cam.y)
			if pup.hp > 0 and pup.pcharacter != Globals.CHARACTER_EXE:
				var frame := clampi(pup.hp, 0, 5)
				_spr(
					"spr_hp_rr" if pup.hasRedRing else "spr_hp",
					0 if pup.isDemonized else frame,
					sx,
					sy - 45.0
				)
			if pup.nicknameWidth == 0:
				pup.nicknameWidth = GM.scr_text_spr_width(pup.nickname)
			if Globals.showHud:
				var col := (
					Color.RED
					if (pup.pcharacter == Globals.CHARACTER_EXE or pup.revivalTimes >= 2)
					else (Color("#9943ad") if pup.hasRedRing else GM.C_GREEN)
				)
				if Net.lvlId == 8:
					col = Color("404040")
				# scr_text_spr draws in ROOM coords (ci.to_local) — the node sits at
				# the camera, so room coords land on the right screen spot
				GM.scr_text_spr(
					self,
					floorf(at.x) - pup.nicknameWidth / 2.0,
					floorf(at.y) - 43.0,
					GM.plain_text(pup.nickname),
					col
				)
			if not pup.isDemonized and pup.hp > 0:
				GM.scr_number_spr(
					self,
					floorf(at.x) - 2.0,
					floorf(at.y) - 45.0 - 12.0,
					str(pup.rings),
					Color("404040") if Net.lvlId == 8 else Color.WHITE
				)


func _draw_local_counters() -> void:
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null or player.hp <= 0 or not player._is_survivor():
		return
	if player.redRingTimer <= 0:
		return  # the frenzy is off — the HUD copy draws the counters (on top)
	var cam := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		cam = c.render_origin
		break
	var ox := floorf(player.position.x) - cam.x
	var oy := (
		floorf(player.position.y)
		- cam.y
		- (float(player.survivor.hp_offset) if player.survivor != null else 20.0)
	)
	var frame := clampi(player.hp, 0, 5)
	if player.revivalTimes >= 2:
		frame = 0
	_spr("spr_hp_rr" if player.redRingTimer > 0 else "spr_hp", frame, ox, oy)
	if player.isSlow:
		_spr("spr_frozen", 0, ox, oy)
	if player.revivalTimes < 2:
		_number_spr(str(player.rings), ox - 2.0, oy - 12.0)


## GM draw_sprite: the sprite's origin lands on (x, y) — same helper as the HUD's
func _spr(sn: String, frame: int, x: float, y: float) -> void:
	var tex := GM.sprite_texture(sn, frame)
	if tex == null:
		return
	var m: Dictionary = GM.sprite_meta(sn)
	var o := Vector2(float(m["xorigin"]), float(m["yorigin"]))
	draw_texture(tex, Vector2(x, y) - o, Color("404040") if Net.lvlId == 8 else Color.WHITE)


func _number_spr(s: String, xx: float, yy: float) -> void:
	var x := xx
	for i in s.length():
		var ind := s[i].unicode_at(0) - ord("0")
		_spr("spr_number", ind, x - ((s.length() - 1) * 2.0), yy)
		x += 5.0
