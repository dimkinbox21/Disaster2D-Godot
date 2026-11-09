extends GMNode
## Quick visual effects (dust, blood) — fade out and die.

func _gm_step() -> void:
	image_alpha -= 0.08
	if image_alpha <= 0:
		queue_free()

func _gm_draw() -> void:
	draw_self()
