extends GMNode
## Port of obj_blackfadeout — black overlay fading out.

func _ready() -> void:
	gm_name = "obj_blackfadeout"  # spawned dynamically — must self-stamp its group
	add_to_group("gm_sound_stop")
	super._ready()
	image_alpha = 1.0
	depth = -900

func _gm_step() -> void:
	image_alpha -= 0.02
	if image_alpha <= 0:
		queue_free()

func _gm_draw() -> void:
	draw_self()
