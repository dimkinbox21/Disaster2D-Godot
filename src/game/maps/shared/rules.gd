extends Node2D
## Shared client map state. Specific mechanics live in each map directory.
var map: Node
var flash := 0.0
var frame := 0


func _ready() -> void:
	process_physics_priority = 60
