extends GMNode


## obj_warning Step_0: fade by distance; spr_warning loops at its original 5 FPS.
func _ready() -> void:
	gm_static = false
	if sprite_name == "":
		sprite_name = "spr_warning"
	image_speed = 1.0
	image_alpha = 0.0
	super._ready()


func _gm_step() -> void:
	var player: GMNode = Globals.player
	if not is_instance_valid(player):
		image_alpha = 0.0
		return
	var a := bbox_rect()
	var b := player.bbox_rect()
	var dx := maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	image_alpha = clampf(1.0 - Vector2(dx, dy).length() / 48.0, 0.0, 1.0)
