extends GMNode
## Port of obj_lobby — lobby controller (icons/ready/chat → map vote → charselect).

var playerCnt := 0
var countdown := -1
var isCounting := false
var isReady := false
var state := 0
var nextMap := -1
var fade := 0.0
var countScale := 1.0
var chat: Array = []
var chatMsg := ""
var chatMode := false
var charIndex := 0.0
var _last_preview := -1
var _map_entered := false

var chars := [
	"spr_menu_tails",
	"spr_menu_knux",
	"spr_menu_egg",
	"spr_menu_amy",
	"spr_menu_cream",
	"spr_menu_sally",
	"spr_menu_exe",
	"spr_menu_chaos",
	"spr_menu_exetior",
	"spr_menu_exeller"
]

var map1 := 0
var map2 := 0
var map3 := 0
var mapOff := 4.0
var map1Votes := 0
var map2Votes := 0
var map3Votes := 0
var mapChose := false
var mapFade := 0.0
var mapChosen := 0
var voteTimer := 20
var canUse := false

var charTimer := 30

var voteKick := false


func _ready() -> void:
	super._ready()
	GameAudio.play_music("mus_lobby")
	Globals.palleteFrom = [0.0]
	Globals.palleteTo = [0.0]
	# the identity handler requests the player list the moment it switches scenes,
	# but change_scene_to_file is DEFERRED — on localhost the reply can land in the
	# same frame, before this object exists, and then no icons are ever spawned
	# (the player sees others who join later but never themselves). Re-request
	# here: obj_lobby exists now, and the server's reply is idempotent.
	if Net.isConnected and Net.nid != -1:
		var req := Net.cpacket_tcp(Net.PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false)
		Net.send_server_tcp(req)
	if Net.isConnected and Net.isReady and Net.nid != -1:
		var f := GMNode.new()
		f.set_script(load("res://src/menu/obj_blackfadeout.gd"))
		f.position = Vector2.ZERO
		f.depth = -100
		add_child(f)


func lobby_player_joined(plr: Dictionary, ng := true) -> void:
	for ic in GMNode.all_of("obj_lobby_icon"):
		if ic.master_id == plr.nid:
			return
	var inst := GMNode.new()
	inst.set_script(load("res://src/net/obj_lobby_icon.gd"))
	inst.z_as_relative = false
	add_child(inst)
	# GM order: instance_create_depth runs the Create event FIRST (aY = 0, xscale = 0,
	# visible = false…) and the spawner's fields land afterwards. Setting them before
	# add_child made _ready clobber aY with 0, so every remote icon sat at y = 0 (top
	# edge, half off-screen) instead of y = 58.
	inst.master_id = plr.nid
	inst.nickname = plr.nickname
	inst.isReady = plr.isReady
	inst.aY = 58
	inst.position = Vector2(32 + 12, 128 + 12)
	playerCnt += 1
	if OS.get_environment("LOBBY_TRACE") == "1":
		print("JOINED icon for nid=", plr.nid, " state=", state, " playerCnt=", playerCnt)
	if ng:
		GameAudio.play_sound("snd_ring")


func lobby_player_left(nid_: int) -> void:
	playerCnt -= 1
	for ic in GMNode.all_of("obj_lobby_icon"):
		if ic.master_id == nid_:
			var blood := GMNode.new()
			blood.set_script(load("res://src/net/obj_lobby_blood.gd"))
			blood.position = ic.position
			blood.depth = -999
			blood.sprite_name = "spr_blood2"
			get_parent().add_child(blood)
			ic.queue_free()
			GameAudio.play_sound("snd_hurt")


func lobby_add_message(sender: String, msg: String) -> void:
	if Globals.muteChat:
		return
	GameAudio.stop_sound("snd_message")
	GameAudio.play_sound("snd_message")
	chat.append(sender + ": " + Net.chat_filter(msg) + "~")
	if chat.size() >= 9:
		chat.pop_front()


func _gm_step() -> void:
	queue_redraw()
	_step_visuals()
	if chatMode:
		if GM.key_down(GM.VK_CONTROL) and GM.key_pressed(86):
			GM.keyboard_string = DisplayServer.clipboard_get()
		chatMsg = GameConfig._gm_string_copy(GM.keyboard_string.to_lower(), 0, 48)
		if GM.keyboard_string.length() > 48:
			GM.keyboard_string = chatMsg

	if kp(Globals.KeyLeft):
		if not canUse:
			return
		if state != 1 or mapChose or mapFade < 1:
			return
		mapChosen -= 1
		if mapChosen < 0:
			mapChosen = 2
		mapOff = 4
		GameAudio.play_sound("snd_menu_select")
	elif kp(Globals.KeyRight):
		if not canUse:
			return
		if state != 1 or mapChose or mapFade < 1:
			return
		mapChosen += 1
		if mapChosen > 2:
			mapChosen = 0
		mapOff = 4
		GameAudio.play_sound("snd_menu_select")
	elif kp(Globals.KeyA):
		if not canUse:
			return
		if state == 1 and not mapChose and mapFade >= 1:
			var packet := Net.cpacket_tcp(Net.PacketType.CLIENT_VOTE_REQUEST, false)
			packet.put_u8(mapChosen)
			Net.send_server_tcp(packet)
			GameAudio.play_sound("snd_menu_press")
			mapChose = true
			return
		if chatMode or voteKick:
			return
		if not Net.isReady:
			return
		if Net.state == Net.STATE_LOBBY:
			isReady = not isReady
			var packet := Net.cpacket_tcp(Net.PacketType.CLIENT_LOBBY_READY_STATE, false)
			packet.put_u8(1 if isReady else 0)
			Net.send_server_tcp(packet)
			GameAudio.play_sound("snd_ready")
	elif kp(Globals.KeyB):
		if not canUse or voteKick:
			return
		if chatMode:
			return
		if not Net.isReady:
			return
		if state == 0:
			Net.net_reset()

	if state != 0:
		return
	if not canUse or voteKick:
		return
	# Enter / T toggles chat (KeyPress_13 / KeyPress_84)
	if kp(GM.VK_ENTER) or kp(84):
		chatMode = not chatMode
		if chatMode:
			GM.keyboard_string = chatMsg
		else:
			GM.keyboard_string = ""
			if chatMsg == "":
				return
			chatMsg = chatMsg.to_lower()
			match chatMsg:
				".mute", ".m":
					if Globals.muteChat:
						Globals.muteChat = false
						lobby_add_message("(mute)", "@chat is now unmuted.~")
					else:
						lobby_add_message("(mute)", "\\chat is now muted.~")
						Globals.muteChat = true
				_:
					var packet := Net.cpacket_tcp(Net.PacketType.CLIENT_CHAT_MESSAGE, true)
					packet.put_u16(Net.nid)
					Net._gm_put_string(packet, Net.chat_filter(chatMsg))
					Net.send_server_tcp(packet)
					lobby_add_message(Globals.nickname, chatMsg)
			chatMsg = ""
			GM.keyboard_string = ""


func _gm_draw() -> void:
	if state == 0:
		draw_sprite("spr_lobby_bars", 0, 0, 0)
		if isCounting and not voteKick:
			draw_sprite("spr_countdown", countdown - 1, 480.0 / 2, 13, countScale, countScale)
		else:
			draw_sprite(
				"spr_lobby_votekick" if voteKick else "spr_lobby_waiting",
				int(Time.get_ticks_msec() / 300) % 4,
				240,
				8
			)
		var str_ := ""
		for c in chat:
			str_ += c + "\n"
		GM.scr_text_spr(self, 3, 148 - 6, str_)
		var ind := 0
		if chatMode or chatMsg.length() > 0:
			ind = 1
		draw_sprite("spr_lobby_chatbox", ind, 0, 211)
		GM.scr_text_spr(self, 2, 214, chatMsg)
		GM.scr_text_spr(self, 170, 256, "\\your chance to be exe: %d%%~" % Net.chance)
	elif state == 1:
		draw_sprite("spr_vote_bars", 0, 0, 0)
		draw_sprite("spr_counter3", voteTimer, 480.0 / 2, 13, countScale, countScale)
		var col := GM.C_DKGRAY if not (mapChosen == 0 and not mapChose) else GM.C_WHITE
		draw_sprite(
			"spr_mapvote",
			map1,
			16,
			58 + 20 * mapFade - (0 if mapChosen != 0 else mapOff),
			1,
			1,
			0,
			col,
			mapFade
		)
		col = GM.C_DKGRAY if not (mapChosen == 1 and not mapChose) else GM.C_WHITE
		draw_sprite(
			"spr_mapvote",
			map2,
			179,
			58 + 20 * mapFade - (0 if mapChosen != 1 else mapOff),
			1,
			1,
			0,
			col,
			mapFade
		)
		col = GM.C_DKGRAY if not (mapChosen == 2 and not mapChose) else GM.C_WHITE
		draw_sprite(
			"spr_mapvote",
			map3,
			341,
			58 + 20 * mapFade - (0 if mapChosen != 2 else mapOff),
			1,
			1,
			0,
			col,
			mapFade
		)
		var _map := map1
		if mapChosen == 1:
			_map = map2
		if mapChosen == 2:
			_map = map3
		GM.scr_text_spr(
			self,
			4,
			233,
			Globals.levelDescriptions[_map] if _map < Globals.levelDescriptions.size() else ""
		)
		if not mapChose:
			return
		var col0 := Color("27ff23") if (mapChose and mapChosen == 0) else GM.C_WHITE
		draw_sprite(
			"spr_counter2",
			map1Votes,
			16 + 61,
			(58 + 20 * mapFade - (0 if mapChosen != 0 else mapOff)) + 53,
			1,
			1,
			0,
			col0,
			1
		)
		var col1 := Color("27ff23") if (mapChose and mapChosen == 1) else GM.C_WHITE
		draw_sprite(
			"spr_counter2",
			map2Votes,
			179 + 61,
			(58 + 20 * mapFade - (0 if mapChosen != 1 else mapOff)) + 53,
			1,
			1,
			0,
			col1,
			1
		)
		var col2 := Color("27ff23") if (mapChose and mapChosen == 2) else GM.C_WHITE
		draw_sprite(
			"spr_counter2",
			map3Votes,
			341 + 61,
			(58 + 20 * mapFade - (0 if mapChosen != 2 else mapOff)) + 53,
			1,
			1,
			0,
			col2,
			1
		)
	elif state == 2 or state == 3:
		var sprInd := 0
		for ic in GMNode.all_of("obj_lobby_icon"):
			if ic.master_id != Net.nid:
				continue
			sprInd = ic.selected - 1
			if Net.exeId == Net.nid:
				sprInd += Globals.CHARACTER_SALLY
		if (
			Net.exeId == Net.nid
			or (sprInd + 1 < Net.avCharacters.size() and Net.avCharacters[sprInd + 1])
		):
			draw_sprite(chars[sprInd], charIndex, 132, 230)
		draw_sprite("spr_char_bars", 1 if Net.exeId == Net.nid else 0, 0, 0)
		draw_sprite("spr_char_info", sprInd, 1, 232 - 5)
		if (
			Globals.character == -1
			or (Globals.character == Globals.CHARACTER_EXE and Globals.exeCharacter == -1)
		):
			draw_sprite(
				"spr_counter3",
				charTimer,
				480.0 / 2,
				13,
				countScale,
				countScale,
				0,
				GM.C_RED if charTimer <= 3 else GM.C_WHITE,
				1
			)

	if state == 3:
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, fade))


func _step_visuals() -> void:
	countScale = maxf(1.0, countScale - 0.02)
	for layer_name in ["Background", "Mercoin1", "Mercoin2"]:
		var layer := get_parent().get_node_or_null(layer_name)
		if layer != null:
			layer.visible = state == 0
	if state == 1:
		mapFade = minf(1.0, mapFade + 0.016)
		mapOff = maxf(0.0, mapOff - 0.32)
		var selected_map: int = [map1, map2, map3][mapChosen]
		for pr in GMNode.all_of("obj_lobby_prolet"):
			pr.visible = true
			pr.image_blend = GM.C_DKGRAY
			if pr.map != selected_map:
				pr.set_zone(selected_map)
	if state in [2, 3]:
		var selected_index := 0
		for ic in GMNode.all_of("obj_lobby_icon"):
			if ic.master_id == Net.nid:
				selected_index = ic.selected - 1 + (6 if Net.exeId == Net.nid else 0)
		selected_index = clampi(selected_index, 0, chars.size() - 1)
		if selected_index != _last_preview:
			charIndex = 0.0
			_last_preview = selected_index
		var meta := GM.sprite_meta(chars[selected_index])
		charIndex += (
			float(meta["playbackSpeed"]) / (60.0 if int(meta["playbackSpeedType"]) == 0 else 1.0)
		)
	if state == 3:
		# Draw_64 in the original covers player icons as well as the preview.
		z_index = 1000
		GameAudio.stop_music()
		fade = minf(1.0, fade + 0.01)
		if fade >= 1.0 and not _map_entered:
			_map_entered = true
			Net.goto_map()
