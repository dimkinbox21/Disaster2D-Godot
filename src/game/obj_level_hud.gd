extends Node2D
## Screen-fixed HUD — the port of obj_level's Draw_64 GUI event plus
## obj_playerui's Draw_64 (the ability icons). GUI events are screen space in
## GameMaker (no camera transform), which is why this lives in a CanvasLayer.
## `level` is the obj_level that owns the round state; obj_level sets it at
## spawn. obj_playerui has depth -1001 vs obj_level's -1000, so the ability
## icons draw FIRST (under the rest).

var level: GMNode = null
var _t0 := 0  # maps GM's current_time (ms since the game started)
const DirectionIndicators = preload("res://src/game/direction_indicators.gd")


func _ready() -> void:
	_t0 = Time.get_ticks_msec()


func _physics_process(_d: float) -> void:
	queue_redraw()  # the original's Draw GUI event runs every frame


func _draw() -> void:
	if level == null:
		var p := get_parent()
		level = p.get_parent() as GMNode if p else null
		if level == null:
			return
	var now := Time.get_ticks_msec() - _t0
	var player: GMNode = _player()
	_draw_playerui(player)  # obj_playerui Draw_64 (depth -1001)
	_draw_player_counters(player)  # obj_tails Draw_64 (the hp bar + ring count over the head)
	_draw_direction_indicators(player)
	_draw_level64(player, now)  # obj_level Draw_64 (depth -1000) — draws LAST on top:
	# the intro card / black fade / overlays cover the counters

	if level.sudden_fade > 0:
		_spr("spr_black", 0, 0, 0, Color.WHITE, level.sudden_fade)
		var overlay_scale: float = 1.5 - level.sudden_fade
		_spr_ext(
			"spr_sudden_death",
			int(Time.get_ticks_msec() / 100) % GM.sprite_count("spr_sudden_death"),
			240,
			135,
			overlay_scale,
			overlay_scale,
			0,
			Color.WHITE,
			level.sudden_fade * 2
		)
	if Net.players.has(Net.nid) and Net.players[Net.nid].get("hasEscaped", false):
		_text("YOU ESCAPED", 190, 245)

	if level.ending_sprite != "":
		_spr("spr_black", 0, 0, 0, Color.WHITE, level.ending_fade)
		var ending_scale: float = 1.5 - level.ending_fade
		_spr_ext(
			level.ending_sprite,
			int(Time.get_ticks_msec() / 100) % GM.sprite_count(level.ending_sprite),
			240,
			135,
			ending_scale,
			ending_scale,
			0,
			Color.WHITE,
			level.ending_fade * 2
		)

	if level.ending_age > 180:
		_spr("spr_black", 0, 0, 0, Color.WHITE, minf(1.0, (level.ending_age - 180) * 0.02))


# --------------------------------------------------------------- obj_playerui
func _draw_direction_indicators(player: GMNode) -> void:
	var camera := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		camera = c.render_origin
		break
	for cmd in DirectionIndicators.commands(player, camera):
		_spr_ext(cmd.sprite, cmd.get("frame", 0), cmd.at.x, cmd.at.y, 1, 1, cmd.angle)


func _draw_playerui(player: GMNode) -> void:
	if not Globals.showHud:
		return
	if player == null or player.isDead:
		return
	match _character():
		Globals.CHARACTER_EXE:
			match _exe_character():
				Globals.EXE_ORIGINAL:
					# attack bar — the sprite slides left as prog → 1
					var prog := 1.0 - minf(player.attackTimer, 180.0) / 180.0
					_spr_ext(
						"spr_gui_exeattack",
						0,
						prog * 10.0,
						240.0,
						1,
						1,
						0,
						Color.WHITE if is_equal_approx(prog, 1.0) else Color.RED,
						prog
					)
					# free jump indicator
					var jprog: bool = Globals.playerControls and player.isJumping
					_spr_ext(
						"spr_gui_exefreejump",
						0,
						3.0,
						218.0,
						1,
						1,
						0,
						Color.WHITE if jprog else Color.RED,
						1.0 if jprog else 0.5
					)
					# invisibility: the original hides the icon WHILE it is active
					# (min(invisTimer,0) = 0 → alpha 0) and fills it back up over
					# the 20s recharge. Negative ÷ negative = the growing fraction:
					#   prog = min(invisTimer, 0) / EXE_INVIS_RECHARGE   (-1200)
					# so charged (-1200) → 1 (white), recharging → 0..1, in use → 0.
					var iprog := clampf(
						minf(player.invisTimer, 0.0) / float(player.EXE_INVIS_RECHARGE), 0.0, 1.0
					)
					_spr_ext(
						"spr_gui_exeinvisability",
						0,
						iprog * 4.0,
						250.0,
						1,
						1,
						0,
						Color.WHITE if is_equal_approx(iprog, 1.0) else Color.RED,
						iprog
					)
				Globals.EXE_CHAOS, Globals.EXE_EXETIOR, Globals.EXE_EXELLER:
					if player.hunter != null:
						player.hunter.draw_abilities(self)
		_:
			if player.survivor != null:
				player.survivor.draw_abilities(self)
	# emotions button (survivors only, standing or emoting)
	if _character() != Globals.CHARACTER_EXE and (player.state == player.IDLE or player.emotion):
		_spr("spr_gui_emotions", 0, 470, 222)


func _ability(
	sprite: String, frame: int, timer: int, recharge: int, yy: float, usable: bool
) -> void:
	var progress := clampf(1.0 - maxf(timer, 0) / recharge, 0, 1)
	_spr_ext(
		sprite,
		frame,
		progress * 10,
		yy,
		1,
		1,
		0,
		Color.WHITE if progress == 1 and usable else Color.RED,
		progress
	)


# ------------------------------------------------------------- obj_level Draw_64
func _draw_level64(player: GMNode, now: float) -> void:
	# screen overlay — the original skips it on the listed (flat-art) rooms
	if not _NO_OVERLAY.has(
		get_tree().current_scene.scene_file_path.get_file() if get_tree().current_scene else ""
	):
		_spr("spr_screenoverlay", 0, 0, 0, Color.WHITE, 0.7)
	_spr("spr_hidegui", 0, 0, 0, Color.WHITE, level.hideFade)
	_spr("spr_attackgui", 0, 0, 0, Color.WHITE, level.bloodFade)

	if Globals.showHud and level.titleCard > 4.0:
		# bad connection icon while packets are late (the original's udp_timeout)
		if Net._udp_timeout < 60 * 3:
			_spr("spr_badconnection", int(floor(now / 200.0)) % 6, 0, 0)
		# clock: face + sweeping hand + digital counter
		_spr("spr_clock", 0, 211, 0)
		level.clockAngle = GM.gml_lerp(level.clockAngle, -45.0 * level.timeFrame, 0.2)
		_spr_ext("spr_clockhand", 0, 212, 11.5, 1, 1, level.clockAngle)
		_spr("spr_counter", 10, 233, 4)
		_draw_counter(Globals.timeMinutes, 224, 4)
		_draw_counter_m(Globals.timeSeconds, 244, 4, 2)
		# "Escape!!!" — blinking, only once the big ring is up
		if not level.showSurvivors and level.state == 1 and int(now / 30.0) % 20 < 10:
			if (
				_character() == Globals.CHARACTER_EXE
				or (player != null and player.revivalTimes >= 2)
			):
				_spr("spr_status", 1, 240, 32)
			else:
				_spr("spr_status", 0, 240, 32)
		_draw_icons(player)

	# title card: black fade, then the two halves slide across
	if level.titleCard < 18.0:
		_spr(
			"spr_black",
			0,
			0,
			0,
			Color.WHITE,
			1.0 - (clampf(level.titleCard, 8.0, 16.0) - 8.0) / 8.0
		)
	if level.titleCard < 30.0:
		var cx := clampf(level.cardX, 0.0, 480.0)
		var cy := clampf(level.cardY, -270.0, 0.0)
		_spr("spr_titlecard2", Net.lvlId, 0, cy)
		_spr("spr_titlecard1", Net.lvlId, cx, 0)

	if Globals.showHud:
		var online := Net.state != Net.STATE_PENDING
		if online:
			var clr := Color("#0fff39")
			if Net.ping >= 80 and Net.ping < 160:
				clr = Color("#ffc400")
			elif Net.ping >= 160:
				clr = Color("#ff0001")
			if Net.ping <= 0:
				var dots := "..."
				_text("waiting for players" + dots.substr(0, int(now / 500.0) % 4), 4, 4)
			elif GameConfig.showPing:
				_text(str(Net.ping) + "ms", 4, 4, clr)
		if GameConfig.showFps:
			_text(str(Engine.get_frames_per_second()) + "fps", 4, 10)

	# tab player list
	var plist: int = GM._GM_TO_GODOT.get(Globals.KeyPList, Globals.KeyPList)
	if Input.is_key_pressed(plist as Key):
		_spr("spr_tab", 0, 0, 0)
		_draw_ping(
			Globals.character,
			Globals.exeCharacter,
			Net.ping,
			player.revivalTimes if player else 0,
			Globals.nickname,
			0
		)
		var index := 1
		for k in Net.players:
			if k == Net.nid or int(Net.players[k].get("character", -1)) < 0:
				continue
			var plr: Dictionary = Net.players[k]
			var ping: int = Net.pings.get(k, 0)
			_draw_ping(
				plr.get("character", -1),
				plr.get("exeCharacter", -1),
				ping,
				_remote_revival(k),
				str(plr.get("nickname", "")),
				index
			)
			index += 1


## obj_tails Draw_64 — the hp pips and the ring count above the player's head
## (screen space: ceil(x - obj_camera.x) / ceil(y - obj_camera.y) - offset)
func _draw_player_counters(player: GMNode) -> void:
	if player == null:
		return
	# obj_exe/chaos/exetior/exeller Draw_64 has its own slow indicator,
	# independent of the survivor HP counters.
	if not player._is_survivor():
		if player.isSlow:
			var camera := Vector2.ZERO
			for c in GMNode.all_of("obj_camera"):
				camera = c.render_origin
				break
			_spr(
				"spr_frozen",
				0,
				ceilf(player.position.x - camera.x),
				ceilf(player.position.y - camera.y) - 20
			)
		return
	if player.hp <= 0:
		return
	# the red-ring frenzy covers the whole over-the-head block (hp pips + ring
	# count) in the original — the fog sits over it, so skip drawing it
	if player.redRingTimer > 0:
		return
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
	var tint := Color("404040") if Net.lvlId == 8 else Color.WHITE
	_spr("spr_hp_rr" if player.redRingTimer > 0 else "spr_hp", frame, ox, oy, tint)
	if player.isSlow:
		_spr("spr_frozen", 0, ox, oy, tint)
	if player.revivalTimes < 2:
		_number_spr(str(player.rings), ox - 2.0, oy - 12.0, tint)


## survivor icon row (self first, then the other survivors — the exe has none)
func _draw_icons(player: GMNode) -> void:
	var others: Array = []
	for id in Net.players:
		if id != Net.nid and int(Net.players[id].get("character", -1)) > 0:
			others.append(id)
	var count := others.size() + (0 if _is_exe() else 1)
	var pos := 240.0 - (count * 28.0) / 2.0
	if not _is_exe():
		# self icon — the original only draws it when exeId != nid
		var ch := _char_index()
		var sprIndex := ch * 7
		if player != null:
			if player.revivalTimes < 2:
				sprIndex += clampi(5 - player.hp, 0, 5)
				if player.hp <= 0:
					sprIndex = ch * 7 + (5 if player.revivalTimes == 0 else 6)
				_spr(
					"spr_playerhealth_redring" if player.redRingTimer > 0 else "spr_playerhealth",
					sprIndex,
					pos,
					268
				)
				if player.revivalTimes >= 1 and player.hp > 0:
					_spr("spr_playerhealth_hit", ch, pos, 268)
				if player.isDead:
					if player.revivalTimes == 0 and player.deadTimer <= 31:
						_number_spr(
							str(player.deadTimer), pos + 12, 264, _player_dead_color(player)
						)
				elif player.shards > 0:
					_number_spr(str(player.shards), pos + 12, 264, Color("#27ff23"))
			else:
				_spr("spr_playerhealth_demon", ch, pos, 268)
		else:
			_spr("spr_playerescaped", ch, pos, 268)
		pos += 28
	var i := 0
	for k in others:
		var plr: Dictionary = Net.players[k]
		var ch2: int = int(plr.get("character", 1)) - 1
		if plr.get("hasEscaped", false):
			_spr("spr_playerescaped", ch2, pos + i * 28, 268)
			i += 1
			continue
		# puppets carry the live hp in netplay; solo has none
		var hp := float(plr.get("hp", 5))
		var remote: GMNode = null
		var revival := 0
		for pup in GMNode.all_of("obj_player_puppet"):
			if pup.master_id == k:
				remote = pup
				hp = pup.hp
				revival = pup.revivalTimes
				break
		var sprIndex := ch2 * 7
		if revival < 2:
			sprIndex += clampi(5 - int(hp), 0, 5)
			if hp <= 0:
				sprIndex = ch2 * 7 + (5 if revival == 0 else 6)
			var red_ring: bool = remote != null and remote.hasRedRing
			_spr(
				"spr_playerhealth_redring" if red_ring else "spr_playerhealth",
				sprIndex,
				pos + i * 28,
				268
			)
			if revival >= 1 and hp > 0:
				_spr("spr_playerhealth_hit", ch2, pos + i * 28, 268)
			if remote != null and revival == 0 and hp <= 0 and remote.deadTimer <= 31:
				_number_spr(str(remote.deadTimer), pos + i * 28 + 12, 264, remote.deadColor)
			elif remote != null and remote.shards > 0:
				_number_spr(str(remote.shards), pos + i * 28 + 12, 264, Color("27ff23"))
		else:
			_spr("spr_playerhealth_demon", ch2, pos + i * 28, 268)
		i += 1


## one tab entry (drawPing in the original's obj_level Create)
func _draw_ping(
	char: int, exe_character: int, ping: int, revival: int, name: String, index: int
) -> void:
	var name_color := GM.C_RED if char == Globals.CHARACTER_EXE or revival >= 2 else GM.C_GREEN
	if char == Globals.CHARACTER_EXE:
		char += Globals.CHARACTER_SALLY + exe_character
	else:
		char -= 1
	_spr("spr_tab_entry", char, 240, 44 + index * 30)
	if char < Globals.CHARACTER_SALLY:
		if revival >= 2:
			_spr("spr_playerhealth_demon", char, 128, 71 + index * 30)
		elif revival >= 1:
			_spr("spr_playerhealth_hit", char, 128, 71 + index * 30)
	var clr := Color("#0fff39")
	var ping_str := ""
	if ping <= 0:
		ping_str = "...".substr(0, int((Time.get_ticks_msec() - _t0) / 500.0) % 4)
		clr = Color("#ff0001")
	else:
		if ping >= 80 and ping < 160:
			clr = Color("#ffc400")
		elif ping >= 160:
			clr = Color("#ff0001")
		ping_str = str(ping) + "ms"
	_text(GM.plain_text(name), 186, 55 + index * 30, name_color)
	_text(ping_str, 310, 55 + index * 30, clr)


## scr_counter_draw / scr_counter_draw_m
func _draw_counter(number: int, xx: float, yy: float) -> void:
	_spr("spr_counter", number, xx, yy)


func _draw_counter_m(number: int, xx: float, yy: float, zeros: int) -> void:
	var s := str(number)
	var dif := zeros - s.length()
	var xX := 0.0
	for i in dif:
		_spr("spr_counter", 0, xx + 11.0 * i, yy)
		xX += 11.0
	for i in s.length():
		_spr("spr_counter", int(s[i]), xx + xX + 11.0 * i, yy)


# ------------------------------------------------------------------- helpers
const _NO_OVERLAY := [
	"map_notperfect.tscn",
	"map_act9.tscn",
	"map_youcantrun.tscn",
	"map_nastyparadise.tscn",
	"map_ravinemist.tscn",
	"map_volcanovalley.tscn",
	"map_greenhill.tscn",
	"map_angelisland.tscn",
	"map_fartzone.tscn",
	"map_weedzone.tscn"
]


func _player() -> GMNode:
	for p in GMNode.all_of("obj_player"):
		return p
	return null


## solo map launch runs as the EXE (player.gd uses the exe acc/speed), so an
## unset character means the exe; in netplay the exe is exeId == nid
func _is_exe() -> bool:
	if Globals.character == Globals.CHARACTER_EXE:
		return true
	return Net.state == Net.STATE_GAME and Net.exeId >= 0 and Net.exeId == Net.nid


func _character() -> int:
	return (
		Globals.character if Globals.character >= Globals.CHARACTER_EXE else Globals.CHARACTER_EXE
	)


func _exe_character() -> int:
	return (
		Globals.exeCharacter
		if Globals.exeCharacter >= Globals.EXE_ORIGINAL
		else Globals.EXE_ORIGINAL
	)


## sprite index base for the 6 survivor icon rows (0 = tails)
func _char_index() -> int:
	return maxi(Globals.character - 1, 0)


func _player_dead_color(player: GMNode) -> Color:
	if "deadColor" in player:
		return player.deadColor
	return Color.WHITE


## GM draw_sprite: the sprite's origin lands on (x, y)
func _spr(sn: String, frame: int, x: float, y: float, col := Color.WHITE, alpha := 1.0) -> void:
	var tex := GM.sprite_texture(sn, frame)
	if tex == null:
		return
	var m: Dictionary = GM.sprite_meta(sn)
	var o := Vector2(float(m["xorigin"]), float(m["yorigin"]))
	draw_texture(tex, Vector2(x, y) - o, Color(col, alpha))


## GM draw_sprite_ext: scale/rotation about the sprite's origin, origin at (x, y).
## GM angles are counter-clockwise, Godot's are clockwise (y-down) → negate.
func _spr_ext(
	sn: String,
	frame: int,
	x: float,
	y: float,
	xs := 1.0,
	ys := 1.0,
	rot_deg := 0.0,
	col := Color.WHITE,
	alpha := 1.0
) -> void:
	var tex := GM.sprite_texture(sn, frame)
	if tex == null:
		return
	var m: Dictionary = GM.sprite_meta(sn)
	var o := Vector2(float(m["xorigin"]), float(m["yorigin"]))
	if is_zero_approx(xs - 1.0) and is_zero_approx(ys - 1.0) and is_zero_approx(rot_deg):
		draw_texture(tex, Vector2(x, y) - o, Color(col, alpha))
		return
	draw_set_transform(Vector2(x, y), deg_to_rad(-rot_deg), Vector2(xs, ys))
	draw_texture(tex, -o, Color(col, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Original bitmap text renderer: digits and punctuation use the tail frames; `\ @ & / | ` ` switch the inline colour)
func _text(str: String, xx: float, yy: float, color := Color.WHITE, alpha := 1.0) -> void:
	var col := color
	var x := xx
	var y := yy
	for c in str:
		if c == "\n":
			x = xx
			y += 8.0
			continue
		if c == " ":
			x += 5.0
			continue
		var ind := 44
		match c:
			"-":
				ind = 26
			",":
				ind = 27
			"1":
				ind = 28
			"2":
				ind = 29
			"3":
				ind = 30
			"4":
				ind = 31
			"5":
				ind = 32
			"6":
				ind = 33
			"7":
				ind = 34
			"8":
				ind = 35
			"9":
				ind = 36
			"0":
				ind = 37
			".":
				ind = 38
			"'":
				ind = 39
			":":
				ind = 40
			"(":
				ind = 41
			")":
				ind = 42
			"%":
				ind = 43
			"+":
				ind = 77
			"\\":
				col = Color("#C20037")
				continue
			"@":
				col = Color("#0fff39")
				continue
			"&":
				col = Color("#b824ff")
				continue
			"/":
				col = Color("#5D67FF")
				continue
			"|":
				col = Color("#646464")
				continue
			"`":
				col = Color("#ffdb00")
				continue
			"~":
				col = color
				continue
		var o := c.unicode_at(0)
		if o >= 0x430 and o <= 0x44F:
			ind = 45 + (o - 0x430)
		elif o >= 0x61 and o <= 0x7A:  # a..z
			ind = o - 0x61
		_spr("spr_letter1", ind, x, y, color if color != Color.WHITE else col, alpha)
		x += 6.0
		match c:
			"w", "m", "x", "n", "м", "д", "и", "й", "ю", "ь", "л", "ш", "щ", "ц", "ж":
				x += 2.0


## scr_number_spr — spr_number digits, 5px advance, centred by (len-1)*2
func _number_spr(str: String, xx: float, yy: float, col := Color.WHITE, alpha := 1.0) -> void:
	var x := xx
	for i in str.length():
		var ind := str[i].unicode_at(0) - ord("0")
		_spr("spr_number", ind, x - ((str.length() - 1) * 2.0), yy, col, alpha)
		x += 5.0


func _remote_revival(id: int) -> int:
	for pup in GMNode.all_of("obj_player_puppet"):
		if pup.master_id == id:
			return pup.revivalTimes
	return 0
