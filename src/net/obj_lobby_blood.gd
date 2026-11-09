extends GMNode
## Port of obj_lobby_blood — blood splash when a player leaves the lobby.
## The original has only Step_0: `if(image_index >= image_number - 1) instance_destroy()`
## — the sprite plays once (image_speed = 1) and the instance destroys itself on the
## last frame.

func _ready() -> void:
	gm_name = "obj_lobby_blood"  # spawned dynamically — must self-stamp its group
	super._ready()

func _gm_step() -> void:
	if int(image_index) >= GM.sprite_count(sprite_name) - 1:
		queue_free()

func _gm_draw() -> void:
	draw_self()
