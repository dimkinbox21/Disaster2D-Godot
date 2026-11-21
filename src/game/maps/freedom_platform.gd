extends "res://src/game/obj_platform_jumptrough.gd"


func _ready():
	canStuck = false
	gm_static = false
	position.y = 1624
	super._ready()
	gm_name = "obj_marijuna_lavaplatform"
	add_child(load("res://src/game/maps/freedom_lava_audio.gd").new())


func cached_bbox() -> Rect2:
	return bbox_rect()


func grid_bbox() -> Rect2:
	return Rect2(position.x, 1090, 160, 650)
