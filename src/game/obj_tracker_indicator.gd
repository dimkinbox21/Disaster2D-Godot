extends Node2D
## obj_surv_indicator target/alarm state. Draw_64 is rendered by the HUD,
## so foreground world art and fog cannot cover the original GUI arrow.
var target_id := -1
var remaining := 180


func _ready() -> void:
	add_to_group("obj_tracker_indicator")
	z_index = 200


func _physics_process(_delta: float) -> void:
	remaining -= 1
	if remaining <= 0:
		queue_free()
