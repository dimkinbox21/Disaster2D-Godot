extends GMNode
## Port of obj_message — error screen (sprite frames = error codes).

func _ready() -> void:
	super._ready()
	image_index = Globals.errorCode
	Net.shutdown()
	GameAudio.stop_music()

func _gm_step() -> void:
	if kp(Globals.KeyA) or kp(GM.VK_ENTER) or GM.mouse_pressed(2):
		Net.net_reset()
