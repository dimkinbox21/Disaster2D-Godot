extends GMNode
## Port of obj_lobby_white — white screen fade-in on menu start.

func _ready() -> void:
	gm_name = "obj_lobby_white"  # spawned dynamically — must self-stamp its group
	image_alpha = 1.0
	z_index = 4096
	super._ready()

func _gm_step() -> void:
	image_alpha -= 0.1
	if image_alpha <= 0:
		queue_free()

func _gm_draw() -> void:
	draw_self()
