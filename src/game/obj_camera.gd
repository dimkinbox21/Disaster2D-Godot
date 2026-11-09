extends GMNode
## Port of obj_camera — follows the player (mode 0), look up/down, shake.

var target: GMNode = null
var dist := 32.0
var look_timer := 0
var shakeTime := 0
var shakeMagnitude := 0.0
var shakeFade := 0.25
var shaking := false
var room_w := 4544.0
var room_h := 1888.0

func _ready() -> void:
	gm_name = "obj_camera"  # spawned by map_controller — must be findable
	super._ready()
	depth = -1000
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room_w)
	cam.limit_bottom = int(room_h)
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.make_current()
	_cam2d = cam

var _cam2d: Camera2D = null

func _gm_step() -> void:
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player:
		if not player.isGrounded:
			# airborne: the camera lags behind up to 32px (dist = actual lag)
			var yy := floorf(player.position.y) - 135
			dist = position.y - yy
			position.x = floorf(player.position.x) - 240
			if absf(dist) > 32:
				dist = 32.0 * signf(dist)
				position.y = floorf(player.position.y) - 135 + dist
		else:
			if player.isLookingDown:
				look_timer += 1
				if look_timer > 90 and dist < 100:
					dist += 2
			elif player.isLookingUp:
				look_timer += 1
				if look_timer > 90 and dist > -100:
					dist -= 2
			else:
				look_timer = 0
			# GM-exact integer camera: with a fractional camera each object
			# crosses its render-snap boundary at a different moment, so the
			# world loses rigidity — thin objects (ladders/fences) slide ±1px
			# against the walls. An integer camera makes everything step in
			# sync. The player's own twitch is fixed separately by its
			# half-pixel world grid (screen x stays constant).
			position.x = floorf(player.position.x) - 240
			position.y = floorf(player.position.y) - 135 + dist
	# original: "Slowly move camera back" — 2px/frame toward 0 when not looking
	if look_timer == 0:
		for i in 2:
			if dist == 0:
				break
			dist -= signf(dist)
	# shake — applied BEFORE the room clamp (choose(-m, m), then fade)
	if shaking:
		position.x += -shakeMagnitude if randf() < 0.5 else shakeMagnitude
		position.y += -shakeMagnitude if randf() < 0.5 else shakeMagnitude
		shakeTime -= 1
		if shakeTime <= 0:
			shakeMagnitude -= shakeFade
			if shakeMagnitude <= 0:
				shakeMagnitude = 0.0
				shaking = false
	# clamp to room + drive the real Camera2D
	position.x = clampf(position.x, 0, room_w - 480)
	position.y = clampf(position.y, 0, room_h - 270)
	if _cam2d:
		# parent node already sits at the view's top-left; center = +240,+135
		_cam2d.position = Vector2(240, 135)
	if OS.get_environment("DISASTER_PROF") == "1" and player and Engine.get_physics_frames() % 6 == 0:
		print("CAMX dx=%.2f p.x=%.1f cam.x=%.0f g=%s" % [player.position.x - (position.x + 240), player.position.x, position.x, player.isGrounded])

func camera_shake(time: int, magnitude: float, fade := 0.25) -> void:
	shakeTime = time
	shakeMagnitude = magnitude
	shakeFade = fade
	shaking = true

func _gm_draw() -> void:
	pass
