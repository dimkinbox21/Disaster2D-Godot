extends GMNode
var packet_type := 0
var selected := 0
var roster: Array = []


func _ready():
	gm_name = "chat_target_selector"
	depth = -200
	process_physics_priority = -50
	super._ready()
	for widget in all_of("obj_lobby") + all_of("obj_menu_waiting"):
		widget.voteKick = true
		widget.chatMode = false
		widget.lobby_add_message("\\()~", "choose the player")
		widget.lobby_add_message("\\()~", "(press \\x~ to cancel)")


func _exit_tree():
	for selector in all_of("chat_target_selector"):
		if selector != self and not selector.is_queued_for_deletion():
			return
	for widget in all_of("obj_lobby") + all_of("obj_menu_waiting"):
		widget.voteKick = false


func _gm_step():
	roster = []
	var data: Dictionary = Net.players
	for waiting in all_of("obj_menu_waiting"):
		data = waiting.players
	for id in data:
		if int(id) != Net.nid:
			roster.append(int(id))
	if roster.is_empty():
		queue_free()
		return
	if kp(Globals.KeyLeft):
		selected -= 1
	if kp(Globals.KeyRight):
		selected += 1
	selected = posmod(selected, roster.size())
	if kp(Globals.KeyB):
		GM._pressed_this_frame.erase(Globals.KeyB)
		queue_free()
		return
	if kp(Globals.KeyA):
		GM._pressed_this_frame.erase(Globals.KeyA)
		var b = Net.cpacket_tcp(packet_type)
		b.put_u16(roster[selected])
		Net.send_server_tcp(b)
		queue_free()
		return
	queue_redraw()


func _gm_draw():
	if roster.is_empty():
		return
	var at = Vector2(40, 58)
	for icon in all_of("obj_lobby_icon"):
		if icon.master_id == roster[selected]:
			at = icon.global_position
	for waiting in all_of("obj_menu_waiting"):
		at = Vector2(40 + waiting.players.keys().find(roster[selected]) * 80, 58)
	draw_sprite("spr_lobby_icon_arrow", Time.get_ticks_msec() / 300.0, at.x, at.y)
