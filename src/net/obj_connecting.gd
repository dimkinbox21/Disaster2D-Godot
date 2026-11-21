extends GMNode
## Port of obj_connecting — "CONNECTING..." screen; Alarm 0 = disnet_connect.

var _alarm := 10


func _ready() -> void:
	super._ready()


func _gm_step() -> void:
	if _alarm > 0:
		_alarm -= 1
		if _alarm == 0:
			if not Net.connect_to_server():
				Globals.errorCode = 0
				get_tree().change_scene_to_file("res://scenes/message.tscn")
	# confirm presses would abort the connection every 20 frames
	if kp(Globals.KeyA):
		Net.net_reset()
	if (
		GM.mouse_x >= 223
		and GM.mouse_x <= 255
		and GM.mouse_y >= 153
		and GM.mouse_y <= 169
		and GM.mouse_pressed(2)
	):
		Net.net_reset()
