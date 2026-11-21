extends GMNode


# Original obj_redring_screen2: faint foreground haze below the GUI.
func _ready():
	process_physics_priority = 120
	sprite_name = "spr_redring_fore"
	depth = -500
	image_alpha = 0.1
	super._ready()


func _gm_step():
	for camera in all_of("obj_camera"):
		position = camera.render_origin
		break
