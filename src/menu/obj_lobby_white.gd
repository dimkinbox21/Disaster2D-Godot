extends GMNode
## Port of obj_lobby_white — white screen fade-in on menu start.


func _ready() -> void:
	gm_name = "obj_lobby_white"  # spawned dynamically — must self-stamp its group
	image_alpha = 1.0
	depth = -500
	super._ready()


func _gm_step() -> void:
	image_alpha -= 0.1
	if image_alpha <= 0:
		queue_free()


func _gm_draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color(1, 1, 1, clampf(image_alpha, 0, 1)))
