extends GMNode
## Port of obj_exe — EXE_ORIGINAL player with the original Sonic-style
## movement (scr_move_basic), sensor collision (scr_collision_basic),
## abilities (scr_exe_special) and animation state machine (Step_2).
## Solo practice build: server-authoritative sync lands in stage 3.5.

# states (scr_survivors)
const IDLE := 0
const WALK := 1
const RUN := 2
const JUMP := 3
const FALL := 4
const HURT := 5
const DEAD := 6
const LOOKUP := 7
const LOOKDOWN := 8
const EMOTION1 := 9
const EMOTION2 := 10
const EMOTION3 := 11
const SPIN := 12
const BALANCING := 13
const EXE_ATTACK := 14
const EXE_AIR_ATTACK := 15
const EXE_SHOCKED := 16
const EXE_WON := 17
const EXE_LOST := 18
const EXE_ZIPLINE := 19

const EXE_INVIS_RECHARGE := -(60 * 20)
const EXE_INVIS_DURATION := 60 * 15
const EXE_MAXSPEED := 12
const EXE_ACC := 0.056875

# anim table — global.player_exesanims[EXE_ORIGINAL]
var anims_visible := [
	"spr_exe_idle", "spr_exe_walk", "spr_exe_run", "spr_exe_jump", "spr_exe_fall",
	"spr_exe_hurt", "spr_exe_jump", "spr_exe_lookup", "spr_exe_lookdown",
	"spr_exe_emotion2", "spr_exe_emotion3", "spr_exe_emotion", "spr_exe_jump",
	"spr_exe_balancing", "spr_exe_attack1", "spr_exe_attack2", "spr_exe_shocked",
	"spr_exe_emotion", "spr_exe_lost", "spr_exe_zipline",
]
var anims_invisible := [
	"spr_exe_invis_idle", "spr_exe_invis_walk", "spr_exe_invis_run", "spr_exe_invis_jump",
	"spr_exe_invis_fall", "spr_exe_invis_walk", "spr_exe_invis_jump", "spr_exe_invis_lookup",
	"spr_exe_invis_lookdown", "spr_exe_invis_emotion", "spr_exe_invis_emotion",
	"spr_exe_invis_emotion", "spr_exe_invis_jump", "spr_exe_invis_balancing",
	"spr_exe_invis_walk", "spr_exe_invis_walk", "spr_exe_invis_lookdown",
	"spr_exe_invis_walk", "spr_exe_invis_walk", "spr_exe_invis_zipline",
]

## the active per-character tables (set by _apply_character)
var anims_cur: Array = []
var anims_invis: Array = []

## Tails' animation table (state-indexed like the exe's; 14=fly, 15=charge attack,
## 16=shocked/dead, 19=zipline — the original's TAILS_* states start at BALANCING+1)
var anims_tails := [
	"spr_tails_idle", "spr_tails_walk", "spr_tails_run", "spr_tails_jump",
	"spr_tails_fall", "spr_tails_hurt", "spr_tails_dead", "spr_tails_lookup",
	"spr_tails_lookdown", "spr_tails_emotion1", "spr_tails_emotion2",
	"spr_tails_emotion3", "spr_tails_jump", "spr_tails_balancing",
	"spr_tails_fly", "spr_tails_attack1", "spr_tails_dead", "spr_tails_dead",
	"spr_tails_dead", "spr_tails_zipline",
]

## the demonized (eanims) table — obj_tails Draw_76 switches the whole animation
## table to it when revivalTimes >= 2 (scr_survivors player_eanims[? CHARACTER_TAILS];
## the original's DEAD slot uses the stun sprite there)
var anims_eanims := [
	"spr_etails_idle", "spr_etails_walk", "spr_etails_run", "spr_etails_jump",
	"spr_etails_fall", "spr_etails_hurt", "spr_etails_stun", "spr_etails_lookup",
	"spr_etails_lookdown", "spr_etails_emotion1", "spr_etails_emotion2",
	"spr_etails_emotion3", "spr_etails_jump", "spr_etails_balancing",
	"spr_etails_fly", "spr_etails_attack1", "spr_etails_stun", "spr_etails_stun",
	"spr_etails_stun", "spr_etails_zipline",
]

## survivor runtime constants (obj_tails Create_0 / scr_tails_special)
const TAILS_ACC := 0.046875
const TAILS_MAXSPEED := 11
const TAILS_FLY := 14          # BALANCING+1 in the original
const TAILS_ATTACK1 := 15      # BALANCING+2
const TAILS_ZIPLINE := 19       # the anim table slot shared with the exe's zipline
const TAILS_FLY_RECHARGE := -420
const TAILS_FLY_TIME := 160
const TAILS_ATTACK_RECHARGE := 23 * 60
const ETAILS_ATTACK_RECHARGE := 12 * 60
const TAILS_CHARGE_MAX := 60 * 3.5

# vars (Create_0)
var gspd := 0.0
var xspd := 0.0
var yspd := 0.0
var state := IDLE
var angle := 0.0
var hurttime := 0
var lookTimer := 0
var effectTime := 0
var attackTimer := 0
var shockedTimer := 0
var deadTimer := 31
var deadColor := Color.WHITE     # obj_exe Create: deadColor = c_white
var invisTimer := EXE_INVIS_RECHARGE
var revivalTimes := 0
var redRingTimer := 0
var attackSpeed := 0.0
var bounceTimer := 0
var shards := 0
var hp := 10000
var isGrounded := false
var isJumping := false
var isLookingUp := false
var isLookingDown := false
var isDead := false
var isHurt := false
var isAttacking := false
var isSpinning := false
var isHiding := false
var won := false
var lost := false
var justJumped := false
var canMove := true      # obj_tails: false while charging the tail shot
var canSpin := true       # obj_tails: false during the shot recovery
var emotion := false
var isBoosting := false
var isZipline := false
## Tails (obj_tails Create)
var isFlying := false
var flyTimer := TAILS_FLY_RECHARGE
var flyGrv := 0.0
var attackCharge := 0
var attackAfter := 0
var attackKDir := 1.0
var recoil := 0.0
## survivor hp model (studied from the original: 100 hp, rings as heal currency)
var rings := 0
var healCooldown := 0
var isOnEdge := false
var edgeDir := 1
var acc := EXE_ACC
var maxHSpeed := EXE_MAXSPEED
var maxYSpeed := 12
var yAccel := 0.21875
var jumpForce := 7.0
var isSlow := false
var fall_limit_y := 1888.0

# sensor state (the original uses 8 sensor nodes; pure math here)
var _sens_coll_BL := false
var _sens_BL := Vector2.ZERO   # obj_player_sensorBL/BR — final bottom-sweep points
var _sens_BR := Vector2.ZERO
## collision_circle_list(x, y, 80, obj_floor_parent) — gathered once per step;
## ALL sensor tests run against this short list (like the original), which is
## also what keeps the sensor sweeps fast
var _sub_x := 0.0                    # sub-pixel x carry (integer-grid player)
var _near: Array = []
var _near_r: Array = []      # parallel cached_bbox() rects (no per-row calls)
var _near_simple: Array = [] # parallel _mask_simple flags

func _near_refresh() -> void:
	_near_r.clear()
	_near_simple.clear()
	for f in _near:
		_near_r.append(f.cached_bbox())
		_near_simple.append(f._mask_simple)
	# NOTE: clear() keeps capacity — no per-frame allocation

func near_inst(x: float, y: float) -> GMFloor:
	for i in _near.size():
		var r: Rect2 = _near_r[i]
		if x >= r.position.x and x < r.end.x and y >= r.position.y and y < r.end.y 				and _near[i].point_in_mask(x, y):
			return _near[i]
	return null

## scr_collision_check walks: first solid pixel within maxd steps of x at row y.
## Unrotated full-frame masks (all spr_block solids) are resolved analytically —
## only rotated/masked floors do the pixel walk.
func near_inst_left(x: float, y: float, maxd: int) -> GMFloor:
	var best := maxd + 1
	var bf: GMFloor = null
	for i in _near.size():
		var r: Rect2 = _near_r[i]
		if y < r.position.y or y >= r.end.y or r.position.x > x or r.end.x - 1.0 < x - maxd:
			continue
		if _near_simple[i]:
			var d := int(x - minf(x, r.end.x - 1.0))
			if d < best:
				best = d
				bf = _near[i]
		else:
			var f: GMFloor = _near[i]
			var cx := x
			var d2 := 0
			while d2 <= maxd:
				if f.point_in_mask(cx, y):
					if d2 < best:
						best = d2
						bf = f
					break
				cx -= 1
				d2 += 1
	return bf

func near_inst_right(x: float, y: float, maxd: int) -> GMFloor:
	var best := maxd + 1
	var bf: GMFloor = null
	for i in _near.size():
		var r: Rect2 = _near_r[i]
		if y < r.position.y or y >= r.end.y or r.end.x - 1.0 < x or r.position.x > x + maxd:
			continue
		if _near_simple[i]:
			var d := int(maxf(x, r.position.x) - x)
			if d < best:
				best = d
				bf = _near[i]
		else:
			var f: GMFloor = _near[i]
			var cx := x
			var d2 := 0
			while d2 <= maxd:
				if f.point_in_mask(cx, y):
					if d2 < best:
						best = d2
						bf = f
					break
				cx += 1
				d2 += 1
	return bf

func pm_near(x: float, y: float) -> bool:
	for f in _near:
		var r: Rect2 = f.cached_bbox()
		if x >= r.position.x and x < r.end.x and y >= r.position.y and y < r.end.y 				and f.point_in_mask(x, y):
			return true
	return false
var _sens_coll_BR := false
var _sens_L_x := 0.0
var _sens_L_y := 0.0
var _sens_R_x := 0.0
var _sens_R_y := 0.0

func _ready() -> void:
	super._ready()
	add_to_group("obj_player")
	gm_name = "obj_player"
	z_as_relative = false
	z_index = 0
	Globals.player = self
	_apply_character()

## per-character constants (the original spawns obj_tails/obj_knux/… per selection;
## one script carries them all and switches on Globals.character)
func _apply_character() -> void:
	if Globals.character == Globals.CHARACTER_EXE or Globals.character < 0:
		hp = 10000            # the exe is not hurt by damage (only bounces)
		acc = EXE_ACC
		maxHSpeed = EXE_MAXSPEED
		anims_cur = anims_visible
		anims_invis = anims_invisible
	else:
		hp = 100               # every survivor: obj_tails Create
		match Globals.character:
			Globals.CHARACTER_TAILS:
				acc = TAILS_ACC
				maxHSpeed = TAILS_MAXSPEED
				anims_cur = anims_tails
				anims_invis = anims_tails   # survivors have no invis sprites
			_:
				acc = EXE_ACC           # other survivors until their ports land
				maxHSpeed = EXE_MAXSPEED
				anims_cur = anims_tails
				anims_invis = anims_tails
		flyTimer = TAILS_FLY_RECHARGE
		attackTimer = 0
		# obj_tails Create: instance_create_depth(x, y, 0, obj_tails_tail)
		if Globals.character == Globals.CHARACTER_TAILS:
			var tail := GMNode.new()
			tail.set_script(load("res://src/game/obj_tails_tail.gd"))
			tail.position = position
			get_parent().add_child(tail)

func _gm_step() -> void:
	if shockedTimer <= 0:
		move_basic()
	else:
		isBoosting = false
		isLookingDown = false
		isLookingUp = false
		isAttacking = false
		isJumping = false
		gspd -= minf(absf(gspd), acc) * signf(gspd)
		xspd -= minf(absf(xspd), acc) * signf(xspd)
		shockedTimer -= 1
		hurttime = 60 * 2

	if won or lost:
		gspd = 0
		xspd = 0
		angle = 0

	collision_basic()

	if invisTimer <= 0 and bounceTimer <= 0:
		pass  # puppet bounce — stage 3.5 (no puppets solo)

	if hurttime > 0:
		hurttime -= 1

	_revival_step()

	image_alpha = 0.5 if (hurttime > 0 or isHiding) else 1.0

	# Step_2 — animation state machine (End Step)
	anim_step()
	# Other_7 (Animation End) — emotions return to idle
	if (state == EMOTION1 or state == EMOTION2 or state == EMOTION3) 			and image_index >= GM.sprite_count(sprite_name) - 1:
		if not kd(Globals.KeyEm1 if state == EMOTION1 else (Globals.KeyEm2 if state == EMOTION2 else Globals.KeyEm3)):
			image_index = 0
			state = IDLE
			emotion = false
		else:
			image_index = 0

	# sprite-screen stability on the integer world grid (GM truncates; Godot's
	# render snap ROUNDS → ±1px wobble). The SUB-PIXEL remainder is carried in
	# _sub_x instead of discarded — the original accelerates at only 0.057
	# px/frame^2, so plain floor() froze the player for ~15 frames (the
	# "input lag") until xspd reached 1px. With the carry the player moves
	# 1px as soon as 1px has accumulated — GM-identical feel.
	_sub_x += position.x
	var _whole := floorf(_sub_x)
	position.x = _whole
	_sub_x -= _whole

# ---------------------------------------------------------------- scr_move_basic
func move_basic() -> void:
	justJumped = false
	isLookingDown = false
	isLookingUp = false

	if isDead:
		if redRingTimer > 0:
			redRingTimer = 0
		emotion = false
		isZipline = false
		isAttacking = false
		isBoosting = false
		isHiding = false
		gspd -= minf(absf(gspd), acc) * signf(gspd)
		xspd -= minf(absf(xspd), acc) * signf(xspd)
		xspd -= 0.225 * sin(angle)
		return

	bounceTimer -= 1
	if bounceTimer > 0:
		if isGrounded:
			bounceTimer = -1
	if bounceTimer == 0:
		if isGrounded:
			bounceTimer = -1

	if isHurt:
		isAttacking = false
		gspd = 0
		if xspd > -1 and xspd < 1 and isGrounded:
			isHurt = false
		if xspd > 0:
			xspd -= 0.06
		else:
			xspd += 0.06
		yspd += 0.08
		isBoosting = false
		emotion = false
		return

	if isBoosting:
		if effectTime <= 0:
			effectTime = 16
		if isGrounded:
			gspd = 12 * image_xscale
			gspd -= 0.125 * sin(angle)
			xspd = gspd * cos(angle)
			yspd = gspd * -sin(angle)
		return

	# edge balancing check
	if isGrounded and absf(xspd) <= 0 and not (_sens_coll_BL and _sens_coll_BR):
		var sensor := _sens_coll_BL
		if sensor:
			var _result := false
			var _dir := 1
			var sx := _sens_L_x
			var rng := range(-8, 8)
			if not _sens_coll_BL:
				rng = range(7, -8, -1)
				sx = _sens_R_x
			for i in rng:
				var _met := false
				for j in range(0, 16):
					if pm_near(sx + i, _sens_L_y + j):
						_met = true
						break
				if _met:
					continue
				_result = true
				_dir = signi(i)
				break
			isOnEdge = _result
			edgeDir = 1 if _dir >= 0 else -1
	else:
		isOnEdge = false

	if state != IDLE and state != EMOTION1 and state != EMOTION2 and state != EMOTION3 and emotion:
		emotion = false

	if state == IDLE and kp(Globals.KeyIdle):
		image_index = 48

	if Globals.playerControls and not emotion and not isOnEdge:
		if kp(Globals.KeyEm1):
			if state == IDLE and taunt1():
				image_index = 0
				state = EMOTION1
				emotion = true
		elif kp(Globals.KeyEm2):
			if state == IDLE and taunt2():
				image_index = 0
				state = EMOTION2
				emotion = true
		elif kp(Globals.KeyEm3):
			if state == IDLE:
				image_index = 0
				state = EMOTION3
				emotion = true
				GameAudio.play_sound("snd_exe_laugh")

	move_ground()
	if _is_survivor():
		tails_special()
	else:
		exe_special()

	if not isGrounded:
		angle = 0
		if Globals.playerControls:
			# the flight steering is 3-4x the air acceleration (user spec) —
			# the escape needs to build speed fast while hovering
			var steer := acc * (7.0 if isFlying else 2.0)
			if kd(Globals.KeyLeft):
				image_xscale = -1
				xspd -= steer
			elif kd(Globals.KeyRight):
				image_xscale = 1
				xspd += steer
		if yspd < 0 and yspd > -4 and not isFlying:
			if absf(xspd) > 0:
				var d := ceili(xspd / 0.125)
				xspd -= d / 256.0
	else:
		if Globals.playerControls and kp(Globals.KeyA) and not isJumping:
			GameAudio.play_sound("snd_jump")
			isGrounded = false
			isSpinning = false
			isJumping = true
			justJumped = true
			image_index = 0
			xspd -= jumpForce * sin(angle)
			yspd = -jumpForce * cos(angle)

func taunt1() -> bool:
	return Unlockables.trades.has("texe1")

func taunt2() -> bool:
	return Unlockables.trades.has("texe0")

func move_ground() -> void:
	if isGrounded:
		isJumping = false
		if Globals.playerControls and kd(Globals.KeyDown):
			if gspd == 0:
				isLookingDown = true
				gspd = 0
			elif absf(gspd) >= 2 and not isSpinning and canSpin:
				GameAudio.play_sound("snd_spin")
				isSpinning = true
		if Globals.playerControls and kd(Globals.KeyUp) and gspd == 0:
			isLookingUp = true
			gspd = 0
		if not isSpinning:
			if not isLookingDown and not isLookingUp:
				if Globals.playerControls and kd(Globals.KeyLeft):
					if gspd < 0:
						image_xscale = -1
					if gspd > 0:
						gspd -= 0.5
						if gspd <= 0:
							gspd = -0.5
					elif gspd > -maxHSpeed:
						gspd -= acc
						if gspd <= -maxHSpeed:
							gspd = -maxHSpeed
				elif Globals.playerControls and kd(Globals.KeyRight):
					if gspd > 0:
						image_xscale = 1
					if gspd < 0:
						gspd += 0.5
						if gspd >= 0:
							gspd = 0.5
					elif gspd < maxHSpeed:
						gspd += acc
						if gspd >= maxHSpeed:
							gspd = maxHSpeed
				else:
					gspd -= minf(absf(gspd), acc) * signf(gspd)
		else:
			if Globals.playerControls and kd(Globals.KeyLeft) and gspd > 0:
				gspd -= 0.125
				if gspd <= 0:
					isSpinning = false
			elif Globals.playerControls and kd(Globals.KeyRight) and gspd < 0:
				gspd += 0.125
				if gspd >= 0:
					isSpinning = false
			gspd -= minf(absf(gspd), 0.0234375) * signf(gspd)

		if not isSpinning:
			gspd -= 0.125 * sin(angle)
			xspd = gspd * cos(angle)
			yspd = gspd * -sin(angle)
		else:
			gspd -= 0.225 * sin(angle)
			xspd = gspd * cos(angle)
			yspd = gspd * -sin(angle)
		if gspd == 0:
			isSpinning = false

## scr_camera_shake — with(obj_camera) { shake = true; ... }
func camera_shake(time: int, magnitude: float, fade := 0.25) -> void:
	for c in GMNode.all_of("obj_camera"):
		c.camera_shake(time, magnitude, fade)
		return

func _is_survivor() -> bool:
	return Globals.character != Globals.CHARACTER_EXE and Globals.character >= 0

# ------------------------------------------------------------- scr_tails_special
## Full port of scr_tails_special (obj_tails): the flight (KeyA in the air) and the
## chargeable tail-shot (KeyB on the ground). flyTimer is negative while recharging
## (-420 .. 0) and positive while flying; attackCharge counts the charge frames and
## the projectile damage tiers at 84/126 frames.
func tails_special() -> void:
	# red ring / hiding soft-lock the abilities (the original pins the timers)
	if redRingTimer > 0:
		if attackTimer <= 2:
			attackTimer = 2
		if flyTimer <= TAILS_FLY_RECHARGE + 2:
			flyTimer = TAILS_FLY_RECHARGE + 2
	if isHiding:
		if attackTimer <= 2 * 60:
			attackTimer = 2 * 60
		if flyTimer <= TAILS_FLY_RECHARGE + 2 * 60:
			flyTimer = TAILS_FLY_RECHARGE + 2 * 60

	# DISASTER_NOFLY=1 — the flight start is off (a plain jump on every press;
	# the tail can be checked without the fly taking over the jump)
	if Globals.playerControls and not isGrounded and kp(Globals.KeyA) 			and attackCharge <= 0 and attackAfter <= 0 			and OS.get_environment("DISASTER_NOFLY") != "1":
		if not isFlying and flyTimer <= TAILS_FLY_RECHARGE:
			GameAudio.play_sound("snd_tails_fly")
			flyTimer = TAILS_FLY_TIME
			isFlying = true
		if isFlying:
			if flyTimer > 0:
				flyGrv = -1.0
			else:
				isFlying = false
			isJumping = false
			if absf(xspd) > 0:
				image_xscale = signf(xspd)

	if isFlying:
		isSpinning = false
		if flyGrv < 2.0:
			flyGrv += 0.035
		if flyTimer <= 0:
			isFlying = false
		yspd = flyGrv

	if flyTimer > 0 and flyTimer % 18 == 0:
		GameAudio.play_sound("snd_tails_fly")

	if Globals.playerControls and kp(Globals.KeyB) and attackTimer == 0 and attackCharge == 0:
		GameAudio.play_sound("snd_tails_charge")
		attackTimer = ETAILS_ATTACK_RECHARGE if revivalTimes >= 2 else TAILS_ATTACK_RECHARGE
		attackCharge = 1

	if attackCharge > 0:
		emotion = false
		attackTimer = ETAILS_ATTACK_RECHARGE if revivalTimes >= 2 else TAILS_ATTACK_RECHARGE
		attackCharge += 1
		isJumping = false
		isFlying = false
		xspd = 0.0
		gspd = 0.0
		canMove = false
		if kd(Globals.KeyLeft):
			image_xscale = -1.0
		elif kd(Globals.KeyRight):
			image_xscale = 1.0
		attackKDir = image_xscale
		if attackCharge >= TAILS_CHARGE_MAX or not Globals.playerControls or isZipline 				or isHurt or isDead or shockedTimer > 0 or not kd(Globals.KeyB):
			GameAudio.stop_sound("snd_tails_charge")
			var val := floorf((attackCharge / 60.0) / 3.5 * 100.0)
			var tier := int(ceili(val / 20.0))
			if revivalTimes >= 2:
				# demon: the shot itself hurts (20/40/60 by charge)
				var dmg := 20
				if attackCharge >= 84 and attackCharge < 126:
					dmg = 40
				if attackCharge >= 126:
					dmg = 60
				_spawn_tails_projectile(dmg, true, tier)
			else:
				_spawn_tails_projectile(1 + int(floorf(attackCharge / 42.0)), false, tier)
			camera_shake(25, 1.2, 0.1)
			GameAudio.play_sound("snd_tails_shoot")
			if attackCharge < 84:
				attackAfter = int(60 * 0.4)
				recoil = -attackKDir * 2.0
			elif attackCharge < 126:
				attackAfter = int(60 * 0.5)
				recoil = -attackKDir * 4.0
			else:
				attackAfter = int(60 * 0.6)
				recoil = -attackKDir * 6.0
		if isHurt or hp <= 0 or isDead or shockedTimer > 0 or isZipline:
			isJumping = false
			isFlying = false
			isSpinning = false
			canMove = true
			attackCharge = 0
			attackAfter = 0

	# the original's tail of scr_tails_special: timer ticks + recoil decay
	if attackAfter <= 0:
		canSpin = true
	else:
		recoil -= minf(absf(recoil), acc * 3.0) * signf(recoil)

	if attackTimer > 0:
		attackTimer -= 1

	if isGrounded:
		if isFlying:
			isFlying = false
			flyTimer = 0
		if flyTimer > TAILS_FLY_RECHARGE:
			flyTimer -= 1
	elif flyTimer > 0:
		flyTimer -= 1

	if attackAfter > 0:
		if isHurt or hp <= 0 or isDead or shockedTimer > 0 or isZipline:
			isJumping = false
			isFlying = false
			isSpinning = false
			canMove = true
			attackAfter = 0
			attackCharge = 0
		canSpin = false
		attackAfter -= 1
		attackCharge = 0
		isJumping = false
		isFlying = false
		isSpinning = false
		canMove = true
		xspd = recoil
		gspd = recoil

## obj_tails_projectile — the tail shot (solo: it flies and hurts the first thing it
## meets; the netplay variant is server-synced, stage 3.5)
func _spawn_tails_projectile(dmg: int, is_exe: bool, charge_tier: int) -> void:
	var p := GMNode.new()
	p.set_script(load("res://src/game/obj_tails_projectile.gd"))
	p.position = position
	p.image_xscale = image_xscale
	p.set("dmg", dmg)
	p.set("is_exe", is_exe)
	p.set("charge", charge_tier)
	p.set("is_owner", true)
	get_parent().add_child(p)

# ---------------------------------------------------------------- scr_exe_special
func exe_special() -> void:
	if won or lost:
		invisTimer = EXE_INVIS_RECHARGE
		isAttacking = false
		attackTimer = 0

	if Globals.playerControls and isJumping and kp(Globals.KeyA):
		isJumping = false

	if Globals.playerControls and kp(Globals.KeyC):
		if invisTimer <= EXE_INVIS_RECHARGE:
			GameAudio.play_sound("snd_exe_invisenter")
			GameAudio.play_sound("snd_exe_appear")
			invisTimer = EXE_INVIS_DURATION
		elif invisTimer > 0:
			invisTimer = 0

	if invisTimer == 0:
		GameAudio.play_sound("snd_exe_appear")

	if invisTimer > EXE_INVIS_RECHARGE:
		invisTimer -= 1

	if Globals.playerControls and kp(Globals.KeyB) and attackTimer <= 0 and invisTimer <= 0:
		if kd(Globals.KeyLeft):
			image_xscale = -1
		elif kd(Globals.KeyRight):
			image_xscale = 1
		image_index = 0
		attackSpeed = xspd
		attackTimer = 60 if isGrounded else 120
		isAttacking = true
		isJumping = false
		isSpinning = false
		GameAudio.play_sound("snd_dash")

	if invisTimer > 0:
		isAttacking = false
		return

	if isAttacking:
		if yspd > 0:
			yspd = 0.0 if isGrounded else 2.5
		if isGrounded and absf(xspd) > 0 and int(floor(position.x)) % 4 == 0:
			quick_effect(position.x - 8 * signf(image_xscale), position.y + 20, "spr_dust")

	if attackTimer > 0:
		attackTimer -= 1

func quick_effect(x: float, y: float, spr: String) -> void:
	var e := GMNode.new()
	e.set_script(load("res://src/game/obj_quickfx.gd"))
	e.position = Vector2(x, y)
	e.sprite_name = spr
	e.z_index = z_index - 1
	get_parent().add_child(e)

# ---------------------------------------------------------------- collision (scr_collision_basic)
func collision_basic() -> void:
	if not isFlying:
		xspd = clampf(xspd, -maxHSpeed, maxHSpeed)
	yspd = clampf(yspd, -maxYSpeed, maxYSpeed)

	# fell out of the room → respawn at deathtp_point, snapped onto the
	# nearest floor below it (the original relies on death-respawn here)
	if position.y - 30 >= 1888.0:
		var nearest: GMNode = null
		var best := 1e18
		for d in GMNode.all_of("obj_deathtp_point"):
			var dist: float = d.position.distance_squared_to(position)
			if dist < best:
				best = dist
				nearest = d
		if nearest:
			position = nearest.position
			xspd = 0
			gspd = 0
			yspd = 0
			# find the first floor below the point and stand on it
			var sx := position.x
			var sy := position.y - 16
			var found := false
			while sy < 1888.0 + 64:
				if GMFloor.point_meeting_floor(sx - 7, sy) or GMFloor.point_meeting_floor(sx + 7, sy):
					found = true
					break
				sy += 1
			if found:
				position.y = sy - 18
			else:
				# no floor under the point — teleport to the first spawnpoint
				for sp in GMNode.all_of("obj_spawnpoint"):
					position = sp.position + Vector2(0, -18)
					break
			player_hurt(20, 0, 0)
			if Globals.character == Globals.CHARACTER_EXE:
				shockedTimer += 30

	if not isGrounded:
		yspd += yAccel

	collision_objects_before()

	_near = GMFloor.gather_near(position.x, position.y, 80)
	_near_refresh()
	collision_check_walls()
	position.x += xspd

	collision_check_top()
	position.y += yspd

	collision_check_bottom()

	collision_objects_after()

## scr_collision_check — walls
func collision_check_walls() -> void:
	var coll := false
	var yy_end := 0 if isGrounded else int(15 - absf(xspd))
	for yy in range(-16, yy_end):
		var sl := Vector2(ceilf(position.x) - 8, ceilf(position.y + yy))
		var sr := Vector2(ceilf(position.x) + 8, ceilf(position.y + yy))
		# left
		var inst1 := near_inst_left(sl.x, sl.y, maxHSpeed + 1)
		var dist1 := maxHSpeed + 1
		if inst1 != null:
			if inst1._mask_simple:
				dist1 = int(sl.x - minf(sl.x, inst1.cached_bbox().end.x - 1.0))
			else:
				dist1 = 0
				var cx2 := sl.x
				while dist1 <= maxHSpeed + 1 and not inst1.point_in_mask(cx2, sl.y):
					cx2 -= 1
					dist1 += 1
		# right
		var inst2 := near_inst_right(sr.x, sr.y, maxHSpeed + 1)
		var dist2 := maxHSpeed + 1
		if inst2 != null:
			if inst2._mask_simple:
				dist2 = int(maxf(sr.x, inst2.cached_bbox().position.x) - sr.x)
			else:
				dist2 = 0
				var cx3 := sr.x
				while dist2 <= maxHSpeed + 1 and not inst2.point_in_mask(cx3, sr.y):
					cx3 += 1
					dist2 += 1
		_sens_L_x = sl.x
		_sens_L_y = sl.y
		_sens_R_x = sr.x
		_sens_R_y = sr.y

		if -dist1 >= minf(xspd, -1):
			if not GMFloor.point_meeting_group(sl.x, sl.y, "gm_jumpthrough"):
				coll = true
				if xspd < 0:
					position.x = ceilf(sl.x) + 8
					xspd = 0
					gspd = 0
					isBoosting = false
					break
		if dist2 <= maxf(xspd, 1):
			if not GMFloor.point_meeting_group(sr.x, sr.y, "gm_jumpthrough"):
				coll = true
				if xspd > 0:
					position.x = ceilf(sr.x) - 8
					xspd = 0
					gspd = 0
					isBoosting = false
					break


## scr_collision_check_top — ceilings
func collision_check_top() -> void:
	var s1 := Vector2(ceilf(position.x) - 7, ceilf(position.y) - 18)
	var s2 := Vector2(ceilf(position.x) + 7, ceilf(position.y) - 18)
	var dist1 := 0
	while not pm_near(s1.x, s1.y) and dist1 < maxYSpeed + 1:
		s1.y -= 1
		dist1 += 1
	var dist2 := 0
	while not pm_near(s2.x, s2.y) and dist2 < maxYSpeed + 1:
		s2.y -= 1
		dist2 += 1

	if dist1 != maxYSpeed + 1 and dist2 != maxYSpeed + 1:
		if s1.y >= s2.y:
			if -dist1 >= yspd and yspd < 0:
				if not GMFloor.point_meeting_group(s1.x, s1.y, "gm_jumpthrough"):
					position.y = ceilf(s1.y) + 18
					yspd = 0
		elif s1.y < s2.y:
			if -dist2 >= yspd and yspd < 0:
				if not GMFloor.point_meeting_group(s2.x, s2.y, "gm_jumpthrough"):
					position.y = ceilf(s2.y) + 18
					yspd = 0
	elif dist1 != maxYSpeed + 1:
		if -dist1 >= yspd and yspd < 0:
			if not GMFloor.point_meeting_group(s1.x, s1.y, "gm_jumpthrough"):
				position.y = ceilf(s1.y) + 18
				yspd = 0
	elif dist2 != maxYSpeed + 1:
		if -dist2 >= yspd and yspd < 0:
			if not GMFloor.point_meeting_group(s2.x, s2.y, "gm_jumpthrough"):
				position.y = ceilf(s2.y) + 18
				yspd = 0

## scr_collision_check_bottom — ground snap + angle
func collision_check_bottom() -> void:
	var s1 := Vector2(ceilf(position.x) - 7, 0)
	var s2 := Vector2(ceilf(position.x) + 7, 0)
	# original resets the BOTTOM sensor coll flags here (edge balance reads them)
	_sens_coll_BL = false
	_sens_coll_BR = false

	if not isGrounded:
		angle = 0
		s1.y = ceilf(position.y) - 16
		s2.y = ceilf(position.y) - 16
		var dist1 := 0
		while not pm_near(s1.x, s1.y) and dist1 < 35:
			s1.y += 1
			dist1 += 1
		var dist2 := 0
		while not pm_near(s2.x, s2.y) and dist2 < 35:
			s2.y += 1
			dist2 += 1
		var land := -1
		if dist1 != 35 and dist2 != 35:
			if s1.y < s2.y:
				land = dist2
				if yspd > 0:
					land_on(s2.y - 18, GMFloor.point_meeting_group(s2.x, s2.y, "gm_jumpthrough") != null, dist2)
			else:
				land = dist1
				if yspd > 0:
					land_on(s1.y - 18, GMFloor.point_meeting_group(s1.x, s1.y, "gm_jumpthrough") != null, dist1)
		elif dist1 != 35:
			land = dist1
			if yspd > 0:
				land_on(s1.y - 18, GMFloor.point_meeting_group(s1.x, s1.y, "gm_jumpthrough") != null, dist1)
		elif dist2 != 35:
			land = dist2
			if yspd > 0:
				land_on(s2.y - 18, GMFloor.point_meeting_group(s2.x, s2.y, "gm_jumpthrough") != null, dist2)
		_sens_coll_BL = land >= 0 and dist1 <= 2
		_sens_coll_BR = land >= 0 and dist2 <= 2
		_sens_BL = s1
		_sens_BR = s2

	if isGrounded:
		s1.y = ceilf(position.y) - 16
		s2.y = ceilf(position.y) - 16
		var maxDist := 48
		var _dist1 := 0
		while not pm_near(s1.x, s1.y) and _dist1 < maxDist:
			s1.y += 1
			_dist1 += 1
		var _dist2 := 0
		while not pm_near(s2.x, s2.y) and _dist2 < maxDist:
			s2.y += 1
			_dist2 += 1

		if _dist1 != maxDist or _dist2 != maxDist:
			var winner := 0.0
			if s1.y == s2.y:
				_sens_coll_BL = true
				_sens_coll_BR = true
			if s1.y > s2.y:
				_sens_coll_BR = true
				winner = s2.y - 18
			else:
				_sens_coll_BL = true
				winner = s1.y - 18
			position.y = winner
			collision_check_angle()
		else:
			angle = 0
			isGrounded = false
		_sens_BL = s1
		_sens_BR = s2

func land_on(winner: float, jumpthrough: bool, dist: int) -> void:
	if jumpthrough:
		if yspd > 0 and dist >= 15:
			position.y = winner
			isGrounded = true
			yspd = 0
			gspd = xspd
	else:
		if yspd > 0:
			position.y = winner
			isGrounded = true
			yspd = 0
			gspd = xspd

## scr_collision_check_angle — OWN sweep (sensors x±7 from y-16, maxDist 66);
## angle=0 when either side misses — standing on a corner must NOT slope
func collision_check_angle() -> void:
	var s1 := Vector2(position.x - 7, position.y - 16)
	var s2 := Vector2(position.x + 7, position.y - 16)
	var d1 := 0
	while not pm_near(s1.x, s1.y) and d1 < 66:
		s1.y += 1
		d1 += 1
	var d2 := 0
	while not pm_near(s2.x, s2.y) and d2 < 66:
		s2.y += 1
		d2 += 1
	if d1 != 66 and d2 != 66:
		angle = -deg_to_rad(rad_to_deg(Vector2(-8, d1).angle_to_point(Vector2(8, d2))))
	else:
		angle = 0

## scr_collision_objects_before — nothing map-specific solo
func collision_objects_before() -> void:
	pass

## scr_collision_objects_after — spikes, springs, angleanullers, hiding
func collision_objects_after() -> void:
	if isDead:
		return
	var feet := Vector2(position.x, position.y)
	# springs — original checks the BOTTOM sensors (BL then BR)
	var spring := GMFloor.point_meeting_group(_sens_BL.x, _sens_BL.y, "obj_spring_parent")
	if spring == null:
		spring = GMFloor.point_meeting_group(_sens_BR.x, _sens_BR.y, "obj_spring_parent")
	if spring and spring.image_blend == GM.C_WHITE and yspd > 0 and shockedTimer <= 0:
		if isHurt:
			isHurt = false
		if isAttacking:
			attackTimer = 60 if isGrounded else 120
			isAttacking = false
		xspd = spring.xdir
		yspd = spring.ydir
		isBoosting = false
		isSpinning = false
		isGrounded = false
		isJumping = false
		spring.spring_hit()
	# damage rects
	var dmg_rect := Rect2(position.x - 6, position.y + 19, 12, 1)
	var dmg := GMFloor.rect_meeting_group(dmg_rect, "obj_damage")
	if dmg is GMNode and dmg.gm_name == "obj_spike":
		# original: collision_rectangle(x-6, y+19, x+6, y+20, obj_spike) →
		# hurt(20, -image_xscale*4, -6, snd_spike). The solid sprite mask means
		# the feet only ever reach the rect standing ON TOP; a side approach is
		# blocked by the wall before the rect can overlap.
		angle = 0
		player_hurt(20, -image_xscale * 4, -6, "snd_spike")
	elif dmg is GMNode and dmg.gm_name == "obj_movingspike":
		# standing ON the spikes = damage; brushing them sideways while running
		# (feet below the mask top, the lifted mask) = no damage
		if dmg.image_index > 0 and dmg.image_index < 5:
			var mr: Rect2 = dmg.bbox_rect()
			if position.y + 18.0 >= mr.position.y - 1.0 and position.y + 18.0 <= mr.position.y + 3.0:
				angle = 0
				player_hurt(20, -image_xscale * 4, -6, "snd_spike")
	# angleanullers
	if GMFloor.point_meeting_group(_sens_L_x, _sens_L_y, "obj_angleanuller") \
			or GMFloor.point_meeting_group(_sens_R_x, _sens_R_y, "obj_angleanuller"):
		angle = 0
	# ladders slow the player
	for lad in GMNode.all_of("obj_ladder"):
		if lad.position_meeting(_sens_L_x, _sens_L_y):
			if absf(xspd) > 7:
				xspd = 7 * signf(xspd)
				gspd = 7 * signf(gspd)
			maxHSpeed = 7
	# hiding
	var hide := GMFloor.point_meeting_group(feet.x, feet.y, "obj_hiding_parent") != null
	isHiding = hide and isLookingDown and not isLookingUp

## scr_player_hurt (solo)
## scr_player_hurt port — the order matters and is the original's exactly:
##   1. hp -= damage (survivors only, and not while demonized) — a ring does NOT
##      restore it, it is consumed afterwards for the ringlose feedback
##   2. hp <= 0 -> scr_player_instakill (death), return
##   3. rings > 0 -> rings = 0 + snd_ringlose (+ camera shake), else the hurt sound
func player_hurt(damage: int, xpw := 4.0, ypw := -6.0, snd_id := "snd_hurt", blood := "spr_blood1") -> void:
	if isDead or (hurttime > 0 and damage > 0):
		return
	if OS.get_environment("DISASTER_DMGDBG") == "1":
		print("HURT f=", Engine.get_physics_frames(), " pos=", position, " snd=", snd_id,
			" hp=", hp, " rings=", rings, " dmg=", damage)
	var was_survivor := _is_survivor() and revivalTimes < 2
	if was_survivor and damage > 0:
		hp -= damage
		if hp <= 0:
			player_instakill()
			return
	if rings > 0 and damage > 0:
		rings = 0
		GameAudio.play_sound("snd_ringlose")
		quick_effect(position.x, position.y - 10, "spr_ringlose")
		camera_shake(25, 1, 0.2)
	elif damage > 0 or snd_id == "snd_buble":
		GameAudio.play_sound(snd_id)
		camera_shake(25, 1, 0.2)
	if damage > 0:
		quick_effect(position.x, position.y - 10, blood)
		isHurt = true
		isJumping = false
	isGrounded = false
	isSpinning = false
	isLookingDown = false
	isLookingUp = false
	xspd = xpw
	yspd = ypw
	# the original: 1s of invulnerability in the first minute of a round, else 3s
	if damage != 0:
		hurttime = 60 if (Globals.timeMinutes <= 0 and Globals.timeSeconds < 60) else 60 * 3
	else:
		hurttime = 0

## scr_player_instakill — solo emulation of the server-driven death: the client
## reports it, the server ticks the dead timer and answers with the revival
## (revivalTimes = 1, hp 40) or the demonization (revivalTimes = 2, hp 100)
func player_instakill() -> void:
	if isDead:
		return
	hp = 0
	deadTimer = 31
	deadColor = Color.WHITE
	isDead = true
	isHurt = false
	shards = 0
	xspd = image_xscale * 2.0
	yspd = 0.0
	isGrounded = false
	isSpinning = false
	isLookingDown = false
	isLookingUp = false
	GameAudio.play_sound("snd_dead")
	quick_effect(position.x, position.y, "spr_blood2")
	_dead_timer = 60 * 31     # the original's deadTimer = 31 SECONDS (the hud shows them)

## solo revival/demonization (SERVER_GAME_DEATHTIMER_END + SERVER_REVIVAL_REVIVED)
func _revival_step() -> void:
	if not isDead or _dead_timer <= 0:
		return
	_dead_timer -= 1
	deadTimer = int(ceili(_dead_timer / 60.0))   # the display counts SECONDS
	if _dead_timer > 0:
		return
	if revivalTimes >= 1:
		# second death: demonized — join the hunters
		hp = 100
		isDead = false
		revivalTimes = 2
		hurttime = 60 * 2
		attackTimer = 0
		flyTimer = TAILS_FLY_RECHARGE
		GameAudio.play_sound("snd_demonization")
	else:
		# first death: revive wounded with 40 hp
		hp = 40
		isDead = false
		revivalTimes += 1
		hurttime = 60 * 4
		GameAudio.play_sound("snd_hurt")

var _dead_timer := 60 * 31   # frames — the original's deadTimer starts at 31 SECONDS
var _dead_pin := false       # the DEAD anim reached its last frame (Draw_76 clamp)

## the heal: 10 rings -> 20 hp (net_state_game ring packet: the check fires on
## EVERY ring gain while rings >= 10 && hp < 100 && _canHeal, and zeroes the
## rings — repeatable, the next heal needs 10 collected again)
func try_heal() -> void:
	if not _is_survivor() or revivalTimes >= 2 or isDead:
		return
	if rings >= 10 and hp < 100:
		rings = 0
		hp += 20
		GameAudio.play_sound("snd_heal")
		quick_effect(position.x, position.y - 10, "spr_heal_part")

## ring pickup (obj_ring Step_0, survivor branch) — rings += n, then the heal check
func ring_collected(count := 1) -> void:
	rings += count
	GameAudio.play_sound("snd_ring")
	quick_effect(position.x, position.y, "spr_ring_sparkle")
	try_heal()

## Step_2 — animation state machine + sprite table
## obj_tails Step_2 — the survivor state machine. Shares the generic states and
## adds the flight / charge-attack / death ones (the original's TAILS_* macros).
func _tails_anim_step() -> void:
	if not emotion:
		state = IDLE
	if isDead or shockedTimer > 0:
		state = DEAD
		apply_anim()
		return
	if attackCharge > 0 or attackAfter > 0:
		state = TAILS_ATTACK1
		apply_anim()
		return
	if isHurt:
		state = HURT
		apply_anim()
		return
	if isFlying:
		state = TAILS_FLY
		apply_anim()
		return
	if isZipline:
		if isGrounded:
			isZipline = false
		else:
			state = TAILS_ZIPLINE
			apply_anim()
			return
	if isLookingUp:
		state = LOOKUP
		apply_anim()
		return
	if isLookingDown:
		state = LOOKDOWN
		apply_anim()
		return
	if isSpinning:
		state = SPIN
		apply_anim()
		return
	if absf(xspd) > 0 and isGrounded:
		state = WALK if absf(xspd) < 8 else RUN
	if isOnEdge:
		state = BALANCING
		apply_anim()
		return
	if not isGrounded:
		state = JUMP if isJumping else FALL
	apply_anim()

func anim_step() -> void:
	if isDead:
		state = DEAD
		apply_anim()
		return
	if _is_survivor():
		_tails_anim_step()
		return
	if not emotion:
		state = IDLE
	if won and isGrounded:
		state = EXE_WON
		apply_anim()
		return
	if lost and isGrounded:
		state = EXE_LOST
		apply_anim()
		return
	if isHurt:
		state = HURT
		apply_anim()
		return
	if shockedTimer > 0:
		state = HURT if not isGrounded else EXE_SHOCKED
		apply_anim()
		return
	if isAttacking:
		if isGrounded:
			if state == EXE_AIR_ATTACK:
				isAttacking = false
			else:
				state = EXE_ATTACK
		else:
			if state == EXE_ATTACK:
				isAttacking = false
			else:
				state = EXE_AIR_ATTACK
		apply_anim()
		return
	if isZipline:
		if isGrounded:
			isZipline = false
		state = EXE_ZIPLINE
		apply_anim()
		return
	if isLookingUp:
		state = LOOKUP
		apply_anim()
		return
	if isLookingDown:
		state = LOOKDOWN
		apply_anim()
		return
	if isSpinning:
		state = SPIN
		apply_anim()
		return
	if absf(xspd) > 0 and isGrounded:
		state = WALK if absf(xspd) < 8 else RUN
	if isOnEdge:
		state = BALANCING
		apply_anim()
		return
	if not isGrounded:
		state = JUMP if isJumping else FALL
	apply_anim()

## obj_tails Draw_0 tail: the charging ball over the player — spr_tailscharge's
## 100 frames run yellow -> red as attackCharge fills (the colour IS the art)
func _draw_charge_effect() -> void:
	if attackCharge > 0:
		var frame := int(floorf((attackCharge / 60.0) / 3.5 * 100.0))
		draw_sprite("spr_tailscharge", clampi(frame, 0, 99),
				position.x + image_xscale * 24.0, position.y, image_xscale, 1.0)

func apply_anim() -> void:
	if state != DEAD:
		_dead_pin = false   # re-arm for the next death/shock
	var invis := invisTimer > 0
	var table := anims_invis if invis else anims_cur
	if _is_survivor() and revivalTimes >= 2:
		table = anims_eanims   # obj_tails Draw_76: the demon table
	var idx := state
	if invis and state == HURT:
		idx = WALK
	sprite_name = table[idx]
	if OS.get_environment("ANIMTRACE") == "1" and Engine.get_physics_frames() % 30 == 0:
		print("ANIMTRACE state=", state, " spr=", sprite_name, " flying=", isFlying,
			" grounded=", isGrounded, " char=", Globals.character)
	match state:
		IDLE:
			image_speed = 1.0
		HURT, EXE_ZIPLINE:
			image_speed = 0.0
			image_index = 0
		DEAD:
			# obj_tails Draw_76: the demon death loops at half speed; a normal
			# death plays once (grounded speed 1, air frozen) and pins on the
			# last frame. My base wraps looping sprites BEFORE this runs, so the
			# pin keeps a done-flag instead of a bare clamp.
			if revivalTimes >= 2:
				image_speed = 0.5
			else:
				image_speed = 1.0 if isGrounded else 0.0
				var cnt := GM.sprite_count(sprite_name)
				if _dead_pin or image_index >= cnt - 1:
					image_index = cnt - 1
					image_speed = 0.0
					_dead_pin = true
		BALANCING:
			image_xscale = edgeDir
			image_speed = 1.0
		FALL:
			image_speed = 0.1
			if image_index >= GM.sprite_count(sprite_name) - 1:
				image_index = GM.sprite_count(sprite_name) - 1
			image_xscale = 1 if xspd > 0 else (-1 if xspd < 0 else image_xscale)
		WALK:
			image_speed = absf(xspd) / maxHSpeed
		RUN, JUMP:
			image_speed = maxf(absf(xspd) / 20.0, 0.5)
		LOOKUP, LOOKDOWN:
			image_speed = 0.2
			if image_index >= 1:
				image_index = 1
		SPIN:
			image_speed = absf(xspd) / 5.0
		EXE_ATTACK:
			image_speed = 2.0
			if image_index >= GM.sprite_count(sprite_name) - 1:
				xspd *= 0.7
				gspd *= 0.7
				isAttacking = false
		EXE_AIR_ATTACK:
			image_speed = 0.8
			if image_index >= GM.sprite_count(sprite_name) - 1:
				xspd *= 0.7
				gspd *= 0.7
				isAttacking = false
				isJumping = false
		EXE_SHOCKED:
			image_speed = 0.5
		EXE_LOST, EXE_WON:
			image_speed = 0.8
		EMOTION1, EMOTION2, EMOTION3:
			image_speed = 0.8

# Other_7 — emotion animation end handling
func anim_special() -> void:
	match state:
		IDLE:
			image_index = GM.sprite_count(sprite_name) - 25
		EMOTION1:
			if not kd(Globals.KeyEm1):
				image_index = 0
				state = IDLE
				emotion = false
		EMOTION2:
			if not kd(Globals.KeyEm2):
				image_index = 0
				state = IDLE
				emotion = false
		EMOTION3:
			if not kd(Globals.KeyEm3):
				image_index = 0
				state = IDLE
				emotion = false

func _gm_draw() -> void:
	_draw_charge_effect()
	if OS.get_environment("DEBUG_PLAYER_VISIBLE") == "1":
		var tex2 := GM.sprite_texture(sprite_name, int(image_index))
		if tex2:
			var m2 := GM.sprite_meta(sprite_name)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(image_xscale, image_yscale))
			draw_texture(tex2, -Vector2(m2["xorigin"], m2["yorigin"]))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if effectTime > 0:
		effectTime -= 1
		if effectTime % 3 == 0:
			quick_effect(position.x, position.y, sprite_name)
	# draw with rotation (spinning stays upright)
	var rot := 0.0 if isSpinning else rad_to_deg(angle)
	var alpha := 0.5 if (hurttime > 0 or isHiding or shockedTimer > 0) else 1.0
	var tex := GM.sprite_texture(sprite_name, int(image_index))
	if tex:
		var m := GM.sprite_meta(sprite_name)
		var origin := Vector2(m["xorigin"], m["yorigin"])
		draw_set_transform(Vector2.ZERO, deg_to_rad(-rot), Vector2(image_xscale, image_yscale))
		draw_texture(tex, -origin, Color(image_blend, image_alpha * image_alpha_f()))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if isDead:
		xspd = 0
		gspd = 0

func image_alpha_f() -> float:
	return 1.0

func _physics_process_stub() -> void:
	pass
