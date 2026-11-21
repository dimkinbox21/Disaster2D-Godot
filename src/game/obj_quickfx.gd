extends GMNode
## Fading dust and one-shot original blood animations.
var fade := true
var fadeSpeed := 0.05
var motion := Vector2.ZERO
var palette_from: Array = []
var palette_to: Array = []


func frame_texture() -> Texture2D:
	return VisualEffects.actor_texture(self, {"from": palette_from, "to": palette_to})


func _ready() -> void:
	gm_name = "obj_quickeffect"
	if Net.lvlId == 8:
		image_blend = Color.BLACK
	super._ready()


func _gm_animation_end() -> void:
	if not fade:
		queue_free()


func _gm_step() -> void:
	position += motion
	if not fade:
		return
	image_alpha -= fadeSpeed
	if image_alpha <= 0:
		queue_free()


func _gm_draw() -> void:
	draw_self()
