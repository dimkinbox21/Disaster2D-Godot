extends RefCounted
## Reconcile authoritative checkpoints, then replay unacknowledged local input.
const Checkpoint = preload("res://src/net/movement_state.gd")
var net: Node
var sequence := 0
var corrections := 0
var history := {}
var states := {}
var replaying := false
var sending := false
var frame_inputs := 0
var previous_inputs := 0
var feedback: GMNode
var bindings: Array = []
var deferred := false
var pending := {}
var transported := false


func _init(client: Node):
	net = client


func clear():
	sequence = 0
	corrections = 0
	history.clear()
	states.clear()
	bindings.clear()
	pending.clear()
	transported = false
	frame_inputs = 0
	previous_inputs = 0
	replaying = false
	sending = false


func keys() -> Array:
	if not bindings.is_empty():
		return bindings
	var g = net.get_node("/root/Globals")
	bindings = [
		g.KeyLeft,
		g.KeyRight,
		g.KeyUp,
		g.KeyDown,
		g.KeyA,
		g.KeyB,
		g.KeyC,
		g.KeyEm1,
		g.KeyEm2,
		g.KeyEm3,
		g.KeyIdle
	]
	return bindings


func inputs() -> int:
	var g = net.get_node("/root/Globals")
	if not g.playerControls and not (is_instance_valid(g.player) and g.player.isZipline):
		return 0
	var gm = net.get_node("/root/GM")
	var bits := 0
	var bindings := keys()
	for i in bindings.size():
		if gm.key_down(bindings[i]):
			bits |= 1 << i
	# Locked cosmetic taunts do not enter the authoritative actor state machine.
	if is_instance_valid(g.player):
		if not g.player.taunt1():
			bits &= ~(1 << 7)
		if not g.player.taunt2():
			bits &= ~(1 << 8)
	return bits


func before_step(_actor: Node):
	if replaying:
		return
	previous_inputs = frame_inputs
	frame_inputs = inputs()


func record(actor: Node) -> int:
	sequence += 1
	history[sequence] = {
		"at": actor.position,
		"state": Checkpoint.capture(actor, net.get_node("/root/Globals").exeCharacter),
		"held": frame_inputs,
		"previous": previous_inputs
	}
	while history.size() > 256:
		history.erase(history.keys()[0])
	return sequence


func silent_effect() -> GMNode:
	if not is_instance_valid(feedback):
		feedback = load("res://src/game/obj_quickfx.gd").new()
		feedback.gm_visible = false
		feedback.gm_static = true
		net.add_child(feedback)
	return feedback


func replay(actor: Node, confirmed: int, held: int):
	var gm = net.get_node("/root/GM")
	var saved = [gm._down_keys, gm._pressed_this_frame, gm._released_this_frame]
	var bindings := keys()
	replaying = true
	var previous := held
	for id in history.keys():
		if id <= confirmed:
			continue
		var input: int = history[id].held
		gm._down_keys = {}
		gm._pressed_this_frame = {}
		gm._released_this_frame = {}
		for bit in bindings.size():
			var key: int = bindings[bit]
			if input & (1 << bit):
				gm._down_keys[key] = true
			if (input & ~previous) & (1 << bit):
				gm._pressed_this_frame[key] = true
			if (previous & ~input) & (1 << bit):
				gm._released_this_frame[key] = true
		actor._physics_process(1.0 / 60)
		for zip in Checkpoint.zip_objects(actor):
			zip._gm_step()
		previous = input
		history[id].at = actor.position
		history[id].state = Checkpoint.capture(actor, net.get_node("/root/Globals").exeCharacter)
	replaying = false
	gm._down_keys = saved[0]
	gm._pressed_this_frame = saved[1]
	gm._released_this_frame = saved[2]


func receive(b: StreamPeerBuffer):
	if b.get_available_bytes() < 42:
		return
	if deferred:
		var raw := b.data_array.slice(b.get_position())
		if raw.decode_u32(0) != net.round_id:
			return
		var id := raw.decode_u16(8)
		if not pending.has(id) or raw.decode_u32(30) > pending[id].decode_u32(30):
			pending[id] = raw
		return
	if b.get_u32() != net.round_id:
		return
	var data = {
		"sequence": b.get_u32(),
		"id": b.get_u16(),
		"epoch": b.get_u16(),
		"at": Vector2(b.get_float(), b.get_float()),
		"velocity": Vector2(b.get_float(), b.get_float()),
		"force": b.get_u8() != 0,
		"state": b.get_u8(),
		"revision": b.get_u32(),
		"health_revision": b.get_u32(),
		"held": b.get_u16()
	}
	var size := b.get_u16()
	if size > b.get_available_bytes() or size > 16384:
		return
	var checkpoint = bytes_to_var(b.get_data(size)[1])
	if not checkpoint is Array:
		return
	data.checkpoint = checkpoint
	var old: Dictionary = states.get(data.id, {})
	if data.epoch < int(old.get("epoch", -1)) or data.revision <= int(old.get("revision", -1)):
		return
	if (
		data.id == net.nid
		and not data.force
		and data.health_revision < int(net.health.states.get(data.id, {}).get("revision", 0))
	):
		return
	states[data.id] = data
	var globals = net.get_node("/root/Globals")
	if (
		data.id != net.nid
		or not is_instance_valid(globals.player)
		or net.state != net.STATE_GAME
		or net.gameEnds
		or not net.active_game_map()
	):
		return
	var actor = globals.player
	var forced: bool = data.force or data.epoch > int(old.get("epoch", data.epoch))
	# A passive lift is drawn from authoritative map snapshots. Replaying walking
	# physics while controls are locked would move the rider away from the lift.
	if not forced and data.state == 5 and riding_lift():
		var display_position: Vector2 = actor.position
		Checkpoint.apply(actor, checkpoint, globals.exeCharacter)
		actor.position = display_position
		actor.xspd = 0
		actor.yspd = 0
		actor.gspd = 0
		history.clear()
		transported = true
		return
	forced = forced or transported
	if history.keys().filter(func(id): return id > data.sequence).size() > 64:
		forced = true
	transported = false
	var expected: Dictionary = history.get(data.sequence, {})
	var different: bool = (
		forced
		or expected.is_empty()
		or expected.at.distance_squared_to(data.at) > 0.015625
		or expected.get("state", []) != checkpoint
	)
	if different:
		if (
			data.sequence > 0
			and (
				forced or (not expected.is_empty() and expected.at.distance_squared_to(data.at) > 1)
			)
		):
			corrections += 1
		actor.position = data.at
		Checkpoint.apply(actor, checkpoint, globals.exeCharacter)
		actor.xspd = data.velocity.x
		actor.yspd = data.velocity.y
		if forced:
			history.clear()
		else:
			replay(actor, data.sequence, data.held)
	for id in history.keys():
		if id <= data.sequence:
			history.erase(id)


func attach(actor: Node, id: int):
	if net.state != net.STATE_GAME or not states.has(id):
		return
	var data: Dictionary = states[id]
	actor.position = data.at
	if id == net.nid:
		history.clear()
		if (
			not data.force
			and data.health_revision < int(net.health.states.get(id, {}).get("revision", 0))
		):
			return
		Checkpoint.apply(
			actor, data.get("checkpoint", []), net.get_node("/root/Globals").exeCharacter
		)
		actor.xspd = data.velocity.x
		actor.yspd = data.velocity.y


func flush():
	deferred = false
	var messages := pending.values()
	pending.clear()
	for raw in messages:
		var b := StreamPeerBuffer.new()
		b.data_array = raw
		receive(b)


func riding_lift() -> bool:
	if net.lvlId != 10:
		return false
	var scene: Node = net.get_tree().current_scene
	if scene == null or scene.get("rules") == null:
		return false
	for lift in scene.rules.state.get("lifts", {}).values():
		if int(lift.get("owner", -1)) == net.nid:
			return true
	return false
