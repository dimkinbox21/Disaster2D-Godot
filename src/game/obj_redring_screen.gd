extends GMNode
## Port of obj_redring_screen — the fullscreen frenzy overlay.
## Draw_0: draw_sprite_ext(spr_redring_fore, image_index, obj_camera.x,
## obj_camera.y, 1, 1, 0, c_white, 0.6) — it follows the camera, so the node
## position is the camera position. Destroyed by the player when redRingTimer
## hits 1 (obj_tails Step_0) and on death (scr_move_basic).


func _ready() -> void:
	process_physics_priority = 120
	gm_name = "obj_redring_screen"  # spawned dynamically — must self-stamp its group
	depth = -500  # GMNode._ready derives z_index from depth — set BEFORE super
	super._ready()
	sprite_name = "spr_redring_fore"
	image_alpha = 0.6


func _gm_step() -> void:
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	if cam:
		position = cam.render_origin
