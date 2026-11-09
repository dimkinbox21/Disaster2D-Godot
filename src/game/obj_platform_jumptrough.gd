extends GMFloor
## Port of obj_platform_jumptrough — one-way platform (jump through from below).

func _ready() -> void:
	add_to_group("gm_jumpthrough")
	super._ready()
	gm_name = "obj_platform_jumptrough"  # after super: GMFloor keeps the scene stamp
