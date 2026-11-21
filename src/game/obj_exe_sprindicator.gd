extends GMNode
## obj_exe_sprindicator Create / Step_2 / Draw_64 / Alarm_0.
## Lives in the HUD canvas; points 32px from the hunter towards the spring use.
var spring := false
var sprX := 0.0
var sprY := 0.0
var remaining := 0


func _ready() -> void:
	gm_name = "obj_exe_sprindicator"
	sprite_name = "spr_indicator3"
	process_physics_priority = 120
	super._ready()
	visible = false


func spring_event(at: Vector2) -> void:
	sprX = at.x
	sprY = at.y
	remaining = 120
	spring = true
	_update_position()


func _gm_step() -> void:
	if remaining > 0:
		remaining -= 1
	if remaining <= 0:
		spring = false
	_update_position()


func _update_position() -> void:
	var player: GMNode = Globals.player
	visible = is_instance_valid(player) and Globals.character == Globals.CHARACTER_EXE and spring
	if not visible:
		return
	var target := Vector2(sprX, sprY)
	var at: Vector2 = player.position.ceil() + (target - player.position).normalized() * 32
	var camera := Vector2.ZERO
	for cam in GMNode.all_of("obj_camera"):
		camera = cam.render_origin
		break
	position = at.ceil() - camera
	image_alpha = 0.7 * remaining / 120.0
	queue_redraw()
