extends GMNode


## obj_jack_in_the_box inherits obj_hiding_parent's front depth and mask.
func _ready() -> void:
	depth = -60
	add_to_group("obj_hiding_parent")
	super._ready()


func _gm_draw() -> void:
	draw_self()
