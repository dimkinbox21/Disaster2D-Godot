extends GMNode
## Port of obj_menu_waiting — waiting room: player list, chat, countdown clock.
## (The snake minigame is stage-3 polish; obj_minigame is stubbed.)

var draw_clock := false
var time_minutes := 0
var time_seconds := 0
var clockAngle := 0.0
var timeFrame := 0

var players: Dictionary = {}
var chat: Array = []
var chatMsg := ""
var chatMode := false
var voteKick := false

func _ready() -> void:
	super._ready()
	sprite_name = "spr_menu_connection"
	draw_clock = false
	time_minutes = 0
	time_seconds = 0
	timeFrame = 0
	players = {}
	chat = []
	chatMsg = ""
	chatMode = false
	voteKick = false

func lobby_add_message(sender: String, msg: String) -> void:
	if Globals.muteChat:
		return
	GameAudio.stop_sound("snd_message")
	GameAudio.play_sound("snd_message")
	chat.append(sender + ": " + Net.chat_filter(msg) + "~")
	if chat.size() >= 9:
		chat.pop_front()

func _gm_step() -> void:
	if chatMode:
		if GM.key_down(GM.VK_CONTROL) and GM.key_pressed(86):
			GM.keyboard_string = DisplayServer.clipboard_get()
		chatMsg = GameConfig._gm_string_copy(GM.keyboard_string.to_lower(), 0, 48)
		if GM.keyboard_string.length() > 48:
			GM.keyboard_string = chatMsg

	if GM.key_pressed(GM.VK_ENTER) and not voteKick:
		# Enter toggles chat / sends message (KeyPress_13)
		if not chatMode:
			chatMode = true
			GM.keyboard_string = chatMsg
		else:
			chatMode = false
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
						Globals.muteChat = true
						lobby_add_message("(mute)", "\\chat is now muted.~")
				_:
					var packet := Net.cpacket_tcp(Net.PacketType.CLIENT_CHAT_MESSAGE, true)
					packet.put_u16(Net.nid)
					Net._gm_put_string(packet, Net.chat_filter(chatMsg))
					Net.send_server_tcp(packet)
					lobby_add_message(Globals.nickname, chatMsg)
			chatMsg = ""
			GM.keyboard_string = ""

func _gm_draw() -> void:
	# original only has a Draw GUI event — the banner itself auto-draws
	draw_self()
	# chat is drawn while waiting music plays (Draw_64 port)
	if true:
		var str_ := ""
		for c in chat:
			str_ += c + "\n"
		GM.scr_text_spr(self, 3, 148 - 6 + 40, str_)
		var ind := 0
		if chatMode or chatMsg.length() > 0:
			ind = 1
		draw_sprite("spr_lobby_chatbox", ind, 0, 211 + 40)
		GM.scr_text_spr(self, 2, 214 + 40, chatMsg)

	if true:  # !obj_minigame.ingame (minigame stubbed out)
		var i := 0
		for k: int in players:
			var plr: Dictionary = players[k]
			var _x := 40.0 + i * 80.0
			var _y := 58.0
			var sprite := "spr_lobby_dicon"
			var index := 0
			if plr.icon == 19954:
				if plr.exe:
					match plr.char:
						0: sprite = "spr_lobby_exeicon"
						1: sprite = "spr_lobby_exeicon2"
						2: sprite = "spr_lobby_exeicon3"
						3: sprite = "spr_lobby_exeicon4"
				else:
					sprite = "spr_lobby_icon"
					index = plr.char + 2
			else:
				sprite = "spr_lobby_dicon"
				index = plr.icon
			draw_sprite_ext_port(sprite, index, _x, _y, plr.scale, 1.0)
			var _size := GM.scr_text_spr(self, -2000, -200, plr.nickname)
			GM.scr_text_spr(self, _x - _size / 2, _y + 16, plr.nickname)
			if plr.scale < 1:
				plr.scale += 0.2
			else:
				plr.scale = 1.0
			i += 1

	if voteKick:
		draw_sprite("spr_lobby_votekick", int(Time.get_ticks_msec() / 300) % 4, 240, 8)
		return
	if not draw_clock:
		return
	draw_sprite("spr_clock", 0, 211, 0)
	clockAngle = GM.gml_lerp(clockAngle, -45.0 * timeFrame, 0.2)
	draw_sprite("spr_clockhand", 0, 212, 11.5, 1, 1, clockAngle)
	draw_sprite("spr_counter", 10, 233, 4)
	draw_counter(time_minutes, 224, 4)
	draw_counter_m(time_seconds, 244, 4, 2)

func draw_sprite_ext_port(name_: String, index: float, x: float, y: float, xs: float, ys: float) -> void:
	draw_sprite(name_, index, x, y, xs, ys)

func draw_counter(number: int, xx: float, yy: float) -> void:
	draw_sprite("spr_counter", number, xx, yy)

func draw_counter_m(number: int, xx: float, yy: float, zeros: int) -> void:
	var s := str(number)
	var dif := zeros - s.length()
	var xX := 0.0
	for i in dif:
		draw_sprite("spr_counter", 0, xx + 11 * i, yy)
		xX += 11
	for i in s.length():
		draw_sprite("spr_counter", int(s[i]), xx + xX + 11 * i, yy)
