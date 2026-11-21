extends GMNode
var record: Dictionary = {}
var properties: Dictionary = {}


func _ready():
	depth = 10
	image_speed = 0
	super._ready()


func _gm_draw():
	var scene = get_tree().current_scene
	var p = Globals.player
	if (
		scene != null
		and scene.get("rules") != null
		and is_instance_valid(p)
		and not p.isDead
		and int(scene.rules.state.get("cooldown", 0)) <= 0
		and bbox_rect().intersects(p.bbox_rect())
	):
		draw_sprite(
			"spr_limpcity_eye_hint", int(Time.get_ticks_msec() / 400), position.x, position.y
		)
	draw_self()
