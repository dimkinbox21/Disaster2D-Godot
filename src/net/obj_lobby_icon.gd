extends GMNode
## Port of obj_lobby_icon — player icon in the lobby / charselect.

var master_id := 0
var nickname := ""
var isReady := false
var is_hidden := false
var isSelected := false
var selected := 1
var aY := 0.0
var offset := 0.0

func _ready() -> void:
	gm_name = "obj_lobby_icon"  # spawned dynamically — must self-stamp its group
	super._ready()
	isSelected = false
	isReady = false
	is_hidden = false
	selected = 1
	aY = 0
	offset = 0
	image_xscale = 0
	image_index = 0
	image_speed = 0
	visible = false
	image_blend = GM.C_WHITE
	depth = -200
	sprite_name = "spr_lobby_dicon"

func _gm_step() -> void:
	if OS.get_environment("LOBBY_TRACE") == "1" and Engine.get_physics_frames() % 60 == 0:
		print("ICONTRACE master=", master_id, " pos=", position, " last_pos=", _last_pos,
			" pos_changed=", position != _last_pos, " alpha=", image_alpha, "/", _last_alpha)
	if image_xscale < 1:
		image_xscale += 0.2
	if offset > 0:
		offset -= 0.2

	if Net.nid == master_id:
		position.x = 240
		position.y = 115
		aY = 115
		for lb in GMNode.all_of("obj_lobby"):
			if lb.state == 0 and lb.isReady != isReady:
				offset = 3
				image_blend = GM.C_LIME if lb.isReady else GM.C_WHITE
				isReady = lb.isReady
		visible = true
		_after_pos()
		return

	var i := 0
	for k: int in Net.players:
		var player: Dictionary = Net.players[k]
		if player.get("pending", false):
			continue
		if player.nid == master_id:
			position.x = 40 + i * 80
			position.y = 58
			image_blend = GM.C_LIME if player.isReady else GM.C_WHITE
			for lb in GMNode.all_of("obj_lobby"):
				if lb.state == 0 and player.isReady != isReady:
					offset = 3
					isReady = player.isReady
				elif lb.state != 0:
					image_blend = GM.C_WHITE if isSelected else GM.C_GRAY
			visible = true
		i += 1
	_after_pos()

func _after_pos() -> void:
	position.y = aY - offset

func _gm_step_late() -> void:
	pass

func _gm_draw() -> void:
	if is_hidden:
		return
	for lb in GMNode.all_of("obj_lobby"):
		if lb.state == 0:
			sprite_name = "spr_lobby_dicon"
			if Net.nid == master_id:
				image_index = Unlockables.lobbyIcon
			elif Net.players.has(master_id):
				image_index = Net.players[master_id].icon

	# charselect controls (own draw, mirrors original using Draw for input)
	if lb_state() == 2 and Net.nid == master_id and not isSelected:
		if kp(Globals.KeyLeft):
			offset = 3
			selected -= 1
			if Net.exeId == master_id:
				if selected < 1:
					selected = 4
			else:
				if selected < 1:
					selected = 6
			GameAudio.play_sound("snd_menu_select")
		elif kp(Globals.KeyRight):
			offset = 3
			selected += 1
			if Net.exeId == master_id:
				if selected > 4:
					selected = 1
			else:
				if selected > 6:
					selected = 1
			GameAudio.play_sound("snd_menu_select")
		if kp(Globals.KeyA):
			if Net.exeId == master_id or (selected < Net.avCharacters.size() and Net.avCharacters[selected]):
				var packet: StreamPeerBuffer
				if Net.exeId == master_id:
					packet = Net.cpacket_tcp(Net.PacketType.CLIENT_REQUEST_EXECHARACTER, false)
				else:
					packet = Net.cpacket_tcp(Net.PacketType.CLIENT_REQUEST_CHARACTER, false)
				packet.put_u8(selected)
				Net.send_server_tcp(packet)
			else:
				GameAudio.play_sound("snd_nono")

		if Net.exeId == master_id:
			match selected:
				1: sprite_name = "spr_lobby_exeicon"
				2: sprite_name = "spr_lobby_exeicon2"
				3: sprite_name = "spr_lobby_exeicon3"
				4: sprite_name = "spr_lobby_exeicon4"
			image_blend = GM.C_GRAY
		else:
			image_index = selected + 1
			image_blend = GM.C_GRAY

	if sprite_name != "spr_lobby_exeicon5" and Net.exeId == master_id:
		# animate at sprite's own speed like image_speed = 1
		pass

	position.y = aY - offset
	if OS.get_environment("LOBBY_TRACE") == "3" and Engine.get_physics_frames() % 60 == 0:
		var _t: Texture2D = GM.sprite_texture(sprite_name, int(image_index))
		print("DRAWALL master=", master_id, " pos=", position, " spr=", sprite_name,
			" idx=", int(image_index), " tex=", (_t.get_size() if _t else null), " scale=", image_xscale,
			" alpha=", image_alpha, " vis=", visible, " gm_static=", gm_static)
	draw_self()
	var _size := GM.scr_text_spr(self, -2000, -200, nickname)
	GM.scr_text_spr(self, position.x - _size / 2, aY + 16, nickname)

	if lb_state() == 2 and not isSelected:
		if master_id == Net.nid:
			draw_sprite("spr_lobby_icon_arrow", int(Time.get_ticks_msec() / 150) % 3, position.x, position.y)
			for k: int in Net.players:
				if Net.players[k].character == selected and Net.exeId != master_id:
					draw_sprite("spr_lobby_icon_used", 0, position.x - 12, position.y - 12)
					break

func lb_state() -> int:
	for lb in GMNode.all_of("obj_lobby"):
		return lb.state
	return 0
