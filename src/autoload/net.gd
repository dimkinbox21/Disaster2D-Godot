extends Node
## Port of obj_netclient + disnet transport (ENet replaces the custom
## reliable-UDP DLL; packet format and flows are 1:1 with net_*.gml).
## Server is authoritative — client only reports inputs/events.

enum PacketType
{
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
var isConnected := false
var isReady := false
var isServerReady := false
var nid: int = -1
var frame := 0
var gameEnds := false
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
var lvlId := -1
var pings: Dictionary = {}
var players: Dictionary = {}   # nid -> Dictionary (mirrors ds_map)
var avCharacters := [false, true, true, true, true, true, true]

var _host: ENetConnection = null
var _peer: ENetPacketPeer = null
var _udp_timeout := 60 * 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## net_join(host, selected_lobby) port
func join(host: String, selected_lobby: int = -1) -> void:
	if OS.get_environment("JOINTRACE") == "1":
		print("JOINTRACE net_join host=", host)
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
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func shutdown() -> void:
	if _peer:
		_peer.peer_reset()
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
	pings.clear()
	avCharacters = [false, true, true, true, true, true, true]
	exeId = 0
	chance = 0
	lvlId = -1
	gameEnds = false

func _exit_tree() -> void:
	if _host:
		_host.destroy()
	_host = null

# ---------------------------------------------------------------- transport
## called by obj_connecting (Alarm 0) — disnet_connect port
func connect_to_server() -> bool:
	# Net.join() sets ip from the menu's connect screen; only fall back to the
	# saved config when nothing was passed (a direct scene launch) — and map
	# "localhost" to the IPv4 literal, because Godot's ENet resolves it to ::1
	# while the server binds 0.0.0.0 (IPv4) and the handshake never lands.
	if ip == "":
		ip = GameConfig.ip if GameConfig.ip != "" else "127.0.0.1"
	if ip.to_lower() == "localhost":
		ip = "127.0.0.1"
	_host = ENetConnection.new()
	var err := _host.create_host(4, 2)
	if err != OK:
		return false
	_peer = _host.connect_to_host(ip, port, 2)
	if OS.get_environment("NETTRACE") == "1":
		print("NETTRACE connecting to ", ip, ":", port, " ok=", _peer != null)
	return _peer != null

func _physics_process(_delta: float) -> void:
	if _host == null:
		return
	# net_poll() port
	while true:
		var ev := _host.service(0)
		var event: int = ev[0]
		if OS.get_environment("NETDBG") == "1":
			if event != ENetConnection.EVENT_NONE:
				print("NETEV ", event)
		if event == ENetConnection.EVENT_ERROR:
			return
		match event:
			ENetConnection.EVENT_NONE:
				return
			ENetConnection.EVENT_CONNECT:
				_on_connected()
				return
			ENetConnection.EVENT_DISCONNECT:
				_on_disconnected(ev[2])
				return
			ENetConnection.EVENT_RECEIVE:
				var pkt: ENetPacketPeer = ev[1]
				var data := pkt.get_packet()
				if data.size() >= 2:
					net_tcpprocess(data)
				continue

func _on_connected() -> void:
	if OS.get_environment("NETTRACE") == "1":
		print("NETTRACE CONNECTED")
	if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != "res://scenes/connecting.tscn":
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
	avCharacters = [false, true, true, true, true, true, true]
	isConnected = true
	get_tree().change_scene_to_file("res://scenes/waiting.tscn")

func _on_disconnected(data) -> void:
	if OS.get_environment("NETTRACE") == "1":
		print("NETTRACE DISCONNECTED data=", data)
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
		PacketType.SERVER_PLAYER_LEFT:
			if _passthrough:
				return
			var _id := rb.get_u16()
			# free character
			if state == STATE_PENDING and is_in_waiting():
				if players.has(_id):
					players.erase(_id)
					GameAudio.play_sound("snd_hurt")
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
				STATE_LOBBY: net_state_lobby(rb, nps, _passthrough)
				STATE_VOTE: net_state_vote(rb, nps, _passthrough)
				STATE_CHARSELECT: net_state_charselect(rb, nps, _passthrough)
				STATE_PENDING: net_state_pending(rb, nps, _passthrough)

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
				return
			isReady = true
			state = STATE_LOBBY
			get_tree().change_scene_to_file("res://scenes/lobby.tscn")
			var b2 := cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false)
			send_server_tcp(b2)
		PacketType.SERVER_GAME_TIME_SYNC:
			if passthrough:
				return
			var _timer := rb.get_u16()
			for w in GMNode.all_of("obj_menu_waiting"):
				w.draw_clock = true
				w.time_minutes = ceili(float(_timer + 1) / 3600.0) - 1
				w.time_seconds = ceili(_timer / 60.0) % 60
				w.timeFrame += 1
				if w.time_minutes == 0 and w.time_seconds <= 10:
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
					w.players[_id] = {"nid": _id, "scale": 0.0, "icon": 19954, "nickname": _nick, "exe": _exe, "char": _char}
			else:
				var _sid: int = rb.get_8()
				for w in GMNode.all_of("obj_menu_waiting"):
					w.players[_id] = {"nid": _id, "scale": 0.0, "icon": _sid, "nickname": _nick, "exe": -1, "char": -1}
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
		PacketType.SERVER_RESULTS:
			lvlId = rb.get_u8()
			isReady = true
			gameEnds = true
			state = STATE_RESULTS
			# results room — stage 3; return to menu
			net_reset()
		PacketType.SERVER_PREIDENTITY:
			send_identity()

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
				"pending": false, "nid": _id, "nickname": _name,
				"character": -1, "exeCharacter": -1, "pet": _pet,
				"isReady": false, "isAlive": true, "hasEscaped": false, "icon": _icon,
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
		PacketType.SERVER_LOBBY_CORRECT:
			for lb in GMNode.all_of("obj_lobby"):
				lb.lobby_player_joined({"nid": nid, "nickname": Globals.nickname, "isReady": false}, true)
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
				"pending": false, "nid": _nid, "nickname": _nick,
				"character": -1, "exeCharacter": -1,
				"isReady": _ready, "isAlive": true, "hasEscaped": false, "icon": _icon, "pet": _pet,
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
			print("NETTRACE GAME_START received")
			for lb in GMNode.all_of("obj_lobby"):
				lb.state = 3
			state = STATE_GAME
			var ch := 0
			if Globals.character == Globals.CHARACTER_EXE:
				ch = Globals.exeCharacter
			elif players.has(exeId):
				ch = players[exeId].exeCharacter
			match ch:
				Globals.EXE_ORIGINAL: GameAudio.play_sound("snd_exe_laugh")
				Globals.EXE_CHAOS: GameAudio.play_sound("snd_chaos_laugh")
				Globals.EXE_EXETIOR: GameAudio.play_sound("snd_exetior_laugh")
				Globals.EXE_EXELLER: GameAudio.play_sound("snd_exeller_laugh")
		PacketType.SERVER_LOBBY_CHARACTER_RESPONSE:
			if passthrough:
				return
			var ch := rb.get_u8()
			var result := rb.get_u8() != 0
			if result:
				Globals.character = ch
				for ic in GMNode.all_of("obj_lobby_icon"):
					if ic.master_id != nid:
						continue
					ic.isSelected = true
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
			Globals.character = Globals.CHARACTER_EXE
			Globals.exeCharacter = ch
			for ic in GMNode.all_of("obj_lobby_icon"):
				if ic.master_id != nid:
					continue
				ic.isSelected = true
				ic.offset = 3
				match ch:
					Globals.EXE_ORIGINAL: ic.sprite_name = "spr_lobby_exeicon"
					Globals.EXE_CHAOS: ic.sprite_name = "spr_lobby_exeicon2"
					Globals.EXE_EXETIOR: ic.sprite_name = "spr_lobby_exeicon3"
					Globals.EXE_EXELLER: ic.sprite_name = "spr_lobby_exeicon4"
				ic.image_index = 0
				ic.image_xscale = 0
			var table: Dictionary = Unlockables.palettes.get(ch + Globals.PALETTE_EXE, {"from": [], "to": []})
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
						Globals.EXE_ORIGINAL: ic.sprite_name = "spr_lobby_exeicon"
						Globals.EXE_CHAOS: ic.sprite_name = "spr_lobby_exeicon2"
						Globals.EXE_EXETIOR: ic.sprite_name = "spr_lobby_exeicon3"
						Globals.EXE_EXELLER: ic.sprite_name = "spr_lobby_exeicon4"
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
func goto_map() -> void:
	print("NETTRACE goto_map lvlId=", lvlId)
	match lvlId:
		2:
			get_tree().change_scene_to_file("res://scenes/map_dotdotdot.tscn")
		3:
			get_tree().change_scene_to_file("res://scenes/map_deserttown.tscn")
		_:
			Globals.errorMessage = "THIS MAP IS NOT PORTED YET (STAGE 3 IN PROGRESS)"
			shutdown()
			get_tree().change_scene_to_file("res://scenes/message.tscn")

# ---------------------------------------------------------------- helpers
static func chat_filter(s: String) -> String:
	var out := s
	for w in ["nigger", "nigga", "niggas", "nigg", "faggot", "tranny",
			"экзюшка", "эгусик", "эггусик", "эмичка", "кримка", "салька", "наксик", "хохол", "москаль"]:
		out = out.replace(w, "*".repeat(w.length()))
	out = out.replace("\r", "").replace("\t", "").replace("\n", "")
	return out
