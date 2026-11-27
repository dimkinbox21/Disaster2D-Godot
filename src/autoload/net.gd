extends Node
## Port of obj_netclient + disnet transport (ENet replaces the custom
## reliable-UDP DLL; packet format and flows are 1:1 with net_*.gml).
## Server is authoritative — client only reports inputs/events.

enum PacketType {
	IDENTITY,
	SERVER_IDENTITY_RESPONSE,
	SERVER_PLAYER_JOINED,
	SERVER_PLAYER_LEFT,
	SERVER_PLAYER_FORCE_DISCONNECT,
	SERVER_WAITING_PLAYER_INFO,
	SERVER_LOBBY_READY_STATE,
	SERVER_LOBBY_EXE,
	SERVER_LOBBY_COUNTDOWN,
	SERVER_LOBBY_EXE_CHANGE,
	SERVER_LOBBY_CHARACTER_CHANGE,
	SERVER_LOBBY_CHARACTER_RESPONSE,
	SERVER_LOBBY_EXECHARACTER_RESPONSE,
	SERVER_LOBBY_GAME_START,
	SERVER_LOBBY_PLAYER,
	SERVER_LOBBY_EXE_CHANCE,
	SERVER_LOBBY_CORRECT,
	SERVER_LOBBY_CHOOSEVOTEKICK,
	SERVER_LOBBY_CHOOSEBAN,
	SERVER_LOBBY_CHOOSEKICK,
	SERVER_LOBBY_CHOOSEOP,
	SERVER_LOBBY_CHANGELOBBY,
	SERVER_CHAR_TIME_SYNC,
	SERVER_VOTE_MAPS,
	SERVER_VOTE_SET,
	SERVER_VOTE_TIME_SYNC,
	SERVER_GAME_PLAYERS_READY,
	SERVER_GAME_EXE_WINS,
	SERVER_GAME_SURVIVOR_WIN,
	SERVER_GAME_SPAWN_RING,
	SERVER_GAME_PLAYER_ESCAPED,
	SERVER_GAME_BACK_TO_LOBBY,
	SERVER_GAME_TIME_SYNC,
	SERVER_GAME_TIME_OVER,
	SERVER_GAME_PING,
	SERVER_PLAYER_DEATH_STATE,
	SERVER_GAME_DEATHTIMER_TICK,
	SERVER_GAME_DEATHTIMER_END,
	SERVER_REQUEST_INFO,
	SERVER_HEARTBEAT,
	SERVER_PONG,
	SERVER_FORCE_DAMAGE,
	SERVER_GAME_RING_READY,
	SERVER_PLAYER_BACKTRACK,
	SERVER_TPROJECTILE_STATE,
	SERVER_ETRACKER_STATE,
	SERVER_ERECTOR_BRING_SPAWN,
	SERVER_RMZSLIME_STATE,
	SERVER_RMZSLIME_RINGBONUS,
	SERVER_RMZSHARD_STATE,
	SERVER_LCEYE_STATE,
	SERVER_LCCHAIN_STATE,
	SERVER_NPCONTROLLER_STATE,
	SERVER_KAFMONITOR_STATE,
	SERVER_YCRSMOKE_STATE,
	SERVER_YCRSMOKE_READY,
	SERVER_MOVINGSPIKE_STATE,
	SERVER_RING_STATE,
	SERVER_RING_COLLECTED,
	SERVER_ACT9WALL_STATE,
	SERVER_NAPBALL_STATE,
	SERVER_NAPICE_STATE,
	SERVER_PFLIFT_STATE,
	SERVER_BRING_STATE,
	SERVER_BRING_COLLECTED,
	SERVER_VVLCOLUMN_STATE,
	SERVER_VVVASE_STATE,
	SERVER_GHZTHUNDER_STATE,
	SERVER_TCGOM_STATE,
	SERVER_EXELLERCLONE_STATE,
	SERVER_DTTAILSDOLL_STATE,
	SERVER_DTBALL_STATE,
	SERVER_DTASS_STATE,
	SERVER_HDDOOR_STATE,
	SERVER_WDLATERN_ACTIVATE,
	SERVER_FART_STATE,
	SERVER_MJLAVA_STATE,
	SERVER_MJJUDGER_STATE,
	SERVER_MJCRYSTAL_STATE,
	CLIENT_ETRACKER,
	CLIENT_ETRACKER_ACTIVATED,
	CLIENT_TPROJECTILE,
	CLIENT_TPROJECTILE_HIT,
	CLIENT_TPROJECTILE_STARTCHARGE,
	CLIENT_ERECTOR_BALLS,
	CLIENT_ERECTOR_BRING_SPAWN,
	CLIENT_EXELLER_SPAWN_CLONE,
	CLIENT_EXELLER_TELEPORT_CLONE,
	CLIENT_MERCOIN_BONUS,
	CLIENT_RMZSLIME_HIT,
	CLIENT_LCEYE_REQUEST_ACTIVATE,
	CLIENT_KAFMONITOR_ACTIVATE,
	CLIENT_RING_COLLECTED,
	CLIENT_RING_BROKE,
	CLIENT_BRING_COLLECTED,
	CLIENT_NAPICE_ACTIVATE,
	CLIENT_SPRING_USE,
	CLIENT_PFLIT_ACTIVATE,
	CLIENT_VVVASE_BREAK,
	CLIENT_RMZSHARD_COLLECT,
	CLIENT_RMZSHARD_LAND,
	CLIENT_DTASS_ACTIVATE,
	CLIENT_HDDOOR_TOGGLE,
	CLIENT_FART_PUSH,
	CLIENT_LOBBY_READY_STATE,
	CLIENT_REQUESTED_INFO,
	CLIENT_PLAYER_DATA,
	CLIENT_PLAYER_HURT,
	CLIENT_SOUND_EMIT,
	CLIENT_PING,
	CLIENT_REVIVAL_PROGRESS,
	CLIENT_PLAYER_HEAL,
	CLIENT_PLAYER_HEAL_PART,
	SERVER_REVIVAL_PROGRESS,
	SERVER_REVIVAL_STATUS,
	SERVER_REVIVAL_RINGSUB,
	SERVER_REVIVAL_REVIVED,
	CLIENT_REQUEST_CHARACTER,
	CLIENT_REQUEST_EXECHARACTER,
	CLIENT_VOTE_REQUEST,
	CLIENT_PLAYER_DEATH_STATE,
	CLIENT_PLAYER_ESCAPED,
	SERVER_PLAYER_ESCAPED,
	CLIENT_LOBBY_PLAYERS_REQUEST,
	CLIENT_CREAM_SPAWN_RINGS,
	CLIENT_SPAWN_EFFECT,
	CLIENT_CHAT_MESSAGE,
	CLIENT_LOBBY_CHOOSEVOTEKICK,
	CLIENT_LOBBY_CHOOSEBAN,
	CLIENT_LOBBY_CHOOSEKICK,
	CLIENT_LOBBY_CHOOSEOP,
	CLIENT_PLAYER_PALETTE,
	CLIENT_PET_PALETTE,
	SERVER_RESULTS,
	SERVER_RESULTS_DATA,
	CLIENT_RESULTS_REQUEST,
	CLIENT_STATS_REPORT,
	SERVER_PREIDENTITY,
	SERVER_FELLA,
	CLIENT_PLAYER_POTATER,
	CLIENT_EGG_SHIELD,
	SERVER_CHARACTER_STATUS,
	CLIENT_PLAYER_PARRY,
	CLIENT_SALLY_SHIELD,
	SERVER_MAP_DAMAGE,
	CLIENT_CHAOS_ACTION,
	CLIENT_EXETIOR_ACTION,
	SERVER_EXETIOR_WAVES,
	CLIENT_EXELLER_ATTACK,
	SERVER_CITY_STATE,
	SERVER_TOWER_STATE,
	CLIENT_TOWER_INTERACT,
	SERVER_TOWER_WARP,
	SERVER_FREEDOM_STATE,
	SERVER_PROFILE_EVENT,
	SERVER_PLAYER_HEALTH,
	SERVER_PLAYER_MOTION,
}

const STATE_PENDING := -1
const STATE_LOBBY := 0
const STATE_VOTE := 1
const STATE_CHARSELECT := 2
const STATE_GAME := 3
const STATE_RESULTS := 4

const PLAYER_EFFECT := 1 << 1
const PLAYER_HURT := 1 << 2
const PLAYER_REDRING := 1 << 3
const PLAYER_ATTACKING := 1 << 4
const PLAYER_SALLYSHIELD := 1 << 5
const PLAYER_INVIS := 1 << 6
const PLAYER_SLIME := 1 << 7

# ---------------------------------------------------------------- client state
var motion = preload("res://src/net/predicted_movement.gd").new(self)
var health = preload("res://src/net/player_health.gd").new(self)
var queued_chat: Array = []
var isConnected := false
var isReady := false
var isServerReady := false
var nid: int = -1
var frame := 0
var gameEnds := false
var results_rows: Array = []
var reconnAttempts := 0
var want_lobby: int = -1

var ip := ""
var port := 8606
var ping := 0

var state := STATE_PENDING
var sendTimeout := 60
var isInit := false

var exeId := 0
var chance := 0
var test_round := false
var lvlId := -1
var round_id := 0
var round_ticks := -1
var pings: Dictionary = {}
var players: Dictionary = {}  # nid -> Dictionary (mirrors ds_map)
var avCharacters := [false, true, true, true, true, true, true]

var _host: ENetConnection = null
var _peer: ENetPacketPeer = null
var _udp_timeout := 60 * 5


func _ready() -> void:
	process_physics_priority = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(
		func(node):
			if node is GMNode and node.gm_name in ["obj_lobby", "obj_menu_waiting"]:
				flush_chat.call_deferred()
	)


func flush_chat():
	var widgets = GMNode.all_of("obj_lobby") + GMNode.all_of("obj_menu_waiting")
	if widgets.is_empty():
		return
	for item in queued_chat:
		widgets[0].lobby_add_message(item[0], item[1])
	queued_chat.clear()


## net_join(host, selected_lobby) port
func join(host: String, selected_lobby: int = -1) -> void:
	host = host.strip_edges()
	# ENet is IPv4-only: make sure "localhost" resolves to 127.0.0.1
	if host.to_lower() == "localhost":
		host = "127.0.0.1"
	ip = host
	port = 8606 if selected_lobby == -1 else selected_lobby
	want_lobby = selected_lobby
	if isConnected:
		return
	get_tree().change_scene_to_file("res://scenes/connecting.tscn")


## net_reset port — kills connection and restarts to menu
func net_reset() -> void:
	shutdown()
	Globals.errorCode = -1
	GM.keyboard_string = ""
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func shutdown() -> void:
	# Notify the server before destroying the host; destroy alone leaves a ghost
	# until ENet times out. This path also cancels an in-flight connection.
	if _peer != null and _peer.is_active():
		_peer.peer_disconnect_now()
	if _host:
		_host.flush()
	if _host:
		_host.destroy()
	_host = null
	_peer = null
	isConnected = false
	isReady = false
	isServerReady = false
	nid = -1
	state = STATE_PENDING
	players.clear()
	health.clear()
	motion.clear()
	queued_chat.clear()
	pings.clear()
	test_round = false
	avCharacters = [false, true, true, true, true, true, true]
	exeId = 0
	chance = 0
	lvlId = -1
	round_ticks = -1
	gameEnds = false


func _exit_tree() -> void:
	shutdown()


# ---------------------------------------------------------------- transport
## called by obj_connecting (Alarm 0) — disnet_connect port
func connect_to_server() -> bool:
	# Net.join() sets ip from the menu's connect screen; only fall back to the
	# saved config when nothing was passed (a direct scene launch) — and map
	# "localhost" to the IPv4 literal, because Godot's ENet resolves it to ::1
	# while the server binds 0.0.0.0 (IPv4) and the handshake never lands.
	ip = ip.strip_edges()
	if ip == "":
		ip = GameConfig.ip.strip_edges()
	if ip == "" or ip.to_lower() == "localhost":
		ip = "127.0.0.1"
	_host = ENetConnection.new()
	var err := _host.create_host(4, 2)
	if err != OK:
		return false
	_peer = _host.connect_to_host(ip, port, 2)
	return _peer != null


func _physics_process(_delta: float) -> void:
	if _host == null:
		return
	# the ping + the in-map player state sender (obj_netclient Step_2: once per
	# 60 frames — both ride the same cadence)
	_pd_timer -= 1
	if _pd_timer % 60 == 0:
		var pb := cpacket_tcp(PacketType.CLIENT_PING)
		send_server_tcp(pb)
	if state == STATE_GAME and isReady and not gameEnds:
		motion.sending = true
		_send_player_data()
		motion.sending = false
	# net_poll() port
	motion.deferred = true
	for _event_index in 256:
		var ev := _host.service(0)
		var event: int = ev[0]
		if event == ENetConnection.EVENT_ERROR:
			break
		match event:
			ENetConnection.EVENT_NONE:
				break
			ENetConnection.EVENT_CONNECT:
				_on_connected()
				break
			ENetConnection.EVENT_DISCONNECT:
				_on_disconnected(ev[2])
				break
			ENetConnection.EVENT_RECEIVE:
				var pkt: ENetPacketPeer = ev[1]
				var data := pkt.get_packet()
				if data.size() >= 2:
					net_tcpprocess(data)
				if _host == null:
					break
				continue

	motion.flush()


func _on_connected() -> void:
	if (
		get_tree().current_scene == null
		or get_tree().current_scene.scene_file_path != "res://scenes/connecting.tscn"
	):
		net_reset()
		return
	pings.clear()
	players.clear()
	isReady = false
	state = STATE_PENDING
	_udp_timeout = 60 * 5
	sendTimeout = 60
	isInit = false
	exeId = 0
	chance = 0
	lvlId = -1
	round_ticks = -1
	avCharacters = [false, true, true, true, true, true, true]
	isConnected = true
	get_tree().change_scene_to_file("res://scenes/waiting.tscn")


func _on_disconnected(data) -> void:
	if Globals.errorCode == -1:
		var code := 0
		if data is PackedByteArray and (data as PackedByteArray).size() >= 4:
			var buf := StreamPeerBuffer.new()
			buf.data_array = data
			buf.big_endian = false
			code = buf.get_u32()
		Globals.errorCode = code
		get_tree().change_scene_to_file("res://scenes/message.tscn")


# ---------------------------------------------------------------- packets
## cpacket_tcp port — [passthrough u8, type u8] + payload (little-endian)
func cpacket_tcp(type: int, passthrough := false) -> StreamPeerBuffer:
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.put_u8(1 if passthrough else 0)
	b.put_u8(type)
	return b


func send_server_tcp(b: StreamPeerBuffer) -> void:
	if motion.replaying:
		return
	if _peer == null:
		return
	_peer.put_packet(b.data_array)


## net_identity port
func send_identity() -> void:
	var pak := cpacket_tcp(PacketType.IDENTITY, false)
	pak.put_u16(GM.BUILD_VER)
	pak.put_32(want_lobby)
	_gm_put_string(pak, Globals.nickname)
	_gm_put_string(pak, "mod-godot-" + str(randi() % 999999))
	pak.put_8(Unlockables.lobbyIcon)
	pak.put_8(Unlockables.pet)
	pak.put_u64(0)
	pak.put_u64(0)
	send_server_tcp(pak)


static func _gm_put_string(b: StreamPeerBuffer, s: String) -> void:
	# GM buffer_string: bytes + NUL terminator
	var raw := s.to_utf8_buffer()
	b.put_data(raw)
	b.put_u8(0)


static func _gm_get_string(b: StreamPeerBuffer) -> String:
	var bytes := PackedByteArray()
	while b.get_available_bytes() > 0:
		var c := b.get_u8()
		if c == 0:
			break
		bytes.append(c)
	return bytes.get_string_from_utf8()


# ------------------------------------------------------- CLIENT_PLAYER_DATA
## the bitflags live in the PacketType block above (the original net_packets
## macros: PLAYER_EFFECT = 1 << 1 …)


## GM buffer_f16 (half float) — StreamPeerBuffer has no 16-bit float
static func put_f16(b: StreamPeerBuffer, v: float) -> void:
	var ba := PackedByteArray()
	ba.resize(4)
	ba.encode_float(0, v)
	var bits := ba.decode_u32(0)
	var h := (bits >> 16) & 0x8000
	var exp8 := int((bits >> 23) & 0xFF)
	var exp := exp8 - 127 + 15
	var man := bits & 0x7FFFFF
	if exp8 == 0:
		pass  # zero/denormal → 0 (good enough for speeds)
	elif exp >= 0x1F:
		h |= 0x7C00
	elif exp <= 0:
		pass  # underflow → 0
	else:
		h |= (exp << 10) | (man >> 13)
	b.put_16(h)


static func get_f16(b: StreamPeerBuffer) -> float:
	var h := b.get_16()
	var sign := (h >> 15) & 1
	var exp := int((h >> 10) & 0x1F)
	var man := h & 0x3FF
	if exp == 0:
		return 0.0
	if exp == 0x1F:
		return INF
	var f: float = (1.0 + man / 1024.0) * pow(2.0, exp - 15)
	return -f if sign == 1 else f


var _pd_timer := 30  # the original's sendTimeout = 60 * 0.5


## CLIENT_RING_COLLECTED — the pickup report (the server owns the ring counter)
func report_ring_collected(iid: int, uid: int) -> void:
	var b := cpacket_tcp(PacketType.CLIENT_RING_COLLECTED)
	b.put_u8(iid)
	b.put_u16(uid)
	send_server_tcp(b)


## CLIENT_PLAYER_HURT — the victim reports a hit; the server validates
## (hurttime/dead) and applies the authoritative damage
func report_player_hurt(attacker_pid: int, x: int, y: int, stun: int) -> void:
	var b := cpacket_tcp(PacketType.CLIENT_PLAYER_HURT)
	b.put_u16(attacker_pid)
	b.put_u16(x)
	b.put_u16(y)
	b.put_u16(stun)
	send_server_tcp(b)


func report_parry(other_pid: int) -> void:
	if state != STATE_GAME:
		return
	var b := cpacket_tcp(PacketType.CLIENT_PLAYER_PARRY)
	b.put_u16(other_pid)
	send_server_tcp(b)


## Hide and Seek Act 2 spring echo; the server replaces the supplied identity.
func report_spring_use(at: Vector2) -> void:
	var packet := cpacket_tcp(PacketType.CLIENT_SPRING_USE, true)
	packet.put_u16(nid)
	packet.put_16(int(at.x))
	packet.put_16(int(at.y))
	send_server_tcp(packet)


## CLIENT_RING_BROKE — the demon shot / exe attack broke a ring; iid/uid let
## the server also broadcast the destroy (the particles alone leave the other
## clients' ring copies on screen)
func report_ring_broke(iid: int, uid: int, x: int, y: int, xspd: float) -> void:
	var b := cpacket_tcp(PacketType.CLIENT_RING_BROKE)
	b.put_u8(iid)
	b.put_u16(uid)
	b.put_u16(x)
	b.put_u16(y)
	put_f16(b, xspd)
	send_server_tcp(b)


## obj_netclient Step_2 — the local player's state packet, every physics frame
# Character-specific events keep their original packet shapes.
const CHARACTER_SOUNDS := {
	1: "snd_dash",
	2: "snd_dead",
	4: "snd_jump",
	6: "snd_ringlose",
	9: "snd_hurt",
	11: "snd_buble",
	18: "snd_egg_djump",
	19: "snd_egg_shield",
	20: "snd_electroshock",
	21: "snd_creamdash",
	22: "snd_sally_shield",
	23: "snd_sally_slide",
	24: "snd_sally_shieldbreak",
	26: "snd_creamring",
	29: "snd_egg_tracker",
	30: "snd_egg_tracker_activate",
	32: "snd_ringabsorb",
	37: "snd_snap",
	40: "snd_chaos_attack",
	41: "snd_chaos_dash",
	42: "snd_chaos_land",
	43: "snd_chaos_sturn",
	44: "snd_exetior_stomp",
	45: "snd_exetior_stompland",
	46: "snd_blackring",
	47: "snd_exetior_laugh",
	48: "snd_exetior_taunt1",
	49: "snd_exetior_taunt2",
	50: "snd_exetior_taunt3",
	51: "snd_exetior_ring1",
	52: "snd_exetior_ring2",
	53: "snd_exetior_ring3",
	54: "snd_exetior_ring4",
	55: "snd_exeller_clone",
	56: "snd_exe_appear",
	57: "snd_exeller_cloneline",
	58: "snd_exeller_laugh",
	59: "snd_exeller_taunt1",
	60: "snd_exeller_taunt2",
	61: "snd_exeller_taunt3",
	62: "snd_lavahit",
	63: "snd_boohoo"
}


func report_sally_shield(activate: bool) -> void:
	if state != STATE_GAME:
		return
	var b := cpacket_tcp(PacketType.CLIENT_SALLY_SHIELD)
	b.put_u8(int(activate))
	send_server_tcp(b)


func character_sound(sound: String, at: Vector2) -> void:
	GameAudio.play_sound(sound)
	if state != STATE_GAME:
		return
	var sound_id: int = CHARACTER_SOUNDS.find_key(sound)
	var b := cpacket_tcp(PacketType.CLIENT_SOUND_EMIT)
	b.put_u16(nid)
	b.put_u8(sound_id)
	b.put_u8(0)
	send_server_tcp(b)


func report_egg_shield() -> void:
	if state == STATE_GAME:
		send_server_tcp(cpacket_tcp(PacketType.CLIENT_EGG_SHIELD))


func report_egg_tracker(at: Vector2) -> void:
	if state == STATE_GAME:
		_send_player_data(8)  # crouch and its position must precede the placement event
		var b := cpacket_tcp(PacketType.CLIENT_ETRACKER)
		b.put_16(int(at.x))
		b.put_16(int(at.y))
		send_server_tcp(b)
	else:
		spawn_tracker(0, nid, at, Globals.player.revivalTimes >= 2)


func spawn_tracker(id: int, owner_id: int, at: Vector2, demon: bool) -> void:
	for existing in GMNode.all_of("obj_eggtrack"):
		if existing.nid == id:
			return
	var trap := GMNode.new()
	trap.set_script(load("res://src/game/obj_eggtrack.gd"))
	trap.nid = id
	trap.owner_id = owner_id
	trap.demon = demon
	trap.position = at
	get_tree().current_scene.add_child(trap)


func report_cream_rings(at: Vector2, demon: bool) -> void:
	if state == STATE_GAME:
		_send_player_data(15)
		var b := cpacket_tcp(PacketType.CLIENT_CREAM_SPAWN_RINGS)
		b.put_16(int(at.x))
		b.put_16(int(at.y))
		b.put_u8(int(demon))
		send_server_tcp(b)
	else:
		var offsets := (
			[Vector2(25, 0), Vector2(-27, 0)]
			if demon
			else [Vector2(26, 0), Vector2(0, -26), Vector2(-27, 0)]
		)
		for offset in offsets:
			spawn_cream_ring(255, 0, at + offset, demon)


func spawn_cream_ring(iid: int, uid: int, at: Vector2, red: bool) -> void:
	var ring := GMNode.new()
	ring.set_script(load("res://src/game/obj_redring.gd" if red else "res://src/game/obj_ring.gd"))
	ring.gm_name = "obj_redring" if red else "obj_ring"
	ring.position = at
	ring.iid = iid
	ring.nid = uid
	get_tree().current_scene.add_child(ring)


var _palette_sent = 0
var profile_interaction: Dictionary = {}


func draw_profile_interaction(node: GMNode, id: int):
	if not node.has_meta("revival_indicator"):
		var indicator = load("res://src/game/effects/revival_indicator.gd").new()
		indicator.actor = node
		indicator.actor_id = id
		node.set_meta("revival_indicator", true)
		node.get_parent().add_child(indicator)


func send_palette() -> void:
	if state != STATE_GAME or not is_instance_valid(Globals.player):
		return
	var pal = Unlockables.actor_palette(
		Globals.character, Globals.exeCharacter, Globals.player.revivalTimes
	)
	var signature = hash(
		[nid, lvlId, Globals.character, Globals.exeCharacter, Globals.player.revivalTimes >= 2, pal]
	)
	if signature == _palette_sent:
		return
	_palette_sent = signature
	Globals.palleteName = pal.get("name", "default")
	Globals.palleteFrom = pal["from"]
	Globals.palleteTo = pal["to"]
	for side in ["from", "to"]:
		var b = cpacket_tcp(PacketType.CLIENT_PLAYER_PALETTE, true)
		b.put_u8(int(side == "from"))
		b.put_u16(nid)
		_gm_put_string(b, Globals.palleteName)
		var values: Array = pal[side]
		b.put_u8(values.size())
		for value in values:
			b.put_u8(clampi(roundi(float(value) * 255), 0, 255))
		send_server_tcp(b)


func _send_player_data(_state_override := -1) -> void:
	if not motion.sending or motion.replaying:
		return
	var p: GMNode = Globals.player
	if p == null or not active_game_map():
		return
	send_palette()
	var b := cpacket_tcp(PacketType.CLIENT_PLAYER_DATA)
	b.put_u32(round_id)
	b.put_u32(motion.record(p))
	b.put_u16(motion.frame_inputs)
	send_server_tcp(b)


# ---------------------------------------------------------------- dispatch
## net_tcpprocess port (stage-2 packet set; game-sync lands in stage 3)
func net_tcpprocess(data: PackedByteArray) -> void:
	var rb := StreamPeerBuffer.new()
	rb.data_array = data
	rb.big_endian = false
	rb.seek(0)
	if rb.get_available_bytes() < 2:
		return
	var _passthrough := rb.get_u8() != 0
	var nps := rb.get_u8()
	match nps:
		PacketType.SERVER_PLAYER_MOTION:
			if not _passthrough:
				motion.receive(rb)
		PacketType.SERVER_PLAYER_HEALTH:
			if not _passthrough:
				health.receive(rb)
		PacketType.CLIENT_CHAT_MESSAGE:
			if _passthrough or rb.get_available_bytes() < 3:
				return
			var sender_id = rb.get_u16()
			var text = _gm_get_string(rb)
			var sender = "(server)"
			if sender_id != 0:
				if players.has(sender_id):
					sender = str(players[sender_id].nickname)
				else:
					var found = false
					for waiting in GMNode.all_of("obj_menu_waiting"):
						if waiting.players.has(sender_id):
							sender = waiting.players[sender_id].nickname
							found = true
					if not found:
						return
			queued_chat.append([sender, text])
			if queued_chat.size() > 64:
				queued_chat.pop_front()
			flush_chat()

		PacketType.SERVER_LOBBY_CHOOSEVOTEKICK, PacketType.SERVER_LOBBY_CHOOSEKICK, PacketType.SERVER_LOBBY_CHOOSEBAN, PacketType.SERVER_LOBBY_CHOOSEOP:
			if _passthrough or get_tree().current_scene == null:
				return
			for old in GMNode.all_of("chat_target_selector"):
				old.queue_free()
			var chooser = load("res://src/net/chat_target_selector.gd").new()
			chooser.packet_type = {
				PacketType.SERVER_LOBBY_CHOOSEVOTEKICK: PacketType.CLIENT_LOBBY_CHOOSEVOTEKICK,
				PacketType.SERVER_LOBBY_CHOOSEKICK: PacketType.CLIENT_LOBBY_CHOOSEKICK,
				PacketType.SERVER_LOBBY_CHOOSEBAN: PacketType.CLIENT_LOBBY_CHOOSEBAN,
				PacketType.SERVER_LOBBY_CHOOSEOP: PacketType.CLIENT_LOBBY_CHOOSEOP
			}[nps]
			get_tree().current_scene.add_child(chooser)
		PacketType.SERVER_LOBBY_CHANGELOBBY:
			if _passthrough or rb.get_available_bytes() < 4:
				return
			var next_port = rb.get_32()
			var address = ip
			if next_port < 1 or next_port > 65535:
				return
			shutdown()
			join(address, next_port)

		PacketType.SERVER_RESULTS:
			lvlId = rb.get_u8()
			isReady = true
			gameEnds = true
			state = STATE_RESULTS
			results_rows.clear()
			Globals.player = null
			GameAudio.stop_all()
			get_tree().change_scene_to_file("res://scenes/results.tscn")
		PacketType.SERVER_RESULTS_DATA:
			if state != STATE_RESULTS or _passthrough:
				return
			var row := {
				"name": _gm_get_string(rb),
				"character": rb.get_8(),
				"result": rb.get_u8(),
				"time": rb.get_u16(),
				"quit": rb.get_u8(),
				"type": rb.get_u8()
			}
			for key in ["rings", "kills", "damage", "taken", "stun_time", "stuns", "healed"]:
				row[key] = rb.get_u16()
			row.survival = int(rb.get_double() / 60.0)
			row.danger = int(rb.get_double() / 60.0)
			results_rows.append(row)
		PacketType.SERVER_PLAYER_JOINED, PacketType.SERVER_LOBBY_PLAYER, PacketType.SERVER_LOBBY_CORRECT:
			if state in [STATE_LOBBY, STATE_VOTE, STATE_CHARSELECT]:
				net_state_lobby(rb, nps, _passthrough)
		PacketType.CLIENT_RING_BROKE:
			# a relayed ring break — spawn the 4 particles (the original's
			# handler builds them from x/y/xspd alone)
			var bx := rb.get_16()
			var by := rb.get_16()
			var bxs := get_f16(rb)
			GameAudio.play_sound_at("snd_exe_ringshutter", Vector2(bx, by))
			spawn_ring_parts(Vector2(bx, by), bxs)
		PacketType.CLIENT_PLAYER_DATA:
			# the server relays the other clients' packets with their pid
			# (net_udpprocess port)
			if state != STATE_GAME or not active_game_map():
				return
			var pid := rb.get_u16()
			for pup in GMNode.all_of("obj_player_puppet"):
				if pup.master_id == pid:
					pup.net_update(rb)
					pup.apply_anim()
					break
		PacketType.SERVER_PLAYER_LEFT:
			if _passthrough:
				return
			var _id := rb.get_u16()
			for puppet in GMNode.all_of("obj_player_puppet"):
				if puppet.master_id == _id:
					puppet.set_physics_process(false)
					puppet.queue_free()
			# free character
			if state == STATE_PENDING and is_in_waiting():
				for waiting in GMNode.all_of("obj_menu_waiting"):
					if waiting.players.erase(_id):
						GameAudio.play_sound("snd_hurt")
					waiting.queue_redraw()
				players.erase(_id)
			if not players.has(_id):
				return
			if state == STATE_CHARSELECT and players[_id].get("character", -1) != -1:
				avCharacters[players[_id].character] = true
			if state == STATE_LOBBY or state == STATE_VOTE or state == STATE_CHARSELECT:
				for lb in GMNode.all_of("obj_lobby"):
					lb.lobby_player_left(_id)
			players.erase(_id)
		PacketType.SERVER_PLAYER_FORCE_DISCONNECT:
			if _passthrough:
				return
			if state == 9:  # unreachable in practice; mirrors original
				isConnected = false
				reconnAttempts += 1
				if reconnAttempts >= 5 or want_lobby != -1:
					want_lobby = -1
					reconnAttempts = 0
					Globals.errorCode = 9
					get_tree().change_scene_to_file("res://scenes/message.tscn")
					return
				join(ip)
				return
			var msg := _gm_get_string(rb)
			Globals.errorCode = 1
			Globals.errorMessage = msg
			get_tree().change_scene_to_file("res://scenes/message.tscn")
		PacketType.SERVER_LOBBY_COUNTDOWN:
			if _passthrough:
				return
			if state != STATE_LOBBY and state != STATE_CHARSELECT:
				return
			var count := rb.get_u8() != 0
			var val := rb.get_u8()
			for lb in GMNode.all_of("obj_lobby"):
				lb.countScale = 1.5
				lb.isCounting = count
				lb.countdown = val
			GameAudio.play_sound("snd_clock")
		PacketType.SERVER_LOBBY_EXE_CHANCE:
			if _passthrough:
				return
			chance = rb.get_u8()
		PacketType.SERVER_GAME_BACK_TO_LOBBY:
			if _passthrough:
				return
			test_round = false
			GameAudio.stop_all()
			Globals.ringId = 0
			Globals.character = -1
			Globals.exeCharacter = -1
			Globals.playerControls = true
			players.clear()
			exeId = -1
			avCharacters = [false, true, true, true, true, true, true]
			gameEnds = false
			state = STATE_LOBBY
			get_tree().change_scene_to_file("res://scenes/lobby.tscn")
			var b2 := cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false)
			send_server_tcp(b2)
			return
		_:
			match state:
				STATE_LOBBY:
					net_state_lobby(rb, nps, _passthrough)
				STATE_VOTE:
					net_state_vote(rb, nps, _passthrough)
				STATE_CHARSELECT:
					net_state_charselect(rb, nps, _passthrough)
				STATE_PENDING:
					net_state_pending(rb, nps, _passthrough)
				STATE_GAME:
					net_state_game(rb, nps, _passthrough)


func is_in_waiting() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path == "res://scenes/waiting.tscn"


# ---------------------------------------------------------------- net_state_pending
func net_state_pending(rb: StreamPeerBuffer, nps: int, passthrough: bool) -> void:
	match nps:
		PacketType.SERVER_IDENTITY_RESPONSE:
			if passthrough:
				return
			var wait := rb.get_u8() != 0
			nid = rb.get_u16()
			if not wait:
				GameAudio.play_music("mus_waiting")
				for w in GMNode.all_of("obj_menu_waiting"):
					w.sprite_name = "spr_menu_waiting"
					w.waiting_confirmed = true
					w.queue_redraw()
				return
			isReady = true
			state = STATE_LOBBY
			get_tree().change_scene_to_file("res://scenes/lobby.tscn")
			var b2 := cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false)
			send_server_tcp(b2)
		PacketType.SERVER_GAME_TIME_SYNC:
			if passthrough or rb.get_available_bytes() < 2:
				return
			var ticks = rb.get_u16()
			round_ticks = ticks
			for waiting in GMNode.all_of("obj_menu_waiting"):
				waiting.draw_clock = true
				waiting.time_minutes = maxi(0, ceili((ticks + 1) / 3600.0) - 1)
				waiting.time_seconds = ceili(ticks / 60.0) % 60
				waiting.timeFrame += 1
				waiting.queue_redraw()
				if waiting.time_minutes == 0 and waiting.time_seconds <= 10:
					GameAudio.play_sound("snd_clock")
		PacketType.SERVER_WAITING_PLAYER_INFO:
			if passthrough:
				return
			var ingame := rb.get_u8() != 0
			var _id := rb.get_u16()
			var _nick := _gm_get_string(rb)
			if ingame:
				var _exe := rb.get_u8() != 0
				var _char: int = rb.get_8()
				for w in GMNode.all_of("obj_menu_waiting"):
					w.players[_id] = {
						"nid": _id,
						"scale": 0.0,
						"icon": 19954,
						"nickname": _nick,
						"exe": _exe,
						"char": _char
					}
			else:
				var _sid: int = rb.get_8()
				for w in GMNode.all_of("obj_menu_waiting"):
					w.players[_id] = {
						"nid": _id,
						"scale": 0.0,
						"icon": _sid,
						"nickname": _nick,
						"exe": -1,
						"char": -1
					}
			GameAudio.play_sound("snd_ring")
		PacketType.CLIENT_CHAT_MESSAGE:
			if passthrough:
				return
			var _id := rb.get_u16()
			var _msg := _gm_get_string(rb)
			for w in GMNode.all_of("obj_menu_waiting"):
				if _id == 0:
					w.lobby_add_message("(server)", _msg)
					return
				if w.players.has(_id):
					w.lobby_add_message(w.players[_id].nickname, _msg)
		PacketType.SERVER_LOBBY_CHOOSEKICK, PacketType.SERVER_LOBBY_CHOOSEBAN, PacketType.SERVER_LOBBY_CHOOSEOP:
			# op/kick popups — stage 3 (server doesn't send them in stage 2)
			pass
		PacketType.SERVER_PREIDENTITY:
			send_identity()


# ---------------------------------------------------------------- net_state_game
## the in-round packets — the server owns all of this state (stage: netplay sync)
func net_state_game(rb: StreamPeerBuffer, nps: int, passthrough: bool) -> void:
	if (
		not active_game_map()
		and (
			nps
			not in [
				PacketType.SERVER_GAME_TIME_SYNC,
				PacketType.SERVER_GAME_EXE_WINS,
				PacketType.SERVER_GAME_SURVIVOR_WIN,
				PacketType.SERVER_GAME_TIME_OVER,
				PacketType.SERVER_GAME_PING
			]
		)
	):
		return
	match nps:
		PacketType.SERVER_FART_STATE:
			if passthrough or lvlId != 20 or rb.get_available_bytes() < 4:
				return
			var scene = get_tree().current_scene
			if scene != null and scene.get("rules") != null:
				scene.rules.dummy_position(Vector2(rb.get_16(), rb.get_16()))
				if rb.get_available_bytes() >= 9:
					scene.rules.ball = rb.get_float()
					scene.rules.ball_dir = rb.get_float()
					var spike_frame = rb.get_u8()
					for spike in GMNode.all_of("obj_movingspike"):
						spike.change(spike_frame)
		PacketType.CLIENT_PLAYER_POTATER:
			if lvlId != 20 or rb.get_available_bytes() < 3:
				return
			var action = rb.get_u8()
			var pid = rb.get_u16()
			var seconds = rb.get_u8() if action == 0 and rb.get_available_bytes() > 0 else 0
			var scene = get_tree().current_scene
			if scene != null and scene.get("rules") != null:
				scene.rules.potato_packet(action, pid, seconds)
		PacketType.SERVER_MOVINGSPIKE_STATE:
			if passthrough or rb.get_available_bytes() < 1:
				return
			var frame = rb.get_u8()
			for spike in GMNode.all_of("obj_movingspike"):
				spike.change(frame)
			for emitter in GMNode.all_of("obj_soundemitter"):
				if frame in [1, 3]:
					emitter.play_at("snd_movingspike")

		PacketType.CLIENT_PLAYER_HEAL_PART:
			if rb.get_available_bytes() < 4 or get_tree().current_scene == null:
				return
			var particle = load("res://src/game/effects/heal_particle.gd").new()
			particle.position = Vector2(rb.get_16(), rb.get_16())
			get_tree().current_scene.add_child(particle)
		PacketType.SERVER_PROFILE_EVENT:
			if passthrough:
				return
			var payload = JSON.parse_string(
				(rb.get_data(rb.get_available_bytes())[1] as PackedByteArray).get_string_from_utf8()
			)
			if payload is Dictionary:
				if payload.get("kind") == "interaction":
					var helper := int(payload.get("helper", -1))
					if float(payload.get("progress", 0)) > 0:
						profile_interaction[helper] = payload
					else:
						profile_interaction.erase(helper)
				else:
					Achievements.rules.event(
						str(payload.get("kind", "")),
						int(payload.get("value", 1)),
						int(payload.get("other", -1))
					)
		PacketType.CLIENT_PLAYER_PALETTE:
			if rb.get_available_bytes() < 5:
				return
			var side = "from" if rb.get_u8() != 0 else "to"
			var pid = rb.get_u16()
			var label = _gm_get_string(rb)
			if not players.has(pid) or rb.get_available_bytes() < 1:
				return
			var count = rb.get_u8()
			if count % 4 != 0 or rb.get_available_bytes() != count:
				return
			var pal: Dictionary = players[pid].get("palette", {})
			pal["name"] = label
			pal[side] = []
			for i in count:
				pal[side].append(rb.get_u8() / 255.0)
			players[pid].palette = pal
			for puppet in GMNode.all_of("obj_player_puppet"):
				if puppet.master_id == pid:
					puppet.queue_redraw()
		PacketType.SERVER_RMZSLIME_RINGBONUS:
			if (
				passthrough
				or lvlId != 1
				or rb.get_available_bytes() < 2
				or not is_instance_valid(Globals.player)
			):
				return
			var red := rb.get_u8() != 0
			var heal := rb.get_u8() != 0
			if not red and not heal:
				GameAudio.play_sound("snd_ring")
				Globals.player.quick_effect(
					Globals.player.position.x,
					Globals.player.position.y - 10,
					"spr_heal_part" if heal else "spr_ring_sparkle"
				)
		PacketType.SERVER_FREEDOM_STATE:
			if passthrough or lvlId not in [10, 11, 18, 19]:
				return
			var raw := rb.get_data(rb.get_available_bytes())[1] as PackedByteArray
			var data = JSON.parse_string(raw.get_string_from_utf8())
			var scene := get_tree().current_scene
			if (
				data is Dictionary
				and scene != null
				and scene.get("rules") != null
				and scene.rules.has_method("receive")
			):
				scene.rules.receive(data)
		PacketType.SERVER_TOWER_STATE:
			if passthrough or lvlId not in [13, 16, 17]:
				return
			var raw := rb.get_data(rb.get_available_bytes())[1] as PackedByteArray
			var data = JSON.parse_string(raw.get_string_from_utf8())
			var scene := get_tree().current_scene
			if (
				data is Dictionary
				and scene != null
				and scene.get("rules") != null
				and scene.rules.has_method("receive")
			):
				scene.rules.receive(data)
		PacketType.SERVER_TOWER_WARP:
			if passthrough or lvlId != 13 or rb.get_available_bytes() < 5:
				return
			var at := Vector2(rb.get_16(), rb.get_16())
			var reset := rb.get_u8() != 0
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null and scene.rules.has_method("warp"):
				scene.rules.warp(at, reset)
		PacketType.SERVER_CITY_STATE:
			if passthrough or lvlId not in [1, 4, 5]:
				return
			var raw := rb.get_data(rb.get_available_bytes())[1] as PackedByteArray
			var data = JSON.parse_string(raw.get_string_from_utf8())
			var scene := get_tree().current_scene
			if data is Dictionary and scene != null and scene.get("rules") != null:
				scene.rules.receive(data)
		PacketType.SERVER_ACT9WALL_STATE:
			if passthrough or rb.get_available_bytes() < 5:
				return
			var id := rb.get_u8()
			var xx := rb.get_u16()
			var yy := rb.get_u16()
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null and lvlId == 8:
				scene.rules.wall_packet(id, xx, yy)
		PacketType.SERVER_KAFMONITOR_STATE:
			if passthrough or lvlId != 7 or rb.get_available_bytes() < 2:
				return
			var action := rb.get_u8()
			var id := rb.get_u8()
			var owner := rb.get_u16() if action == 2 and rb.get_available_bytes() >= 2 else -1
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null:
				scene.rules.monitor(action, id, owner)
		PacketType.SERVER_NAPICE_STATE:
			if passthrough or lvlId != 9 or rb.get_available_bytes() < 2:
				return
			var action := rb.get_u8()
			var id := rb.get_u8()
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null:
				scene.rules.ice(action, id)
		PacketType.SERVER_GHZTHUNDER_STATE:
			if passthrough or lvlId != 12 or rb.get_available_bytes() < 1:
				return
			var action := rb.get_u8()
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null:
				scene.rules.thunder(action)
		PacketType.SERVER_NAPBALL_STATE:
			if passthrough or lvlId != 9 or rb.get_available_bytes() < 2:
				return
			var action := rb.get_u8()
			var id := rb.get_u8()
			var scene := get_tree().current_scene
			if scene == null or scene.get("rules") == null:
				return
			if action == 0 and rb.get_available_bytes() >= 1:
				scene.rules.snowball(0, id, rb.get_8())
			elif action == 2:
				scene.rules.snowball(2, id)
			elif action == 1 and rb.get_available_bytes() >= 10:
				var waypoint := rb.get_u8()
				var frame := rb.get_u8()
				var progress := rb.get_double()
				scene.rules.snowball(1, id, 1, waypoint, frame, progress)
		PacketType.SERVER_NPCONTROLLER_STATE:
			if passthrough or rb.get_available_bytes() < 3:
				return
			var warn := rb.get_u8() != 0
			var current := rb.get_u8()
			var previous := rb.get_u8()
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null and lvlId == 6:
				scene.rules.np_packet(warn, current, previous)
		PacketType.SERVER_TCGOM_STATE:
			if passthrough or rb.get_available_bytes() < 2:
				return
			var group := rb.get_u8()
			var active := rb.get_u8() != 0
			var scene := get_tree().current_scene
			if scene != null and scene.get("rules") != null and lvlId == 15:
				scene.rules.acid_packet(group, active)
		PacketType.SERVER_EXELLERCLONE_STATE:
			if passthrough or gameEnds or rb.get_available_bytes() < 3:
				return
			var mode := rb.get_u8()
			var id := rb.get_u16()
			if mode == 0 and rb.get_available_bytes() >= 8:
				var owner := rb.get_u16()
				var at := Vector2(rb.get_16(), rb.get_16())
				var facing := rb.get_8()
				spawn_exeller_clone(id, owner, at, facing, rb.get_u8())
			elif mode == 1 and rb.get_available_bytes() >= 7:
				var owner := rb.get_u16()
				var at := Vector2(rb.get_16(), rb.get_16())
				consume_exeller_clone(id, owner, at, rb.get_u8())
			elif mode == 2 and rb.get_available_bytes() >= 4:
				var at := Vector2(rb.get_16(), rb.get_16())
				for clone in GMNode.all_of("obj_exeller_clone"):
					if clone.nid == id:
						clone.position = at
		PacketType.SERVER_ERECTOR_BRING_SPAWN:
			if passthrough or gameEnds or rb.get_available_bytes() < 6:
				return
			var ring_id := rb.get_u16()
			var at := Vector2(rb.get_16(), rb.get_16())
			spawn_black_ring(ring_id, at, rb.get_available_bytes() > 0 and rb.get_u8() != 0)
		PacketType.SERVER_BRING_STATE:
			if passthrough or rb.get_available_bytes() < 3:
				return
			var mode := rb.get_u8()
			var ring_id := rb.get_u16()
			if mode == 1:
				consume_black_ring(ring_id, false)
		PacketType.SERVER_EXETIOR_WAVES:
			if passthrough or gameEnds or rb.get_available_bytes() < 7:
				return
			rb.get_u16()
			var at := Vector2(rb.get_16(), rb.get_16())
			spawn_exetior_waves(at, rb.get_u8())
		PacketType.SERVER_PLAYER_BACKTRACK:
			if passthrough or rb.get_available_bytes() < 4 or not is_instance_valid(Globals.player):
				return
			var at := Vector2(rb.get_16(), rb.get_16())
			var p: GMNode = Globals.player
			p.position = at
			p.xspd = 0
			p.yspd = 0
			p.gspd = 0
			p.isGrounded = false
			p.isHurt = false
			p.isSliding = false
		PacketType.SERVER_MAP_DAMAGE:
			if passthrough or rb.get_available_bytes() < 7 or not is_instance_valid(Globals.player):
				return
			var mode := rb.get_u8()
			var hp := rb.get_8()
			var rings := rb.get_16()
			var invul := rb.get_u16()
			var dead := rb.get_u8() != 0
			var p: GMNode = Globals.player
			# Map packets carry effect hints; the canonical health stream owns values.
			health.hints[nid] = {"mode": mode}
			if mode in [4, 6] and rb.get_available_bytes() > 0:
				health.hints[nid].push = rb.get_8() * (3 if mode == 4 else 4)
			if mode == 5:
				GameAudio.play_sound("snd_ringabsorb")

		PacketType.CLIENT_SOUND_EMIT:
			if not passthrough or rb.get_available_bytes() < 4:
				return
			var pid := rb.get_u16()
			var sid := rb.get_u8()
			rb.get_u8()
			if pid == nid or not CHARACTER_SOUNDS.has(sid):
				return
			for puppet in GMNode.all_of("obj_player_puppet"):
				if puppet.master_id == pid:
					GameAudio.play_sound_at(CHARACTER_SOUNDS[sid], puppet.position)
					break
		PacketType.SERVER_CHARACTER_STATUS:
			if passthrough or gameEnds or not is_instance_valid(Globals.player):
				return
			var kind := rb.get_u8()
			var ticks := rb.get_u16()
			if kind == 0:
				Globals.player.apply_slow(ticks, 0.7 if Globals.character == 0 else 0.6)
			elif kind == 1:
				Globals.player.shockedTimer = ticks
				Globals.player.hurttime = ticks + 120
				Globals.player.xspd = 0
				Globals.player.yspd = -2
				Globals.player.isGrounded = false
			elif kind == 2:
				Globals.player.isAttacking = false
				Globals.player.shieldRechrage = ticks
			elif kind == 3:
				if Globals.player.shockedTimer <= 0:
					GameAudio.play_sound("snd_exe_stun")
					if Globals.character == 0:
						GameAudio.play_exe_stun(Globals.exeCharacter)
				Globals.player.shockedTimer = ticks
				Globals.player.hurttime = ticks + 120
				Globals.player.xspd = rb.get_8()
				Globals.player.yspd = -2
				Globals.player.isGrounded = false
			elif kind == 4:
				Globals.player.apply_parry(rb.get_8(), ticks)
			elif kind == 5:
				Globals.player.shieldTimer = ticks
				Globals.player.shieldRechrage = rb.get_u16()
			elif kind == 10:
				if Globals.player.redRingTimer <= 0:
					get_tree().current_scene.rules.gas_frenzy(Globals.player, ticks)
			elif kind == 9:
				var attack_ticks := rb.get_u16()
				var clone_ticks := rb.get_u16()
				var ids: Array = []
				for i in 2:
					var id := rb.get_u16()
					ids.append(-1 if id == 65535 else id)
				var action := rb.get_u8()
				if (
					Globals.exeCharacter == Globals.EXE_EXELLER
					and Globals.player.hunter != null
					and ticks == 0
				):
					Globals.player.hunter.reconcile(attack_ticks, clone_ticks, ids, action)
			elif kind == 8:
				var attack_ticks := rb.get_u16()
				var ring_ticks := rb.get_u16()
				if (
					Globals.exeCharacter == Globals.EXE_EXETIOR
					and Globals.player.hunter != null
					and ticks == 0
				):
					Globals.player.hunter.reconcile(attack_ticks, ring_ticks)
			elif kind == 7:
				var attack_ticks := rb.get_u16()
				var slime_ticks := rb.get_16()
				if Globals.player.hunter != null and ticks == 0:
					Globals.player.hunter.reconcile(attack_ticks, slime_ticks)
			elif kind == 6:
				var player: GMNode = Globals.player
				if player.survivor != null:
					player.survivor.absorb_damage()
				player.shieldTimer = 0
				player.hurttime = ticks
				var push_x := rb.get_8()
				var push_y := rb.get_8()
				if push_x != 0 or push_y != 0:
					player.isGrounded = false
					player.isHurt = true
					player.isSliding = false
					player.xspd = push_x
					player.yspd = push_y
		PacketType.SERVER_ETRACKER_STATE:
			if passthrough or gameEnds:
				return
			var mode := rb.get_u8()
			var id := rb.get_u16()
			if mode == 0:
				var at := Vector2(rb.get_16(), rb.get_16())
				var owner := rb.get_u16()
				spawn_tracker(id, owner, at, rb.get_u8() != 0)
			else:
				var target := rb.get_u16()
				var demon := false
				var at := Vector2.ZERO
				for trap in GMNode.all_of("obj_eggtrack"):
					if trap.nid != id:
						continue
					demon = trap.current_demon()
					at = trap.position
					trap.destroy_tracker()
					break
				GameAudio.play_sound_at("snd_egg_tracker_activate", at)
				var p: GMNode = Globals.player
				if (
					is_instance_valid(p)
					and target != nid
					and (Globals.character == 0 or p.revivalTimes >= 2) == demon
				):
					var indicators := GMNode.all_of("obj_tracker_indicator")
					var indicator: Node2D = indicators[0] if not indicators.is_empty() else null
					if indicator == null:
						indicator = Node2D.new()
						indicator.set_script(load("res://src/game/obj_tracker_indicator.gd"))
						get_tree().current_scene.add_child(indicator)
					indicator.target_id = target
					indicator.remaining = 180
		PacketType.CLIENT_SPRING_USE:
			if lvlId != 0 or gameEnds or rb.get_available_bytes() < 6:
				return
			rb.get_u16()  # sender
			var at := Vector2(rb.get_16(), rb.get_16())
			GameAudio.play_sound_at("snd_spring", at)
			if Globals.character != Globals.CHARACTER_EXE:
				return
			for indicator in GMNode.all_of("obj_exe_sprindicator"):
				indicator.spring_event(at)
			for camera in GMNode.all_of("obj_camera"):
				if camera.position.distance_to(at) > 600:
					GameAudio.play_sound_at("snd_spring_reverb", at, 500, false)
				break

		PacketType.CLIENT_SPAWN_EFFECT:
			if gameEnds or rb.get_available_bytes() < 13:
				return
			var at := Vector2(rb.get_16(), rb.get_16())
			var fade := rb.get_u8() != 0
			var direction := rb.get_8()
			var effect_id := rb.get_u8()
			var effect_motion := Vector2(rb.get_8(), rb.get_8())
			var speed := rb.get_float()
			var sprites := {
				2: "spr_blood1",
				3: "spr_blood2",
				4: "spr_blood3",
				6: "spr_shieldbreak",
				7: "spr_dust",
				9: "spr_roseheart",
				10: "spr_eroseheart",
				12: "spr_shieldbreak2"
			}
			if not sprites.has(effect_id) or get_tree().current_scene == null:
				return
			var effect = load("res://src/game/obj_quickfx.gd").new()
			effect.position = at
			effect.sprite_name = sprites[effect_id]
			effect.fade = fade
			effect.image_xscale = direction
			effect.image_speed = speed
			effect.motion = effect_motion
			get_tree().current_scene.add_child(effect)
			effect.z_index = 200

		PacketType.CLIENT_PLAYER_HURT:
			# The server relay carries victim, attacker, hit position and stun
			# duration. Reproduce impact/voice for the other clients as well.
			if not passthrough or gameEnds or rb.get_available_bytes() < 10:
				return
			var victim := rb.get_u16()
			var attacker := rb.get_u16()  # attacker
			rb.get_u16()  # x
			rb.get_u16()  # y
			var stun := rb.get_u16()
			if victim == nid or stun <= 0:
				return
			for puppet in GMNode.all_of("obj_player_puppet"):
				if puppet.master_id != victim:
					continue
				if puppet.pcharacter == Globals.CHARACTER_EXE or puppet.revivalTimes >= 2:
					var electro := false
					if players.has(attacker):
						electro = players[attacker].get("character", -1) == 3
					GameAudio.play_sound("snd_electroshock" if electro else "snd_exe_stun")
					if electro and is_instance_valid(Globals.player):
						Globals.player.quick_effect(
							puppet.position.x, puppet.position.y, "spr_shockparticle"
						)
					if puppet.pcharacter == Globals.CHARACTER_EXE and not electro:
						GameAudio.play_exe_stun(puppet.pexe_character)
				break

		PacketType.SERVER_GAME_PING:
			# [_pid u16][_ms u16] — the server's ping reply (net_udpprocess)
			var _p_pid := rb.get_u16()
			var _p_ms := rb.get_u16()
			pings[_p_pid] = _p_ms
			if _p_pid == nid:
				ping = _p_ms
		PacketType.SERVER_GAME_EXE_WINS, PacketType.SERVER_GAME_SURVIVOR_WIN, PacketType.SERVER_GAME_TIME_OVER:
			if passthrough or gameEnds:
				return
			var eligible = rb.get_u8() != 0
			Achievements.rules.finish(nps, eligible)
			gameEnds = true
			Globals.playerControls = false
			GameAudio.stop_all()
			var sprite := "spr_timeover"
			var survivor_win := nps == PacketType.SERVER_GAME_SURVIVOR_WIN
			if nps == PacketType.SERVER_GAME_EXE_WINS:
				var hunter: bool = (
					Globals.character == Globals.CHARACTER_EXE
					or (is_instance_valid(Globals.player) and Globals.player.revivalTimes >= 2)
				)
				sprite = "spr_youkilledeveryone" if hunter else "spr_gameover"
			elif survivor_win:
				var survivor: bool = (
					Globals.character != Globals.CHARACTER_EXE
					and (
						not is_instance_valid(Globals.player)
						or (Globals.player.revivalTimes < 2 and Globals.player.hp > 0)
					)
				)
				sprite = "spr_survivorsescaped" if survivor else "spr_gameover"
			GameAudio.play_sound("snd_survivor_win" if survivor_win else "snd_exe_wins")
			for level in GMNode.all_of("obj_level"):
				level.ending_sprite = sprite
			for player in GMNode.all_of("obj_player"):
				player.isAttacking = false
				player.xspd = 0
				player.yspd = 0
				player.gspd = 0
				if Globals.character == Globals.CHARACTER_EXE:
					player.won = not survivor_win
					player.lost = survivor_win
			for ring in GMNode.all_of("obj_bigring"):
				ring.queue_free()
		PacketType.SERVER_GAME_SPAWN_RING:
			if passthrough:
				return
			var ready := rb.get_u8() != 0
			if not ready:
				# Ravine Mist closes the existing exit when carriers lose shards.
				var existing := GMNode.all_of("obj_bigring")
				if not existing.is_empty():
					for ring in existing:
						ring.ready_to_escape = false
					return
				if rb.get_available_bytes() < 1:
					return
				var index := rb.get_u8()
				var points := GMNode.all_of("obj_ringspawn")
				if points.is_empty():
					return
				if GMNode.all_of("obj_bigring").is_empty():
					var ring := preload("res://src/game/obj_bigring.gd").new()
					ring.position = points[index % points.size()].position
					get_tree().current_scene.add_child(ring)
					GameAudio.stop_music()
					GameAudio.play_music(
						(
							{
								10: "mus_pricelessfreedom_chase",
								11: "mus_volcanovalley_chase",
								18: "mus_weedzone_chase",
								19: "mus_marijuna_chase",
								13: "mus_majinforest_chase",
								16: "mus_darktower_chase",
								17: "mus_hauntdream_chase",
								1: "mus_ravimemist_chase",
								4: "mus_youcantrun_chase",
								5: "mus_limpcity_chase",
								0: "mus_hideandseek2_chase",
								2: "mus_dotdotdot_chase",
								3: "mus_deserttown_chase",
								7: "mus_kindandfair_chase",
								9: "mus_nastyparadise_chase",
								12: "mus_hill_chase",
								6: "mus_notperfect_chase",
								8: "mus_act9_chase",
								14: "mus_angelisland_chase",
								15: "mus_torturecave_chase"
							}
							. get(lvlId, "mus_deserttown_chase")
						)
					)
				for level in GMNode.all_of("obj_level"):
					level.state = 1
			else:
				for ring in GMNode.all_of("obj_bigring"):
					ring.ready_to_escape = true
		PacketType.SERVER_PLAYER_ESCAPED:
			if passthrough:
				return
			_mark_escaped(nid)
		PacketType.SERVER_GAME_PLAYER_ESCAPED:
			if passthrough:
				return
			_mark_escaped(rb.get_u16())
		PacketType.SERVER_TPROJECTILE_STATE:
			if passthrough:
				return
			var action := rb.get_u8()
			if action == 2:
				for shot in GMNode.all_of("obj_tails_projectile"):
					shot._destroy()
			elif action == 0 and get_tree().current_scene != null:
				var shot := preload("res://src/game/obj_tails_projectile.gd").new()
				shot.position = Vector2(rb.get_16(), rb.get_16())
				shot.owner_id = rb.get_u16()
				shot.is_owner = shot.owner_id == nid
				shot.image_xscale = rb.get_8()
				shot.dmg = rb.get_u8()
				shot.is_exe = rb.get_u8() != 0
				shot.charge = rb.get_u8()
				get_tree().current_scene.add_child(shot)
		PacketType.SERVER_GAME_TIME_SYNC:
			if passthrough:
				return
			var _timer := rb.get_u16()
			round_ticks = _timer
			# the in-round clock is server-driven (obj_level's solo emulation
			# stands down while Net.state == STATE_GAME)
			for lv in GMNode.all_of("obj_level"):
				lv.net_time(_timer)
			for w in GMNode.all_of("obj_menu_waiting"):
				w.draw_clock = true
				w.time_minutes = ceili(_timer / 60.0) / 60
				w.time_seconds = ceili(_timer / 60.0) % 60
				w.timeFrame += 1
				if w.time_minutes == 0 and w.time_seconds <= 10:
					GameAudio.play_sound("snd_clock")
		PacketType.SERVER_GAME_DEATHTIMER_TICK:
			# [_exeNear u8][_id u16][_timer u8] — the dying player's HUD + puppets
			var _exe_near := rb.get_u8() != 0
			var _dt_id := rb.get_u16()
			var _dt_timer := rb.get_u8()
			var _col := Color.RED if _exe_near else Color.WHITE
			if _dt_id == nid and Globals.player != null:
				Globals.player.deadTimer = _dt_timer
				Globals.player.deadColor = _col
				Globals.player.server_death = true  # the server owns this death
			for pup in GMNode.all_of("obj_player_puppet"):
				if pup.master_id == _dt_id:
					pup.deadTimer = _dt_timer
					pup.deadColor = _col
					break
		PacketType.SERVER_GAME_DEATHTIMER_END:
			# [_demonize bool] — for THIS client (the server decided)
			if passthrough:
				return
			rb.get_u8()  # HP, death and team changes arrive in SERVER_PLAYER_HEALTH.
		PacketType.SERVER_REVIVAL_REVIVED:
			pass  # Canonical health snapshot applies the revival once.

		PacketType.SERVER_REVIVAL_RINGSUB:
			pass  # Ring cost is canonical; the server emits the achievement event.
		PacketType.SERVER_RING_STATE:
			# state 1: the server confirmed a collection/break — everyone
			# destroys THEIR copy of that spawner's ring (iid matches across
			# clients; the uid is per-raising client)
			var ring_state := rb.get_u8()
			if ring_state == 2:
				var at := Vector2(rb.get_16(), rb.get_16())
				var riid := rb.get_u8()
				var uid := rb.get_u16()
				var red := rb.get_u8() != 0
				spawn_cream_ring(riid, uid, at, red)
				return
			var _riid := rb.get_u8()
			var ring_uid := rb.get_u16()
			if ring_state == 0:
				var red := rb.get_u8() != 0
				for existing in GMNode.all_of("obj_ring") + GMNode.all_of("obj_redring"):
					if existing.iid == _riid and existing.nid == ring_uid:
						return
				var spawners := GMNode.all_of("obj_ring_spawner")
				if _riid >= spawners.size():
					return
				var ring := GMNode.new()
				ring.set_script(
					load("res://src/game/obj_redring.gd" if red else "res://src/game/obj_ring.gd")
				)
				ring.gm_name = "obj_redring" if red else "obj_ring"
				ring.position = spawners[_riid].position
				ring.iid = _riid
				ring.nid = ring_uid
				get_tree().current_scene.add_child(ring)
				return
			if ring_state != 1:
				return
			for ring in GMNode.all_of("obj_ring") + GMNode.all_of("obj_redring"):
				if ring.iid == _riid and ring.nid == ring_uid:
					ring.net_destroy()
					break
		PacketType.SERVER_RING_COLLECTED:
			# [_id u8][_eid u16][_redRing bool][_canHeal bool] — the collector's
			# own response; the server already applied it to its state
			if passthrough:
				return
			rb.get_u8()
			rb.get_u16()
			var _red := rb.get_u8() != 0
			var _can_heal := rb.get_u8() != 0
			var cp: GMNode = Globals.player
			if (
				cp == null
				or Globals.character == Globals.CHARACTER_EXE
				or cp.revivalTimes >= 2
				or cp.isDead
				or cp.hp <= 0
			):
				return
			if _red:
				if cp.redRingTimer > 0:
					return
				cp.take_red_ring()
				return
			if not _can_heal:
				GameAudio.play_sound("snd_ring")
				cp.quick_effect(cp.position.x, cp.position.y, "spr_ring_sparkle")


# ---------------------------------------------------------------- net_state_lobby
func net_state_lobby(rb: StreamPeerBuffer, nps: int, passthrough: bool) -> void:
	match nps:
		PacketType.SERVER_LOBBY_EXE:
			if passthrough:
				return
			var whoExe := rb.get_u16()
			var map := rb.get_u16()
			lvlId = map
			# state first — scene cosmetics may fail during scene transitions
			Globals.character = -1
			Globals.exeCharacter = -1
			if nid == whoExe:
				Globals.character = Globals.CHARACTER_EXE
			elif players.has(whoExe):
				players[whoExe].character = Globals.CHARACTER_EXE
			exeId = whoExe
			state = STATE_CHARSELECT
			GameAudio.play_music("mus_lobby_epic")
			for lw in GMNode.all_of("obj_lobby_waiting"):
				lw.visible = false
			for lb in GMNode.all_of("obj_lobby"):
				lb.state = 2
				lb.nextMap = map
			for pr in GMNode.all_of("obj_lobby_prolet"):
				pr.visible = true
				pr.image_blend = GM.C_WHITE
				pr.set_zone(map)
			for ic in GMNode.all_of("obj_lobby_icon"):
				ic.is_hidden = false
				ic.isSelected = false
				ic.selected = 1
				ic.image_index = 0
				ic.queue_redraw()
				if ic.master_id == nid:
					ic.sprite_name = "spr_lobby_icon"
				if ic.master_id == exeId and ic.master_id != nid:
					ic.sprite_name = "spr_lobby_exeicon5"
					if ic.master_id == nid:
						ic.image_index = Unlockables.lobbyIcon
					elif players.has(ic.master_id):
						ic.image_index = players[ic.master_id].icon
			for lb in GMNode.all_of("obj_lobby_white"):
				lb.queue_free()
			var cs := get_tree().current_scene
			if cs:
				var w := GMNode.new()
				w.set_script(load("res://src/menu/obj_lobby_white.gd"))
				w.position = Vector2.ZERO
				w.depth = -100
				cs.add_child(w)
		PacketType.SERVER_PLAYER_JOINED:
			if passthrough:
				return
			var _id := rb.get_u16()
			var _name := _gm_get_string(rb)
			var _icon := rb.get_u8()
			var _pet: int = rb.get_8()
			players[_id] = {
				"pending": false,
				"nid": _id,
				"nickname": _name,
				"character": -1,
				"exeCharacter": -1,
				"pet": _pet,
				"isReady": false,
				"isAlive": true,
				"hasEscaped": false,
				"icon": _icon,
			}
			for lb in GMNode.all_of("obj_lobby"):
				lb.lobby_player_joined(players[_id], true)
		PacketType.SERVER_LOBBY_READY_STATE:
			if passthrough:
				return
			var pid := rb.get_u16()
			var st := rb.get_u8() != 0
			if players.has(pid):
				players[pid].isReady = st
				GameAudio.play_sound("snd_ready")
			if pid == nid:
				for lb in GMNode.all_of("obj_lobby"):
					lb.isReady = st
		PacketType.SERVER_LOBBY_CORRECT:
			for lb in GMNode.all_of("obj_lobby"):
				lb.lobby_player_joined(
					{"nid": nid, "nickname": Globals.nickname, "isReady": false}, true
				)
				lb.canUse = true
		PacketType.SERVER_LOBBY_PLAYER:
			if passthrough:
				return
			var _nid := rb.get_u16()
			var _ready := rb.get_u8() != 0
			var _nick := _gm_get_string(rb)
			var _icon := rb.get_u8()
			var _pet: int = rb.get_8()
			players[_nid] = {
				"pending": false,
				"nid": _nid,
				"nickname": _nick,
				"character": -1,
				"exeCharacter": -1,
				"isReady": _ready,
				"isAlive": true,
				"hasEscaped": false,
				"icon": _icon,
				"pet": _pet,
			}
			for lb in GMNode.all_of("obj_lobby"):
				lb.lobby_player_joined(players[_nid], false)
		PacketType.CLIENT_CHAT_MESSAGE:
			if passthrough:
				return
			var _id := rb.get_u16()
			var _msg := _gm_get_string(rb)
			for lb in GMNode.all_of("obj_lobby"):
				if _id == 0:
					lb.lobby_add_message("(server)", _msg)
					return
				if players.has(_id):
					lb.lobby_add_message(players[_id].nickname, _msg)
		PacketType.SERVER_VOTE_MAPS:
			if passthrough:
				return
			var m1 := rb.get_u8()
			var m2 := rb.get_u8()
			var m3 := rb.get_u8()
			for lb in GMNode.all_of("obj_lobby"):
				lb.state = 1
				lb.map1 = m1
				lb.map2 = m2
				lb.map3 = m3
			for ic in GMNode.all_of("obj_lobby_icon"):
				ic.is_hidden = true
			state = STATE_VOTE
		PacketType.SERVER_LOBBY_EXE_CHANCE:
			if passthrough:
				return
			chance = rb.get_u8()


# ---------------------------------------------------------------- net_state_vote
func net_state_vote(rb: StreamPeerBuffer, nps: int, passthrough: bool) -> void:
	match nps:
		PacketType.SERVER_LOBBY_EXE:
			net_state_lobby(rb, nps, passthrough)
		PacketType.SERVER_VOTE_TIME_SYNC:
			if passthrough:
				return
			for lb in GMNode.all_of("obj_lobby"):
				lb.countScale = 1
				lb.voteTimer = rb.get_u8()
				if lb.voteTimer <= 3:
					lb.countScale = 1.5
					GameAudio.play_sound("snd_clock")
		PacketType.SERVER_VOTE_SET:
			if passthrough:
				return
			for lb in GMNode.all_of("obj_lobby"):
				lb.map1Votes = rb.get_u8()
				lb.map2Votes = rb.get_u8()
				lb.map3Votes = rb.get_u8()


# ---------------------------------------------------------------- net_state_charselect
func net_state_charselect(rb: StreamPeerBuffer, nps: int, passthrough: bool) -> void:
	match nps:
		PacketType.SERVER_CHAR_TIME_SYNC:
			if passthrough:
				return
			for lb in GMNode.all_of("obj_lobby"):
				if not is_instance_valid(lb):
					continue
				lb.countScale = 1
				lb.charTimer = rb.get_u8()
				if lb.charTimer <= 3:
					lb.countScale = 1.5
					GameAudio.play_sound("snd_clock")
		PacketType.SERVER_LOBBY_GAME_START:
			if passthrough:
				return
			gameEnds = false
			health.clear()
			motion.clear()
			test_round = rb.get_available_bytes() > 0 and rb.get_u8() != 0
			round_id = rb.get_u32() if rb.get_available_bytes() >= 4 else 0
			Achievements.rules.begin()
			_palette_sent = 0
			profile_interaction.clear()
			for lb in GMNode.all_of("obj_lobby"):
				lb.state = 3
			state = STATE_GAME
			round_ticks = -1
			var ch := -1
			if Globals.character == Globals.CHARACTER_EXE:
				ch = Globals.exeCharacter
			elif players.has(exeId):
				ch = players[exeId].exeCharacter
			match ch:
				Globals.EXE_ORIGINAL:
					GameAudio.play_sound("snd_exe_laugh")
				Globals.EXE_CHAOS:
					GameAudio.play_sound("snd_chaos_laugh")
				Globals.EXE_EXETIOR:
					GameAudio.play_sound("snd_exetior_laugh")
				Globals.EXE_EXELLER:
					GameAudio.play_sound("snd_exeller_laugh")
		PacketType.SERVER_LOBBY_CHARACTER_RESPONSE:
			if passthrough:
				return
			var ch := rb.get_u8()
			var result := rb.get_u8() != 0
			if result:
				Globals.character = ch
				if players.has(nid):
					players[nid].character = ch
				for ic in GMNode.all_of("obj_lobby_icon"):
					if ic.master_id != nid:
						continue
					ic.isSelected = true
					ic.selected = ch
					ic.offset = 3
					ic.sprite_name = "spr_lobby_icon"
					ic.image_index = ch + 1
					ic.image_xscale = 0
				var table: Dictionary = Unlockables.palettes.get(ch, {"from": [], "to": []})
				Globals.palleteFrom = table.get("from", [])
				Globals.palleteTo = table.get("to", [])
				Globals.palleteName = table.get("name", "default")
				GameAudio.play_sound("snd_clock")
			else:
				GameAudio.play_sound("snd_nono")
				avCharacters[ch] = false
		PacketType.SERVER_LOBBY_EXECHARACTER_RESPONSE:
			if passthrough:
				return
			var ch := rb.get_u8()
			var _result := rb.get_u8() != 0
			if not _result or ch < 0 or ch > 3:
				GameAudio.play_sound("snd_nono")
				return
			Globals.character = Globals.CHARACTER_EXE
			Globals.exeCharacter = ch
			if players.has(nid):
				players[nid].character = Globals.CHARACTER_EXE
				players[nid].exeCharacter = ch
			for ic in GMNode.all_of("obj_lobby_icon"):
				if ic.master_id != nid:
					continue
				ic.isSelected = true
				ic.selected = ch + 1
				ic.offset = 3
				match ch:
					Globals.EXE_ORIGINAL:
						ic.sprite_name = "spr_lobby_exeicon"
					Globals.EXE_CHAOS:
						ic.sprite_name = "spr_lobby_exeicon2"
					Globals.EXE_EXETIOR:
						ic.sprite_name = "spr_lobby_exeicon3"
					Globals.EXE_EXELLER:
						ic.sprite_name = "spr_lobby_exeicon4"
				ic.image_index = 0
				ic.image_xscale = 0
			var table: Dictionary = Unlockables.palettes.get(
				ch + Globals.PALETTE_EXE, {"from": [], "to": []}
			)
			Globals.palleteFrom = table.get("from", [])
			Globals.palleteTo = table.get("to", [])
			Globals.palleteName = table.get("name", "default")
			GameAudio.play_sound("snd_clock")
		PacketType.SERVER_LOBBY_CHARACTER_CHANGE:
			if passthrough:
				return
			var pid := rb.get_u16()
			var ch := rb.get_u8()
			if not players.has(pid):
				return
			if exeId == pid:
				players[pid].character = Globals.CHARACTER_EXE
				players[pid].exeCharacter = ch
			else:
				players[pid].character = ch
				avCharacters[ch] = false
			for ic in GMNode.all_of("obj_lobby_icon"):
				if ic.master_id != pid:
					continue
				ic.isSelected = true
				ic.offset = 3
				if exeId == pid:
					match ch:
						Globals.EXE_ORIGINAL:
							ic.sprite_name = "spr_lobby_exeicon"
						Globals.EXE_CHAOS:
							ic.sprite_name = "spr_lobby_exeicon2"
						Globals.EXE_EXETIOR:
							ic.sprite_name = "spr_lobby_exeicon3"
						Globals.EXE_EXELLER:
							ic.sprite_name = "spr_lobby_exeicon4"
					ic.image_xscale = 0
				else:
					ic.sprite_name = "spr_lobby_icon"
					ic.image_xscale = 0
					ic.image_index = ch + 1
			GameAudio.play_sound("snd_clock")
		PacketType.SERVER_LOBBY_EXE_CHANCE:
			if passthrough:
				return
			chance = rb.get_u8()


# ---------------------------------------------------------------- map entry
var _solo_clone_id := 1


func request_exeller_clone():
	var p: GMNode = Globals.player
	if (
		not is_instance_valid(p)
		or Globals.character != 0
		or Globals.exeCharacter != Globals.EXE_EXELLER
	):
		return
	if state == STATE_GAME:
		_send_player_data()
		var b := cpacket_tcp(PacketType.CLIENT_EXELLER_SPAWN_CLONE)
		b.put_16(int(p.position.x))
		b.put_16(int(p.position.y))
		b.put_8(int(p.image_xscale))
		send_server_tcp(b)
	else:
		var slot: int = p.hunter.clones.find(-1)
		if slot >= 0:
			spawn_exeller_clone(_solo_clone_id, nid, p.position, int(p.image_xscale), slot)
			_solo_clone_id += 1


func request_clone_teleport(id: int):
	if state == STATE_GAME:
		_send_player_data()
		var b := cpacket_tcp(PacketType.CLIENT_EXELLER_TELEPORT_CLONE)
		b.put_u16(id)
		send_server_tcp(b)
	else:
		for clone in GMNode.all_of("obj_exeller_clone"):
			if clone.nid == id and clone.owner_id == nid:
				consume_exeller_clone(id, nid, clone.position, clone.slot)
				return


func clone_effect(at: Vector2):
	var effect := GMNode.new()
	effect.set_script(load("res://src/game/obj_quickfx.gd"))
	effect.sprite_name = "spr_ring_teleport"
	effect.position = at + Vector2(0, 32)
	effect.image_speed = 2
	effect.fade = false
	get_tree().current_scene.add_child(effect)
	effect.z_index = 200


func spawn_exeller_clone(id: int, owner: int, at: Vector2, facing: int, slot: int):
	for old in GMNode.all_of("obj_exeller_clone"):
		if old.nid == id:
			return
	if slot not in [0, 1]:
		return
	var clone := GMNode.new()
	clone.set_script(load("res://src/game/hunters/exeller_clone.gd"))
	clone.nid = id
	clone.owner_id = owner
	clone.slot = slot
	clone.position = at
	clone.image_xscale = facing
	clone.nickname = str(
		players.get(owner, {}).get("nickname", Globals.nickname if owner == nid else "")
	)
	get_tree().current_scene.add_child(clone)
	var p: GMNode = Globals.player
	if (
		owner == nid
		and Globals.character == 0
		and Globals.exeCharacter == Globals.EXE_EXELLER
		and is_instance_valid(p)
		and p.hunter != null
	):
		p.hunter.clones[slot] = id
	clone_effect(at)
	GameAudio.play_sound_at("snd_exeller_clone", at)


func consume_exeller_clone(id: int, owner: int, at: Vector2, slot: int):
	for clone in GMNode.all_of("obj_exeller_clone"):
		if clone.nid == id:
			clone.queue_free()
	var p: GMNode = Globals.player
	if (
		owner == nid
		and Globals.character == 0
		and Globals.exeCharacter == Globals.EXE_EXELLER
		and is_instance_valid(p)
		and p.hunter != null
	):
		p.position = at  # Preserve velocity/facing/attack state, as the original handler does.
		p.hunter.clones[slot] = -1
		p.hunter.cloneTimer = 1800
		p.hunter.indicatorTimer = 420
	else:
		for puppet in GMNode.all_of("obj_player_puppet"):
			if puppet.master_id == owner:
				puppet.position = at
	clone_effect(at)
	GameAudio.play_sound_at("snd_exe_appear", at)


func report_black_ring(id: int):
	if state != STATE_GAME:
		return
	# ENet preserves order: validate this contact against its current position.
	_send_player_data()
	var b := cpacket_tcp(PacketType.CLIENT_BRING_COLLECTED)
	b.put_u16(id)
	send_server_tcp(b)


var _solo_black_ring_id := 1


func spawn_black_ring(id: int, at: Vector2, purple := false):
	if state != STATE_GAME and id == 0:
		id = _solo_black_ring_id
		_solo_black_ring_id += 1
	for old in GMNode.all_of("obj_blackring"):
		if old.nid == id:
			return
	var ring := GMNode.new()
	ring.set_script(load("res://src/game/hunters/black_ring.gd"))
	ring.nid = id
	ring.position = at
	ring.purple = purple or (Globals.character == 0 and Globals.palleteName == "menace")
	get_tree().current_scene.add_child(ring)


func consume_black_ring(id: int, apply_cost := true):
	if apply_cost and state != STATE_GAME:
		var scene := get_tree().current_scene
		if (
			scene != null
			and scene.get("rules") != null
			and scene.rules.has_method("collect_map_ring")
			and scene.rules.collect_map_ring(id)
		):
			return
	for ring in GMNode.all_of("obj_blackring"):
		if ring.nid != id:
			continue
		var effect := GMNode.new()
		effect.set_script(load("res://src/game/obj_quickfx.gd"))
		effect.sprite_name = (
			"spr_blackring_sparkle_purple"
			if ring.sprite_name.ends_with("purple")
			else "spr_blackring_sparkle"
		)
		effect.position = ring.position
		effect.fade = false
		get_tree().current_scene.add_child(effect)
		ring.queue_free()
		if not apply_cost or state == STATE_GAME:
			return
		var player: GMNode = Globals.player
		if not is_instance_valid(player):
			return
		if player.rings >= 5:
			player.rings -= 5
			GameAudio.play_sound("snd_ringabsorb")
		else:
			player.hp = maxi(0, player.hp - 1)
			GameAudio.play_sound("snd_blackring")
			if player.hp == 0:
				player.player_instakill()
			for level in GMNode.all_of("obj_level"):
				level.bloodFade = 0.4
		return


func spawn_exetior_waves(at: Vector2, age := 0):
	if age >= 20:
		return
	for direction in [-1, 1]:
		var wave := GMNode.new()
		wave.set_script(load("res://src/game/hunters/exetior_wave.gd"))
		wave.dir = direction
		wave.cnt = int(age >= 10)
		wave.position = at + Vector2(direction * (50 if age >= 10 else 25), 19)
		get_tree().current_scene.add_child(wave)
		wave.image_index = floori((age % 10) * 25.0 / 60)


func goto_map() -> void:
	var data = preload("res://src/data/maps.gd").entry(lvlId)
	if not data.is_empty():
		get_tree().change_scene_to_file(data.scene)
	else:
		Globals.errorMessage = "UNKNOWN MAP"
		shutdown()
		get_tree().change_scene_to_file("res://scenes/message.tscn")


# ---------------------------------------------------------------- helpers
static func chat_filter(s: String) -> String:
	var out := s
	for w in [
		"nigger",
		"nigga",
		"niggas",
		"nigg",
		"faggot",
		"tranny",
		"экзюшка",
		"эгусик",
		"эггусик",
		"эмичка",
		"кримка",
		"салька",
		"наксик",
		"хохол",
		"москаль"
	]:
		out = out.replace(w, "*".repeat(w.length()))
	out = out.replace("\r", "").replace("\t", "").replace("\n", "")
	return out


func spawn_ring_parts(at: Vector2, speed: float) -> void:
	var depth := -1.0
	if Globals.player != null:
		depth = Globals.player.depth - 1.0
	var offsets := [Vector2(12, 4), Vector2(0, 12), Vector2(4, 4), Vector2(12, 12)]
	var sprites := ["spr_ringpart", "spr_ringpart2", "spr_ringpart3", "spr_ringpart4"]
	var xs := [1, -1, -1, 1]
	var ys := [[-4, -2], [1, 2], [-4, -2], [1, 2]]
	for i in 4:
		var part := GMNode.new()
		part.set_script(load("res://src/game/obj_ringpart.gd"))
		part.position = at + offsets[i]
		part.xspd = xs[i] + speed
		part.yspd = (ys[i][0] + randi_range(0, ys[i][1] - ys[i][0]))
		part.sprite_name = sprites[i]
		part.depth = depth
		get_tree().current_scene.add_child(part)


func _mark_escaped(id: int) -> void:
	if players.get(id, {}).get("hasEscaped", false):
		return
	if id != nid:
		Achievements.rules.event("escape")
	if id == nid and is_instance_valid(Globals.player):
		Achievements.rules.r["escape_hp"] = Globals.player.hp
		Achievements.rules.r["escape_ticks"] = round_ticks

	if players.has(id):
		players[id].hasEscaped = true
	if id == nid:
		var player: GMNode = Globals.player
		Globals.player = null
		if is_instance_valid(player):
			player.set_physics_process(false)
			player.remove_from_group("obj_player")
			player.queue_free()
	else:
		for puppet in GMNode.all_of("obj_player_puppet"):
			if puppet.master_id == id:
				puppet.set_physics_process(false)
				puppet.queue_free()
	GameAudio.play_sound("snd_teleport")
	for ring in GMNode.all_of("obj_bigring"):
		var effect := preload("res://src/game/obj_quickfx.gd").new()
		effect.position = ring.position
		effect.sprite_name = "spr_ring_teleport"
		effect.image_speed = 2.0
		get_tree().current_scene.add_child(effect)


func active_game_map() -> bool:
	var scene = get_tree().current_scene
	return scene != null and scene.get("lvl_id") == lvlId
