extends GMNode
## Simple map objects: eggstatue (hiding spot), angleanuller, corpse — deco/markers.


func _ready() -> void:
	super._ready()
	if gm_name == "obj_eggstatue":
		add_to_group("obj_hiding_parent")
		image_speed = 0.0


func _gm_draw() -> void:
	draw_self()
