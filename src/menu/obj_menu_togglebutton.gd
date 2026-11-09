extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_togglebutton.

var state := false
var initFrame := 0

func _ready() -> void:
	super._ready()
	initFrame = int(image_index)

func _gm_step() -> void:
	if offset > 0:
		position.y = sY - offset
		offset -= 0.2
	else:
		position.y = sY
	image_index = initFrame + (1.0 if state else 0.0)
