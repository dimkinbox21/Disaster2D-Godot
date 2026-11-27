extends GMNode
## Port of obj_camera — follows the player (mode 0), look up/down, shake.

var render_origin := Vector2.ZERO
var target: GMNode = null
var dist := 32.0
var look_timer := 0
var shakeTime := 0
var shakeMagnitude := 0.0
var shakeFade := 0.25
var shaking := false
var _death_hold := 0
var _spectating := false
var _cycle_spectator := false
@export_storage var room_w := 4544.0
@export_storage var room_h := 1888.0


func _ready() -> void:
	process_physics_priority = 100  # after player and puppet movement
	gm_name = "obj_camera"  # spawned by map_controller — must be findable
	super._ready()
	depth = -1000
	var cam := Camera2D.new()
	cam.position = Vector2(240, 135)
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.process_physics_priority = 101
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room_w)
	cam.limit_bottom = int(room_h)
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.make_current()
	_cam2d = cam


var _cam2d: Camera2D = null


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Publish the same physics snapshot that the player just produced, including
	# spectator/end-of-round branches which return early from _gm_step.
	render_origin = position.floor()
	if is_instance_valid(_cam2d):
		_cam2d.global_position = render_origin + Vector2(240, 135)
		_cam2d.force_update_scroll()


func _gm_step() -> void:
	if Net.gameEnds:
		var killer: GMNode = Globals.player if Globals.character == Globals.CHARACTER_EXE else null
		if not is_instance_valid(killer):
			for puppet in GMNode.all_of("obj_player_puppet"):
				if puppet.master_id == Net.exeId:
					killer = puppet
		if is_instance_valid(killer):
			target = killer
			position.x = clampf(killer.position.x - 240, 0, maxf(0, room_w - 480))
			position.y = clampf(killer.position.y - 135, 0, maxf(0, room_h - 270))
		return
	if _death_camera():
		return
	var scene := get_tree().current_scene
	if scene != null and scene.get("rules") != null and scene.rules.get("eye_target") != null:
		var eye: GMNode = scene.rules.eye_target
		if is_instance_valid(eye):
			position = Vector2(
				clampf(eye.position.x - 240, 0, maxf(0, room_w - 480)),
				clampf(eye.position.y - 135, 0, maxf(0, room_h - 270))
			)
			return
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			target = null
			for puppet in GMNode.all_of("obj_player_puppet"):
				if not puppet.isInactive and not puppet.is_queued_for_deletion():
					target = puppet
					break
		if is_instance_valid(target):
			position.x = clampf(target.position.x - 240, 0, maxf(0, room_w - 480))
			position.y = clampf(target.position.y - 135, 0, maxf(0, room_h - 270))
		return
	if player:
		if not player.isGrounded:
			# airborne: the camera lags behind up to 32px (dist = actual lag)
			var yy := player.position.y - 135
			dist = position.y - yy
			position.x = player.position.x - 240
			if absf(dist) > 32:
				dist = 32.0 * signf(dist)
				position.y = player.position.y - 135 + dist
		else:
			if player.isLookingDown:
				look_timer += 1
				if look_timer > 90 and dist < 100:
					dist = minf(100.0, dist + 2.0)
			elif player.isLookingUp:
				look_timer += 1
				if look_timer > 90 and dist > -100:
					dist = maxf(-100.0, dist - 2.0)
			else:
				look_timer = 0
			position.x = player.position.x - 240
			position.y = player.position.y - 135 + dist
	# original: "Slowly move camera back" — 2px/frame toward 0 when not looking
	if look_timer == 0:
		# A fractional offset must reach zero rather than oscillating around it.
		dist = move_toward(dist, 0.0, 2.0)
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


func camera_shake(time: int, magnitude: float, fade := 0.25) -> void:
	shakeTime = time
	shakeMagnitude = magnitude
	shakeFade = fade
	shaking = true


func _unhandled_key_input(event: InputEvent) -> void:
	if _spectating and event is InputEventKey and event.pressed and not event.echo:
		_cycle_spectator = true


func _death_camera() -> bool:
	var player = Globals.player
	if not is_instance_valid(player) or not player.isDead:
		_death_hold = 0
		_spectating = false
		_cycle_spectator = false
		return false
	if not _spectating:
		_death_hold += 1
		if _death_hold <= 180:
			return true
		_spectating = true
		Globals.cameraMode = 2
		target = null
	var candidates: Array[GMNode] = []
	for puppet in GMNode.all_of("obj_player_puppet"):
		if (
			not puppet.isInactive
			and puppet.hp > 0
			and not puppet.isDemonized
			and puppet.pstate != 6
		):
			candidates.append(puppet)
	var index := candidates.find(target)
	if _cycle_spectator or index < 0:
		target = candidates[(index + 1) % candidates.size()] if not candidates.is_empty() else null
		_cycle_spectator = false
	if is_instance_valid(target):
		var destination := target.position.floor() - Vector2(240, 135)
		position = (
			position.lerp(destination, 0.5)
			if position.distance_to(destination) > 10
			else destination
		)
		position.x = clampf(position.x, 0, maxf(0, room_w - 480))
		position.y = clampf(position.y, 0, maxf(0, room_h - 270))
	return true


func _gm_draw() -> void:
	pass
