extends GMFloor
var nid := 0
var request_cooldown := 0


func _ready():
	depth = -2
	canStuck = false
	gm_static = false
	gm_visible = true
	super._ready()


func change(active: bool):
	collision_active = active
	visible = active
	_bbox_cached = false
	_mcached = false
	sprite_name = "spr_nap_iceblock2" if active else "spr_nap_iceblock3"
	image_index = 0
	image_speed = 1 if active else 0
	GameAudio.play_sound_at("snd_ice_spawn" if active else "snd_ice_break", position)


func _gm_step():
	if sprite_name == "spr_nap_iceblock2" and image_index >= GM.sprite_count(sprite_name) - 1:
		sprite_name = "spr_nap_iceblock"
		image_index = 0
		image_speed = 0
		_bbox_cached = false
		_mcached = false
	request_cooldown = maxi(0, request_cooldown - 1)
